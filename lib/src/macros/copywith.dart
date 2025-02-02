import 'dart:async';
import 'package:macros/macros.dart' hide MacroException;
import 'package:model_suite/src/model.dart';
import 'package:model_suite/utils/clazz_data.dart';

import 'package:model_suite/utils/macros_utils.dart';

final _copywithMacro = Uri.parse('package:model_suite/src/macros/copywith.dart');

const undefined = _Undefined();

class _Undefined {
  const _Undefined();
}

/// Mixin that provides exception handling functionality for the CopyWith macro
/// Contains methods to generate specific error messages for different scenarios
class _CopyWithMacroException {
  final ClassDeclaration clazz;
  const _CopyWithMacroException(this.clazz);

  String get className => clazz.identifier.name;
  DiagnosticTarget get classTarget => clazz.asDiagnosticTarget;

  /// Warns when a copyWith method already exists in the target class
  MacroException existingCopyWithWarning({String? className, DiagnosticTarget? target}) => MacroException(
      'A `copyWith` method already exists in this class. To use @CopyWithMacro, either remove the existing copyWith method or remove the macro annotation.',
      target: target ?? clazz.asDiagnosticTarget,
      severity: Severity.warning);

  /// Error when the target class is missing a required constructor
  MacroException missingConstructorError({String? className, DiagnosticTarget? target}) => MacroException(
      'Class `${className ?? this.className}` is missing the required constructor. Please define a constructor matching the name specified in @CopyWithMacro annotation. If using default constructor, ensure it exists.',
      target: target ?? classTarget);

  /// Error when constructor parameters are missing type annotations
  MacroException missingTypeAnnotationsError({String? className, DiagnosticTarget? target}) => MacroException(
      'All constructor parameters in `${className ?? this.className}` must have explicit type annotations. Found nullable or dynamic parameters which are not supported. Please add type annotations to all parameters.',
      target: target ?? classTarget);

  /// Error when the class is abstract or sealed
  MacroException invalidClassTypeError({String? className, DiagnosticTarget? target}) => MacroException(
      'Class `${className ?? this.className}` cannot be abstract or sealed when using @CopyWithMacro. Remove the abstract/sealed modifier or use a concrete class instead.',
      target: target ?? classTarget);

  // Error when the class has no parameters in the constructor
  MacroException missingParametersWarning({String? className, DiagnosticTarget? target}) => MacroException(
      'Class `${className ?? this.className}` has no parameters in the constructor. Please add parameters to the constructor to use @CopyWithMacro.',
      target: target ?? classTarget,
      severity: Severity.warning);
}

/// Macro implementation for generating copyWith functionality
/// Implements both declaration and definition phase macros
class CopyWithModelBuilder extends ModelBuilder {
  const CopyWithModelBuilder(super.clazzData, super.builder);

  /// Fields that should be excluded from the copyWith method
  Set<String> get immutable => const {};

  /// Named constructor to use for generating copyWith (empty string for unnamed constructor)
  String get constructor => '';

  @override
  Future<void> build() async {
    if (clazzData.hasCopyWith) return;
    final _CopyWithMacroException exception = _CopyWithMacroException(clazz);
    if (clazz.hasAbstract || clazz.hasSealed) throw exception.invalidClassTypeError();

    final params = <Parameter>[];

    if (!clazzData.hasConstructor) {
      if (clazzData.isModelConstructorDefined) {
        params.addAll(clazzData.clazzfields.map(Parameter.fromBothFieldAndFPD));
        if (clazzData.hasSuperConstructor) {
          params.addAll(clazzData.superConstructor!.parameters.map(Parameter.fromFPD));
        }
      } else {
        throw exception.missingConstructorError();
      }
    } else if (clazzData.constructor!.parameters.isEmpty) {
      if (clazzData.allFields.isNotEmpty)
        builder.report(exception
            .missingParametersWarning(
              className: clazzData.constructorAlongWithClazzName,
              target: clazzData.constructor!.asDiagnosticTarget,
            )
            .diagnostic);
      return;
    } else {
      var fieldMapping = {for (var f in clazzData.allFields) f.identifier.name: f};

      final constructorParameters = clazzData.constructor!.parameters;
      for (var cParm in constructorParameters) {
        var field = fieldMapping[cParm.identifier.name];
        if (field == null) throw exception.missingTypeAnnotationsError(className: cParm.identifier.name);
        params.add(Parameter.fromBothFieldAndFPD(field, cParm));
      }
    }

    // Retrieve object and Undefined codes
    var (object, undefined) = await (
      builder.codeFrom.object,
      builder.codeFrom.get('undefined', _copywithMacro),
    ).wait;

    // Generate arguments and parameter list for the copyWith method
    final args = [
      for (var (i, param) in params.indexed)
        if (!immutable.contains(param.name)) ...[
          '\n  ',
          object,
          '? ',
          param.name,
          if (param.isNullable) ...[' = ', undefined],
          if (i < params.length - 1) ', '
        ],
    ];

    final parmslist = [
      for (var (i, param) in params.indexed) ...[
        '\n  ',
        ...param.copyWith(immutable.contains(param.name), undefined),
        if (i < params.length - 1) ', '
      ],
    ];

    final body = DeclarationCode.fromParts(
      [
        '\n  ',
        clazz.identifier,
        if (clazzData.isGeneric) ...[
          '<',
          ...clazzData.generics.map((e) => e.identifier).toList().joinAsCode(', '),
          '>',
        ],
        ' Function({',
        for (final (i, field) in params.indexed) ...[
          '\n  ',
          field.typeCode,
          ' ',
          field.name,
          if (i < params.length - 1) ', '
        ],
        '})\n  get copyWith => ({',
        ...args,
        '})\n  => ',
        clazzData.constructorAlongWithClazzName,
        '(',
        ...parmslist,
        ');\n',
      ],
    );
    return builder.declareInType(body);
  }
}

/// Represents a parameter in the copyWith method generation
class Parameter {
  /// Parameter name
  final String name;

  /// Parameter type annotation
  final TypeAnnotation typeCode;

  /// Whether the parameter is named
  final bool isNamed;

  /// Whether the parameter is nullable
  final bool isNullable;

  /// Whether the parameter is required
  final bool isRequired;

  bool get isPositional => !isNamed;
  bool get isOptional => !isRequired;

  const Parameter({
    required this.name,
    required this.typeCode,
    required this.isNamed,
    required this.isNullable,
    required this.isRequired,
  });

  /// FieldDeclaration field is class variable
  /// FormalParameterDeclaration cParam is constructor parameter
  factory Parameter.fromBothFieldAndFPD(FieldDeclaration field, [FormalParameterDeclaration? cParam]) {
    return Parameter(
      isNullable: field.type.isNullable,
      name: field.identifier.name,
      typeCode: field.type.code,
      isNamed: cParam?.isNamed ?? true,
      isRequired: cParam?.isRequired ?? !field.type.isNullable,
    );
  }
  factory Parameter.fromFPD(FormalParameterDeclaration cParam) {
    return Parameter(
      isNullable: cParam.type.isNullable,
      name: cParam.identifier.name,
      typeCode: cParam.type.code,
      isNamed: cParam.isNamed,
      isRequired: cParam.isRequired,
    );
  }

  /// Generates the parameter code for the copyWith method
  List<Object> copyWith(bool immutable, Object undefined) {
    var parts = <Object>[isNamed ? '$name : (' : '('];
    if (immutable) return [...parts, 'this.', name, ') as ', typeCode];
    parts
      ..addAll(isNullable ? [name, ' == ', undefined] : [name, ' == null'])
      ..addAll([' ? this.', name, ' : ', name, ') as ', typeCode]);

    return parts;
  }
}
