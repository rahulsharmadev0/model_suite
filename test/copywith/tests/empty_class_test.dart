import 'package:model_suite/model.dart';

@CopyWithModel()
class EmptyClass {
  const EmptyClass();
}

void main() {
  /// The `EmptyClass` class is empty, so the `copyWith` method should not generate any code.
}
