part of '../equality.dart';

/// Implements the Jenkins hash function algorithm for generating hash codes
///
/// This implementation:
/// - Handles null values
/// - Provides consistent hashing for collections (List, Set, Map)
/// - Ensures hash codes are consistent with equality
///
/// [fields] - The collection of fields to generate a hash code for
/// Returns a 32-bit integer hash code
@internal
int jenkinsHash(Iterable<Object?>? fields) {
  return _finish(fields == null ? 0 : fields.fold(0, _combine));
}

/// Internal helper function to combine hash values in the Jenkins algorithm
///
/// [hash] - The current hash value
/// [object] - The object to combine into the hash
/// Returns the combined hash value
int _combine(int hash, Object? object) {
  if (object is Map) {
    object.keys.sorted((Object? a, Object? b) => a.hashCode - b.hashCode).forEach((Object? key) {
      hash = hash ^ _combine(hash, [key, (object! as Map)[key]]);
    });
    return hash;
  }
  if (object is Set) {
    object = object.sorted((Object? a, Object? b) => a.hashCode - b.hashCode);
  }
  if (object is Iterable) {
    for (final value in object) {
      hash = hash ^ _combine(hash, value);
    }
    return hash ^ object.length;
  }

  hash = 0x1fffffff & (hash + object.hashCode);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

/// Finalizes the Jenkins hash computation
///
/// Applies final mixing steps to improve the distribution of hash values
/// [hash] - The hash value to finalize
/// Returns the finalized hash value
int _finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}
