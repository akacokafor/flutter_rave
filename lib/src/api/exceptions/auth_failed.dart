import 'package:equatable/equatable.dart';

class AuthFailedException extends Equatable {
  final String message = "Authentication Failed";

  @override
  List<Object> get props => [message];
}

class RegistrationFailedException extends Equatable {
  final String message = "User Registration Failed";

  @override
  List<Object> get props => [message];
}
