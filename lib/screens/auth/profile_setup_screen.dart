import '../../utils/snackbar_helper.dart';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'auth_gate.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String? email;
  final String? initialName;
  final String? initialPhone;
  final String? initialEmail;
  final bool authenticatedProfile;
  final bool needsPassword;
  final bool redirectToCheckout;

  const ProfileSetupScreen({
    super.key,
    this.email,
    this.initialName,
    this.initialPhone,
    this.initialEmail,
    this.authenticatedProfile = false,
    this.needsPassword = true,
    this.redirectToCheckout = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _phoneController.text = widget.initialPhone ?? '';

    // Lắng nghe để cập nhật thời gian thực tiêu chuẩn mật khẩu
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCompletePressed() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        phone.isEmpty ||
        (widget.needsPassword &&
            (password.isEmpty || confirmPassword.isEmpty))) {
      SnackbarHelper.showError(context, 'Vui lòng điền đầy đủ các thông tin');
      return;
    }

    final phoneRegex = RegExp(r'^0\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      SnackbarHelper.showError(
        context,
        'Số điện thoại không hợp lệ (Phải gồm 10 số và bắt đầu bằng 0)',
      );
      return;
    }

    // Kiểm tra quy tắc mật khẩu mạnh bắt buộc
    final validation = PasswordValidation.validate(password);
    if (widget.needsPassword && !validation.isValid) {
      SnackbarHelper.showError(
        context,
        validation.firstErrorMessage ??
            'Mật khẩu chưa đáp ứng tiêu chuẩn an toàn bắt buộc',
      );
      return;
    }

    if (widget.needsPassword && password != confirmPassword) {
      SnackbarHelper.showError(context, 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.authenticatedProfile) {
        await AuthService.completeAuthenticatedProfile(
          name: name,
          phone: phone,
          password: widget.needsPassword ? password : null,
        );
      } else {
        await AuthService.completeRegistration(
          name: name,
          phone: phone,
          password: password,
        );
      }

      if (!mounted) return;

      SnackbarHelper.showSuccess(
        context,
        'Đăng ký thành công! Chào mừng $name',
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AuthGate(redirectToCheckout: widget.redirectToCheckout),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        final message = e is StateError
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        SnackbarHelper.showError(context, 'Lỗi thiết lập tài khoản: $message');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordCriteriaBox(
    PasswordValidation validation,
    String password,
  ) {
    if (password.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Yêu cầu mật khẩu mạnh (bắt buộc):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCriteriaItem(false, 'Tối thiểu 12 ký tự'),
            _buildCriteriaItem(false, 'Chữ cái viết hoa (A-Z)'),
            _buildCriteriaItem(false, 'Chữ cái viết thường (a-z)'),
            _buildCriteriaItem(false, 'Chữ số (0-9)'),
            _buildCriteriaItem(
              false,
              'Ký tự đặc biệt (!, @, #, \$, %, ^, *...)',
            ),
            _buildCriteriaItem(
              true,
              'Không dùng tiếng Việt có dấu (đ, â, ớ...) và khoảng trắng đầu/cuối',
            ),
          ],
        ),
      );
    }

    final score = validation.strengthScore;
    final isFullValid = validation.isValid;

    String strengthText;
    Color strengthColor;
    if (isFullValid) {
      strengthText = 'Rất mạnh (Hợp lệ)';
      strengthColor = Colors.green;
    } else if (score >= 3) {
      strengthText = 'Khá tốt (Chưa đủ điều kiện)';
      strengthColor = Colors.blue;
    } else if (score >= 2) {
      strengthText = 'Trung bình';
      strengthColor = Colors.orange;
    } else {
      strengthText = 'Yếu';
      strengthColor = Colors.red;
    }

    final hasAccentViolation = !validation.hasNoAccents;
    final hasSpaceViolation = !validation.hasNoEdgeSpaces;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullValid
              ? Colors.green.shade300
              : (hasAccentViolation || hasSpaceViolation
                    ? Colors.red.shade300
                    : Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isFullValid ? Icons.check_circle : Icons.shield_outlined,
                    size: 16,
                    color: strengthColor,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Độ mạnh mật khẩu:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Thanh đánh giá 4 nấc độ mạnh
          Row(
            children: List.generate(4, (index) {
              final active = isFullValid || (index < score);
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: active ? strengthColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Danh sách kiểm tra chi tiết theo thời gian thực
          _buildCriteriaItem(
            validation.hasMinLength,
            'Độ dài tối thiểu 12 ký tự (${password.length}/12)',
          ),
          _buildCriteriaItem(validation.hasUppercase, 'Chữ cái viết hoa (A-Z)'),
          _buildCriteriaItem(
            validation.hasLowercase,
            'Chữ cái viết thường (a-z)',
          ),
          _buildCriteriaItem(validation.hasNumber, 'Chữ số (0-9)'),
          _buildCriteriaItem(
            validation.hasSpecial,
            'Ký tự đặc biệt (!, @, #, \$, %, ^, *...)',
          ),
          _buildCriteriaItem(
            validation.hasNoAccents && validation.hasNoEdgeSpaces,
            'Không dấu tiếng Việt (đ, â, ớ...) & không khoảng trắng đầu/cuối',
            isWarning: hasAccentViolation || hasSpaceViolation,
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(
    bool isMet,
    String label, {
    bool isWarning = false,
  }) {
    Color iconColor;
    IconData icon;
    Color textColor;

    if (isWarning) {
      iconColor = Colors.red;
      icon = Icons.cancel_outlined;
      textColor = Colors.red.shade700;
    } else if (isMet) {
      iconColor = Colors.green;
      icon = Icons.check_circle;
      textColor = Colors.green.shade800;
    } else {
      iconColor = Colors.grey.shade400;
      icon = Icons.radio_button_unchecked;
      textColor = Colors.grey.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: isMet || isWarning
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail =
        widget.email ?? widget.initialEmail ?? AuthService.pendingEmail ?? '';
    final currentPassword = _passwordController.text;
    final passwordValidation = PasswordValidation.validate(currentPassword);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Thiết lập tài khoản',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22.0,
                    vertical: 30.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Thiết lập hồ sơ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Điền thông tin cá nhân và mật khẩu để hoàn tất',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Email hiển thị
                      if (displayEmail.isNotEmpty) ...[
                        TextFormField(
                          initialValue: displayEmail,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Email đã xác thực',
                            prefixIcon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Họ và tên
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Số điện thoại
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: const Icon(Icons.phone_android),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (widget.needsPassword) ...[
                        // Mật khẩu
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        // Bảng tiêu chuẩn mật khẩu an toàn thời gian thực
                        _buildPasswordCriteriaBox(
                          passwordValidation,
                          currentPassword,
                        ),

                        // Xác nhận mật khẩu
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận lại mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        // Trạng thái đối chiếu xác nhận mật khẩu
                        if (_confirmPasswordController.text.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _passwordController.text ==
                                        _confirmPasswordController.text
                                    ? Icons.check_circle
                                    : Icons.cancel_outlined,
                                size: 15,
                                color:
                                    _passwordController.text ==
                                        _confirmPasswordController.text
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _passwordController.text ==
                                        _confirmPasswordController.text
                                    ? 'Mật khẩu xác nhận trùng khớp'
                                    : 'Mật khẩu xác nhận chưa khớp',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _passwordController.text ==
                                          _confirmPasswordController.text
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: 28),

                      // Nút Hoàn tất
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onCompletePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Hoàn tất đăng ký',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
