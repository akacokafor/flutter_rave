import 'package:equatable/equatable.dart';

class ApiCallFailedException extends Equatable {
  final String message;

  ApiCallFailedException({this.message = "Api call failed"});

  @override
  List<Object> get props => [message];
}
