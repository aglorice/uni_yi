import 'package:dio/dio.dart';

class SessionAwareHttpClient {
  SessionAwareHttpClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, String>? headers,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      options: Options(headers: headers),
    );
  }
}
