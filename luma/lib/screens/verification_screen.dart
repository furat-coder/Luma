import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_store.dart';

class VerificationScreen extends StatefulWidget {
  final String name;
  final String username;
  final String email;
  final String password;

  // Development code returned by the backend.
  final String verificationCode;

  final bool isAddingAccount;

  const VerificationScreen({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.verificationCode,
    this.isAddingAccount = false,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late final AnimationController _animationController;

  late String _currentVerificationCode;

  Timer? _timer;

  int _secondsRemaining = 60;

  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();

    _currentVerificationCode = widget.verificationCode;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animationController.forward();

    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    _animationController.dispose();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _secondsRemaining = 0;
        });

        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });
  }

  String get _enteredCode {
    return _controllers.map((controller) => controller.text).join();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (digits.isEmpty) {
        return;
      }

      int currentIndex = index;

      for (int i = 0; i < digits.length && currentIndex < 6; i++) {
        _controllers[currentIndex].text = digits[i];

        _controllers[currentIndex].selection = TextSelection.fromPosition(
          TextPosition(offset: _controllers[currentIndex].text.length),
        );

        currentIndex++;
      }

      if (currentIndex < 6) {
        _focusNodes[currentIndex].requestFocus();
      } else {
        _focusNodes[5].unfocus();
      }

      setState(() {});

      return;
    }

    if (value.isNotEmpty) {
      final digit = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (digit.isEmpty) {
        _controllers[index].clear();
        return;
      }

      _controllers[index].text = digit[0];

      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );

      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    setState(() {});
  }

  Future<void> _verifyCode() async {
    final code = _enteredCode;

    if (code.length != 6) {
      _showMessage(
        'Please enter the 6-digit verification code.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /*
       * REAL BACKEND VERIFICATION
       *
       * POST /api/auth/verify-email
       */
      final response = await ApiClient.instance.post(
        '/auth/verify-email',
        body: {'email': widget.email, 'code': code},
      );

      final account = response['account'];
      final session = response['session'];

      final token = session is Map ? session['token']?.toString() : null;

      if (account is! Map) {
        throw ApiException(
          statusCode: 500,
          message: 'Invalid account response from server.',
        );
      }

      final accountEmail = account['email']?.toString() ?? widget.email;

      final accountName = account['displayName']?.toString() ?? widget.name;

      final accountUsername =
          account['username']?.toString() ?? widget.username;

      if (widget.isAddingAccount) {
        await AuthStore.instance.addAccount(
          name: accountName,
          username: accountUsername,
          email: accountEmail,
          token: token,
        );
      } else {
        await AuthStore.instance.register(
          name: accountName,
          username: accountUsername,
          email: accountEmail,
          token: token,
        );
      }

      if (!mounted) {
        return;
      }

      _showMessage('Your Luma account has been verified!', isError: false);

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isResending || _secondsRemaining > 0) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      /*
       * REAL BACKEND RESEND
       *
       * POST /api/auth/resend-verification
       */
      final response = await ApiClient.instance.post(
        '/auth/resend-verification',
        body: {'email': widget.email},
      );

      final verification = response['verification'];

      if (verification is Map) {
        _currentVerificationCode = verification['code']?.toString() ?? '';
      }

      for (final controller in _controllers) {
        controller.clear();
      }

      _startTimer();

      if (!mounted) {
        return;
      }

      _focusNodes.first.requestFocus();

      _showMessage('A new verification code has been sent.', isError: false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message, isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to resend the code.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final background = theme.scaffoldBackgroundColor;

    final primary = theme.colorScheme.primary;

    final textColor = theme.colorScheme.onSurface;

    final secondaryText = textColor.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final animation = Curves.easeOutCubic.transform(
              _animationController.value,
            );

            return Opacity(
              opacity: animation,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - animation)),
                child: child,
              ),
            );
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primary, const Color(0xFF22D3EE)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Verify your email',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'We sent a 6-digit verification code to',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: secondaryText,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 36),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: 52,
                            height: 62,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: textColor.withValues(alpha: 0.10),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                _onCodeChanged(index, value);
                              },
                              onSubmitted: (_) {
                                if (index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 30),

                    if (_secondsRemaining > 0)
                      Text(
                        'You can request a new code in '
                        '${_secondsRemaining}s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryText,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _isResending ? null : _resendCode,
                        child: _isResending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Resend verification code',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primary.withValues(
                            alpha: 0.45,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Development mode',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'The verification code is currently '
                            'returned by the development API. '
                            'Real email delivery will be connected later.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            _currentVerificationCode.isEmpty
                                ? 'Code unavailable'
                                : 'Development code: '
                                      '$_currentVerificationCode',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: secondaryText,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
