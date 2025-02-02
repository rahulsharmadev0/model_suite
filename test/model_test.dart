import 'package:model_suite/src/macros/copywith.dart';
import 'package:model_suite/src/macros/equality.dart';
import 'package:model_suite/src/macros/json.dart';
import 'package:model_suite/src/macros/tostring.dart';
import 'package:model_suite/src/model.dart';

@Model()
class Subject {
  final String id;
  final String name;
  final int chapters;
  Subject({
    required this.id,
    required this.name,
    required this.chapters,
  });
}

@Model()
class Student {
  final String name;
  final int age;
  final double gpa;
  final String standard;
  final Set<Subject> subjects;
  Student({
    required this.name,
    required this.age,
    required this.gpa,
    required this.standard,
    required this.subjects,
  });
}
