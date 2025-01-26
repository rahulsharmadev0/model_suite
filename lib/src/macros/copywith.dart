import 'dart:async';

import 'package:macros/macros.dart';
import 'package:model_suite/src/part_utils.dart';


macro class CopyWithMacro implements ClassDeclarationsMacro {
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) {
    throw UnimplementedError();
  }
}




  Future<void> _generateCopyWith(
    List<_Field> fields,
    MemberDeclarationBuilder builder,
    ClassDeclaration clazz,
  ) async {
    if (fields.isEmpty) {
      return;
    }

    final copyWithPrototype = await builder.parts(
      args: {
        'Class': clazz.identifier,
        'CopyWithParameters': DeclarationCode.fromParts([
          for (final field in fields) ...[
            '\n    ',
            field.type.code,
            ' ${field.name},',
          ],
        ]),
      },
      '''
{{Class}} Function({{{CopyWithParameters}}
  })''',
    ).asDeclarationCode();

    final object =
        await builder.resolveIdentifier(Uri.parse('dart:core'), 'Object');
    final sentinel = await builder
        .parts(
          '{{package:model_suite/dataclass.dart#Sentinel}}',
        )
        .asDeclarationCode();

    if (clazz.hasSealed) {
      builder.declareInLibrary(
        DeclarationCode.fromParts([
          '  ',
          copyWithPrototype,
          ' get copyWith;',
        ]),
      );
      return;
    }

    builder.declareInLibrary(
      await builder.parts(args: {
        'CopyWithPrototype': copyWithPrototype,
        'CopyWithParameters': DeclarationCode.fromParts([
          for (final field in fields) ...[
            '\n      ',
            NullableTypeAnnotationCode(NamedTypeAnnotationCode(name: object)),
            ' ${field.name}',
            if (field.type.isNullable) ...[
              ' = const ',
              sentinel,
              '()',
            ],
            ',',
          ]
        ]),
        'Instance': DeclarationCode.fromParts([
          clazz.identifier,
          if (constructor != null) '.$constructor',
          '(',
          for (final field in fields) ...[
            '\n        ',
            if (field.isNamed) '${field.name}: ',
            '${field.name} == ',
            if (field.type.isNullable) ...[
              ' const ',
              sentinel,
              '()',
            ] else
              ' null',
            '\n          ? this.${field.name}\n          : ${field.name} as ',
            field.type.code,
            ',',
          ],
          '\n      )',
        ]),
      }, '''

  {{CopyWithPrototype}} get copyWith {
    return ({{{CopyWithParameters}}
    }) {
      return {{Instance}};
    };
  }''').asDeclarationCode(),
    );
  }

