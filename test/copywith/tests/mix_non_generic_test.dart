import 'package:model_suite/model.dart';
import 'package:test/test.dart';

void main() {
  group('CopyWith Testing', () {
    test('A', () {
      final a = A(
        listOfSerializableField: [C(x: 1)],
        setOfSerializableField: {C(x: 1)},
        mapOfSerializableField: {'key': C(x: 1)},
      );

      final copy = a.copyWith(
        listOfSerializableField: [C(x: 2)],
        setOfSerializableField: {C(x: 2)},
        mapOfSerializableField: {'key': C(x: 2)},
      );

      expect(copy.listOfSerializableField.first.x, 2);
      expect(copy.setOfSerializableField.first.x, 2);
      expect(copy.mapOfSerializableField['key']!.x, 2);
    });
    test('B', () {
      final b = B(
        nullableListOfSerializableField: [C(x: 1)],
        nullableSetOfSerializableField: {C(x: 1)},
        nullableMapOfSerializableField: {'key': C(x: 1)},
      );

      final copy = b.copyWith(
        nullableListOfSerializableField: [C(x: 2)],
        nullableSetOfSerializableField: {C(x: 2)},
        nullableMapOfSerializableField: {'key': C(x: 2)},
      );

      expect(copy.nullableListOfSerializableField!.first.x, 2);
      expect(copy.nullableSetOfSerializableField!.first.x, 2);
      expect(copy.nullableMapOfSerializableField!['key']!.x, 2);
    });

    test('C', () {
      final c = C(x: 1);
      final copy = c.copyWith(x: 2);
      expect(copy.x, 2);
    });
  });

  group('Parent and Child CopyWith Testing', () {
    test('Parent copyWith - all fields', () {
      final parent = Parent(
        intField: 1,
        nullableIntField: 2,
        listOfIntField: [1, 2, 3],
        nullableListOfIntField: [4, 5, 6],
        setOfIntField: {1, 2, 3},
        nullableSetOfIntField: {4, 5, 6},
        mapOfStringToIntField: {'a': 1, 'b': 2},
        nullableMapOfStringToIntField: {'c': 3, 'd': 4},
      );

      final copy = parent.copyWith(
        intField: 10,
        nullableIntField: null,
        listOfIntField: [7, 8, 9],
        nullableListOfIntField: null,
        setOfIntField: {7, 8, 9},
        nullableSetOfIntField: null,
        mapOfStringToIntField: {'x': 10, 'y': 11},
        nullableMapOfStringToIntField: null,
      );

      expect(copy.intField, 10);
      expect(copy.nullableIntField, null);
      expect(copy.listOfIntField, [7, 8, 9]);
      expect(copy.nullableListOfIntField, null);
      expect(copy.setOfIntField, {7, 8, 9});
      expect(copy.nullableSetOfIntField, null);
      expect(copy.mapOfStringToIntField, {'x': 10, 'y': 11});
      expect(copy.nullableMapOfStringToIntField, null);
    });

    test('Child copyWith - complex inheritance test', () {
      final child = Child(
        Obj(x: 1),
        Obj(x: 2),
        [Obj(x: 3), Obj(x: 4)],
        [Obj(x: 5), Obj(x: 6)],
        {Obj(x: 7), Obj(x: 8)},
        {Obj(x: 9), Obj(x: 10)},
        {'a': Obj(x: 11), 'b': Obj(x: 12)},
        {'c': Obj(x: 13), 'd': Obj(x: 14)},
        intField: 15,
        nullableIntField: 16,
        listOfIntField: [17, 18],
        nullableListOfIntField: [19, 20],
        setOfIntField: {21, 22},
        nullableSetOfIntField: {23, 24},
        mapOfStringToIntField: {'e': 25, 'f': 26},
        nullableMapOfStringToIntField: {'g': 27, 'h': 28},
      );

      final copy = child.copyWith(
        objField: Obj(x: 100),
        nullableObjField: null,
        listOfObjField: [Obj(x: 101)],
        nullableListOfObjField: null,
        setOfObjField: {Obj(x: 102)},
        nullableSetOfObjField: null,
        mapOfStringToObjField: {'new': Obj(x: 103)},
        nullableMapOfStringToObjField: null,
        intField: 104,
        nullableIntField: null,
        listOfIntField: [105, 106],
        nullableListOfIntField: null,
        setOfIntField: {107, 108},
        nullableSetOfIntField: null,
        mapOfStringToIntField: {'new': 109},
        nullableMapOfStringToIntField: null,
      );

      // Verify Child fields
      expect(copy.objField.x, 100);
      expect(copy.nullableObjField, null);
      expect(copy.listOfObjField.single.x, 101);
      expect(copy.nullableListOfObjField, null);
      expect(copy.setOfObjField.single.x, 102);
      expect(copy.nullableSetOfObjField, null);
      expect(copy.mapOfStringToObjField['new']!.x, 103);
      expect(copy.nullableMapOfStringToObjField, null);

      // Verify inherited Parent fields
      expect(copy.intField, 104);
      expect(copy.nullableIntField, null);
      expect(copy.listOfIntField, [105, 106]);
      expect(copy.nullableListOfIntField, null);
      expect(copy.setOfIntField, {107, 108});
      expect(copy.nullableSetOfIntField, null);
      expect(copy.mapOfStringToIntField['new'], 109);
      expect(copy.nullableMapOfStringToIntField, null);
    });

    test('Child copyWith - partial update test', () {
      final child = Child(
        Obj(x: 1),
        null,
        [Obj(x: 2)],
        null,
        {Obj(x: 3)},
        null,
        {'a': Obj(x: 4)},
        null,
        intField: 5,
        nullableIntField: null,
        listOfIntField: [6],
        nullableListOfIntField: null,
        setOfIntField: {7},
        nullableSetOfIntField: null,
        mapOfStringToIntField: {'b': 8},
        nullableMapOfStringToIntField: null,
      );

      final copy = child.copyWith(
        objField: Obj(x: 100),
        listOfIntField: [200],
        mapOfStringToObjField: {'new': Obj(x: 300)},
      );

      // Verify only specified fields are updated
      expect(copy.objField.x, 100);
      expect(copy.nullableObjField, null);
      expect(copy.listOfIntField, [200]);
      expect(copy.mapOfStringToObjField['new']!.x, 300);

      // Verify other fields remain unchanged
      expect(copy.listOfObjField.single.x, 2);
      expect(copy.nullableListOfObjField, null);
      expect(copy.intField, 5);
      expect(copy.setOfIntField, {7});
    });
  });
}

@CopyWithModel()
class A {
  final List<C> listOfSerializableField;
  final Set<C> setOfSerializableField;
  final Map<String, C> mapOfSerializableField;

  A({
    required this.listOfSerializableField,
    required this.setOfSerializableField,
    required this.mapOfSerializableField,
  });
}

@CopyWithModel()
class B {
  final List<C>? nullableListOfSerializableField;
  final Set<C>? nullableSetOfSerializableField;
  final Map<String, C>? nullableMapOfSerializableField;

  B({
    this.nullableListOfSerializableField,
    this.nullableSetOfSerializableField,
    this.nullableMapOfSerializableField,
  });
}

@CopyWithModel()
class C {
  final int x;
  C({required this.x});
}

class Obj {
  final int x;
  Obj({required this.x});

  @override
  bool operator ==(Object other) {
    if (other is Obj) return x == other.x;
    return false;
  }

  @override
  int get hashCode => x.hashCode;
}

@CopyWithModel()
class Parent {
  final int intField;
  final int? nullableIntField;
  final List<int> listOfIntField;
  final List<int>? nullableListOfIntField;
  final Set<int> setOfIntField;
  final Set<int>? nullableSetOfIntField;
  final Map<String, int> mapOfStringToIntField;
  final Map<String, int>? nullableMapOfStringToIntField;
  Parent({
    required this.intField,
    required this.nullableIntField,
    required this.listOfIntField,
    required this.nullableListOfIntField,
    required this.setOfIntField,
    required this.nullableSetOfIntField,
    required this.mapOfStringToIntField,
    required this.nullableMapOfStringToIntField,
  });
}

@CopyWithModel()
class Child extends Parent {
  final Obj objField;
  final Obj? nullableObjField;
  final List<Obj> listOfObjField;
  final List<Obj>? nullableListOfObjField;
  final Set<Obj> setOfObjField;
  final Set<Obj>? nullableSetOfObjField;
  final Map<String, Obj> mapOfStringToObjField;
  final Map<String, Obj>? nullableMapOfStringToObjField;
  Child(
      this.objField,
      this.nullableObjField,
      this.listOfObjField,
      this.nullableListOfObjField,
      this.setOfObjField,
      this.nullableSetOfObjField,
      this.mapOfStringToObjField,
      this.nullableMapOfStringToObjField,
      {required super.intField,
      required super.nullableIntField,
      required super.listOfIntField,
      required super.nullableListOfIntField,
      required super.setOfIntField,
      required super.nullableSetOfIntField,
      required super.mapOfStringToIntField,
      required super.nullableMapOfStringToIntField});
}
