// import 'package:macros/macros.dart';
// import 'macros/equality.dart';
// import 'macros/copywith.dart';
// import 'macros/tostring.dart';
// import 'macros/json.dart';

// const JsonMacro _jsonMacro = JsonMacro();
// const EqualityMacro _equalityMacro = EqualityMacro();
// const CopyWithMacro _copyWithMacro = CopyWithMacro();
// const ToStringMacro _toStringMacro = ToStringMacro();

// macro
// class Model implements ClassDeclarationsMacro, ClassDefinitionMacro {
//   const Model();

//   @override
//   Future<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
//     await _jsonMacro.buildDefinitionForClass(clazz, builder);
//     await _equalityMacro.buildDefinitionForClass(clazz, builder);
//     await _copyWithMacro.buildDefinitionForClass(clazz, builder);
//     await _toStringMacro.buildDefinitionForClass(clazz, builder);
//   }

//   @override
//   Future<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
//     await _jsonMacro.buildDeclarationsForClass(clazz, builder);
//     await _equalityMacro.buildDeclarationsForClass(clazz, builder);
//     await _copyWithMacro.buildDeclarationsForClass(clazz, builder);
//     await _toStringMacro.buildDeclarationsForClass(clazz, builder);
//   }
// }
