import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../user/user_home_screen.dart';

/// Bước 4: Điền hồ sơ cá nhân (Tên, Email)
/// Bước 5: Lưu trữ phiên đăng nhập (Token) xuống local
class ProfileSetupScreen extends StatefulWidget {
  final String? phone;
  final String? prefilledName;
  final String? prefilledEmail;
  final String authMethod;

  const ProfileSetupScreen({
    super.key,
    this.phone,
    this.prefilledName,
    this.prefilledEmail,
    this.authMethod = 'phone',
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledName != null) {
      _nameController.text = widget.prefilledName!;
    }
    if (widget.prefilledEmail != null) {
      _emailController.text = widget.prefilledEmail!;
    }
    if (widget.phone != null) {
      _phoneController.text = widget.phone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập họ và tên');
      return;
    }

    if (email.isEmpty) {
      SnackbarHelper.showError(context, 'Vui lòng nhập địa chỉ email');
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      SnackbarHelper.showError(context, 'Địa chỉ email không đúng định dạng');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi service: tạo user -> tạo Token -> lưu Token xuống local (StorageService)
      await AuthService.completeProfile(
        name: name,
        email: email,
        phone: phone.isNotEmpty ? phone : widget.phone,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      SnackbarHelper.showSuccess(
        context,
        'Thiết lập hồ sơ thành công! Đã lưu phiên đăng nhập.',
      );

      // Chuyển thẳng vào UserHomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      SnackbarHelper.showError(context, 'Lỗi thiết lập hồ sơ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thiết lập hồ sơ cá nhân',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 45,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Hoàn tất thông tin tài khoản',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Điền tên và email của bạn để lưu hồ sơ mua sắm',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              // 1. HỌ VÀ TÊN
              const Text(
                'Họ và tên *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Trần Gia Huy',
                  prefixIcon: const Icon(Icons.person, color: Colors.green),
                  filled: true,
                  fillColor: const Color(0xFFF7F9F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. EMAIL
              const Text(
                'Địa chỉ Email *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: huytg@gmail.com',
                  prefixIcon: const Icon(Icons.email, color: Colors.green),
                  filled: true,
                  fillColor: const Color(0xFFF7F9F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. SỐ ĐIỆN THOẠI (Read-only hoặc bổ sung)
              const Text(
                'Số điện thoại',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                readOnly: widget.phone != null && widget.phone!.isNotEmpty,
                decoration: InputDecoration(
                  hintText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone_android, color: Colors.green),
                  suffixIcon: widget.phone != null && widget.phone!.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF7F9F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // NÚT LƯU HỒ SƠ & BẮT ĐẦU TRẢI NGHIỆM
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Hoàn tất & Bắt đầu mua sắm',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
