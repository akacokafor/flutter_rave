import 'package:equatable/equatable.dart';

class ApiConfig extends Equatable {
  static ApiConfig get instance => ApiConfig._();

  final String baseUrl;
  final String raveEndpoint;
  final String ravePublicKey;
  final String paystackEndPoint;
  final String paystackPublicKey;
  final String defaultCardProvider;

  String raveEncryptionKey;

  ApiConfig._({
    this.baseUrl,
    this.paystackEndPoint,
    this.raveEndpoint,
    this.paystackPublicKey,
    this.ravePublicKey,
    this.raveEncryptionKey,
    this.defaultCardProvider,
  }) : super([
          baseUrl,
          paystackPublicKey,
          ravePublicKey,
          raveEndpoint,
          raveEncryptionKey,
          defaultCardProvider,
          paystackEndPoint,
        ]);

  factory ApiConfig(
    String baseUrl, {
    String raveEndpoint,
    String ravePublicKey,
    String raveEncryptionKey,
    String paystackEndPoint,
    String paystackPublicKey,
    String defaultProvider,
    bool force: false,
  }) {
    return ApiConfig._(
      baseUrl: baseUrl,
      raveEndpoint: raveEndpoint,
      ravePublicKey: ravePublicKey,
      raveEncryptionKey: raveEncryptionKey,
      paystackEndPoint: paystackEndPoint,
      paystackPublicKey: paystackPublicKey,
      defaultCardProvider: defaultProvider,
    );
  }

  factory ApiConfig.make(
    String baseUrl, {
    String raveEndpoint,
    String ravePublicKey,
    String raveEncryptionKey,
    String paystackEndPoint,
    String paystackPublicKey,
    String defaultProvider,
  }) {
    return ApiConfig(
      baseUrl,
      raveEndpoint: raveEndpoint,
      ravePublicKey: ravePublicKey,
      raveEncryptionKey: raveEncryptionKey,
      paystackEndPoint: paystackEndPoint,
      paystackPublicKey: paystackPublicKey,
      defaultProvider: defaultProvider,
    );
  }
}
