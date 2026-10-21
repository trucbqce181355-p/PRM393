import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class LinkGoogleForm extends StatefulWidget {
  const LinkGoogleForm({super.key, required this.busy});

  final bool busy;

  @override
  State<LinkGoogleForm> createState() => _LinkGoogleFormState();
}

class _LinkGoogleFormState extends State<LinkGoogleForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.busy || !_formKey.currentState!.validate()) return;
    await AuthService.linkExistingGoogleAccount(_passwordController.text);
    if (mounted &&
        AuthService.googleStatus.value == GoogleSignInStatus.success) {
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 420,
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link, size: 56, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Email Google này đã có tài khoản Fruitopia. Nhập mật khẩu tài khoản cũ một lần để liên kết và giữ lại dữ liệu của bạn.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            enabled: !widget.busy,
            obscureText: _obscurePassword,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Mật khẩu tài khoản cũ',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: widget.busy
                    ? null
                    : () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu.';
              }
              if (value.length > 256) return 'Mật khẩu không hợp lệ.';
              return null;
            },
          ),
          if (AuthService.googleError != null) ...[
            const SizedBox(height: 12),
            Text(
              AuthService.googleError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.busy ? null : _submit,
            child: widget.busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Liên kết Google'),
          ),
        ],
      ),
    ),
  );
}
