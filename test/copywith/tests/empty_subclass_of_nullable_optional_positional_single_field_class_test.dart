import 'package:model_suite/model.dart';
import 'package:test/test.dart';

abstract class BaseClass {
  const BaseClass([this.field]);
  final String? field;
}

@CopyWithModel()
class EmptySubClass extends BaseClass {
  const EmptySubClass({String? field}) : super(field);
}

void main() {
  group(EmptySubClass, () {
    test('copyWith creates a copy when no arguments are passed', () {
      final instance = EmptySubClass(field: 'field');
      final copy = instance.copyWith();
      expect(copy.field, equals(instance.field));
    });

    test('copyWith creates a copy and overrides field', () {
      final instance = EmptySubClass(field: 'field');
      final copy = instance.copyWith(field: 'other');
      expect(copy.field, equals('other'));
    });

    test('copyWith creates a copy and overrides field with null', () {
      final instance = EmptySubClass(field: 'field');
      final copy = instance.copyWith(field: null);
      expect(copy.field, isNull);
    });
  });
}
