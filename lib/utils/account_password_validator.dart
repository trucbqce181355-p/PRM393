String? validateAccountPassword(String? value) {
  final password = value ?? '';
  if (password != password.trim()) {
    return 'Mật khẩu không có khoảng trắng đầu/cuối.';
  }
  if (password.length < 12 || password.length > 256) {
    return 'Mật khẩu cần từ 12 đến 256 ký tự.';
  }
  if (RegExp(r'[^\x20-\x7e]').hasMatch(password)) {
    return 'Mật khẩu không chứa ký tự có dấu.';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[a-z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password) ||
      !RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?`~]''')
          .hasMatch(password)) {
    return 'Cần chữ hoa, chữ thường, số và ký tự đặc biệt.';
  }
  return null;
}
