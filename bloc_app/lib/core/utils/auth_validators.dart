import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart' as validator;

abstract final class AuthValidators {
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập email.';
    if (!validator.isEmail(v)) return 'Email chưa đúng định dạng.';
    return null;
  }

  static String? password(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 6 || v.length > 20) {
      return 'Mật khẩu cần từ 6 đến 20 ký tự.';
    }
    return null;
  }

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập tên hiển thị.';
    if (v.length < 2) return 'Tên hiển thị cần ít nhất 2 ký tự.';
    if (v.length > 20) {
      return 'Tên hiển thị tối đa 20 ký tự.';
    }
    return null;
  }

  /// Mật khẩu khi đăng ký, có thông báo lỗi chi tiết hơn login.
  static String? newPassword(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (v.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự.';
    if (v.length > 20) {
      return 'Mật khẩu tối đa 20 ký tự.';
    }
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
