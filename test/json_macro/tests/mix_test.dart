// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_string_interpolations, unnecessary_this

import 'dart:math';
import 'package:test/test.dart';
import 'package:macros_suite/data_model.dart';

@DataModel()
class SimpleClass {
  String name;
  int age;
  final String? $father;
  SimpleClass(this.name, this.age, {this.$father});
  void haveBirthday() => age++;
  bool isAdult() => age >= 18;
}

@DataModel()
class ComplexClass {
  String name;
  int age;
  List<String> hobbies;
  Set<String> skills;
  Map<String, int> scores;
  final String? $mother;
  ComplexClass(this.name, this.age, this.hobbies, this.skills, this.scores, {this.$mother});
  void haveBirthday() => age++;
  bool isAdult() => age >= 18;
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//      Simple Tests
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
void main() {
  group('Simple Tests', () {
    test('Json', () {
      var jsonObj = {'name': 'John', 'age': 25};
      SimpleClass person = SimpleClass.fromJson(jsonObj);
      expect(person.name, 'John');
      expect(person.isAdult(), isTrue);

      expect(person.age, 25); // Before birthday incerement
      person.haveBirthday();
      expect(person.age, 26); // After birthday increment
    });

    test('Equality', () {
      SimpleClass person1 = SimpleClass('John', 25);
      SimpleClass person2 = SimpleClass('John', 25);

      expect(person1, person2);
      expect(person1.copyWith(name: 'Rahul', age: 21), person2.copyWith(name: 'Rahul', age: 21));

      var j2 = person1.toJson();
      var j1 = person1.toJson();
      expect(j1, j2);
      for (var e in j1.entries) {
        expect(j2[e.key], e.value);
      }
    });

    test('Copywith', () {
      SimpleClass person = SimpleClass('John', 25);

      expect(person.copyWith(age: 30).age, 30);
      expect(person.copyWith(name: 'Ram').name, 'Ram');
      expect(person.copyWith($father: 'Ranu').$father, 'Ranu');
    });

    test('toString', () {
      SimpleClass person = SimpleClass('John', 25);
      expect(person.toString(), 'SimpleClass(name: John, age: 25, \$father: null, )');
    });
  });

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//      Complex Tests
//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  group('Complex Tests', () {
    test('Json', () {
      var jsonObj = {
        'name': 'Jane',
        'age': 30,
        'hobbies': ['reading', 'swimming'],
        'skills': {'coding', 'design'},
        'scores': {'math': 95, 'english': 88}
      };
      ComplexClass person = ComplexClass.fromJson(jsonObj);
      expect(person.name, 'Jane');
      expect(person.isAdult(), isTrue);

      expect(person.age, 30); // Before birthday increment
      person.haveBirthday();
      expect(person.age, 31); // After birthday increment
    });

    test('Equality', () {
      ComplexClass person1 = ComplexClass(
          'Jane', 30, ['reading', 'swimming'], {'coding', 'design'}, {'math': 95, 'english': 88});
      ComplexClass person2 = ComplexClass(
          'Jane', 30, ['reading', 'swimming'], {'coding', 'design'}, {'math': 95, 'english': 88});

      expect(person1, person2);
      expect(person1.copyWith(name: 'Alice', age: 28), person2.copyWith(name: 'Alice', age: 28));

      var j2 = person1.toJson();
      var j1 = person1.toJson();
      expect(j1, j2);
      for (var e in j1.entries) {
        expect(j2[e.key], e.value);
      }
    });

    test('Copywith', () {
      ComplexClass person = ComplexClass(
          'Jane', 30, ['reading', 'swimming'], {'coding', 'design'}, {'math': 95, 'english': 88});

      expect(person.copyWith(age: 35).age, 35);
      expect(person.copyWith(name: 'Alice').name, 'Alice');
      expect(person.copyWith($mother: 'Anna').$mother, 'Anna');
    });

    test('toString', () {
      ComplexClass person = ComplexClass(
          'Jane', 30, ['reading', 'swimming'], {'coding', 'design'}, {'math': 95, 'english': 88});
      expect(person.toString(),
          'ComplexClass(name: Jane, age: 30, hobbies: [reading, swimming], skills: {coding, design}, scores: {math: 95, english: 88}, \$mother: null, )');
    });
  });
}
