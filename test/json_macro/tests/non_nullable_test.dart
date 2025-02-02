import 'package:model_suite/src/macros/json.dart';
import 'package:model_suite/model.dart';

@JsonModel()
class BasicDataType {
  final int nullableInt;
  final double nullableDouble;
  final String nullableString;
  final bool nullableBool;
  final DateTime nullableDateTime;
  final int $int;
  final double $double;
  final String $string;
  final bool $bool;
  final DateTime $dateTime;
}

@JsonModel()
class ListDataType {
  final List<int> nullableListInt;
  final List<double> nullableListDouble;
  final List<String> nullableListString;
  final List<bool> nullableListBool;
  final List<DateTime> nullableListDateTime;
}

@JsonModel()
class SetDataType {
  final Set<int> nullableSetInt;
  final Set<double> nullableSetDouble;
  final Set<String> nullableSetString;
  final Set<bool> nullableSetBool;
  final Set<DateTime> nullableSetDateTime;
}

@JsonModel()
class MapKeyAsStringDataType {
  final Map<String, int> nullableMapInt;
  final Map<String, double> nullableMapDouble;
  final Map<String, String> nullableMapString;
  final Map<String, bool> nullableMapBool;
  final Map<String, DateTime> nullableMapDateTime;
}
