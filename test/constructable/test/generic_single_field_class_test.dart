import 'package:model_suite/model.dart';
import 'package:test/test.dart';

// @ConstructorModel()
class GenericSingleFieldClass<T> {
  final T field;
  const GenericSingleFieldClass({required this.field});
}

void main() {
  group(GenericSingleFieldClass, () {
    test('has a const constructor and required param', () {
      // expect(const GenericSingleFieldClass<bool>(field: false).field, equals(false));
      // expect(const GenericSingleFieldClass<String>(field: 'field').field, equals('field'));
      // expect(const GenericSingleFieldClass<int>(field: 42).field, equals(42));
      // expect(const GenericSingleFieldClass<double>(field: 42.0).field, equals(42.0));
    });
  });
}
