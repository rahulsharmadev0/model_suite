import 'package:model_suite/model.dart';
import 'package:test/test.dart';

abstract class BaseClass {
  const BaseClass({required this.field});
  final String field;
}

@ConstructorModel()
class EmptySubClass extends BaseClass {}

void main() {
  group(EmptySubClass, () {
    test('has a const constructor and requires the super class param', () {
      const instance = EmptySubClass(field: 'field');
      expect(instance.field, equals('field'));
      expect(instance, isA<EmptySubClass>());
      expect(instance, isA<BaseClass>());
    });
  });
}
