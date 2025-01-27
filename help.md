1. json has own constructor.
2. may class have own constructor such as Named, default, factory constructor.
3. handling variables of super class. 

```dart
/// Extension method to safely parse nested JSON data.
extension MapJsonParsing<K, V> on Map<K, V> {
  /// Extension method to safely parse nested JSON data.
  R? get<R, FT>(K key, [R? Function(FT value)? parser]) {
    final value = this[key];
    if (value == null) return null;

    return parser != null ? parser(value as FT) : value as R?;
  }
}
```