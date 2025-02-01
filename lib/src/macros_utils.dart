import 'dart:async';

import 'package:collection/collection.dart';
import 'package:macros/macros.dart';

// Libraries used in augmented code.
final dartCore = Uri.parse('dart:core');

typedef FieldMetadata = ({String name, bool isRequired, TypeAnnotation? type});
typedef ConstructorParams = ({List<FieldMetadata> positional, List<FieldMetadata> named});

extension NamedTypeAnnotationCodeX on NamedTypeAnnotationCode {
  NamedTypeAnnotationCode copyWith({Identifier? name, List<TypeAnnotationCode>? typeArguments}) {
    return NamedTypeAnnotationCode(
      name: name ?? this.name,
      typeArguments: typeArguments ?? this.typeArguments,
    );
  }
}

typedef IdentifierResolverCallback = Future<Identifier> Function(Uri library, String name);

class CodeFrom {
  CodeFrom(this.resolveIdentifier);
  final IdentifierResolverCallback resolveIdentifier;

  Future<NamedTypeAnnotationCode> get int => get('int');
  Future<NamedTypeAnnotationCode> get bool => get('bool');
  Future<NamedTypeAnnotationCode> get double => get('double');
  Future<NamedTypeAnnotationCode> get num => get('num');
  Future<NamedTypeAnnotationCode> get string => get('String');
  Future<NamedTypeAnnotationCode> get object => get('Object');
  Future<NamedTypeAnnotationCode> get list => get('List');
  Future<NamedTypeAnnotationCode> get map => get('Map');
  Future<NamedTypeAnnotationCode> get set => get('Set');
  Future<NamedTypeAnnotationCode> get dynamic => get('dynamic');
  Future<NamedTypeAnnotationCode> get mapEntry => get('MapEntry');
  Future<NamedTypeAnnotationCode> get iterable => get('Iterable');
  Future<NamedTypeAnnotationCode> get identical => get('identical');
  Future<NamedTypeAnnotationCode> get dateTime => get('DateTime');

  Future<NamedTypeAnnotationCode> get(String name, [Uri? uri]) async =>
      NamedTypeAnnotationCode(name: await resolveIdentifier(uri ?? dartCore, name));
}

// Compatible with both DefinitionBuilder & DeclarationBuilder.
extension X on DeclarationPhaseIntrospector {
  //
  CodeFrom get codeFrom => CodeFrom(resolveIdentifier);

  /// Returns default or Named constructor.
  Future<ConstructorDeclaration?> defConstructorOf(TypeDeclaration clazz, [String? namedCtors]) async {
    final ctors = await constructorsOf(clazz);
    namedCtors ??= '';
    return ctors.firstWhereOrNull((c) => c.identifier.name == namedCtors);
  }

  Future<ClassDeclaration?> superclassOf(ClassDeclaration clazz) async {
    final superclassType =
        clazz.superclass != null ? await typeDeclarationOf(clazz.superclass!.identifier) : null;
    return superclassType is ClassDeclaration ? superclassType : null;
  }

  /// Returns all fields of a class & its superclasses.
  Future<List<FieldDeclaration>> allFieldsOf(ClassDeclaration clazz) async {
    final allFields = <FieldDeclaration>[...await fieldsOf(clazz)];
    var superclass = await superclassOf(clazz);
    while (superclass != null && superclass.identifier.name != 'Object') {
      allFields.addAll(await fieldsOf(superclass));
      superclass = await superclassOf(superclass);
    }
    return allFields..removeWhere((f) => f.hasStatic);
  }
}

extension TypeAnnotationX on TypeAnnotation {
  T cast<T extends TypeAnnotation>() => this as T;

  NamedTypeAnnotation? checkNamed(Builder builder) {
    if (this is NamedTypeAnnotation) return this as NamedTypeAnnotation;
    if (this is OmittedTypeAnnotation) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Only fields with explicit types are allowed on data classes, please add a type.',
            target: asDiagnosticTarget,
          ),
          Severity.error,
        ),
      );
    } else {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Only fields with named types are allowed on data classes.',
            target: asDiagnosticTarget,
          ),
          Severity.error,
        ),
      );
    }
    return null;
  }
}

//
// ----------------------------------------------------------------------------
//
extension DefinitionBuilderX on DefinitionBuilder {
  Future<TypeAnnotation?> resolveType(FormalParameterDeclaration declaration, ClassDeclaration clazz) {
    return _resolveType(declaration, clazz, fieldsOf, superclassOf, report);
  }

  Future<ConstructorParams> constructorParamsOf(ConstructorDeclaration constructor, ClassDeclaration clazz) {
    return _constructorParamsOf(constructor, clazz, resolveType);
  }
}

extension DeclarationBuilderX on DeclarationBuilder {
  Future<TypeAnnotation?> resolveType(FormalParameterDeclaration declaration, ClassDeclaration clazz) {
    return _resolveType(declaration, clazz, fieldsOf, superclassOf, report);
  }

  Future<ConstructorParams> constructorParamsOf(ConstructorDeclaration constructor, ClassDeclaration clazz) {
    return _constructorParamsOf(constructor, clazz, resolveType);
  }
}

Future<ConstructorParams> _constructorParamsOf(
  ConstructorDeclaration constructor,
  ClassDeclaration clazz,
  Future<TypeAnnotation?> Function(
    FormalParameterDeclaration declaration,
    ClassDeclaration clazz,
  ) resolveType,
) async {
  final (positional, named) = await (
    Future.wait([
      ...constructor.positionalParameters.map((p) {
        return resolveType(p, clazz).then((type) {
          return (
            // TODO(felangel): this workaround until we are able to detect default values.
            isRequired: type?.isNullable == false ? true : p.isRequired,
            name: p.identifier.name,
            type: type,
          );
        });
      })
    ]),
    Future.wait([
      ...constructor.namedParameters.map((p) {
        return resolveType(p, clazz).then((type) {
          return (
            isRequired: p.isRequired,
            name: p.identifier.name,
            type: type,
          );
        });
      })
    ])
  ).wait;
  return (positional: positional, named: named);
}

Future<TypeAnnotation?> _resolveType(
  FormalParameterDeclaration declaration,
  ClassDeclaration clazz,
  Future<List<FieldDeclaration>> Function(TypeDeclaration type) fieldsOf,
  Future<ClassDeclaration?> Function(ClassDeclaration clazz) superclassOf,
  void Function(Diagnostic diagnostic) report,
) async {
  final type = declaration.type;
  final name = declaration.name;
  if (type is NamedTypeAnnotation) return type;
  final fieldDeclarations = await fieldsOf(clazz);
  final field = fieldDeclarations.firstWhereOrNull(
    (f) => f.identifier.name == name,
  );

  if (field != null) return field.type;
  final superclass = await superclassOf(clazz);
  if (superclass != null) {
    return _resolveType(
      declaration,
      superclass,
      fieldsOf,
      superclassOf,
      report,
    );
  }

  report(
    Diagnostic(
      DiagnosticMessage(
        '''
Only fields with explicit types are allowed on data classes.
Please add a type to field "$name" on class "${clazz.identifier.name}".''',
        target: declaration.asDiagnosticTarget,
      ),
      Severity.error,
    ),
  );
  return null;
}

extension NamedTypeAnnotationExtension on NamedTypeAnnotation {
  /// Follows the declaration of this type through any type aliases, until it
  /// reaches a [ClassDeclaration], or returns null if it does not bottom out on
  /// a class.
  Future<ClassDeclaration?> classDeclaration(DefinitionBuilder builder) async {
    var typeDecl = await builder.typeDeclarationOf(identifier);
    while (typeDecl is TypeAliasDeclaration) {
      final aliasedType = typeDecl.aliasedType;
      if (aliasedType is! NamedTypeAnnotation) {
        builder.report(Diagnostic(
            DiagnosticMessage(
                'Only fields with named types are allowed on serializable '
                'classes',
                target: asDiagnosticTarget),
            Severity.error));
        return null;
      }
      typeDecl = await builder.typeDeclarationOf(aliasedType.identifier);
    }
    if (typeDecl is! ClassDeclaration) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only classes are supported as field types for serializable '
              'classes',
              target: asDiagnosticTarget),
          Severity.error));
      return null;
    }
    return typeDecl;
  }
}

extension IsExactly on TypeDeclaration {
  /// Cheaper than checking types using a [StaticType].
  bool isExactly(String name, Uri library) => identifier.name == name && this.library.uri == library;
}

extension CodeExtension on Code {
  /// Used for error messages.
  String get debugString {
    final buffer = StringBuffer();
    _writeDebugString(buffer);
    return buffer.toString();
  }

  void _writeDebugString(StringBuffer buffer) {
    for (final part in parts) {
      switch (part) {
        case Code():
          part._writeDebugString(buffer);
        case Identifier():
          buffer.write(part.name);
        case OmittedTypeAnnotation():
          buffer.write('<omitted>');
        default:
          buffer.write(part);
      }
    }
  }
}

extension FunctionUtils on FunctionDeclaration {
  /// All parameters for this function.
  Iterable<FormalParameterDeclaration> get parameters => positionalParameters.followedBy(namedParameters);
}

/// A diagnostic reported from a [Macro].
class MacroException extends DiagnosticException {
  MacroException(String message, {Severity severity = Severity.error, DiagnosticTarget? target})
      : super(Diagnostic(DiagnosticMessage(message, target: target), severity));
}
