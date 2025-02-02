import 'package:macros/macros.dart';
import 'package:model_suite/src/model.dart';
import 'package:model_suite/utils/clazz_data.dart';
import 'package:model_suite/utils/macros_utils.dart';

class ConstructorModelBuilder extends ModelBuilder {
  ConstructorModelBuilder(super.clazzData, super.builder);

  @override
  Future<void> build() async {
    if (clazzData.hasConstructor) return;
    if (clazz.hasAbstract || clazz.hasSealed) return;

    final fields = clazzData.clazzfields;
    final superParams = <Object>[];
    final superCallParams = <Object>[];

    // Handle superclass constructor
    if (clazzData.hasSuperConstructor) {
      var parameters = clazzData.superConstructor!.parameters;
      for (final (i, param) in parameters.indexed) {
        final name = param.identifier.name;
        final type = param.type.code;
        superParams
          ..add(RawCode.fromParts([if (param.isRequired) 'required ', type, ' ', name]))
          ..add(', ');
        superCallParams.addAll([param.isNamed ? '$name: $name' : name, if (i < parameters.length - 1) ', ']);
      }
    }

    // Handle empty case (no fields and no super params)
    if (fields.isEmpty && superParams.isEmpty) {
      builder.declareInType(
        DeclarationCode.fromString(
          'const ${clazzData.constructorAlongWithClazzName}();',
        ),
      );
      return;
    }

    final declaration = DeclarationCode.fromParts([
      'const ${clazzData.constructorAlongWithClazzName}({',
      ...superParams,
      for (final field in fields) ...[
        if (!field.type.isNullable) 'required ',
        'this.',
        field.identifier.name,
        ',',
      ],
      '})',
      if (clazzData.hasSuperConstructor) ...[
        ' : super(',
        ...superCallParams,
        ')',
      ],
      ';',
    ]);

    builder.declareInType(declaration);
    clazzData.isModelConstructorDefined = true;
    return;
  }
}
