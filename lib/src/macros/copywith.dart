import 'dart:async';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart' hide MacroException;
import 'package:model_suite/src/macros.dart';
import 'package:model_suite/src/macros_utils.dart';



const undefined = Object(); // Undefined object for copyWith method
final _copywithMacro = Uri.parse('package:model_suite/src/macros/copywith.dart');

/// Mixin that provides exception handling functionality for the CopyWith macro
/// Contains methods to generate specific error messages for different scenarios
mixin _CopyWithMacroException {
  /// Warns when a copyWith method already exists in the target class
  MacroException existingCopyWithWarning(DiagnosticTarget target) =>
      MacroException(
        'A `copyWith` method already exists in this class. To use @CopyWithMacro, either remove the existing copyWith method or remove the macro annotation.',
        target: target,
        severity: Severity.warning
      );

  /// Error when the target class is missing a required constructor
  MacroException missingConstructorError(ClassDeclaration clazz) =>
      MacroException(
        'Class "${clazz.identifier.name}" is missing the required constructor. Please define a constructor matching the name specified in @CopyWithMacro annotation. If using default constructor, ensure it exists.',
        target: clazz.asDiagnosticTarget
      );

  /// Error when constructor parameters are missing type annotations
  MacroException missingTypeAnnotationsError(ClassDeclaration clazz) =>
      MacroException(
        'All constructor parameters in "${clazz.identifier.name}" must have explicit type annotations. Found nullable or dynamic parameters which are not supported. Please add type annotations to all parameters.',
        target: clazz.asDiagnosticTarget
      );

  /// Error when the class is abstract or sealed
  MacroException invalidClassTypeError(ClassDeclaration clazz) =>
      MacroException(
        'Class `${clazz.identifier.name}` cannot be abstract or sealed when using @CopyWithMacro. Remove the abstract/sealed modifier or use a concrete class instead.',
        target: clazz.asDiagnosticTarget
      );
}

/// Macro implementation for generating copyWith functionality
/// Implements both declaration and definition phase macros
macro 
class CopyWithMacro with _CopyWithMacroException implements ClassDeclarationsMacro, ClassDefinitionMacro {
  /// Fields that should be excluded from the copyWith method
  final Set<String> immutable;
  /// Named constructor to use for generating copyWith (empty string for unnamed constructor)
  final String constructor;

  const CopyWithMacro({this.constructor = '', this.immutable = const {}});

  @override
  Future<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    // Validate class is not abstract or sealed
    if(clazz.hasAbstract || clazz.hasSealed) throw invalidClassTypeError(clazz);

    // Check for existing copyWith method
    final copyWithMethod = await getMethod(clazz, builder);
    if (copyWithMethod != null) throw existingCopyWithWarning(copyWithMethod.asDiagnosticTarget);

    final fields = await builder.allFieldsOf(clazz);

    // Validate all fields have type annotations
    if (fields.any((f) => f.type.checkNamed(builder) == null)) return;

    // Generate copyWith method declaration
    final args = [
      for (final (i, field) in fields.indexed) ...[
        '\n    ',
        field.type.code,
        ' ',
        field.identifier.name,
        if (i < fields.length - 1) ', '
      ],
    ];

    final declaration = DeclarationCode.fromParts(
        ['  external ', clazz.identifier, ' Function({', ...args, '}) get copyWith;']);

    return builder.declareInType(declaration);
  }

  @override
  Future<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    // Check for existing copyWith method
    final copyWith = await getMethod(clazz, builder);
    if (copyWith == null) return;

    // Retrieve method and constructor definitions
    final (copyWithMethod, defConstructor) = await (
      builder.buildMethod(copyWith.identifier),
      builder.defConstructorOf(clazz, constructor),
    ).wait;

    // Validate constructor
    if (defConstructor == null || constructor != defConstructor.identifier.name) {
      throw missingConstructorError(clazz);
    }

    // Retrieve parameters and validate types
    final params = [
      ...defConstructor.positionalParameters,
      ...defConstructor.namedParameters,
    ].map(Parameter.fromFPD);

    if (params.any((p) => p.isNullable)) throw missingTypeAnnotationsError(clazz);

    // Retrieve object and undefined codes
    final (object, undefined) = await (
      builder.codeFrom.object,
      builder.codeFrom.get('undefined', _copywithMacro),
    ).wait;

    // Generate arguments and parameter list for the copyWith method
    final args = [
      for (var (i, param) in params.indexed)
        if (!immutable.contains(param.name)) ...[
          '\n     ',
          object,
          '? ',
          param.name,
          ' = ',
          undefined,
          if (i < params.length - 1) ', '
        ],
    ];
    final parmslist = [
      for (var (i, param) in params.indexed) ...[
        '\n     ',
        ...param.copyWith(immutable.contains(param.name), undefined),
        if (i < params.length - 1) ', '
      ],
    ];

    // Generate method implementation with parameter handling
    String constructorName = defConstructor.identifier.name;
    if (constructor.isNotEmpty) constructorName = '.$constructorName';
    
    final body = FunctionBodyCode.fromParts(
      [
        '\n  => ({',
        ...args,
        '})\n  => ',
        clazz.identifier,
        constructorName,
        '(',
        ...parmslist,
        ');',
      ],
    );
    return copyWithMethod.augment(body);
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
  final TypeAnnotationCode type;
  
  /// Whether the parameter is named
  final bool isNamed;
  
  /// Whether the parameter is nullable
  final bool isNullable;
  
  /// Whether the parameter is required
  final bool isRequired;

  const Parameter({
    required this.name,
    required this.type,
    this.isNamed = false,
    this.isNullable = false,
    this.isRequired = false,
  });

  /// Creates a Parameter instance from a FormalParameterDeclaration
  factory Parameter.fromFPD(FormalParameterDeclaration param) => Parameter(
        name: param.identifier.name,
        type: param.type.code,
        isNamed: param.isNamed,
        isNullable: param.type.isNullable,
        isRequired: param.isRequired,
      );

  /// Generates the parameter code for the copyWith method
  List<Object> copyWith(bool immutable, Object undefined) {
    var prefix = isNamed ? '$name : ' : '';
    if (immutable) return [prefix, 'this.', name, ' as ', type, ','];
    return [prefix, name, ' == ', undefined, ' ? this.', name, ' : ', name, ' as ', type];
  }
}