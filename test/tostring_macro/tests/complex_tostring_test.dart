import 'package:test/test.dart';
import 'package:model_suite/src/macros/tostring.dart';

@ToStringMacro()
class ComplexPerson<T> {
  final String name;
  final int age;
  final T data;
  final List<String>? hobbies;
  final Address address;

  const ComplexPerson(
    this.name,
    this.age,
    this.data,
    this.hobbies,
    this.address,
  );
}

@ToStringMacro()
class Address {
  final String street;
  final String? city;
  final int zipCode;

  const Address(this.street, this.city, this.zipCode);
}

@ToStringMacro()
class Employee extends ComplexPerson<Map<String, dynamic>> {
  final double salary;
  final Department department;

  const Employee(
    super.name,
    super.age,
    super.data,
    super.hobbies,
    super.address,
    this.salary,
    this.department,
  );
}

@ToStringMacro()
class Department {
  final String name;
  Employee? manager;

  Department(this.name, this.manager);
}

void main() {
  group('Complex ToString Tests', () {
    test('Complex person with generic type and nullable fields', () {
      final address = Address('123 Main St', 'Springfield', 12345);
      final person = ComplexPerson<int>(
        'John Doe',
        30,
        42,
        ['reading', 'coding'],
        address,
      );

      expect(
        person.ToStringMacro(),
        'ComplexPerson(name: John Doe, age: 30, data: 42, '
        'hobbies: [reading, coding], '
        'address: Address(street: 123 Main St, city: Springfield, zipCode: 12345))',
      );
    });

    test('Employee with inherited fields and nested objects', () {
      final address = Address('456 Work Ave', null, 67890);
      final department = Department('Engineering', null);
      final employee = Employee(
        'Jane Smith',
        35,
        {'role': 'developer', 'level': 'senior'},
        null,
        address,
        75000.0,
        department,
      );

      expect(
        employee.ToStringMacro(),
        'Employee(name: Jane Smith, age: 35, '
        'data: {role: developer, level: senior}, hobbies: null, '
        'address: Address(street: 456 Work Ave, city: null, zipCode: 67890), '
        'salary: 75000.0, '
        'department: Department(name: Engineering, manager: null))',
      );
    });

    test('Circular reference handling', () {
      final address = Address('789 Boss St', 'Managerville', 11111);
      final department = Department('Executive', null);
      final manager = Employee(
        'Boss Person',
        45,
        {'role': 'manager', 'level': 'executive'},
        ['golf', 'meetings'],
        address,
        100000.0,
        department,
      );

      department.manager = manager; // Create circular reference

      expect(
        department.ToStringMacro(),
        matches(RegExp(r'Department\(name: Executive, manager: Employee\(.*\)\)')),
      );
    });
  });
}
