import 'package:equatable/equatable.dart';
import 'user.dart';

class AuthResult extends Equatable {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? message;
  final bool isSuccess;

  const AuthResult({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.message,
    required this.isSuccess,
  });

  factory AuthResult.success({
    required User user,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      isSuccess: true,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      message: message,
      isSuccess: false,
    );
  }

  @override
  List<Object?> get props => [
        user,
        accessToken,
        refreshToken,
        message,
        isSuccess,
      ];
}