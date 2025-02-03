import 'package:model_suite/model.dart';
import 'package:test/test.dart';

@ConstructorModel()
class StaticFieldClass {
  static const String field = 'field';
}

void main() {
  group(StaticFieldClass, () {
    test('has a const constructor', () {
      expect(const StaticFieldClass(), isA<StaticFieldClass>());
    });
  });
}
