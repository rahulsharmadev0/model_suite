import 'package:model_suite/model.dart';

@Model()
class Subject {
  final String id;
  final String name;
  final int chapters;
}

@Model()
class Student {
  final String name;
  final int age;
  final double gpa;
  final String standard;
  final Set<Subject> subjects;
}
