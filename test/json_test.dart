import 'package:model_suite/src/macros/copywith.dart';
import 'package:model_suite/src/macros/equality.dart';
import 'package:model_suite/src/macros/json.dart';
import 'package:model_suite/src/macros/tostring.dart';
import 'package:model_suite/src/model.dart';

@Model()
class A {
  final int a;
  final String b;
  final Map<int, String>? c;
  final List<int>? d;
  final Set<DateTime>? e;
  final Map<int, A> f;
  final List<List<Map<String, int>>>? complex;
  final ObjectMixin? mixinObj;

  const A(this.a, this.b, this.c, this.d, this.e, this.f, {this.complex, this.mixinObj});
}

@Model()
class ObjectMixin {
  final int a;
  ObjectMixin(this.a);
}

@Model()
class ObjectMixinA {
  final int a;
  final int b;
  final int c;

  ObjectMixinA({required this.a, required this.b, required this.c});
}
