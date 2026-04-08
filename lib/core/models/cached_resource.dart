import 'data_origin.dart';

class CachedResource<T> {
  const CachedResource({
    required this.data,
    required this.fetchedAt,
    required this.origin,
  });

  final T data;
  final DateTime fetchedAt;
  final DataOrigin origin;

  bool get isFromCache => origin == DataOrigin.cache;
}
