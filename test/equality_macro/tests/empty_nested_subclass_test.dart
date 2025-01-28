import 'package:model_suite/src/macros/equality.dart';
import 'package:test/test.dart';

abstract class BaseClass {}

abstract class SubClass extends BaseClass {}

@EqualityMacro()
class EmptyNestedSubClass extends SubClass {}

void main() {
  group(EmptyNestedSubClass, () {
    test('== is correct', () {
      expect(EmptyNestedSubClass(), equals(EmptyNestedSubClass()));
    });

    test('hashCode is correct', () {
      expect(EmptyNestedSubClass().hashCode, equals(EmptyNestedSubClass().hashCode));
    });
  });
}
