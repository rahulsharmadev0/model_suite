import 'package:collection/collection.dart' show DeepCollectionEquality, IterableExtension;
import 'package:macros/macros.dart' hide MacroException;
import 'package:meta/meta.dart';
import 'package:model_suite/model.dart';
import 'utils/clazz_data.dart';
import 'utils/macros_utils.dart';
part 'utils/jenkins_hash.dart';

/// URI for the equatable library
final _equality = Uri.parse('package:model_suite/src/equality.dart');

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
class EqualityModelBuilder extends ModelBuilder with EqualityMacroException {
  const EqualityModelBuilder(super.clazzData, super.builder);

  @override
  Future<void> build() async {
    final fieldsName = clazzData.allFields.map((f) {
      if (f.hasLate) throw lateFieldError(clazzData.name, clazzData.clazz.asDiagnosticTarget);
      return f.identifier.name;
    });

    await (
      buildEquals(fieldsName),
      buildHashCode(fieldsName),
    ).wait;
  }

  /// Mixin that handles the equality operator generation
  ///
  /// Implements the logic for generating a proper `==` operator that:
  /// - Handles identical instance comparison
  /// - Compares runtime types
  /// - Performs deep equality comparison of fields
  Future<void> buildEquals(Iterable<String> fieldsName) async {
    if (clazzData.hasEqualityOperator) return;

    var generics = clazzData.generics.map((g) => g.name);

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
        clazzData.identifier,
        if (generics.isNotEmpty) ...[
          '<',
          ...generics,
          '>',
        ],
        ' other){\n',
        '  if(',
        identical,
        '(this, other)) return true;\n',
        '    return other is ${clazzData.name} && ',
        'other.runtimeType == runtimeType',
        ...body,
        '  }'
      ]),
    );
  }

  /// Mixin that handles the hashCode generation
  ///
  /// Implements the logic for generating a consistent hashCode that:
  /// - Uses Jenkins hash algorithm for combining field values
  /// - Handles all field types including collections
  /// - Maintains hash consistency with equality implementation
  Future<void> buildHashCode(Iterable<String> fieldsName) async {
    if (clazzData.hasHashCode) return;

    final (integer, jenkinsHash) =
        await (builder.codeFrom.int, builder.codeFrom.get('jenkinsHash', _equality)).wait;

    var body = [jenkinsHash, '([', fieldsName.join(', '), ']);'];

    return builder.declareInType(
      DeclarationCode.fromParts(['\n  ', integer.code, ' get hashCode {\n    return ', ...body, '\n  }']),
    );
  }
}
