import 'dart:async';

import 'package:macros/macros.dart';


macro class EqualityMacro implements ClassDeclarationsMacro {
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) {
    throw UnimplementedError();
  }
}