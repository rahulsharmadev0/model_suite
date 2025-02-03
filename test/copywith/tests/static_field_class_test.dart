import 'package:model_suite/model.dart';

@CopyWithModel()
class StaticFieldClass {
  const StaticFieldClass();
  static const String field = 'field';
}

void main() {
  /// The `StaticFieldClass` class is considered empty even though it has a static field, so the `copyWith` method should not generate any code.
}
