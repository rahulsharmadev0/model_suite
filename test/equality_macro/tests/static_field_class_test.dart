import 'package:model_suite/src/macros/equality.dart';
import 'package:test/test.dart';

@EqualityMacro()
class StaticFieldClass {
  static const String field = 'field';
}

void main() {
  group(StaticFieldClass, () {
    test('== is correct', () {
      expect(StaticFieldClass(), equals(StaticFieldClass()));
    });

    test('hashCode is correct', () {
      expect(StaticFieldClass().hashCode, equals(StaticFieldClass().hashCode));
    });
  });
}
