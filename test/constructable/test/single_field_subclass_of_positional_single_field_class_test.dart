import 'package:model_suite/model.dart';
import 'package:test/test.dart';

abstract class BaseClass {
  const BaseClass(this.baseField);
  final String baseField;
}

@ConstructorModel()
class SingleFieldSubClass extends BaseClass {
  final String field;
}

void main() {
  group(SingleFieldSubClass, () {
    test('has a const constructor and has required param for all fields', () {
      const instance = SingleFieldSubClass(
        baseField: 'baseField',
        field: 'field',
      );
      expect(instance.baseField, equals('baseField'));
      expect(instance.field, equals('field'));
      expect(instance, isA<SingleFieldSubClass>());
      expect(instance, isA<BaseClass>());
    });
  });
}
