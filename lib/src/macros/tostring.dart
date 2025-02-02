import 'dart:async';
import 'package:macros/macros.dart' hide MacroException;
import 'package:model_suite/src/model.dart' show ModelBuilder;
import 'package:model_suite/utils/clazz_data.dart';
import 'package:model_suite/utils/macros_utils.dart';

mixin ToStringMacroException {
  MacroException toStringError(DiagnosticTarget target) =>
      MacroException('Cannot generate a `toString` method for a class that already has one.', target: target);
}

class ToStringModelBuilder extends ModelBuilder with ToStringMacroException {
  const ToStringModelBuilder(super.clazzData, super.builder);

  @override
  Future<void> build() async {
    if (clazzData.hasToString) return;

    final string = await builder.codeFrom.string;
    var allFields = clazzData.allFields;
    final fieldsCode = <Object>[
      for (var (i, f) in allFields.indexed) ...[
        f.identifier.name,
        ': ',
        r'${',
        f.identifier,
        '.toString()}',
        if (i < allFields.length - 1) ', '
      ]
    ];

    var parts = ['  ', string, ' toString() => "', clazzData.name, '(', ...fieldsCode, ')";'];
    builder.declareInType(DeclarationCode.fromParts(parts));
  }
}
