import 'package:model_suite/model.dart';
import 'package:test/test.dart';

abstract class BaseClass {
  const BaseClass();
}

@ConstructorModel()
class EmptySubClass extends BaseClass {}

void main() {
  group(EmptySubClass, () {
    test('has a const constructor', () {
      expect(const EmptySubClass(), isA<EmptySubClass>());
      expect(const EmptySubClass(), isA<BaseClass>());
    });
  });
}
