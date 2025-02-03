import 'package:model_suite/model.dart';
import 'package:test/test.dart';

@ConstructorModel()
class EmptyClass {}

void main() {
  group(EmptyClass, () {
    test('has a const constructor', () {
      expect(const EmptyClass(), isA<EmptyClass>());
    });
  });
}
