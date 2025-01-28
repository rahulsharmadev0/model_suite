import 'package:model_suite/src/macros/equality.dart';
import 'package:test/test.dart';

@EqualityMacro()
class EmptyClass {}

void main() {
  group(EmptyClass, () {
    test('== is correct', () {
      expect(EmptyClass(), equals(EmptyClass()));
    });

    test('hashCode is correct', () {
      expect(EmptyClass().hashCode, equals(EmptyClass().hashCode));
    });
  });
}
