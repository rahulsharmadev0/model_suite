import 'package:macros/macros.dart';
import 'package:model_suite/src/macros/json.dart';

const JsonMacro jsonMacro = JsonMacro();

macro
class Model implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const Model();

  @override
  Future<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    await jsonMacro.buildDefinitionForClass(clazz, builder);
  }

  @override
  Future<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    await jsonMacro.buildDeclarationsForClass(clazz, builder);
  }
}
