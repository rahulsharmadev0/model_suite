import 'dart:async';

import 'package:macros/macros.dart';
import 'package:model_suite/src/macros/copywith.dart';
import 'package:model_suite/src/macros/json.dart';
import 'package:model_suite/utils/clazz_data.dart';
import 'macros/equality.dart';
import 'macros/tostring.dart';





abstract class ModelBuilder {
  final ClazzData clazzData;
  final MemberDeclarationBuilder builder;
  const ModelBuilder(this.clazzData, this.builder);
  Future<void> build();

  ClassDeclaration get clazz => clazzData.clazz;
}

abstract interface class ModelMacro implements ClassDeclarationsMacro {
  const ModelMacro();
}

macro
class Model extends ModelMacro {
  const Model();

  @override
  Future<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final clazzData = await ClazzData.build(clazz, builder, '', '');

    final builders = <ModelBuilder>[
      JsonModelBuilder(clazzData, builder),
      EqualityModelBuilder(clazzData, builder),
      CopyWithModelBuilder(clazzData, builder),
      ToStringModelBuilder(clazzData, builder),
    ];

    await builders.map((e) => e.build()).wait;
  }
}

//---------------------------------------------------------------------

macro
class JsonModel extends ModelMacro {
  const JsonModel();
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
     final clazzData = await ClazzData.build(clazz, builder, '', '');
    final jsonBuilder = JsonModelBuilder(clazzData, builder);
    return jsonBuilder.build();
  }
}

macro
class EqualityModel extends ModelMacro {
  const EqualityModel();
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final clazzData = await ClazzData.build(clazz, builder, '', '');
    final equalityBuilder = EqualityModelBuilder(clazzData, builder);
    return equalityBuilder.build();
  }
}

macro
class CopyWithModel extends ModelMacro {
  const CopyWithModel();
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final clazzData = await ClazzData.build(clazz, builder, '', '');
    final copyWithBuilder = CopyWithModelBuilder(clazzData, builder);
    return copyWithBuilder.build();
  }
}

macro
class ToStringModel extends ModelMacro {
  const ToStringModel();
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final clazzData = await ClazzData.build(clazz, builder, '', '');
    final toStringBuilder = ToStringModelBuilder(clazzData, builder);
    return toStringBuilder.build();
  }
}
