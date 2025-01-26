import 'package:model_suite/src/model.dart';

@Model()
class A {
  int a;
  String b;
  Map<int, String> c;
  List<int> d;
  Set<int> e;
  Map<int, A> f;

  // A.fromJson(Map<String, dynamic> json)
  //     : a = json['a'] as int,
  //       b = json['b'] as String,
  //       c = json['c'] as Map<int, String>,
  //       d = (json['d'] as List).map((e) => e as int).toList(),
  //       e = (json['e'] as List).map((e) => e as int).toSet(),
  //       f = (json['f'] as Map).map((k, v) => MapEntry(k as int, A.fromJson(v as Map<String, dynamic>)));
}
