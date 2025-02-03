import 'package:model_suite/model.dart';
import 'package:test/test.dart';

@EqualityModel()
class A1<C extends String, B> {
  final List<C?>? listOfSerializableField;
  final Set<C> setOfSerializableField;
  final Map<C, B?>? mapOfSerializableField;
  final Point? pointField;
  final Map<String, Point>? mapOfPointField;
  final int? intField;
  final double doubleField;
  final String stringField;

  A1({
    required this.mapOfPointField,
    required this.listOfSerializableField,
    required this.setOfSerializableField,
    required this.mapOfSerializableField,
    required this.intField,
    required this.doubleField,
    required this.stringField,
    required this.pointField,
  });
}

@EqualityModel()
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}

void main() {
  group('Point Tests', () {
    test('equal points compare as equal', () {
      final p1 = Point(1, 2);
      final p2 = Point(1, 2);
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('different points compare as not equal', () {
      final p1 = Point(1, 2);
      final p2 = Point(1, 3);
      expect(p1, isNot(equals(p2)));
    });
  });

  group('Generic A1 Tests', () {
    test('equal instances of same generic type compare as equal', () {
      final a1 = A1<String, int>(
        listOfSerializableField: ['test', null],
        setOfSerializableField: {'test1', 'test2'},
        mapOfSerializableField: {'key': null, 'key2': 42},
        pointField: Point(1, 2),
        mapOfPointField: {'p1': Point(1, 2)},
        intField: 42,
        doubleField: 3.14,
        stringField: 'test',
      );

      final a2 = A1<String, int>(
        listOfSerializableField: ['test', null],
        setOfSerializableField: {'test1', 'test2'},
        mapOfSerializableField: {'key': null, 'key2': 42},
        pointField: Point(1, 2),
        mapOfPointField: {'p1': Point(1, 2)},
        intField: 42,
        doubleField: 3.14,
        stringField: 'test',
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isA<A1<String, int>>());
    });

    test('instances with different generic types are not equal', () {
      final a1 = A1<String, int>(
        listOfSerializableField: ['test'],
        setOfSerializableField: {'test'},
        mapOfSerializableField: {'key': 1},
        pointField: Point(1, 2),
        mapOfPointField: {'p1': Point(1, 2)},
        intField: 42,
        doubleField: 3.14,
        stringField: 'test',
      );

      final a2 = A1<String, double>(
        listOfSerializableField: ['test'],
        setOfSerializableField: {'test'},
        mapOfSerializableField: {'key': 1.0},
        pointField: Point(1, 2),
        mapOfPointField: {'p1': Point(1, 2)},
        intField: 42,
        doubleField: 3.14,
        stringField: 'test',
      );

      expect(a1, isNot(equals(a2)));
      expect(a1, isA<A1<String, int>>());
      expect(a2, isA<A1<String, double>>());
    });

    test('null fields are handled correctly', () {
      final a1 = A1<String, int>(
        listOfSerializableField: null,
        setOfSerializableField: {'test'},
        mapOfSerializableField: null,
        pointField: null,
        mapOfPointField: null,
        intField: null,
        doubleField: 3.14,
        stringField: 'test',
      );

      final a2 = A1<String, int>(
        listOfSerializableField: null,
        setOfSerializableField: {'test'},
        mapOfSerializableField: null,
        pointField: null,
        mapOfPointField: null,
        intField: null,
        doubleField: 3.14,
        stringField: 'test',
      );

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
    });

    test('collection equality respects generic types', () {
      final a1 = A1<String, Point>(
        listOfSerializableField: ['test1', 'test2'],
        setOfSerializableField: {'test1', 'test2'},
        mapOfSerializableField: {'key1': Point(1, 2), 'key2': Point(3, 4)},
        pointField: Point(1, 2),
        mapOfPointField: {'p1': Point(1, 2)},
        intField: 42,
        doubleField: 3.14,
        stringField: 'test',
      );

      expect(a1, isA<A1<String, Point>>());
      expect(a1.mapOfSerializableField?['key1'], isA<Point>());
    });
  });
}
