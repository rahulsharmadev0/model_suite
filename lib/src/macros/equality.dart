import 'package:collection/collection.dart' show DeepCollectionEquality, IterableExtension;
import 'package:macros/macros.dart' hide MacroException;
import 'package:meta/meta.dart';
import 'package:model_suite/src/macros_utils.dart';
import './../macros.dart';
part 'utils/jenkins_hash.dart';


/// URI for the equatable library
final _equatable = Uri.parse('package:model_suite/src/macros/equality.dart');

/// Utility function for deep equality comparison of collections
/// Uses [DeepCollectionEquality] from the collection package
final deepEquals = const DeepCollectionEquality().equals;

/// Error message generation for equality-related operations
mixin EqualityMacroException {
  MacroException equalityOperatorError(DiagnosticTarget target) =>
      MacroException('Cannot generate a `==` operator for a class that already has one.', target: target);

  MacroException createHashCodeError(DiagnosticTarget target) =>
      MacroException('Cannot generate a `hashCode` getter for a class that already has one.', target: target);
}

/// {@template equality}
/// A macro that automatically generates equality operations for a class
///
/// This macro implements both [ClassDeclarationsMacro] and [ClassDefinitionMacro] to:
/// 1. Generate the `==` operator for comparing instances
/// 2. Generate the `hashCode` getter for consistent hashing
/// 3. Handle deep equality comparison for collection fields
/// {@endtemplate}
macro
class EqualityMacro
    with EqualityMacroException, _Equals, _HashCode
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  /// {@macro equality}
  const EqualityMacro();

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    final (equality, hashCode) = await (
      getEquality(clazz, builder),
      getHashCode(clazz, builder),
    ).wait;

    await (
      declareEquals(clazz, equality, builder),
      declareHashCode(clazz, hashCode, builder),
    ).wait;
  }

  @override
  Future<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final (equality, hashCode) = await (
      getEquality(clazz, builder),
      getHashCode(clazz, builder),
    ).wait;

    await (
      defineEquals(clazz, equality, builder),
      defineHashCode(clazz, hashCode, builder),
    ).wait;
  }
}

/// Mixin that handles the equality operator generation
///
/// Implements the logic for generating a proper `==` operator that:
/// - Handles identical instance comparison
/// - Compares runtime types
/// - Performs deep equality comparison of fields
mixin _Equals on EqualityMacroException {
  Future<MethodDeclaration?> getEquality(ClassDeclaration clazz, DeclarationPhaseIntrospector builder) async {
    final methods = await builder.methodsOf(clazz);
    return methods.firstWhereOrNull((m) => m.identifier.name == '==');
  }

  Future<void> declareEquals(
    ClassDeclaration clazz,
    MethodDeclaration? equality,
    MemberDeclarationBuilder builder,
  ) async {
    if (equality != null) throw equalityOperatorError(equality.asDiagnosticTarget);

    final boolean = await builder.codeFrom.bool;

    return builder.declareInType(
      DeclarationCode.fromParts([
        '  external ',
        boolean,
        ' operator==(',
        ' covariant ${clazz.identifier.name}',
        ' other);',
      ]),
    );
  }

  Future<void> defineEquals(
    ClassDeclaration clazz,
    MethodDeclaration? equality,
    TypeDefinitionBuilder builder,
  ) async {
    if (equality == null) return;

    final (equalsMethod, fields, identical, deepEquals) = await (
      builder.buildMethod(equality.identifier),
      builder.allFieldsOf(clazz),
      builder.codeFrom.identical,
      builder.codeFrom.get('deepEquals', _equatable),
    ).wait;

    fields.removeWhere((f) => f.hasStatic);

    if (fields.isEmpty) {
      return equalsMethod.augment(
        FunctionBodyCode.fromParts(
          [
            '{',
            'if (',
            identical,
            '(this, other)',
            ')',
            'return true;',
            'return other is ${clazz.identifier.name} && ',
            'other.runtimeType == runtimeType;',
            '}',
          ],
        ),
      );
    }

    final fieldNames = fields.map((f) => f.identifier.name);
    final lastField = fieldNames.last;
    return equalsMethod.augment(
      FunctionBodyCode.fromParts(
        [
          '{',
          'if (',
          identical,
          '(this, other)',
          ')',
          'return true;',
          'return other is ${clazz.identifier.name} && ',
          'other.runtimeType == runtimeType && ',
          for (final field in fieldNames) ...[
            deepEquals,
            '($field, other.$field)',
            if (field != lastField) ' && ',
          ],
          ';',
          '}',
        ],
      ),
    );
  }
}

/// Mixin that handles the hashCode generation
///
/// Implements the logic for generating a consistent hashCode that:
/// - Uses Jenkins hash algorithm for combining field values
/// - Handles all field types including collections
/// - Maintains hash consistency with equality implementation
mixin _HashCode on EqualityMacroException {
  Future<MethodDeclaration?> getHashCode(ClassDeclaration clazz, DeclarationPhaseIntrospector builder) async {
    final methods = await builder.methodsOf(clazz);
    return methods.firstWhereOrNull((m) => m.identifier.name == 'hashCode');
  }

  Future<void> declareHashCode(
    ClassDeclaration clazz,
    MethodDeclaration? hashCode,
    MemberDeclarationBuilder builder,
  ) async {
    if (hashCode != null) throw createHashCodeError(hashCode.asDiagnosticTarget);
    final integer = await builder.codeFrom.int;

    return builder.declareInType(
      DeclarationCode.fromParts(['  external ', integer, ' get hashCode;']),
    );
  }

  Future<void> defineHashCode(
    ClassDeclaration clazz,
    MethodDeclaration? hashCode,
    TypeDefinitionBuilder builder,
  ) async {
    if (hashCode == null) return;

    final (hashCodeMethod, jenkinsHash, fields) = await (
      builder.buildMethod(hashCode.identifier),
      builder.codeFrom.get('jenkinsHash', _equatable),
      builder.allFieldsOf(clazz),
    ).wait;

    fields.removeWhere((f) => f.hasStatic);

    final fieldNames = fields.map((f) => f.identifier.name);

    return hashCodeMethod.augment(
      FunctionBodyCode.fromParts(
        [
          '=> ',
          jenkinsHash,
          '([',
          fieldNames.join(', '),
          ']);',
        ],
      ),
    );
  }
}
