import 'dart:async';

import 'package:collection/collection.dart';
import 'package:macros/macros.dart' hide MacroException;
import 'package:model_suite/src/model.dart';
import 'package:model_suite/utils/clazz_data.dart';
import 'package:model_suite/utils/macros_utils.dart';

/// Mixin that provides standardized error messages for JSON serialization/deserialization
mixin _JsonMacroException {
  // Generic class errors
  MacroException get cannotApplyToGenericClasses =>
      MacroException('Cannot be applied to classes with generic type parameters');

  MacroException get abstractMemberRestriction =>
      MacroException('Abstract/Sealed/mixin classes cannot declares a constructor.');

  // Inheritance-related errors
  MacroException get fromJsonUnsupportedInheritance => MacroException(
      'Serialization of classes that extend other classes requires a valid `fromJson(Map<String, Object?> json)` constructor in parent class.');

  MacroException get toJsonUnsupportedInheritance => MacroException(
      'Serialization of classes that extend other classes requires a valid `toJson()` method in parent class.');

  // Method existence errors
  MacroException get fromJsonAlreadyExists =>
      MacroException('Cannot generate `fromJson` constructor: constructor already exists.');

  MacroException get toJsonAlreadyExists =>
      MacroException('Cannot generate `toJson` method: method already exists.');

  // Type conversion errors
  MacroException get unsupportedTypeConversion =>
      MacroException('Type must be a native JSON type or have appropriate fromJson/toJson implementations.');

  MacroException get missingExplicitType =>
      MacroException('Fields in serializable classes must have explicit type annotations.');

  MacroException get invalidNamedType => MacroException('Only named types are supported for serialization.');
}

/// Macro for generating JSON serialization and deserialization code
macro
class JsonModelBuilder extends ModelBuilder
    with _JsonMacroException, _Converter{
  const JsonModelBuilder(super.clazzData, super.builder);

  @override
  Future<void> build() async {
    if (clazz.typeParameters.isNotEmpty) throw cannotApplyToGenericClasses;
    if (clazz.hasAbstract || clazz.hasSealed || clazz.hasMixin) throw abstractMemberRestriction;
    final classData = await _SharedIntrospectionData.build(builder, clazz);

    await (
      defineFromJson(classData),
      defineToJson(classData),
    ).wait;

  }


Future<void> defineToJson(
    _SharedIntrospectionData classData,
  ) async {
    if (clazzData.hasToJson) return; // Exit if there is no `toJson` method.

    var superclass = classData.superclass;
    if (superclass != null && superclass.isExactly('Object', dartCore)) {
      final superMethod = await builder.methodsOf(superclass);
      final superFromJson = superMethod.firstWhereOrNull((c) => c.identifier.name == 'toJson');
      if (superFromJson == null) throw fromJsonUnsupportedInheritance;
    }

    final fields = classData.allFields;
    final parts = <Object>['  ', classData.mapCode, ' toJson() => {\n'];

    Future<Code> addEntryForField(FieldDeclaration field) async {
      final parts = <Object>['     '];
      final doNullCheck = field.type.isNullable;
      if (doNullCheck) parts.addAll(['if (', field.identifier, ' != null) ']);

      parts.addAll([
        "r'",
        field.identifier.name,
        "' : ",
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
        ',\n',
      ]);
      return RawCode.fromParts(parts);
    }

    parts..addAll(await Future.wait(fields.map(addEntryForField)))
    ..add(RawCode.fromParts([if(superclass!=null) '...super.toJson(),', '    };']));

    builder.declareInType(DeclarationCode.fromParts(parts));
  }



    Future<void> defineFromJson(
    _SharedIntrospectionData classData
  ) async {
    if (clazzData.hasFromJson) return; // Exit if there is no `fromJson` method.

    var superclass = classData.superclass;
    if (superclass != null && superclass.isExactly('Object', dartCore)) {
      final superConstr = await builder.constructorsOf(superclass);
      final superFromJson = superConstr.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
      if (superFromJson == null) throw fromJsonUnsupportedInheritance;
    }

    Future<Code> initializerForField(FieldDeclaration field) async {
      return RawCode.fromParts([
        field.identifier,
        ' = ',
        await _convertTypeFromJson(
            field.type,
            RawCode.fromParts([
           
              "json[r'",
              field.identifier.name,
              "']",
            ]),
            builder,
            classData),
      ]);
    }

    final initializers = await Future.wait(classData.allFields.map(initializerForField));

    List<Object> parts = [
      ...['  ',clazz.identifier.name, '.fromJson(', classData.mapCode, ' json) :\n'],

      for(var (i, f) in  initializers.indexed) ...[
      '    ', f,
      if(i != initializers.length - 1) ',\n',
      ],
      if(superclass != null) 'super.fromJson(json)',
      ';'
    ];
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
  final NamedTypeAnnotationCode listCode;

  /// A [Code] representation of the type [Set<Object?>].
  final NamedTypeAnnotationCode setCode;

  /// A [Code] representation of the type [Map<String, Object?>].
  final NamedTypeAnnotationCode mapCode;

  /// The resolved identifier for the [MapEntry] class.
  final Identifier mapEntry;

  /// A [Code] representation of the type [Object].
  final NamedTypeAnnotationCode objectCode;

  /// A [Code] representation of the type [String].
  final NamedTypeAnnotationCode stringCode;

  /// The declaration of the superclass of [clazz], if it is not [Object].
  final ClassDeclaration? superclass;

  /// The resolved identifier for the [DateTime] class.
  final Identifier dateTimeCode;

  const _SharedIntrospectionData({
    required this.clazz,
    required this.allFields,
    required this.listCode,
    required this.setCode,
    required this.mapCode,
    // required this.mapType,
    required this.mapEntry,
    required this.objectCode,
    required this.stringCode,
    required this.superclass,
    required this.dateTimeCode,
  });

  ///
  /// Builds the shared introspection data for the given [clazz].
  static Future<_SharedIntrospectionData> build(
    DeclarationPhaseIntrospector builder,
    ClassDeclaration clazz,
  ) async {
    final (listCode, setCode, mapCode, mapEntryCode, $dynamic, stringCode, dateTimeCode) = await (
      builder.codeFrom.list,
      builder.codeFrom.set,
      builder.codeFrom.map,
      builder.codeFrom.mapEntry,
      builder.codeFrom.dynamic,
      builder.codeFrom.string,
      builder.codeFrom.dateTime,
    ).wait;

    final superclass = clazz.superclass;
    final jsonListCode = listCode.copyWith(typeArguments: [$dynamic]);
    final jsonSetCode = setCode.copyWith(typeArguments: [$dynamic]);
    final jsonMapCode = mapCode.copyWith(typeArguments: [stringCode, $dynamic]);

    final (fields, superclassDecl) = await (
      builder.fieldsOf(clazz),
      // jsonMapType  =  builder.resolve(jsonMapCode),
      superclass == null ? Future.value(null) : builder.typeDeclarationOf(superclass.identifier),
    ).wait;

    return _SharedIntrospectionData(
      clazz: clazz,
      allFields: fields,
      listCode: jsonListCode,
      setCode: jsonSetCode,
      mapCode: jsonMapCode,
      // mapType: jsonMapType,
      mapEntry: mapEntryCode.name,
      dateTimeCode: dateTimeCode.name,
      objectCode: $dynamic,
      stringCode: stringCode,
      superclass: superclassDecl as ClassDeclaration?,
    );
  }
}

/// Mixin that provides standardized error messages for JSON serialization/deserialization
mixin _Converter on _JsonMacroException {
  /// Validates that a type annotation is a named type and reports appropriate errors
  NamedTypeAnnotation? _checkNamedType(TypeAnnotation type, DeclarationPhaseIntrospector builder) {
    if (type is NamedTypeAnnotation) return type;
    if (type is OmittedTypeAnnotation) throw missingExplicitType;
    throw invalidNamedType;
  }

  /// Returns a [Code] object which is an expression that converts a JSON map
  /// (referenced by [jsonReference]) into an instance of type.
  Future<Code> _convertTypeFromJson(TypeAnnotation rawType, Code jsonReference, DeclarationPhaseIntrospector builder,
      _SharedIntrospectionData classData) async {
    final type = _checkNamedType(rawType, builder);
    if (type == null) throw unsupportedTypeConversion;

    // Follow type aliases until we reach an actual named type.
    var classDecl = await type.classDeclaration(builder);
    if (classDecl == null) throw unsupportedTypeConversion;

    // Generate null check code if the type is nullable.
    final nullCheck = type.isNullable ? RawCode.fromParts([jsonReference, ' == null ? null : ']) : null;

    // Check for the supported core types, and deserialize them accordingly.
    if (classDecl.library.uri == dartCore) {
      var typeName = classDecl.identifier.name;
      switch (typeName) {
        case 'List' || 'Set':
          bool isSet = typeName == 'Set';
          return RawCode.fromParts([
            if (nullCheck != null) nullCheck,
            isSet ? '{ ' : '[ ',
            'for (final item in ',
            jsonReference,
            ' as ',
            isSet ? classData.setCode : classData.listCode,
            ') ',
            await _convertTypeFromJson(
                type.typeArguments.single, RawCode.fromString('item'), builder, classData),
            isSet ? '}' : ']',
          ]);
        case 'Map':
          return RawCode.fromParts([
            if (nullCheck != null) nullCheck,
            '{ for (final ',
            classData.mapEntry,
            '(:key, :value) in (',
            jsonReference,
            ' as ',
            classData.mapCode,
            ').entries) ',
            await _convertMapKeyFromJson(
                type.typeArguments.first, RawCode.fromString('key'), builder, classData),
            ': ',
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
            classData.dateTimeCode,
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
    throw unsupportedTypeConversion;
  }

  /// Returns a [Code] object which is an expression that converts an instance
  /// of type [rawType] (referenced by [valueReference]) into a JSON map.
  ///
  /// Null checks will be inserted if [rawType] is  nullable, unless
  /// [omitNullCheck] is `true`.
  Future<Code> _convertTypeToJson(TypeAnnotation rawType, Code valueReference, DeclarationPhaseIntrospector builder,
      _SharedIntrospectionData classData,
      {bool omitNullCheck = false}) async {
    final type = _checkNamedType(rawType, builder);
    if (type == null) throw unsupportedTypeConversion;

    // Follow type aliases until we reach an actual named type.
    var classDecl = await type.classDeclaration(builder);
    if (classDecl == null) throw unsupportedTypeConversion;

    var nullCheck =
        type.isNullable && !omitNullCheck ? RawCode.fromParts([valueReference, ' == null ? null : ']) : null;

    // Check for the supported core types, and serialize them accordingly.
    if (classDecl.library.uri == dartCore) {
      switch (classDecl.identifier.name) {
        case 'List' || 'Set':
          bool isSet = classDecl.identifier.name == 'Set';
          return RawCode.fromParts([
            if (nullCheck != null) nullCheck,
            isSet ? '{ ' : '[ ',
            'for (final item in ',
            valueReference,
            ') ',
            await _convertTypeToJson(
                type.typeArguments.single, RawCode.fromString('item'), builder, classData),
            isSet ? '}' : ']',
          ]);
        case 'Map':
          return RawCode.fromParts([
            if (nullCheck != null) nullCheck,
            '{ for (final ',
            classData.mapEntry,
            '(:key, :value) in ',
            valueReference,
            '.entries) ',
            await _convertMapKeyToJson(type.typeArguments.first, RawCode.fromString('key'), builder),
            ': ',
            await _convertTypeToJson(
                type.typeArguments.last, RawCode.fromString('value'), builder, classData),
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
      return RawCode.fromParts([if (nullCheck != null) nullCheck, valueReference, '.toJson()']);
    }

    // Unsupported type, report an error and return valid code that throws.
    throw unsupportedTypeConversion;
  }

  Future<Code> _convertMapKeyFromJson(TypeAnnotation keyType, Code keyReference, DeclarationPhaseIntrospector builder,
      _SharedIntrospectionData classData) async {
    final type = _checkNamedType(keyType, builder);
    if (type == null) throw unsupportedTypeConversion;

    var classDecl = await type.classDeclaration(builder);
    if (classDecl == null) throw unsupportedTypeConversion;

    if(classDecl.identifier.name == 'String') return keyReference;
    throw unsupportedTypeConversion;
  }

  Future<Code> _convertMapKeyToJson(TypeAnnotation keyType, Code keyReference, DeclarationPhaseIntrospector builder) async {
    final type = _checkNamedType(keyType, builder);
    if (type == null) throw unsupportedTypeConversion;

    var classDecl = await type.classDeclaration(builder);
    if (classDecl == null) throw unsupportedTypeConversion;

    if (classDecl.library.uri == dartCore) {
      switch (classDecl.identifier.name) {
        case 'String':
          return keyReference;
        case 'int' || 'double':
          return RawCode.fromParts([keyReference, '.toString()']);
        case 'DateTime':
          return RawCode.fromParts([keyReference, '.toIso8601String()']);
      }
    }
    throw unsupportedTypeConversion;
  }
}
