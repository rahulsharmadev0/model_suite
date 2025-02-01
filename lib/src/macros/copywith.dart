import 'dart:async';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart' hide MacroException;

import 'package:model_suite/src/macros_utils.dart';

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

  String get className =>  clazz.identifier.name;
  DiagnosticTarget get classTarget => clazz.asDiagnosticTarget;

  /// Warns when a copyWith method already exists in the target class
  MacroException existingCopyWithWarning({String? className, DiagnosticTarget? target}) => MacroException(
      'A `copyWith` method already exists in this class. To use @CopyWithMacro, either remove the existing copyWith method or remove the macro annotation.',
      target: target??clazz.asDiagnosticTarget,
      severity: Severity.warning);

  /// Error when the target class is missing a required constructor
  MacroException missingConstructorError({String? className, DiagnosticTarget? target}) => MacroException(
      'Class `${className??this.className}` is missing the required constructor. Please define a constructor matching the name specified in @CopyWithMacro annotation. If using default constructor, ensure it exists.',
      target: target ?? classTarget);

  

  /// Error when constructor parameters are missing type annotations
  MacroException missingTypeAnnotationsError({String? className, DiagnosticTarget? target}) => MacroException(
      'All constructor parameters in `${className??this.className}` must have explicit type annotations. Found nullable or dynamic parameters which are not supported. Please add type annotations to all parameters.',
      target: target ?? classTarget);

  /// Error when the class is abstract or sealed
  MacroException invalidClassTypeError({String? className, DiagnosticTarget? target}) => MacroException(
      'Class `${className??this.className}` cannot be abstract or sealed when using @CopyWithMacro. Remove the abstract/sealed modifier or use a concrete class instead.',
      target: target ?? classTarget);

  // Error when the class has no parameters in the constructor
  MacroException missingParametersWarning({String? className, DiagnosticTarget? target}) =>
      MacroException(
          'Class `${className??this.className}` has no parameters in the constructor. Please add parameters to the constructor to use @CopyWithMacro.',
          target: target ?? classTarget,
          severity: Severity.warning);

        
}

/// Macro implementation for generating copyWith functionality
/// Implements both declaration and definition phase macros
macro
class CopyWithMacro implements ClassDeclarationsMacro {
  /// Fields that should be excluded from the copyWith method
  final Set<String> immutable;

  /// Named constructor to use for generating copyWith (empty string for unnamed constructor)
  final String constructor;

  const CopyWithMacro({this.constructor = '', this.immutable = const {}});

  @override
  Future<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final _CopyWithMacroException exception = _CopyWithMacroException(clazz);
    
    // Validate class is not abstract or sealed
    if (clazz.hasAbstract || clazz.hasSealed) throw exception.invalidClassTypeError();
    // Check for existing copyWith method
    final copyWith = await getMethod(clazz, builder);
    if (copyWith != null) throw exception.existingCopyWithWarning();

    // Retrieve method and constructor definitions
    final (allFields, defConstructor) = await (
      builder.allFieldsOf(clazz),
      builder.defConstructorOf(clazz, constructor),
    ).wait;

    // Validate constructor
    if (defConstructor == null || constructor != defConstructor.identifier.name) {
      throw exception.missingConstructorError();
    } else if (defConstructor.parameters.isEmpty) {
      if (allFields.isNotEmpty)
        builder.report(
            exception.missingParametersWarning(className:clazz.identifier.name, target:defConstructor.asDiagnosticTarget).diagnostic);
      return;
    }

    var fieldMapping = {for (var field in allFields) field.identifier.name: field};
    // Retrieve parameters and validate types
    final params = <Parameter>[];

    for (var cParm in defConstructor.parameters) {
      var field = fieldMapping[cParm.identifier.name];
      if (field == null) throw exception.missingTypeAnnotationsError();
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
    
    var generics = [
      for (final type in clazz.typeParameters) ...[
        type.identifier,
      ],
    ].joinAsCode(', ');


    // Generate method implementation with parameter handling
    String constructorName = defConstructor.identifier.name;
    if (constructor.isNotEmpty) constructorName = '.$constructorName';

    final body = DeclarationCode.fromParts(
      [
        clazz.identifier,
         if (generics.isNotEmpty) ...[
          '<',
          ...generics,
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
    var parts = <Object>[isNamed ? '$name : (' : '('];
    if (immutable) return [...parts, 'this.', name, ') as ', typeCode];
    parts
      ..addAll(isNullable ? [name, ' == ', undefined] : [name, ' == null'])
      ..addAll([' ? this.', name, ' : ', name, ') as ', typeCode]);

    return parts;
  }
}
