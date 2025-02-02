import 'package:collection/collection.dart';
import 'package:macros/macros.dart';
import 'package:meta/meta.dart';
import 'macros_utils.dart';

/// This data is collected asynchronously, so we only want to do it once and
/// share that work across multiple locations.
@internal
class ClazzData {
  /// The declaration of the class we are generating for.
  final ClassDeclaration clazz;
  final List<FieldDeclaration> clazzfields;
  final ConstructorDeclaration? constructor;

  final ClassDeclaration? superClazz;
  final List<FieldDeclaration> superClazzFields;
  final ConstructorDeclaration? superConstructor;
  final Iterable<MethodDeclaration> clazzMethods;

  const ClazzData(
      {required this.clazz,
      required this.clazzMethods,
      required this.clazzfields,
      required this.constructor,
      required this.superClazz,
      required this.superClazzFields,
      required this.superConstructor});

  /// Builds the shared introspection data for the given [clazz].
  static Future<ClazzData> build(
    ClassDeclaration clazz,
    DeclarationPhaseIntrospector builder,
    String constructorName,
    String superConstructorName,
  ) async {
    final (fields, methods, constructors, superClazz) = await (
      builder.fieldsOf(clazz),
      builder.methodsOf(clazz),
      builder.constructorsOf(clazz),
      builder.superclassOf(clazz)
    ).wait;

    List<ConstructorDeclaration>? superConstructor;
    List<FieldDeclaration>? superFields;

    if (superClazz != null && superClazz.identifier.name != 'Object') {
      (superFields, superConstructor) = await (
        builder.fieldsOf(superClazz),
        builder.constructorsOf(superClazz),
      ).wait;
    }
    return ClazzData(
      clazz: clazz,
      clazzfields: fields.where((f) => !f.hasStatic).toList(),
      superClazzFields: superFields?.where((f) => !f.hasStatic).toList() ?? [],
      clazzMethods: methods.where((f) => !f.hasStatic),
      superClazz: superClazz,
      superConstructor: superConstructor?.firstWhereOrNull((e) => e.identifier.name == superConstructorName),
      constructor: constructors.firstWhereOrNull((e) => e.identifier.name == constructorName),
    );
  }
}

extension SharedDataExtension on ClazzData {
  bool get hasCopyWith => clazzMethods.any((f) => f.identifier.name == 'copyWith');
  bool get hasToJson => clazzMethods.any((f) => f.identifier.name == 'toJson');
  bool get hasFromJson => clazzMethods.any((f) => f.identifier.name == 'fromJson');
  bool get hasHashCode => clazzMethods.any((f) => f.identifier.name == 'hashCode');
  bool get hasToString => clazzMethods.any((f) => f.identifier.name == 'toString');
  bool get hasEqualityOperator => clazzMethods.any((f) => f.identifier.name == '==');

  Iterable<FieldDeclaration> get allFields => clazzfields.followedBy(superClazzFields);

  bool get hasSuperConstructor => superConstructor != null;

  bool get hasConstructor => constructor != null;

  bool get hasSuperClazz => superClazz != null;

  bool get isGeneric => clazz.typeParameters.isNotEmpty;

  Identifier get identifier => clazz.identifier;

  Identifier? get superIdentifier => superClazz?.identifier;

  Iterable<TypeParameterDeclaration> get generics => clazz.typeParameters;

  String get name => clazz.identifier.name;

  String get constructorAlongWithClazzName {
    if (constructor != null && constructor!.identifier.name.isNotEmpty)
      return '$name.${constructor!.identifier.name}';
    else
      return name;
  }
}
