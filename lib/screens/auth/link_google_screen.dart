import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/auth_repository.dart';
import '../../utils/snackbar_helper.dart';
import 'auth_gate.dart';

class LinkGoogleScreen extends StatefulWidget {
  const LinkGoogleScreen({super.key});
  @override
  State<LinkGoogleScreen> createState() => _LinkGoogleScreenState();
}

class _LinkGoogleScreenState extends State<LinkGoogleScreen> {
  final _password = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_loading || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthRepository.linkExistingGoogleAccount(_password.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          error is StateError ? error.message : 'Không thể liên kết tài khoản.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Liên kết tài khoản Google',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Email ${Supabase.instance.client.auth.currentUser?.email ?? ''} đã có tài khoản Fruitopia. Nhập mật khẩu cũ một lần để giữ hồ sơ và lịch sử đơn hàng.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: true,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu tài khoản cũ',
                ),
                onSubmitted: (_) => _link(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _link,
                child: Text(
                  _loading ? 'Đang xác minh...' : 'Xác minh và liên kết',
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        try {
                          await AuthRepository.signOut();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthGate()),
                            (_) => false,
                          );
                        } catch (error) {
                          if (context.mounted) {
                            SnackbarHelper.showError(
                              context,
                              error is StateError
                                  ? error.message
                                  : 'Không thể đăng xuất.',
                            );
                          }
                        }
                      },
                child: const Text('Quay lại đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
