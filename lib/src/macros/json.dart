import 'dart:async';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart';
import 'package:model_suite/src/macros_utils.dart';
import 'package:model_suite/src/part_utils.dart';

class MacroException extends DiagnosticException {
  MacroException(String message) : super(Diagnostic(DiagnosticMessage(message), Severity.error));
}

mixin _JsonMacroException {
  MacroException get cannotApplyToGenericClasses =>
      MacroException('Cannot be applied to classes with generic type parameters');

  MacroException get abstractMemberRestriction =>
      MacroException('Abstract/Sealed/mixin classes cannot declares a constructor.');

  MacroException get fromJsonUnsupportedInheritance => MacroException(
      'Serialization of classes that extend other classes is only supported if those classes have a valid `fromJson(Map<String, Object?> json)` constructor.');

  MacroException get toJsonUnsupportedInheritance => MacroException(
      'Serialization of classes that extend other classes is only supported if those classes have a valid `toJson()` method.');

  MacroException get fromJsonAlreadyExists =>
      MacroException('Cannot generate a `fromJson` constructor due to this existing one.');

  MacroException get toJsonAlreadyExists =>
      MacroException('Cannot generate a `toJson` constructor due to this existing one.');
}

class JsonMacro
    with _JsonMacroException, _ToJson, _FromJson
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const JsonMacro();
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    if (clazz.typeParameters.isNotEmpty) throw cannotApplyToGenericClasses;
    if (clazz.hasAbstract || clazz.hasSealed || clazz.hasMixin) throw abstractMemberRestriction;

    final (map, string, object) = await (
      builder.codeFrom(Map),
      builder.codeFrom(String),
      builder.codeFrom(Object),
    ).wait;

    final mapStringObject = map.copyWith(typeArguments: [string, object.asNullable]);

    await (
      declareFromJson(clazz, builder, mapStringObject),
      declareToJson(clazz, builder, mapStringObject),
    ).wait;
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async {
    final classData = await _SharedIntrospectionData.build(builder, clazz);

    await (
      defineFromJson(clazz, builder, classData),
      defineToJson(clazz, builder, classData),
    ).wait;
  }
}

//
mixin _ToJson on _JsonMacroException {
  ///
  /// Need to write the code for the `toJson` method.
  ///
  Future<void> defineToJson(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
    _SharedIntrospectionData classData,
  ) async {
    final listOfmethod = await builder.methodsOf(clazz);
    final toJsonMethod = listOfmethod.firstWhereOrNull((m) => m.identifier.name == 'toJson');
    if (toJsonMethod == null) return; // Exit if there is no `toJson` method.

    var superclass = classData.superclass;
    if (superclass != null && superclass.isExactly('Object', dartCore)) {
      final superMethod = await builder.methodsOf(superclass);
      final superFromJson = superMethod.firstWhereOrNull((c) => c.identifier.name == 'toJson');
      if (superFromJson == null) throw fromJsonUnsupportedInheritance;
    }

    final fields = classData.allFields;
    final toJsonBuilder = await builder.buildMethod(toJsonMethod.identifier);

    // TODO: Refactor
    final parts = <Object>[
      '{\n    final json = ',
      if (superclass != null)
        'super.toJson()'
      else ...[
        '<',
        classData.stringCode,
        ', ',
        classData.objectCode.asNullable,
        '>{}',
      ],
      ';\n    ',
    ];

    Future<Code> addEntryForField(FieldDeclaration field) async {
      final parts = <Object>[];
      final doNullCheck = field.type.isNullable;
      if (doNullCheck) {
        parts.addAll([
          'if (',
          field.identifier,
          // `null` is a reserved word, we can just use it.
          ' != null) {\n      ',
        ]);
      }
      parts.addAll([
        "json[r'",
        field.identifier.name,
        "'] = ",
        await _convertTypeToJson(
            field.type,
            RawCode.fromParts([
              field.identifier,
              if (doNullCheck) '!',
            ]),
            builder,
            classData,
            // We already are doing the null check.
            omitNullCheck: true),
        ';\n    ',
        if (doNullCheck) '}\n    ',
      ]);

      return RawCode.fromParts(parts);
    }

    parts
      ..addAll(await Future.wait(fields.map(addEntryForField)))
      ..add('return json;\n  }');

    toJsonBuilder.augment(FunctionBodyCode.fromParts(parts));
  }

  /// Declare the `toJson` method in the class.
  Future<void> declareToJson(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
    NamedTypeAnnotationCode mapStringObject,
  ) async {
    final methods = await builder.methodsOf(clazz);
    if (methods.any((c) => c.identifier.name == 'toJson')) throw toJsonAlreadyExists;

    var parts = ['  external ', mapStringObject, ' toJson();'];
    builder.declareInType(DeclarationCode.fromParts(parts));
  }
}

mixin _FromJson on _JsonMacroException {
  Future<void> defineFromJson(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
    _SharedIntrospectionData classData,
  ) async {
    final constructors = await builder.constructorsOf(clazz);
    final fromJsonMethod = constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
    if (fromJsonMethod == null) return; // Exit if there is no `fromJson` method.

    var superclass = classData.superclass;
    if (superclass != null && superclass.isExactly('Object', dartCore)) {
      final superConstr = await builder.constructorsOf(superclass);
      final superFromJson = superConstr.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
      if (superFromJson == null) throw fromJsonUnsupportedInheritance;
    }

    final fromJsonBuilder = await builder.buildConstructor(fromJsonMethod.identifier);

    final fields = classData.allFields;
    final jsonParam = fromJsonMethod.positionalParameters.single.identifier;

    Future<Code> initializerForField(FieldDeclaration field) async {
      return RawCode.fromParts([
        field.identifier,
        ' = ',
        await _convertTypeFromJson(
            field.type,
            RawCode.fromParts([
              jsonParam,
              "[r'",
              field.identifier.name,
              "']",
            ]),
            builder,
            classData),
      ]);
    }

    final initializers = await Future.wait(fields.map(initializerForField));

    if (superclass != null) {
      initializers.add(RawCode.fromParts([
        'super.fromJson(',
        jsonParam,
        ')',
      ]));
    }

    fromJsonBuilder.augment(initializers: initializers);
  }

  Future<void> declareFromJson(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
    NamedTypeAnnotationCode mapStringObject,
  ) async {
    final constr = await builder.constructorsOf(clazz);
    if (constr.any((c) => c.identifier.name == 'fromJson')) throw fromJsonAlreadyExists;

    var parts = ['  external ', clazz.identifier.name, '.fromJson(', mapStringObject, ' json);'];
    builder.declareInType(DeclarationCode.fromParts(parts));
  }
}

//
//
//
//
/// This data is collected asynchronously, so we only want to do it once and
/// share that work across multiple locations.
final class _SharedIntrospectionData {
  /// The declaration of the class we are generating for.
  final ClassDeclaration clazz;

  /// All the fields on the [clazz].
  final List<FieldDeclaration> allFields;

  /// A [Code] representation of the type [List<Object?>].
  final NamedTypeAnnotationCode jsonListCode;

  /// A [Code] representation of the type [Set<Object?>].
  final NamedTypeAnnotationCode jsonSetCode;

  /// A [Code] representation of the type [Map<String, Object?>].
  final NamedTypeAnnotationCode jsonMapCode;

  /// The resolved [StaticType] representing the [Map<String, Object?>] type.
  final StaticType jsonMapType;

  /// The resolved identifier for the [MapEntry] class.
  final Identifier mapEntry;

  /// A [Code] representation of the type [Object].
  final NamedTypeAnnotationCode objectCode;

  /// A [Code] representation of the type [String].
  final NamedTypeAnnotationCode stringCode;

  /// The declaration of the superclass of [clazz], if it is not [Object].
  final ClassDeclaration? superclass;

  const _SharedIntrospectionData({
    required this.clazz,
    required this.allFields,
    required this.jsonListCode,
    required this.jsonSetCode,
    required this.jsonMapCode,
    required this.jsonMapType,
    required this.mapEntry,
    required this.objectCode,
    required this.stringCode,
    required this.superclass,
  });

  ///
  /// Builds the shared introspection data for the given [clazz].
  static Future<_SharedIntrospectionData> build(
    DeclarationPhaseIntrospector builder,
    ClassDeclaration clazz,
  ) async {
    final (listCode, setCode, mapCode, mapEntryCode, objectCode, stringCode) = await (
      builder.codeFrom(List),
      builder.codeFrom(Set),
      builder.codeFrom(Map),
      builder.codeFrom(MapEntry),
      builder.codeFrom(Object),
      builder.codeFrom(String),
    ).wait;

    final superclass = clazz.superclass;
    final nullableObjectCode = objectCode.asNullable;
    final jsonListCode = listCode.copyWith(typeArguments: [nullableObjectCode]);
    final jsonSetCode = setCode.copyWith(typeArguments: [nullableObjectCode]);
    final jsonMapCode = mapCode.copyWith(typeArguments: [stringCode, nullableObjectCode]);

    final (fields, jsonMapType, superclassDecl) = await (
      builder.fieldsOf(clazz),
      builder.resolve(jsonMapCode),
      superclass == null ? Future.value(null) : builder.typeDeclarationOf(superclass.identifier),
    ).wait;

    return _SharedIntrospectionData(
      clazz: clazz,
      allFields: fields,
      jsonListCode: jsonListCode,
      jsonSetCode: jsonSetCode,
      jsonMapCode: jsonMapCode,
      jsonMapType: jsonMapType,
      mapEntry: mapEntryCode.name,
      objectCode: objectCode,
      stringCode: stringCode,
      superclass: superclassDecl as ClassDeclaration?,
    );
  }
}

final _macrosJson = Uri.parse('package:model_suite/src/macros/json.dart');

/// Extension method to safely parse nested JSON data.
extension MapJsonParsing<K, V> on Map<K, V> {
  /// Extension method to safely parse nested JSON data.
  R? get<R, FT>(K key, [R? Function(FT value)? parser]) {
    final value = this[key];
    if (value == null) return null;

    return parser != null ? parser(value as FT) : value as R?;
  }
}

NamedTypeAnnotation? _checkNamedType(TypeAnnotation type, Builder builder) {
  if (type is NamedTypeAnnotation) return type;
  if (type is OmittedTypeAnnotation) {
    builder.report(Diagnostic(
        DiagnosticMessage(
            'Only fields with explicit types are allowed on serializable '
            'classes, please add a type.',
            target: type.asDiagnosticTarget),
        Severity.error));
  } else {
    builder.report(Diagnostic(
        DiagnosticMessage(
            'Only fields with named types are allowed on serializable '
            'classes.',
            target: type.asDiagnosticTarget),
        Severity.error));
  }
  return null;
}

// TODO: Rewrite this to use the below class.

//
//
/// Returns a [Code] object which is an expression that converts a JSON map
/// (referenced by [jsonReference]) into an instance of type [type].
Future<Code> _convertTypeFromJson(TypeAnnotation rawType, Code jsonReference, DefinitionBuilder builder,
    _SharedIntrospectionData classData) async {
  final type = _checkNamedType(rawType, builder);
  if (type == null) {
    return RawCode.fromString("throw 'Unable to deserialize type ${rawType.code.debugString}'");
  }

  // Follow type aliases until we reach an actual named type.
  var classDecl = await type.classDeclaration(builder);
  if (classDecl == null) {
    return RawCode.fromString("throw 'Unable to deserialize type ${type.code.debugString}'");
  }

  var nullCheck = type.isNullable
      ? RawCode.fromParts([
          jsonReference,
          // `null` is a reserved word, we can just use it.
          ' == null ? null : ',
        ])
      : null;

  // Check for the supported core types, and deserialize them accordingly.
  if (classDecl.library.uri == dartCore) {
    switch (classDecl.identifier.name) {
      case 'List':
        return RawCode.fromParts([
          if (nullCheck != null) nullCheck,
          '[ for (final item in ',
          jsonReference,
          ' as ',
          classData.jsonListCode,
          ') ',
          await _convertTypeFromJson(
              type.typeArguments.single, RawCode.fromString('item'), builder, classData),
          ']',
        ]);
      case 'Set':
        return RawCode.fromParts([
          if (nullCheck != null) nullCheck,
          '{ for (final item in ',
          jsonReference,
          ' as ',
          classData.jsonSetCode,
          ')',
          await _convertTypeFromJson(
              type.typeArguments.single, RawCode.fromString('item'), builder, classData),
          '}',
        ]);
      case 'Map':
        return RawCode.fromParts([
          if (nullCheck != null) nullCheck,
          '{ for (final ',
          classData.mapEntry,
          '(:key, :value) in (',
          jsonReference,
          ' as ',
          classData.jsonMapCode,
          ').entries) key: ',
          await _convertTypeFromJson(
              type.typeArguments.last, RawCode.fromString('value'), builder, classData),
          '}',
        ]);
      case 'int' || 'double' || 'num' || 'String' || 'bool':
        return RawCode.fromParts([
          jsonReference,
          ' as ',
          type.code,
        ]);
      case 'DateTime':
        return RawCode.fromParts([
          if (nullCheck != null) nullCheck,
          await builder.resolveIdentifier(dartCore, 'DateTime'),
          '.parse(',
          jsonReference,
          ' as ',
          classData.stringCode,
          ')'
        ]);
    }
  }

  // Otherwise, check if `classDecl` has a `fromJson` constructor.
  final constructors = await builder.constructorsOf(classDecl);
  final fromJson = constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');

  if (fromJson != null) {
    return RawCode.fromParts([
      if (nullCheck != null) nullCheck,
      fromJson.identifier,
      '(',
      jsonReference,
      ' as ',
      fromJson.positionalParameters.first.type.code,
      ')',
    ]);
  }

  // Unsupported type, report an error and return valid code that throws.
  builder.report(Diagnostic(
      DiagnosticMessage(
          'Unable to deserialize type, it must be a native JSON type or a '
          'type with a `fromJson(Map<String, Object?> json)` constructor.',
          target: type.asDiagnosticTarget),
      Severity.error));
  return RawCode.fromString("throw 'Unable to deserialize type ${type.code.debugString}'");
}

/// Returns a [Code] object which is an expression that converts an instance
/// of type [rawType] (referenced by [valueReference]) into a JSON map.
///
/// Null checks will be inserted if [rawType] is  nullable, unless
/// [omitNullCheck] is `true`.
Future<Code> _convertTypeToJson(TypeAnnotation rawType, Code valueReference, DefinitionBuilder builder,
    _SharedIntrospectionData classData,
    {bool omitNullCheck = false}) async {
  final type = _checkNamedType(rawType, builder);
  if (type == null) {
    return RawCode.fromString("throw 'Unable to serialize type ${rawType.code.debugString}'");
  }

  // Follow type aliases until we reach an actual named type.
  var classDecl = await type.classDeclaration(builder);
  if (classDecl == null) {
    return RawCode.fromString("throw 'Unable to serialize type ${type.code.debugString}'");
  }

  var nullCheck = type.isNullable && !omitNullCheck
      ? RawCode.fromParts([
          valueReference,
          // `null` is a reserved word, we can just use it.
          ' == null ? null : ',
        ])
      : null;

  // Check for the supported core types, and serialize them accordingly.
  if (classDecl.library.uri == dartCore) {
    switch (classDecl.identifier.name) {
      case 'List':
        return RawCode.fromParts([
          if (nullCheck != null) nullCheck,
          '[ for (final item in ',
          valueReference,
          ') ',
          await _convertTypeToJson(type.typeArguments.single, RawCode.fromString('item'), builder, classData),
          ']',
        ]);
      case 'Set':
        return RawCode.fromParts([
          if (nullCheck != null) nullCheck,
          '{ for (final item in ',
          valueReference,
          ') ',
          await _convertTypeToJson(type.typeArguments.single, RawCode.fromString('item'), builder, classData),
          '}',
        ]);
      case 'Map':
        return RawCode.fromParts([
          if (nullCheck != null) nullCheck,
          '{ for (final ',
          classData.mapEntry,
          '(:key, :value) in ',
          valueReference,
          '.entries) key: ',
          await _convertTypeToJson(type.typeArguments.last, RawCode.fromString('value'), builder, classData),
          '}',
        ]);
      case 'int' || 'double' || 'num' || 'String' || 'bool':
        return valueReference;
      case 'DateTime':
        return RawCode.fromParts([if (nullCheck != null) nullCheck, valueReference, '.toIso8601String()']);
    }
  }

  // Next, check if it has a `toJson()` method and call that.
  final methods = await builder.methodsOf(classDecl);
  final toJson = methods.firstWhereOrNull((c) => c.identifier.name == 'toJson')?.identifier;
  if (toJson != null) {
    return RawCode.fromParts([
      if (nullCheck != null) nullCheck,
      valueReference,
      '.toJson()',
    ]);
  }

  // Unsupported type, report an error and return valid code that throws.
  builder.report(Diagnostic(
      DiagnosticMessage(
          'Unable to serialize type, it must be a native JSON type or a '
          'type with a `Map<String, Object?> toJson()` method.',
          target: type.asDiagnosticTarget),
      Severity.error));
  return RawCode.fromString("throw 'Unable to serialize type ${type.code.debugString}'");
}
