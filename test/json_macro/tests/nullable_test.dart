import 'package:model_suite/src/macros/json.dart';
import 'package:model_suite/model.dart';
import 'package:test/test.dart';

@JsonModel()
class BasicDataType {
  final int? nullableInt;
  final double? nullableDouble;
  final String? nullableString;
  final bool? nullableBool;
  final DateTime? nullableDateTime;
  final int $int;
  final double $double;
  final String $string;
  final bool $bool;
  final DateTime $dateTime;
}

@JsonModel()
class ListDataType {
  List<int>? nullableListInt;
  List<double>? nullableListDouble;
  List<String>? nullableListString;
  List<bool>? nullableListBool;
  List<DateTime>? nullableListDateTime;
}

class SetDataType {
  Set<int>? nullableSetInt;
  Set<double>? nullableSetDouble;
  Set<String>? nullableSetString;
  Set<bool>? nullableSetBool;
  Set<DateTime>? nullableSetDateTime;
}

@JsonModel()
class MapKeyAsStringDataType {
  Map<String, int>? nullableMapInt;
  Map<String, double>? nullableMapDouble;
  Map<String, String>? nullableMapString;
  Map<String, bool>? nullableMapBool;
  Map<String, DateTime>? nullableMapDateTime;
}

void main() {
  group('BasicDataType', () {
    final data = BasicDataType.fromJson({
      'nullableInt': 42,
      'nullableDouble': 3.14,
      'nullableString': 'test',
      'nullableBool': true,
      'nullableDateTime': '2023-01-01T00:00:00.000Z',
      r'$int': 100,
      r'$double': 2.5,
      r'$string': 'required',
      r'$bool': false,
      r'$dateTime': '2023-12-31T00:00:00.000Z',
    });

    test('should serialize and deserialize correctly', () {
      final json = data.toJson();
      expect(json['nullableInt'], 42);
      expect(json['nullableDouble'], 3.14);
      expect(json['nullableString'], 'test');
      expect(json['nullableBool'], true);
      expect(json['nullableDateTime'], '2023-01-01T00:00:00.000Z');
      expect(json[r'$int'], 100);
      expect(json[r'$double'], 2.5);
      expect(json[r'$string'], 'required');
      expect(json[r'$bool'], false);
      expect(json[r'$dateTime'], '2023-12-31T00:00:00.000Z');
    });

    test("some non existing key checker", () {
      final json = data.toJson();
      expect(json['nonExistingKey'], null);
      expect(json[r'$nonExistingKey'], null);
    });

    test("try to extra keys with requiared keys", () {
      final raw = {
        'nullableInt': 42,
        'nullableDouble': 3.14,
        'nullableString': 'test',
        'nullableBool': true,
        'nullableDateTime': '2023-01-01T00:00:00.000Z',
        r'$int': 100,
        r'$double': 2.5,
        r'$string': 'required',
        r'$bool': false,
        r'$dateTime': '2023-12-31T00:00:00.000Z',
        'extraKey': 'extra',
        'extraKey2': 'extra2',
        r'int': 100,
        r'double': 2.5,
        r'string': 'required',
        r'bool': false,
      };

      final data = BasicDataType.fromJson(raw);
      expect(data.toJson(), isA<Map<String, dynamic>>());
    });

    test("Inefficient json pass should false or occuer errro ", () {
      final raw = {'nullableInt': 42, 'nullableDouble': 3.14};

      expect(() => BasicDataType.fromJson(raw), throwsA(isA<TypeError>()));
    });
  });

  group('ListDataType', () {
    test('should serialize and deserialize lists correctly', () {
      final data = ListDataType.fromJson({
        'nullableListInt': [1, 2, 3],
        'nullableListDouble': [1.1, 2.2, 3.3],
        'nullableListString': ['a', 'b', 'c'],
        'nullableListBool': [true, false],
        'nullableListDateTime': ['2023-01-01T00:00:00.000Z', '2023-12-31T00:00:00.000Z'],
      });

      final json = data.toJson();
      expect(json['nullableListInt'], [1, 2, 3]);
      expect(json['nullableListDouble'], [1.1, 2.2, 3.3]);
      expect(json['nullableListString'], ['a', 'b', 'c']);
      expect(json['nullableListBool'], [true, false]);
      expect(json['nullableListDateTime'], ['2023-01-01T00:00:00.000Z', '2023-12-31T00:00:00.000Z']);
    });
  });

  group('MapKeyAsStringDataType', () {
    test('should serialize and deserialize string maps correctly', () {
      final data = MapKeyAsStringDataType.fromJson({
        'nullableMapInt': {'a': 1, 'b': 2},
        'nullableMapDouble': {'x': 1.1, 'y': 2.2},
        'nullableMapString': {'key1': 'value1', 'key2': 'value2'},
        'nullableMapBool': {'t': true, 'f': false},
        'nullableMapDateTime': {'date1': '2023-01-01T00:00:00.000Z', 'date2': '2023-12-31T00:00:00.000Z'},
      });

      final json = data.toJson();
      expect(json['nullableMapInt'], {'a': 1, 'b': 2});
      expect(json['nullableMapDouble'], {'x': 1.1, 'y': 2.2});
      expect(json['nullableMapString'], {'key1': 'value1', 'key2': 'value2'});
      expect(json['nullableMapBool'], {'t': true, 'f': false});
      expect(json['nullableMapDateTime'],
          {'date1': '2023-01-01T00:00:00.000Z', 'date2': '2023-12-31T00:00:00.000Z'});
    });
  });
}
