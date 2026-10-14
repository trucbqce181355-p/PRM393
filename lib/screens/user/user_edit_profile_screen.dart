import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/mongodb_service.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../auth/login_screen.dart';

class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key});

  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController; // old/current password reference if needed
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  @override
  void initState() {
    super.initState();
    final customer = AuthService.currentUser;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _passwordController = TextEditingController(text: customer?.password ?? '');
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSavePressed() async {
    if (AuthService.isBackendSession) {
      SnackbarHelper.showError(context, 'Hồ sơ này cần được cập nhật qua máy chủ xác thực.');
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final customer = AuthService.currentUser;
        if (customer != null) {
          String finalPassword = _passwordController.text;
          
          if (_isChangingPassword) {
            finalPassword = _newPasswordController.text;
          }

          // Cập nhật local Hive
          await DataService.updateCustomerProfile(
            customer.id,
            _nameController.text.trim(),
            _phoneController.text.trim(),
            finalPassword,
          );
          
          // Cập nhật MongoDB
          try {
            var usersColl = MongoDBService.getCollection("users");
            await usersColl.updateOne(
              mongo.where.eq('email', customer.email),
              mongo.modify
                  .set('name', _nameController.text.trim())
                  .set('phone', _phoneController.text.trim())
                  .set('password', finalPassword)
            );
          } catch (e) {
            print("Lỗi sync MongoDB: $e");
          }
          
          // Cập nhật lại AuthService state
          await AuthService.saveProfile(
            _nameController.text.trim(), 
            customer.email
          );
          
          if (mounted) {
            SnackbarHelper.showSuccess(context, 'Cập nhật thông tin thành công!');
            
            if (_isChangingPassword) {
              // Văng ra trang đăng nhập
              AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } else {
              Navigator.pop(context, true);
            }
          }
        } else {
          if (mounted) SnackbarHelper.showError(context, 'Lỗi: Không tìm thấy thông tin tài khoản!');
        }
      } catch (e) {
        if (mounted) SnackbarHelper.showError(context, 'Lỗi cập nhật: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = AuthService.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: customer == null 
        ? const Center(child: Text('Không tìm thấy thông tin người dùng'))
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            customer.name.isNotEmpty ? customer.name.substring(0, 1).toUpperCase() : 'K',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Email (Không cho sửa)
                  TextFormField(
                    initialValue: customer.email,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Họ và Tên
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Số điện thoại
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (value.length < 10) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Nút bấm Đổi mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isChangingPassword = !_isChangingPassword;
                        });
                      },
                      icon: Icon(
                        _isChangingPassword ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.green,
                      ),
                      label: Text(
                        _isChangingPassword ? 'Hủy đổi mật khẩu' : 'Đổi mật khẩu',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  if (_isChangingPassword) ...[
                    const SizedBox(height: 10),
                    // Mật khẩu mới
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (!_isChangingPassword) return null;
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải từ 6 ký tự trở lên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Xác nhận mật khẩu mới
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận lại mật khẩu',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (!_isChangingPassword) return null;
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Mật khẩu xác nhận không khớp';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Lưu thay đổi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
