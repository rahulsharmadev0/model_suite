import 'tests/empty_class_test.dart' as empty_class_test;
import 'tests/empty_subclass_of_named_multi_field_class_test.dart'
    as empty_subclass_of_named_multi_field_class_test;
import 'tests/empty_subclass_of_named_single_field_class_test.dart'
    as empty_subclass_of_named_single_field_class_test;
import 'tests/empty_subclass_of_nullable_named_single_field_class_test.dart'
    as empty_subclass_of_nullable_named_single_field_class_test;
import 'tests/empty_subclass_of_nullable_optional_positional_single_field_class_test.dart'
    as empty_subclass_of_nullable_optional_positional_single_field_class_test;
import 'tests/empty_subclass_of_nullable_positional_single_field_class_test.dart'
    as empty_subclass_of_nullable_positional_single_field_class_test;
import 'tests/empty_subclass_of_optional_positional_single_field_class_test.dart'
    as empty_subclass_of_optional_positional_single_field_class_test;
import 'tests/empty_subclass_of_positional_multi_field_class_test.dart'
    as empty_subclass_of_positional_multi_field_class_test;
import 'tests/empty_subclass_of_positional_single_field_class_test.dart'
    as empty_subclass_of_positional_single_field_class_test;
import 'tests/generic_nullable_test.dart' as generic_nullable_test;
import 'tests/generic_single_field_class_test.dart' as generic_single_field_class_test;
import 'tests/generic_test.dart' as generic_test;
import 'tests/mix_non_generic_test.dart' as mix_non_generic_test;
import 'tests/nullable_single_field_class_test.dart' as nullable_single_field_class_test;
import 'tests/single_field_class_test.dart' as single_field_class_test;
import 'tests/single_field_nested_subclass_of_positional_single_field_class_test.dart'
    as single_field_nested_subclass_of_positional_single_field_class_test;
import 'tests/single_field_subclass_of_positional_single_field_class_test.dart'
    as single_field_subclass_of_positional_single_field_class_test;
import 'tests/static_field_class_test.dart' as static_field_class_test;

void main() {
  mix_non_generic_test.main();
  generic_test.main();
  generic_nullable_test.main();
  empty_class_test.main();
  empty_subclass_of_named_multi_field_class_test.main();
  empty_subclass_of_named_single_field_class_test.main();
  empty_subclass_of_nullable_named_single_field_class_test.main();
  empty_subclass_of_nullable_optional_positional_single_field_class_test.main();
  empty_subclass_of_nullable_positional_single_field_class_test.main();
  empty_subclass_of_optional_positional_single_field_class_test.main();
  empty_subclass_of_positional_multi_field_class_test.main();
  empty_subclass_of_positional_single_field_class_test.main();
  generic_single_field_class_test.main();
  nullable_single_field_class_test.main();
  single_field_class_test.main();
  single_field_nested_subclass_of_positional_single_field_class_test.main();
  single_field_subclass_of_positional_single_field_class_test.main();
  static_field_class_test.main();
}
