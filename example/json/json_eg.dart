class A {
  final int a;
  final A? $a;
  final int? b;
  final int d;
  final int c = 0;

  const A(this.a, this.$a, {this.b, this.d = 0});

  A.fromJson(Map<String, dynamic> json)
      : a = json['a'] as int,
        $a = json.get('\$a', A.fromJson),
        b = json['b'] as int?,
        d = json['d'] as int;

  Map<String, dynamic> toJson() => {
        'a': a,
        '\$a': $a?.toJson(),
        'b': b,
        'd': d,
        'c': c,
      };
}

extension dynamicToMap on dynamic {
  Map<String, dynamic> get toMap {
    return Map<String, dynamic>.from(this as Map);
  }
}

extension MapJsonParsing<K, V> on Map<K, V> {
  /// Extension method to safely parse nested JSON data.
  R? get<R, FT>(K key, [R? Function(FT value)? parser]) {
    final value = this[key];
    if (value == null) return null;

    return parser != null ? parser(value as FT) : value as R?;
  }
}
