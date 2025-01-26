import 'dart:async';

import 'package:macros/macros.dart';


macro class CopyWith implements ClassDeclarationsMacro {
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) {
    throw UnimplementedError();
  }
}