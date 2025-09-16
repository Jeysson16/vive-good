import '../../domain/entities/auth_result.dart';
import 'user_model.dart';

class AuthResultModel extends AuthResult {
  const AuthResultModel({
    super.user,
    super.accessToken,
    super.refreshToken,
    super.message,
    required super.isSuccess,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    return AuthResultModel(
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      message: json['message'],
      isSuccess: json['is_success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user != null ? (user as UserModel).toJson() : null,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'message': message,
      'is_success': isSuccess,
    };
  }

  factory AuthResultModel.success({
    required UserModel user,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthResultModel(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      isSuccess: true,
    );
  }

  factory AuthResultModel.failure(String message) {
    return AuthResultModel(
      message: message,
      isSuccess: false,
    );
  }
}