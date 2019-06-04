import 'package:equatable/equatable.dart';

class AuthFailedException extends Equatable {
  final String message = "Authentication Failed";
}

class RegistrationFailedException extends Equatable {
  final String message = "User Registration Failed";
}
