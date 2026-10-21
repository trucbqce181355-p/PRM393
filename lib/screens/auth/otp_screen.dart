import 'package:flutter/material.dart';

import 'email_otp_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => EmailOtpScreen(email: email);
}
