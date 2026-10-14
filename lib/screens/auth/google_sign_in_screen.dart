import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../admin/admin_dashboard_screen.dart';
import '../user/user_home_screen.dart';
import 'link_google_form.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});
  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _navigating = false;

  void _returnToLogin() {
    AuthService.cancelGoogleSignIn();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập Google'),
        automaticallyImplyLeading: false,
      ),
      body: ValueListenableBuilder<GoogleSignInStatus>(
        valueListenable: AuthService.googleStatus,
        builder: (context, status, child) {
          if (status == GoogleSignInStatus.success &&
              AuthService.hasCompletedProfile &&
              !_navigating) {
            _navigating = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => AuthService.role == 'admin'
                      ? const AdminDashboardScreen()
                      : const UserHomeScreen(),
                ),
                (route) => false,
              );
            });
          }
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (AuthService.googleLinkRequired)
                      LinkGoogleForm(
                        busy: status == GoogleSignInStatus.verifying,
                      )
                    else if (status == GoogleSignInStatus.success) ...[
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text('Đăng nhập Google thành công!'),
                      Text(AuthService.userEmail ?? ''),
                    ] else if (status == GoogleSignInStatus.error) ...[
                      Text(
                        AuthService.googleError ??
                            'Không thể đăng nhập Google.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: AuthService.retryGoogleSignIn,
                        child: const Text('Thử lại'),
                      ),
                    ] else ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        status == GoogleSignInStatus.verifying
                            ? 'Đang xác minh đăng nhập Google...'
                            : 'Hoàn tất đăng nhập trên trình duyệt rồi quay lại ứng dụng.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (status != GoogleSignInStatus.success) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _returnToLogin,
                        child: const Text('Quay lại đăng nhập'),
                      ),
                    ] else if (!AuthService.hasCompletedProfile) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          try {
                            await AuthService.logout();
                            if (context.mounted) Navigator.pop(context);
                          } catch (_) {
                            if (context.mounted) {
                              SnackbarHelper.showError(
                                context,
                                'Không thể đăng xuất. Vui lòng thử lại.',
                              );
                            }
                          }
                        },
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
