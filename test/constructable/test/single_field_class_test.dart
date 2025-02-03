import 'package:model_suite/model.dart';
import 'package:test/test.dart';

@ConstructorModel()
class SingleFieldClass {
  final String field;
}

void main() {
  group(SingleFieldClass, () {
    test('has a const constructor and required param', () {
      expect(const SingleFieldClass(field: 'field').field, equals('field'));
    });
  });
}
