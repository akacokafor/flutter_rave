import 'package:dio/dio.dart';
import 'package:dio_flutter_transformer/dio_flutter_transformer.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_rave/src/config/api.dart';

class HttpService extends Equatable {
  static HttpService get instance => HttpService._(ApiConfig.instance);

  final ApiConfig config;

  Dio _dio;

  Dio get dio => _dio;

  HttpService._(this.config) : super([config]) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: 30000,
        receiveTimeout: 30000,
        responseType: ResponseType.json,
        headers: {"Accept": "application/json"},
      ),
    );

    _dio.transformer = FlutterTransformer();

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options) {
          return options;
        },
        onResponse: (Response response) {
          return response;
        },
      ),
    );
  }

  factory HttpService(ApiConfig apiConfig) {
    return HttpService._(apiConfig);
  }

  setCurrentUser(String authToken) {
    if (authToken == null || authToken.length <= 0) {
      throw "Auth Token cannot be empty";
    }
    _dio.options.headers["Authorization"] = "Bearer $authToken";
    return this;
  }

  removeCurrentUser() {
    final headers = _dio.options.headers;
    headers.remove("Authorization");
    _dio.options.headers = headers;
    return this;
  }
}
