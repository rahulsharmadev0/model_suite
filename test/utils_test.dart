import 'package:test/test.dart';

extension MapJsonParsing<K, V> on Map<K, V> {
  /// Extension method to safely parse nested JSON data.
  R? get<R, FT>(K key, [R? Function(FT value)? parser]) {
    final value = this[key];
    if (value == null) return null;

    return parser != null ? parser(value as FT) : value as R?;
  }
}

void main() {
  group('MapJsonParsing extension tests', () {
    test('Retrieve value without parser', () {
      final map = {'key1': 'value1', 'key2': 42};
      expect(map.get('key1'), 'value1');
      expect(map.get('key2'), 42);
      expect(map.get('key3'), null); // Nonexistent key
    });

    test('Retrieve value with parser', () {
      final map = {
        'nested': {'subKey': 'subValue'}
      };
      final result = map.get<String, Map<String, String>>(
        'nested',
        (nestedMap) => nestedMap['subKey'] ?? 'default',
      );
      expect(result, 'subValue');
    });

    test('Handle missing key gracefully', () {
      final map = {'key1': 'value1'};
      final result = map.get<String, Map<String, String>>(
        'missingKey',
        (nestedMap) => nestedMap['subKey'] ?? 'default',
      );
      expect(result, null);
    });

    test('Handle null value without parser', () {
      final map = {'key1': null};
      expect(map.get('key1'), null);
    });

    test('Handle null value with parser', () {
      final map = {'key1': null};
      final result = map.get<String, Map<String, String>>(
        'key1',
        (nestedMap) => nestedMap['subKey'] ?? 'default',
      );
      expect(result, null);
    });

    test('Nested map parsing with parser', () {
      final map = {
        'key1': {'nestedKey': 123}
      };
      final result = map.get<int, Map<String, int>>(
        'key1',
        (nestedMap) => nestedMap['nestedKey'] ?? 0,
      );
      expect(result, 123);
    });

    test('Parser returning default value when key is missing', () {
      final map = {
        'key1': {'nestedKey': 123}
      };
      final result = map.get<int, Map<String, int>>(
        'key1',
        (nestedMap) => nestedMap['missingKey'] ?? 0,
      );
      expect(result, 0);
    });

    test('Parser handling incorrect types gracefully', () {
      final map = {'key1': 'value1'};
      final result = map.get<int, String>(
        'key1',
        (value) {
          try {
            return int.parse(value);
          } catch (_) {
            return -1;
          }
        },
      );
      expect(result, -1);
    });
  });
}
