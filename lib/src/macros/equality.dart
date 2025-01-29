import 'package:collection/collection.dart' show DeepCollectionEquality, IterableExtension;
import 'package:macros/macros.dart' hide MacroException;
import 'package:meta/meta.dart';
import 'package:model_suite/src/macros_utils.dart';
import './../macros.dart';
part 'utils/jenkins_hash.dart';

/// URI for the equatable library
final _equality = Uri.parse('package:model_suite/src/macros/equality.dart');

/// Utility function for deep equality comparison of collections
/// Uses [DeepCollectionEquality] from the collection package
final deepEquals = const DeepCollectionEquality().equals;

/// Error message generation for equality-related operations
mixin EqualityMacroException {
  MacroException equalityOperatorError(DiagnosticTarget target) =>
      MacroException('Cannot generate a `==` operator for a class that already has one.', target: target);

  MacroException createHashCodeError(DiagnosticTarget target) =>
      MacroException('Cannot generate a `hashCode` getter for a class that already has one.', target: target);

  MacroException lateFieldError(String className, DiagnosticTarget target) =>
      MacroException('Cannot generate equality for `$className` class with late fields', target: target);


}

/// {@template equality}
/// A macro that automatically generates equality operations for a class
/// 1. Generate the `==` operator for comparing instances
/// 2. Generate the `hashCode` getter for consistent hashing
/// 3. Handle deep equality comparison for collection fields
/// {@endtemplate}
macro
class EqualityMacro with EqualityMacroException, _Equals, _HashCode implements ClassDeclarationsMacro {
  /// {@macro equality}
  const EqualityMacro();

  Future<Iterable<String>> getFieldsName(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final fields = await builder.allFieldsOf(clazz);
    List<String> ls = [];
    for (final f in fields) {
      if (f.hasLate) throw lateFieldError(clazz.identifier.name, f.asDiagnosticTarget);
      if (!f.hasStatic) ls.add(f.identifier.name);
    }
    return ls;
  }

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    /// Shared resources for equality and hashCode generation
    final (equality, fields, hashCode) = await (
      getEquality(clazz, builder),
      getFieldsName(clazz, builder),
      getHashCode(clazz, builder),
    ).wait;

    await (
      buildEquals(clazz, fields, equality, builder),
      buildHashCode(clazz, fields, hashCode, builder),
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

  Future<void> buildEquals(
    ClassDeclaration clazz,
    Iterable<String> fieldsName,
    MethodDeclaration? equality,
    MemberDeclarationBuilder builder,
  ) async {
    if (equality != null) throw equalityOperatorError(equality.asDiagnosticTarget);

    var generics = [
      for (final type in clazz.typeParameters) ...[
        type.identifier,
      ],
    ].joinAsCode(', ');

    final (boolean, identical, deepEquals) = await (
      builder.codeFrom.bool,
      builder.codeFrom.identical,
      builder.codeFrom.get('deepEquals', _equality),
    ).wait;

    var body = <Object>[
      fieldsName.isEmpty ? ';\n' : '\n',
      for (final field in fieldsName) ...[
        '    && ',
        deepEquals,
        '($field, other.$field)',
        field != fieldsName.last ? '\n' : ';\n',
      ],
    ];

    return builder.declareInType(
      DeclarationCode.fromParts([
        '  ',
        boolean,
        ' operator==(',
        ' covariant ',
        clazz.identifier,
        if (generics.isNotEmpty) ...[
          '<',
          ...generics,
          '>',
        ],
        ' other){\n',
        '  if(',
        identical,
        '(this, other)) return true;\n',
        '    return other is ${clazz.identifier.name} && ',
        'other.runtimeType == runtimeType',
        ...body,
        '  }'
      ]),
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

  Future<void> buildHashCode(
    ClassDeclaration clazz,
    Iterable<String> fieldsName,
    MethodDeclaration? hashCode,
    MemberDeclarationBuilder builder,
  ) async {
    if (hashCode != null) throw createHashCodeError(hashCode.asDiagnosticTarget);

    final (integer, jenkinsHash) =
        await (builder.codeFrom.int, builder.codeFrom.get('jenkinsHash', _equality)).wait;

    var body = [
      jenkinsHash,
      '([',
      fieldsName.join(', '),
      ']);',
    ];

    return builder.declareInType(
      DeclarationCode.fromParts(['  ', integer.code, ' get hashCode {\n    return ', ...body, '\n  }']),
    );
  }
}
