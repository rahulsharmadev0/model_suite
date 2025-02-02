import 'package:model_suite/src/model.dart';
import 'package:test/test.dart';

@Model()
class Address {
  final String street;
  final String? city;
  final int? zipCode;
}

@Model()
class Item {
  final String name;
  final double price;
}

@Model()
class Shop extends Address {
  final String? name;
  final List<Item>? items;
  final Map<String, Item>? itemMap;
}

void main() {
  group('Address Model Tests', () {
    test('constructor and getters', () {
      final address = const Address(street: '123 Main St', city: 'New York', zipCode: 10001);
      expect(address.street, '123 Main St');
      expect(address.city, 'New York');
      expect(address.zipCode, 10001);
    });

    test('toJson and fromJson', () {
      final address = const Address(street: '123 Main St', city: 'New York', zipCode: 10001);
      final json = address.toJson();
      final fromJson = Address.fromJson(json);
      expect(fromJson, address);
    });

    test('copyWith', () {
      final address = const Address(street: '123 Main St', city: 'New York', zipCode: 10001);
      final copied = address.copyWith(city: 'Boston');
      expect(copied.street, '123 Main St');
      expect(copied.city, 'Boston');
      expect(copied.zipCode, 10001);
    });

    test('toString', () {
      final address = const Address(street: '123 Main St', city: 'New York', zipCode: 10001);
      expect(address.toString(), contains('street: 123 Main St'));
    });
  });

  group('Item Model Tests', () {
    test('constructor and getters', () {
      final item = const Item(name: 'Book', price: 29.99);
      expect(item.name, 'Book');
      expect(item.price, 29.99);
    });

    test('toJson and fromJson', () {
      final item = const Item(name: 'Book', price: 29.99);
      final json = item.toJson();
      final fromJson = Item.fromJson(json);
      expect(fromJson, item);
    });

    test('copyWith', () {
      final item = const Item(name: 'Book', price: 29.99);
      final copied = item.copyWith(price: 39.99);
      expect(copied.name, 'Book');
      expect(copied.price, 39.99);
    });
  });

  group('Shop Model Tests', () {
    test('constructor and getters', () {
      final items = [const Item(name: 'Book', price: 29.99)];
      final itemMap = {'book': const Item(name: 'Book', price: 29.99)};
      final shop = Shop(
        street: '123 Main St',
        name: 'Bookstore',
        items: items,
        itemMap: itemMap,
      );

      expect(shop.street, '123 Main St');
      expect(shop.name, 'Bookstore');
      expect(shop.items, items);
      expect(shop.itemMap, itemMap);
    });

    test('toJson and fromJson', () {
      final shop = const Shop(
        street: '123 Main St',
        name: 'Bookstore',
        items: [Item(name: 'Book', price: 29.99)],
        itemMap: {'book': Item(name: 'Book', price: 29.99)},
      );
      final json = shop.toJson();
      final fromJson = Shop.fromJson(json);
      expect(fromJson, shop);
    });

    test('copyWith', () {
      final shop = const Shop(
        street: '123 Main St',
        name: 'Bookstore',
      );
      final copied = shop.copyWith(name: 'New Bookstore');
      expect(copied.street, '123 Main St');
      expect(copied.name, 'New Bookstore');
    });

    test('nullable fields', () {
      final shop = const Shop(street: '123 Main St');
      expect(shop.name, null);
      expect(shop.items, null);
      expect(shop.itemMap, null);
    });
  });
}
