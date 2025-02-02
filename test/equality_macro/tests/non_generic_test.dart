import 'package:model_suite/src/macros/equality.dart';
import 'package:model_suite/src/model.dart';
import 'package:test/test.dart';

@EqualityModel()
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

@EqualityModel()
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

@EqualityModel()
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

@EqualityModel()
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

@EqualityModel()
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

void main() {
  group('Class C Tests', () {
    test('equal instances compare as equal', () {
      final c1 = C(x: 1);
      final c2 = C(x: 1);
      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('different instances compare as not equal', () {
      final c1 = C(x: 1);
      final c2 = C(x: 2);
      expect(c1, isNot(equals(c2)));
    });
  });

  group('Class A Tests', () {
    test('equal instances with collections compare as equal', () {
      final a1 = A(
        listOfSerializableField: [C(x: 1), C(x: 2)],
        setOfSerializableField: {C(x: 1), C(x: 2)},
        mapOfSerializableField: {'a': C(x: 1), 'b': C(x: 2)},
      );
      final a2 = A(
        listOfSerializableField: [C(x: 1), C(x: 2)],
        setOfSerializableField: {C(x: 1), C(x: 2)},
        mapOfSerializableField: {'a': C(x: 1), 'b': C(x: 2)},
      );
      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
    });
  });

  group('Class B Tests', () {
    test('equal instances with nullable collections compare as equal', () {
      final b1 = B(
        nullableListOfSerializableField: [C(x: 1)],
        nullableSetOfSerializableField: {C(x: 1)},
        nullableMapOfSerializableField: {'a': C(x: 1)},
      );
      final b2 = B(
        nullableListOfSerializableField: [C(x: 1)],
        nullableSetOfSerializableField: {C(x: 1)},
        nullableMapOfSerializableField: {'a': C(x: 1)},
      );
      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
    });

    test('instances with null fields compare as equal', () {
      final b1 = B();
      final b2 = B();
      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
    });
  });

  group('Inheritance Tests', () {
    test('equal Child instances compare as equal', () {
      final child1 = Child(
        Obj(x: 1),
        Obj(x: 2),
        [Obj(x: 3)],
        [Obj(x: 4)],
        {Obj(x: 5)},
        {Obj(x: 6)},
        {'a': Obj(x: 7)},
        {'b': Obj(x: 8)},
        intField: 1,
        nullableIntField: 2,
        listOfIntField: [1, 2],
        nullableListOfIntField: [3, 4],
        setOfIntField: {1, 2},
        nullableSetOfIntField: {3, 4},
        mapOfStringToIntField: {'a': 1},
        nullableMapOfStringToIntField: {'b': 2},
      );
      final child2 = Child(
        Obj(x: 1),
        Obj(x: 2),
        [Obj(x: 3)],
        [Obj(x: 4)],
        {Obj(x: 5)},
        {Obj(x: 6)},
        {'a': Obj(x: 7)},
        {'b': Obj(x: 8)},
        intField: 1,
        nullableIntField: 2,
        listOfIntField: [1, 2],
        nullableListOfIntField: [3, 4],
        setOfIntField: {1, 2},
        nullableSetOfIntField: {3, 4},
        mapOfStringToIntField: {'a': 1},
        nullableMapOfStringToIntField: {'b': 2},
      );
      expect(child1, equals(child2));
      expect(child1.hashCode, equals(child2.hashCode));
    });
  });
}
