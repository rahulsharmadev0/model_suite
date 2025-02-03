import 'package:model_suite/model.dart';
import 'package:test/test.dart';

abstract class BaseClass {
  const BaseClass();
}

abstract class SubClass extends BaseClass {
  const SubClass();
}

@ConstructorModel()
class EmptyNestedSubClass extends SubClass {}

void main() {
  group(EmptyNestedSubClass, () {
    test('has a const constructor', () {
      expect(const EmptyNestedSubClass(), isA<EmptyNestedSubClass>());
      expect(const EmptyNestedSubClass(), isA<SubClass>());
      expect(const EmptyNestedSubClass(), isA<BaseClass>());
    });
  });
}
