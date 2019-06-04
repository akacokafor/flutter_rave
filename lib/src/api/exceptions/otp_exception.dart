import 'package:dio/dio.dart';

class NeedsOtpException {
  final DioError e;
  NeedsOtpException(this.e);
}
