import 'package:model_suite/src/model.dart';

@ConstructorModel()
class Address {
  final String street;
  final String? city;
  final int? zipCode;
}

@ConstructorModel()
class Shop extends Address {
  final String? name;
}
