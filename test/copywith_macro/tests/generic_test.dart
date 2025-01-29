import 'package:model_suite/src/macros/copywith.dart';
import 'package:test/test.dart';

void main() {
  group('A<String> CopyWith Tests', () {
    late A<String> instance;

    setUp(() {
      instance = A<String>(
        listOfSerializableField: ['a', 'b', 'c'],
        setOfSerializableField: {'x', 'y', 'z'},
        mapOfSerializableField: {'key1': 'value1', 'key2': 'value2'},
        intValue: 1,
        doubleValue: 1.0,
        stringValue: 'test',
        boolValue: true,
        objectValue: TestObject('test', 1),
      );
    });

    test('copyWith should create new instance with specified fields', () {
      final result = instance.copyWith(
        listOfSerializableField: ['d', 'e'],
        setOfSerializableField: {'w'},
        mapOfSerializableField: {'key3': 'value3'},
      );

      expect(result, isA<A<String>>());
      expect(result.listOfSerializableField, isA<List<String>>());
      expect(result.setOfSerializableField, isA<Set<String>>());
      expect(result.mapOfSerializableField, isA<Map<String, String>>());

      expect(result.listOfSerializableField, ['d', 'e']);
      expect(result.setOfSerializableField, {'w'});
      expect(result.mapOfSerializableField, {'key3': 'value3'});
    });

    test('copyWith should keep original values for null parameters', () {
      final result = instance.copyWith();

      expect(result.listOfSerializableField, instance.listOfSerializableField);
      expect(result.setOfSerializableField, instance.setOfSerializableField);
      expect(result.mapOfSerializableField, instance.mapOfSerializableField);
    });

    test('copyWith should handle partial updates', () {
      final result = instance.copyWith(
        listOfSerializableField: ['new'],
      );

      expect(result.listOfSerializableField, ['new']);
      expect(result.setOfSerializableField, instance.setOfSerializableField);
      expect(result.mapOfSerializableField, instance.mapOfSerializableField);
    });
  });

  group('Primitive Values Tests', () {
    late A<String> instance;
    final testObj = TestObject('test', 1);

    setUp(() {
      instance = A<String>(
        listOfSerializableField: ['a'],
        setOfSerializableField: {'x'},
        mapOfSerializableField: {'key': 'value'},
        intValue: 0,
        doubleValue: 0.0,
        stringValue: '',
        boolValue: false,
        objectValue: testObj,
      );
    });

    test('boundary values', () {
      final result = instance.copyWith(
        intValue: 2147483647, // max int32
        doubleValue: double.maxFinite,
        stringValue: String.fromCharCodes(List.filled(1000, 65)), // long string
        boolValue: true,
      );

      expect(result.intValue, 2147483647);
      expect(result.doubleValue, double.maxFinite);
      expect(result.stringValue.length, 1000);
      expect(result.boolValue, true);
    });

    test('special number values', () {
      final result = instance.copyWith(
        doubleValue: double.infinity,
      );

      expect(result.doubleValue.isInfinite, true);
    });
  });

  group('Complex Object Tests', () {
    late A<TestObject> complexInstance;
    final testObj1 = TestObject('test1', 1);
    final testObj2 = TestObject('test2', 2);

    setUp(() {
      complexInstance = A<TestObject>(
        listOfSerializableField: [testObj1],
        setOfSerializableField: {testObj1},
        mapOfSerializableField: {'obj1': testObj1},
        intValue: 42,
        doubleValue: 3.14,
        stringValue: 'test',
        boolValue: true,
        objectValue: testObj1,
      );
    });

    test('complex object operations', () {
      final result = complexInstance.copyWith(
        listOfSerializableField: [testObj2],
        objectValue: testObj2,
      );

      expect(result.listOfSerializableField.first, testObj2);
      expect(result.objectValue, testObj2);
    });

    test('large collections', () {
      final manyObjects = List.generate(
        1000,
        (i) => TestObject('obj$i', i),
      );

      final result = complexInstance.copyWith(
        listOfSerializableField: manyObjects,
        setOfSerializableField: Set.from(manyObjects),
        mapOfSerializableField: Map<String, TestObject>.fromIterable(
          manyObjects,
          key: (obj) => 'key${(obj as TestObject).value}',
          value: (obj) => obj as TestObject,
        ),
      );

      expect(result.listOfSerializableField.length, 1000);
      expect(result.setOfSerializableField.length, 1000);
      expect(result.mapOfSerializableField.length, 1000);
    });
  });

  group('Edge Cases Tests', () {
    late A<String> instance;
    final testObj = TestObject('test', 1);

    setUp(() {
      instance = A<String>(
        listOfSerializableField: ['a'],
        setOfSerializableField: {'x'},
        mapOfSerializableField: {'key': 'value'},
        intValue: 1,
        doubleValue: 1.0,
        stringValue: 'test',
        boolValue: true,
        objectValue: testObj,
      );
    });

    test('special characters', () {
      final result = instance.copyWith(
        stringValue: '!@#\$%^&*()\n\t\r',
        mapOfSerializableField: {'!@#': '\n\t\r'},
      );

      expect(result.stringValue, '!@#\$%^&*()\n\t\r');
      expect(result.mapOfSerializableField['!@#'], '\n\t\r');
    });
  });

  group('A<int> CopyWith Tests', () {
    late A<int> instance;

    setUp(() {
      instance = A<int>(
        listOfSerializableField: [1, 2, 3],
        setOfSerializableField: {4, 5, 6},
        mapOfSerializableField: {'one': 1, 'two': 2},
        intValue: 1,
        doubleValue: 1.0,
        stringValue: 'test',
        boolValue: true,
        objectValue: TestObject('test', 1),
      );
    });

    test('copyWith should work with different generic type', () {
      final result = instance.copyWith(
        listOfSerializableField: [10, 20],
        setOfSerializableField: {30},
        mapOfSerializableField: {'three': 3},
      );

      expect(result, isA<A<int>>());
      expect(result.listOfSerializableField, isA<List<int>>());
      expect(result.setOfSerializableField, isA<Set<int>>());
      expect(result.mapOfSerializableField, isA<Map<String, int>>());

      expect(result.listOfSerializableField, [10, 20]);
      expect(result.setOfSerializableField, {30});
      expect(result.mapOfSerializableField, {'three': 3});
    });
  });
}

@CopyWithMacro()
class A<C> {
  final List<C> listOfSerializableField;
  final Set<C> setOfSerializableField;
  final Map<String, C> mapOfSerializableField;
  final int intValue;
  final double doubleValue;
  final String stringValue;
  final bool boolValue;
  final TestObject objectValue;

  A({
    required this.listOfSerializableField,
    required this.setOfSerializableField,
    required this.mapOfSerializableField,
    required this.intValue,
    required this.doubleValue,
    required this.stringValue,
    required this.boolValue,
    required this.objectValue,
  });
}

@CopyWithMacro()
class TestObject {
  final String name;
  final int value;
  TestObject(this.name, this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestObject && runtimeType == other.runtimeType && name == other.name && value == other.value;

  @override
  int get hashCode => name.hashCode ^ value.hashCode;
}
