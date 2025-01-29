import 'tests/generic_nullable_test.dart' as generic_nullable_test;
import 'tests/generic_test.dart' as generic_test;
import 'tests/mix_non_generic_test.dart' as mix_non_generic_test;

void main() {
  mix_non_generic_test.main();
  generic_test.main();
  generic_nullable_test.main();
}
