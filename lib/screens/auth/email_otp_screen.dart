import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/snackbar_helper.dart';
import '../../services/email_otp_service.dart';
import 'email_registration_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;

  const EmailOtpScreen({super.key, required this.email});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _cursorAnimController;
  late final Animation<double> _cursorOpacity;

  Timer? _countdownTimer;
  int _resendCountdown = 60;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Hiệu ứng con trỏ nhấp nháy cho ô đang chờ nhập
    _cursorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
    _cursorOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_cursorAnimController);

    // Bắt sự kiện nhập và luôn neo con trỏ ở ô kế tiếp
    _otpController.addListener(() {
      if (mounted) {
        if (_otpController.selection.baseOffset != _otpController.text.length) {
          _otpController.selection = TextSelection.collapsed(
            offset: _otpController.text.length,
          );
        }
        setState(() {});
      }
    });

    // Bắt đầu đếm ngược 60s gửi lại OTP
    _startCountdown();

    // Tự động kích hoạt bàn phím khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = EmailOtpService.resendAfter);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _cursorAnimController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onVerifyPressed() async {
    if (_isLoading) return;
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ 6 số OTP');
      return;
    }

    setState(() => _isLoading = true);
    bool isValid;
    try {
      isValid = await EmailOtpService.verifyOtp(otp);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      final message = error is StateError
          ? error.message
          : 'Không thể xác minh OTP.';
      SnackbarHelper.showError(context, message);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (isValid) {
      SnackbarHelper.showSuccess(context, 'Xác thực OTP thành công!');
      _focusNode.unfocus();
      _countdownTimer?.cancel();
      _cursorAnimController.stop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const EmailRegistrationScreen(),
        ),
      );
    } else {
      setState(() {
        _hasError = true;
      });
      _otpController.clear();
      _focusNode.requestFocus();
      SnackbarHelper.showError(
        context,
        'Mã OTP không chính xác. Vui lòng kiểm tra lại email hoặc nhấn Gửi lại OTP.',
      );
    }
  }

  void _onResendOtpPressed() async {
    if (_isLoading || _resendCountdown > 0) return;

    setState(() => _isLoading = true);
    try {
      await EmailOtpService.sendOtp(widget.email);
      if (!mounted) return;
      _otpController.clear();
      _focusNode.requestFocus();
      _startCountdown();
      SnackbarHelper.showSuccess(
        context,
        'Đã gửi lại mã OTP mới tới email của bạn. Vui lòng kiểm tra hộp thư!',
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Lỗi gửi lại mã OTP: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSingleSquareBox({
    required int index,
    required String text,
    required bool hasFocus,
    required double boxSize,
  }) {
    final isFilled = index < text.length;
    final isCurrent = index == text.length && hasFocus;
    final char = isFilled ? text[index] : '';

    Color borderColor;
    Color backgroundColor;
    double borderWidth;
    List<BoxShadow> shadows = [];

    // Quy tắc xác định trạng thái màu sắc và viền cho từng ô vuông
    if (_hasError) {
      borderColor = Colors.red.shade400;
      backgroundColor = const Color(0xFFFEF2F2); // red-50
      borderWidth = 1.6;
    } else if (isCurrent) {
      borderColor = Colors.green;
      backgroundColor = const Color(0xFFF0FDF4); // green-50
      borderWidth = 2.2;
      shadows = [
        BoxShadow(
          color: Colors.green.withValues(alpha: 0.22),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isFilled) {
      borderColor = Colors.green.shade600;
      backgroundColor = Colors.white;
      borderWidth = 1.8;
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      borderColor = Colors.grey.shade300;
      backgroundColor = const Color(0xFFF8FAFC); // slate-50
      borderWidth = 1.2;
    }

    Widget content;
    if (isFilled) {
      // Ô đã nhập: hiển thị số rõ nét, đậm nét
      content = Text(
        char,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      );
    } else if (isCurrent) {
      // Ô đang chờ nhập: hiển thị con trỏ xanh nhấp nháy
      content = FadeTransition(
        opacity: _cursorOpacity,
        child: Container(
          width: 2.2,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
    } else {
      // Ô chưa nhập: hiển thị chấm tròn nhỏ biểu thị vị trí chờ
      content = Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: boxSize,
      height: boxSize, // Đảm bảo chiều cao = chiều rộng (Ô vuông 1:1)
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      alignment: Alignment.center,
      child: content,
    );
  }

  Widget _buildOtpBoxes() {
    final text = _otpController.text;
    final hasFocus = _focusNode.hasFocus;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Quy tắc khoảng cách đồng nhất và kích thước ô vuông chuẩn tỉ lệ 1:1
        const double gap = 10.0;
        const int count = 6;
        final double calculatedSize =
            (constraints.maxWidth - ((count - 1) * gap)) / count;
        final double boxSize = calculatedSize.clamp(40.0, 50.0);

        List<Widget> boxList = [];
        for (int i = 0; i < count; i++) {
          if (i > 0) {
            boxList.add(const SizedBox(width: gap));
          }
          boxList.add(
            _buildSingleSquareBox(
              index: i,
              text: text,
              hasFocus: hasFocus,
              boxSize: boxSize,
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
            _otpController.selection = TextSelection.collapsed(
              offset: _otpController.text.length,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 6 Ô VUÔNG TÁCH ĐỀU NHAU THEO QUY TẮC
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: boxList,
              ),

              // TextField ẩn bên dưới để nhận phím nhập/xóa/dán từ bàn phím một cách mượt mà
              Positioned.fill(
                child: Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enableInteractiveSelection: false,
                    showCursor: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      if (_hasError) {
                        setState(() => _hasError = false);
                      }
                      // Tự động kích hoạt kiểm tra khi đã nhập đủ 6 số
                      if (val.length == 6) {
                        _onVerifyPressed();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Xác thực OTP',
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
                        'Xác thực mã OTP',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chúng tôi đã gửi mã gồm 6 số tới email:\n${widget.email}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 6 Ô VUÔNG NHẬP MÃ OTP
                      _buildOtpBoxes(),
                      const SizedBox(height: 20),

                      // Hộp lưu ý kiểm tra email
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Vui lòng kiểm tra hộp thư đến (hoặc mục Thư rác/Spam) của email trên để nhập đúng mã OTP.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Xác nhận OTP
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onVerifyPressed,
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
                                  'Xác nhận OTP',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nút Gửi lại mã OTP có đếm ngược
                      Center(
                        child: TextButton.icon(
                          onPressed: (_isLoading || _resendCountdown > 0)
                              ? null
                              : _onResendOtpPressed,
                          icon: Icon(
                            _resendCountdown > 0
                                ? Icons.timer_outlined
                                : Icons.refresh,
                            size: 18,
                            color: _resendCountdown > 0
                                ? Colors.grey
                                : Colors.green,
                          ),
                          label: Text(
                            _resendCountdown > 0
                                ? 'Gửi lại mã OTP sau ${_resendCountdown}s'
                                : 'Chưa nhận được mã? Gửi lại OTP',
                            style: TextStyle(
                              color: _resendCountdown > 0
                                  ? Colors.grey
                                  : Colors.green,
                              fontSize: 14,
                              fontWeight: _resendCountdown > 0
                                  ? FontWeight.normal
                                  : FontWeight.w600,
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
