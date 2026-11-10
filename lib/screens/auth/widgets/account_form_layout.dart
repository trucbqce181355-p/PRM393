import 'package:flutter/material.dart';

class AccountFormLayout extends StatelessWidget {
  const AccountFormLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  static const linkColor = Color(0xFF1684FF);
  static InputDecoration input(String label) => InputDecoration(
    hintText: label,
    hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 18),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFF555555)),
    ),
  );
  static ButtonStyle get buttonStyle => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF191919),
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFF777777),
    minimumSize: const Size(double.infinity, 58),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: Colors.black87,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
