String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  if (email.isEmpty) {
    return 'Vui lòng nhập email';
  }

  if (!emailPattern.hasMatch(email)) {
    return 'Email không hợp lệ';
  }

  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Vui lòng nhập mật khẩu';
  }

  return null;
}
