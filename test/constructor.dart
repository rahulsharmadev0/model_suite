import 'package:model_suite/src/model.dart';
import 'package:test/test.dart';

@Model()
class Item {
  final String name;
  final double price;
  final String? description;
  final Map<String, String>? metadata;
}

@Model()
class Address {
  final String street;
  final String? city;
  final int? zipCode;
}

@Model()
class Shop extends Address {
  final String? name;
  final List<Item>? items;
  final Map<String, Item>? itemMap;
}
