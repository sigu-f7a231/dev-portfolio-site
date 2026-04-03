// Iterable<MapEntry<K, V>> に index を付与する拡張
extension MapIndex<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<T> mapIndexed<T>(T Function(MapEntry<K, V> entry, int index) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}