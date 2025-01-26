import 'dart:async';

import 'package:macros/macros.dart';


macro class CopyWithMacro implements ClassDeclarationsMacro {
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) {
    throw UnimplementedError();
  }
}