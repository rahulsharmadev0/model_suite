import 'package:model_suite/src/macros/equality.dart';

@EqualityMacro()
class Human {
  final int legs = 2;
  final int arms = 2;
  final int eyes = 2;
  final int nose = 1;
  final int mouth = 1;
}

@EqualityMacro()
class Child extends Human {
  final String name;
  final int age;
  List<Child> friends = [];
  Child({required this.name, required this.age});
}

@EqualityMacro()
class Table {}
