import 'package:test/test.dart';
import 'complex.dart';

void main() {
  group('Table Equality Tests', () {
    test('identical tables should be equal', () {
      final table1 = Table();
      final table2 = Table();
      expect(table1, equals(table2));
      expect(table1.hashCode, equals(table2.hashCode));
    });

    test('table should not be equal to null', () {
      final table = Table();
      expect(table, isNot(equals(null)));
    });

    test('table should not be equal to different type', () {
      final table = Table();
      final human = Human();
      expect(table, isNot(equals(human)));
    });
  });

  group('Human Equality Tests', () {
    test('identical humans should be equal', () {
      final human1 = Human();
      final human2 = Human();
      expect(human1, equals(human2));
      expect(human1.hashCode, equals(human2.hashCode));
    });

    test('same human reference should be equal', () {
      final human = Human();
      expect(human, equals(human));
    });

    test('human fields should match', () {
      final human = Human();
      expect(human.legs, equals(2));
      expect(human.arms, equals(2));
      expect(human.eyes, equals(2));
      expect(human.nose, equals(1));
      expect(human.mouth, equals(1));
    });
  });

  group('Child Equality Tests', () {
    test('identical children should be equal', () {
      final child1 = Child(name: 'Alice', age: 10);
      final child2 = Child(name: 'Alice', age: 10);
      expect(child1, equals(child2));
      expect(child1.hashCode, equals(child2.hashCode));
    });

    test('children with different names should not be equal', () {
      final child1 = Child(name: 'Alice', age: 10);
      final child2 = Child(name: 'Bob', age: 10);
      expect(child1, isNot(equals(child2)));
    });

    test('children with different ages should not be equal', () {
      final child1 = Child(name: 'Alice', age: 10);
      final child2 = Child(name: 'Alice', age: 11);
      expect(child1, isNot(equals(child2)));
    });

    test('children should inherit human equality', () {
      final child1 = Child(name: 'Alice', age: 10);
      final child2 = Child(name: 'Alice', age: 10);
      expect(child1.legs, equals(child2.legs));
      expect(child1.arms, equals(child2.arms));
      expect(child1.eyes, equals(child2.eyes));
    });

    group('Friend List Tests', () {
      test('empty friend lists should be equal', () {
        final child1 = Child(name: 'Alice', age: 10);
        final child2 = Child(name: 'Alice', age: 10);
        expect(child1.friends, equals(child2.friends));
      });

      test('different friend lists should not be equal', () {
        final child1 = Child(name: 'Alice', age: 10);
        final child2 = Child(name: 'Alice', age: 10);
        child1.friends.add(Child(name: 'Bob', age: 10));
        expect(child1, isNot(equals(child2)));
      });

      test('same friend lists should be equal', () {
        final child1 = Child(name: 'Alice', age: 10);
        final child2 = Child(name: 'Alice', age: 10);
        final friend = Child(name: 'Bob', age: 10);

        child1.friends.add(friend);
        child2.friends.add(friend);
        expect(child1, equals(child2));
      });

      test('equivalent friend lists should be equal', () {
        final child1 = Child(name: 'Alice', age: 10);
        final child2 = Child(name: 'Alice', age: 10);

        child1.friends.add(Child(name: 'Bob', age: 10));
        child2.friends.add(Child(name: 'Bob', age: 10));
        expect(child1, equals(child2));
      });

      test('friend lists with different order should be equal', () {
        final child1 = Child(name: 'Alice', age: 10);
        final child2 = Child(name: 'Alice', age: 10);

        child1.friends.addAll([Child(name: 'Bob', age: 10), Child(name: 'Charlie', age: 11)]);

        child2.friends.addAll([Child(name: 'Charlie', age: 11), Child(name: 'Bob', age: 10)]);

        expect(child1, equals(child2));
      });
    });

    test('hash code should be consistent', () {
      final child = Child(name: 'Alice', age: 10);
      final initialHash = child.hashCode;

      child.friends.add(Child(name: 'Bob', age: 10));
      final hashWithFriend = child.hashCode;

      expect(initialHash, isNot(equals(hashWithFriend)));
      expect(child.hashCode, equals(hashWithFriend));
    });
  });
}
