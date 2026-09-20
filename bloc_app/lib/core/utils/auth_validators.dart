import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart' as validator;

abstract final class AuthValidators {
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email.';
    if (!validator.isEmail(v)) return 'Please enter a valid email.';
    return null;
  }

  static String? password(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 6 || v.length > 20) {
      return 'Please enter a password from 6 to 20 characters.';
    }
    return null;
  }

    static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter username.';
    if (v.length < 2) return 'Please enter at least 2 characters for username.';
    if (v.length > 20) {
      return 'Please enter a username up to 20 characters long.';
    }
    return null;
  }

  /// Mật khẩu khi đăng ký, có thông báo lỗi chi tiết hơn login.
  static String? newPassword(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter password.';
    if (v.length < 6) return 'Please enter at least 6 characters for password.';
    if (v.length > 20) return 'Please enter a password up to 20 characters long.';
    return null;
  }

  /// Trả về validator so khớp với mật khẩu hiện tại.
  static String? Function(String?) confirmPassword(
    TextEditingController passwordController,
  ) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please enter your confirmation password.';
      }
      if (value != passwordController.text) {
        return 'The password does not match.';
      }
      return null;
    };
  }
}
