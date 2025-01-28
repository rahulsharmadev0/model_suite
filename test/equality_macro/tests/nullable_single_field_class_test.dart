import 'package:model_suite/src/macros/equality.dart';
import 'package:test/test.dart';

@EqualityMacro()
class NullableSingleFieldClass {
  NullableSingleFieldClass({this.field});
  final String? field;
}

void main() {
  group(NullableSingleFieldClass, () {
    test('== is correct', () {
      final instanceA = NullableSingleFieldClass(field: 'field');
      final instanceB = NullableSingleFieldClass(field: 'field');
      final instanceC = NullableSingleFieldClass();
      expect(instanceA, equals(instanceB));
      expect(instanceC, isNot(equals(instanceB)));
      expect(instanceC, isNot(equals(instanceA)));
    });

    test('hashCode is correct', () {
      final instanceA = NullableSingleFieldClass(field: 'field');
      final instanceB = NullableSingleFieldClass(field: 'field');
      final instanceC = NullableSingleFieldClass();
      expect(instanceA.hashCode, equals(instanceB.hashCode));
      expect(instanceC.hashCode, isNot(equals(instanceB.hashCode)));
      expect(instanceC.hashCode, isNot(equals(instanceA.hashCode)));
    });
  });
}
