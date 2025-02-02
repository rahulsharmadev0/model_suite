import 'package:model_suite/src/model.dart';
import 'package:test/test.dart';
import 'package:model_suite/src/macros/tostring.dart';

@ToStringModel()
class Address {
  final String street;
  final String? city;
  final int zipCode;

  const Address(this.street, this.city, this.zipCode);
}

@ToStringModel()
class Department {
  final String name;
  Employee? manager;

  Department(this.name, this.manager);
}

@ToStringModel()
class Employee {
  final String name;
  final int age;
  final Address address;
  final Department department;

  Employee(this.name, this.age, this.address, this.department);
}

void main() {
  group('Complex ToString Tests', () {
    test('Address toString test', () {
      final address = const Address('123 Main St', 'Boston', 12345);
      expect(
        address.toString(),
        'Address(street: 123 Main St, city: Boston, zipCode: 12345)',
      );

      final addressNullCity = const Address('456 Oak St', null, 67890);
      expect(
        addressNullCity.toString(),
        'Address(street: 456 Oak St, city: null, zipCode: 67890)',
      );
    });

    test('Department toString test', () {
      final department = Department('Engineering', null);
      expect(
        department.toString(),
        'Department(name: Engineering, manager: null)',
      );
    });

    test('Employee with nested objects toString test', () {
      final address = const Address('789 Tech St', 'San Francisco', 94105);
      final department = Department('R&D', null);
      final employee = Employee('John Doe', 30, address, department);

      expect(
        employee.toString(),
        'Employee(name: John Doe, age: 30, '
        'address: Address(street: 789 Tech St, city: San Francisco, zipCode: 94105), '
        'department: Department(name: R&D, manager: null))',
      );
    });
  });
}
