import 'package:model_suite/src/macros/copywith.dart';
import 'package:model_suite/src/model.dart';
import 'package:test/test.dart';

@CopyWithModel()
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

void main() {
  group('Complex A<String> CopyWith Tests', () {
    late A<String> instance;
    final testObj = TestObject('test', 42);

    setUp(() {
      instance = A<String>(
        listOfSerializableField: ['a', null, 'c'],
        setOfSerializableField: {'x', null, 'z'},
        mapOfSerializableField: {'key1': 'value1', 'key2': null},
        intValue: 42,
        doubleValue: 3.14,
        stringValue: 'hello',
        boolValue: true,
        objectValue: testObj,
        nullableObject: null,
      );
    });

    test('copyWith should handle all field types correctly', () {
      final newTestObj = TestObject('new', 100);
      final result = instance.copyWith(
        listOfSerializableField: ['new'],
        setOfSerializableField: {'updated'},
        mapOfSerializableField: {'new': 'map'},
        intValue: 100,
        doubleValue: 2.718,
        stringValue: 'world',
        boolValue: false,
        objectValue: newTestObj,
        nullableObject: testObj,
      );

      expect(result.intValue, 100);
      expect(result.doubleValue, 2.718);
      expect(result.stringValue, 'world');
      expect(result.boolValue, false);
      expect(result.objectValue, newTestObj);
      expect(result.nullableObject, testObj);
    });

    test('copyWith should handle null values for nullable fields', () {
      final result = instance.copyWith(
        intValue: null,
        doubleValue: null,
        stringValue: null,
        boolValue: null,
        objectValue: null,
        nullableObject: null,
      );

      expect(result.intValue, null);
      expect(result.doubleValue, null);
      expect(result.stringValue, null);
      expect(result.boolValue, null);
      expect(result.objectValue, null);
      expect(result.nullableObject, null);
    });
  });

  group('Complex A<TestObject> CopyWith Tests', () {
    late A<TestObject> instance;
    final testObj1 = TestObject('test1', 1);
    final testObj2 = TestObject('test2', 2);

    setUp(() {
      instance = A<TestObject>(
        listOfSerializableField: [testObj1, null, testObj2],
        setOfSerializableField: {testObj1, null},
        mapOfSerializableField: {'key1': testObj1, 'key2': null},
        intValue: 42,
        doubleValue: 3.14,
        stringValue: 'hello',
        boolValue: true,
        objectValue: testObj1,
        nullableObject: null,
      );
    });

    test('copyWith should work with complex generic type', () {
      final newTestObj = TestObject('new', 100);
      final result = instance.copyWith(
        listOfSerializableField: [newTestObj],
        setOfSerializableField: {newTestObj},
        mapOfSerializableField: {'new': newTestObj},
      );

      expect(result.listOfSerializableField, [newTestObj]);
      expect(result.setOfSerializableField, {newTestObj});
      expect(result.mapOfSerializableField, {'new': newTestObj});
    });
  });

  group('A<int> CopyWith Tests', () {
    late A<int> instance;

    setUp(() {
      instance = A<int>(
        listOfSerializableField: [1, null, 3],
        setOfSerializableField: {4, null, 6},
        mapOfSerializableField: {'one': 1, 'two': null},
      );
    });

    test('copyWith should work with different generic type', () {
      final result = instance.copyWith(
        listOfSerializableField: [10, 20],
        setOfSerializableField: {30},
        mapOfSerializableField: {'three': 3},
      );

      expect(result, isA<A<int>>());
      expect(result.listOfSerializableField, isA<List<int?>>());
      expect(result.setOfSerializableField, isA<Set<int?>>());
      expect(result.mapOfSerializableField, isA<Map<String, int?>?>());

      expect(result.listOfSerializableField, [10, 20]);
      expect(result.setOfSerializableField, {30});
      expect(result.mapOfSerializableField, {'three': 3});
    });

    test('copyWith should handle null values with int type', () {
      final result = instance.copyWith(
        listOfSerializableField: [10, null, 30],
        setOfSerializableField: {40, null},
        mapOfSerializableField: {'three': null, 'four': 4},
      );

      expect(result.listOfSerializableField, [10, null, 30]);
      expect(result.setOfSerializableField, {40, null});
      expect(result.mapOfSerializableField, {'three': null, 'four': 4});
    });
  });
}

@CopyWithModel()
class A<C> {
  final List<C?>? listOfSerializableField;
  final Set<C?>? setOfSerializableField;
  final Map<String, C?>? mapOfSerializableField;
  final int? intValue;
  final double? doubleValue;
  final String? stringValue;
  final bool? boolValue;
  final TestObject? objectValue;
  final TestObject? nullableObject;

  A({
    required this.listOfSerializableField,
    required this.setOfSerializableField,
    required this.mapOfSerializableField,
    this.intValue,
    this.doubleValue,
    this.stringValue,
    this.boolValue,
    this.objectValue,
    this.nullableObject,
  });
}
