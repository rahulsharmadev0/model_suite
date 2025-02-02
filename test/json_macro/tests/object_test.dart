import 'package:model_suite/src/macros/json.dart';
import 'package:model_suite/src/model.dart';
import 'package:test/test.dart';

@JsonModel()
class A {
  final int? nullableInt;
  final double? nullableDouble;
}

@JsonModel()
class ObjectClass extends A {
  final String? nullableString;
  final bool? nullableBool;
}

@JsonModel()
class BasicDataType {
  final DateTime? nullableDateTime;
  final int $int;
  final double $double;
  final String $string;
  final bool $bool;
  final DateTime $dateTime;
  final ObjectClass $objectClass;
  final A $a;
}

void main() {
  group("BasicDataType Tests", () {
    test("should correctly serialize and deserialize JSON", () {
      var json = {
        'nullableDateTime': '2023-01-01T00:00:00.000Z',
        r'$int': 100,
        r'$double': 2.5,
        r'$string': 'required',
        r'$bool': false,
        r'$dateTime': '2023-12-31T00:00:00.000Z',
        r'$objectClass': {
          'nullableInt': 42,
          'nullableDouble': 3.14,
          'nullableString': 'test',
          'nullableBool': true,
        },
        r'$a': {
          'nullableInt': 42,
          'nullableDouble': 3.14,
        },
      };
      final data = BasicDataType.fromJson(json);

      expect(data.toJson(), json);
    });
  });
}
