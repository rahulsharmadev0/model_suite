import 'dart:async';

import 'package:collection/collection.dart';
import 'package:macros/macros.dart' hide MacroException;
import 'package:model_suite/src/macros.dart';
import 'package:model_suite/src/macros_utils.dart';

mixin ToStringMacroException {
  MacroException toStringError(DiagnosticTarget target) =>
      MacroException('Cannot generate a `toString` method for a class that already has one.', target: target);
}

macro
class ToStringMacro
    with ToStringMacroException, _ToString
    implements ClassDefinitionMacro, ClassDeclarationsMacro {

  const ToStringMacro();

  @override
  FutureOr<void> buildDeclarationsForClass(
    ClassDeclaration clazz,
    MemberDeclarationBuilder builder,
  ) async {
    await declareToString(clazz, builder);
  }

  @override
  FutureOr<void> buildDefinitionForClass(
    ClassDeclaration clazz,
    TypeDefinitionBuilder builder,
  ) async =>
      await defineToString(clazz, builder);
}

mixin _ToString on ToStringMacroException {
  Future<MethodDeclaration?> getMethod(ClassDeclaration clazz, DeclarationPhaseIntrospector builder) async {
    var methods = await builder.methodsOf(clazz);
    return methods.firstWhereOrNull((e) => e.identifier.name == 'toString');
  }

  Future<void> defineToString(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final toStringMethod = await getMethod(clazz, builder);
    if (toStringMethod == null) return;

    final (toStringMethodBuilder, fields, string) = await (
      builder.buildMethod(toStringMethod.identifier),
      builder.allFieldsOf(clazz),
      builder.codeFrom.string,
    ).wait;

    final fieldsCode = <Object>[
    for (var (i, f) in fields.indexed) 
    ...[
      f.identifier.name,
      ': ',
      r'${',
      f.identifier,
      '}',
      if(i < fields.length - 1) ', '
      ]
    ];

    var parts = ['=> "', clazz.identifier.name, '(', ...fieldsCode, ')";'];

    toStringMethodBuilder.augment(FunctionBodyCode.fromParts(parts));
  }

  Future<void> declareToString(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    var toStringMethod = await getMethod(clazz, builder);
    if (toStringMethod != null) throw toStringError(toStringMethod.asDiagnosticTarget);

    // ignore: deprecated_member_use
    var string = await builder.codeFrom.string;
    builder.declareInType(DeclarationCode.fromParts(['  external ', string, ' toString();']));
  }
}
