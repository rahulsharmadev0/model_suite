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
  final ClassDeclaration? superClazz;
  final ConstructorDeclaration? constructor;
  final ConstructorDeclaration? superConstructor;

  /// All non static fields on the [clazz].
  final Iterable<FieldDeclaration> allFields;
  final Iterable<MethodDeclaration> clazzMethods;

  const ClazzData(
      {required this.clazz,
      required this.superClazz,
      required this.clazzMethods,
      required this.allFields,
      required this.constructor,
      required this.superConstructor});

  /// Builds the shared introspection data for the given [clazz].
  static Future<ClazzData> build(
    ClassDeclaration clazz,
    DeclarationPhaseIntrospector builder,
    String constructorName,
    String superConstructorName,
  ) async {
    final (allFields, methods, constructors, superClazz) = await (
      builder.allFieldsOf(clazz),
      builder.methodsOf(clazz),
      builder.constructorsOf(clazz),
      builder.superclassOf(clazz)
    ).wait;

    ConstructorDeclaration? superConstructor;
    if (superClazz != null) {
      superConstructor = (await builder.constructorsOf(superClazz))
          .firstWhereOrNull((e) => e.identifier.name == superConstructorName);
    }
    return ClazzData(
      clazz: clazz,
      allFields: allFields.where((f) => !f.hasStatic),
      clazzMethods: methods.where((f) => !f.hasStatic),
      superClazz: superClazz,
      superConstructor: superConstructor,
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
