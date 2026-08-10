
import 'package:equatable/equatable.dart';

abstract class Failures extends Equatable {
  const Failures({required this.message});

  final String message;

  @override
  List<Object> get props => [message];

  @override
  String toString() => '${runtimeType.toString()}: $message';
}

class ServerFailure extends Failures{
  const ServerFailure({required super.message});
}

class NetworkFailure extends Failures{
  const NetworkFailure({super.message = 'Please check your connection...'});
}
class AuthenticationFailure extends Failures{
  const AuthenticationFailure({required super.message});
}

class PermissionFailure extends Failures{
  const PermissionFailure({super.message = 'You do not have permission for the request.'});
}

class NotFoundFailure extends Failures{
  const NotFoundFailure({super.message = 'The data requested not found'});
}

class ConnectionFailure extends Failures{
  const ConnectionFailure({required super.message});
}

class UnknownFailure extends Failures{
  const UnknownFailure({super.message = 'An unknown error has occurred. Please try again later.'});
}




