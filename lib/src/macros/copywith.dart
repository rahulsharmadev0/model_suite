import 'dart:async';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart' hide MacroException;
import 'package:model_suite/src/macros.dart';
import 'package:model_suite/src/macros_utils.dart';

final _copywithMacro = Uri.parse('package:model_suite/src/macros/copywith.dart');

const undefined = _Undefined();

class _Undefined {
  const _Undefined();
}

/// Mixin that provides exception handling functionality for the CopyWith macro
/// Contains methods to generate specific error messages for different scenarios
mixin _CopyWithMacroException {
  /// Warns when a copyWith method already exists in the target class
  MacroException existingCopyWithWarning(DiagnosticTarget target) => MacroException(
      'A `copyWith` method already exists in this class. To use @CopyWithMacro, either remove the existing copyWith method or remove the macro annotation.',
      target: target,
      severity: Severity.warning);

  /// Error when the target class is missing a required constructor
  MacroException missingConstructorError(ClassDeclaration clazz) => MacroException(
      'Class "${clazz.identifier.name}" is missing the required constructor. Please define a constructor matching the name specified in @CopyWithMacro annotation. If using default constructor, ensure it exists.',
      target: clazz.asDiagnosticTarget);

  /// Error when constructor parameters are missing type annotations
  MacroException missingTypeAnnotationsError(ClassDeclaration clazz) => MacroException(
      'All constructor parameters in "${clazz.identifier.name}" must have explicit type annotations. Found nullable or dynamic parameters which are not supported. Please add type annotations to all parameters.',
      target: clazz.asDiagnosticTarget);

  /// Error when the class is abstract or sealed
  MacroException invalidClassTypeError(ClassDeclaration clazz) => MacroException(
      'Class `${clazz.identifier.name}` cannot be abstract or sealed when using @CopyWithMacro. Remove the abstract/sealed modifier or use a concrete class instead.',
      target: clazz.asDiagnosticTarget);

  // Error when the class has no parameters in the constructor
  MacroException missingParametersWarning(String clazz, DeclarationDiagnosticTarget asDiagnosticTarget) =>
      MacroException(
          'Class "$clazz" has no parameters in the constructor. Please add parameters to the constructor to use @CopyWithMacro.',
          target: asDiagnosticTarget,
          severity: Severity.warning);
}

/// Macro implementation for generating copyWith functionality
/// Implements both declaration and definition phase macros
macro
class CopyWithMacro with _CopyWithMacroException implements ClassDeclarationsMacro {
  /// Fields that should be excluded from the copyWith method
  final Set<String> immutable;

  /// Named constructor to use for generating copyWith (empty string for unnamed constructor)
  final String constructor;

  const CopyWithMacro({this.constructor = '', this.immutable = const {}});

  @override
  Future<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    // Validate class is not abstract or sealed
    if (clazz.hasAbstract || clazz.hasSealed) throw invalidClassTypeError(clazz);
    // Check for existing copyWith method
    final copyWith = await getMethod(clazz, builder);
    if (copyWith != null) throw existingCopyWithWarning(clazz.asDiagnosticTarget);

    // Retrieve method and constructor definitions
    final (allFields, defConstructor) = await (
      builder.allFieldsOf(clazz),
      builder.defConstructorOf(clazz, constructor),
    ).wait;

    // Validate constructor
    if (defConstructor == null || constructor != defConstructor.identifier.name) {
      throw missingConstructorError(clazz);
    } else if (defConstructor.parameters.isEmpty) {
      if (allFields.isNotEmpty)
        builder.report(
            missingParametersWarning(clazz.identifier.name, defConstructor.asDiagnosticTarget).diagnostic);
      return;
    }

    var fieldMapping = {for (var field in allFields) field.identifier.name: field};
    // Retrieve parameters and validate types
    final params = <Parameter>[];

    for (var cParm in defConstructor.parameters) {
      var field = fieldMapping[cParm.identifier.name];
      if (field == null) throw missingTypeAnnotationsError(clazz);
      // Generic constructor parameter
      params.add(Parameter.fromFPD(field, cParm));
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

    // Generate method implementation with parameter handling
    String constructorName = defConstructor.identifier.name;
    if (constructor.isNotEmpty) constructorName = '.$constructorName';

    final body = DeclarationCode.fromParts(
      [
        clazz.identifier,
        ' Function({',
        for (final (i, field) in params.indexed) ...[
          '\n  ',
          field.typeCode,
          ' ',
          field.name,
          if (i < params.length - 1) ', '
        ],
        '}) get copyWith => ({',
        ...args,
        '}) => ',
        clazz.identifier,
        constructorName,
        '(',
        ...parmslist,
        ');\n',
      ],
    );
    return builder.declareInType(body);
  }

  /// Retrieves the copyWith method declaration if it exists
  Future<MethodDeclaration?> getMethod(ClassDeclaration clazz, DeclarationPhaseIntrospector builder) async {
    final methods = await builder.methodsOf(clazz);
    return methods.firstWhereOrNull((m) => m.identifier.name == 'copyWith');
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
  factory Parameter.fromFPD(FieldDeclaration field, FormalParameterDeclaration cParam) {
    return Parameter(
      isNullable: field.type.isNullable,
      name: field.identifier.name,
      typeCode: field.type.code,
      isNamed: cParam.isNamed,
      isRequired: cParam.isRequired,
    );
  }

  /// Generates the parameter code for the copyWith method
  List<Object> copyWith(bool immutable, Object undefined) {
    var parts = <Object>[isNamed ? '$name : ' : ''];
    if (immutable) return [...parts, 'this.', name, ' as ', typeCode];
    parts
      ..addAll(isNullable ? [name, ' == ', undefined] : [name, ' == null'])
      ..addAll([' ? this.', name, ' : ', name, ' as ', typeCode]);

    return parts;
  }
}
