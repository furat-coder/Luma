import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_store.dart';
import 'verification_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late final AnimationController _pageController;
  late final AnimationController _buttonController;
  late final AnimationController _logoController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  bool isLogin = true;
  bool obscurePassword = true;
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();

  final TextEditingController usernameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutBack),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonController.dispose();
    _logoController.dispose();

    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (isLoading) {
      return;
    }

    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (!isLogin && name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    if (!isLogin && username.isEmpty) {
      _showMessage('Please choose a username.');
      return;
    }

    if (!isLogin && username.length < 3) {
      _showMessage('Username must be at least 3 characters.');
      return;
    }

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      // ============================================================
      // LOGIN
      // ============================================================

      if (isLogin) {
        await AuthStore.instance.loginWithApi(
          identifier: email,
          password: password,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
        });

        _showMessage('Welcome back to Luma!');

        return;
      }

      // ============================================================
      // REGISTRATION
      // ============================================================

      final response = await ApiClient.instance.post(
        '/auth/register',
        body: {
          'email': email,
          'username': username,
          'displayName': name,
          'password': password,
        },
      );

      final verification = response['verification'];

      if (verification is! Map) {
        throw ApiException(
          statusCode: 500,
          message: 'The server did not return a verification code.',
        );
      }

      final verificationCode = verification['code']?.toString() ?? '';

      if (verificationCode.length != 6) {
        throw ApiException(
          statusCode: 500,
          message: 'The server returned an invalid verification code.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      debugPrint(
        'LUMA BACKEND VERIFICATION CODE: '
        '$verificationCode',
      );

      // ============================================================
      // OPEN VERIFICATION SCREEN
      // ============================================================

      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, animation, secondaryAnimation) {
            return VerificationScreen(
              name: name,
              username: username,
              email: email,
              password: password,
              verificationCode: verificationCode,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.12, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      debugPrint('LUMA AUTH ERROR: $error');

      _showMessage(
        'Unable to connect to Luma. '
        'Make sure the backend is running.',
      );
    }
  }

  void _switchMode() {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLogin = !isLogin;

      nameController.clear();
      usernameController.clear();
      emailController.clear();
      passwordController.clear();

      obscurePassword = true;
    });

    _pageController.reset();
    _pageController.forward();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isDark
              ? const Color(0xFF1F2937)
              : const Color(0xFF374151),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _AnimatedBackground(isDark: isDark),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            final y = sin(_logoController.value * pi) * 7;

                            return Transform.translate(
                              offset: Offset(0, -y),
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: const _LumaLogo(),
                        ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.25),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            isLogin ? 'Welcome back' : 'Join Luma',
                            key: ValueKey(isLogin),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            isLogin
                                ? 'Your world. Your people. Your journey.'
                                : 'Create. Connect. Grow.',
                            key: ValueKey('${isLogin}_subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.07)
                                    : Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : Colors.white.withValues(alpha: 0.9),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.18 : 0.08,
                                    ),
                                    blurRadius: 35,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildModeSwitcher(isDark),
                                  const SizedBox(height: 24),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    child: Column(
                                      children: [
                                        if (!isLogin) ...[
                                          _AnimatedField(
                                            controller: nameController,
                                            label: 'Full name',
                                            icon: Icons.person_outline_rounded,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 13),
                                          _AnimatedField(
                                            controller: usernameController,
                                            label: 'Username',
                                            icon: Icons.alternate_email_rounded,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 13),
                                        ],
                                        _AnimatedField(
                                          controller: emailController,
                                          label: 'Email',
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 13),
                                        _AnimatedField(
                                          controller: passwordController,
                                          label: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: obscurePassword,
                                          isDark: isDark,
                                          suffix: IconButton(
                                            tooltip: obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                            onPressed: () {
                                              setState(() {
                                                obscurePassword =
                                                    !obscurePassword;
                                              });
                                            },
                                            icon: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: Icon(
                                                obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                key: ValueKey(obscurePassword),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _buildMainButton(),
                                  const SizedBox(height: 18),
                                  GestureDetector(
                                    onTap: _switchMode,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: RichText(
                                        key: ValueKey(isLogin),
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                            fontSize: 13,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: isLogin
                                                  ? "Don't have an account? "
                                                  : 'Already have an account? ',
                                            ),
                                            TextSpan(
                                              text: isLogin
                                                  ? 'Create one'
                                                  : 'Login',
                                              style: const TextStyle(
                                                color: Color(0xFF7C3AED),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Luma • Create. Connect. Grow.',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          _modeButton(text: 'Login', selected: isLogin, isDark: isDark),
          _modeButton(
            text: 'Create account',
            selected: !isLogin,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String text,
    required bool selected,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _switchModeIfNeeded(text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  )
                : null,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : isDark
                  ? Colors.white54
                  : Colors.black45,
              fontSize: 13,
            ),
            child: Text(text, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  VoidCallback? _switchModeIfNeeded(String text) {
    return () {
      if (text == 'Login' && !isLogin) {
        _switchMode();
      }

      if (text == 'Create account' && isLogin) {
        _switchMode();
      }
    };
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTapDown: (_) {
        if (!isLoading) {
          _buttonController.reverse();
        }
      },
      onTapUp: (_) {
        _buttonController.forward();

        if (!isLoading) {
          _submit();
        }
      },
      onTapCancel: () {
        _buttonController.forward();
      },
      child: AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          return Transform.scale(scale: _buttonController.value, child: child);
        },
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF7C3AED), Color(0xFF22D3EE)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: ValueKey(isLogin),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLogin
                              ? Icons.login_rounded
                              : Icons.rocket_launch_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          isLogin ? 'Enter Luma' : 'Create my Luma',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _AnimatedField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        if (!mounted) {
          return;
        }

        setState(() {
          focused = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.14),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: TextStyle(
            color: widget.isDark ? Colors.white : const Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
          cursorColor: const Color(0xFF8B5CF6),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(
              widget.icon,
              color: focused
                  ? const Color(0xFF8B5CF6)
                  : widget.isDark
                  ? Colors.white54
                  : Colors.black45,
            ),
            suffixIcon: widget.suffix,
            filled: true,
            fillColor: widget.isDark
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.7),
            labelStyle: TextStyle(
              color: focused
                  ? const Color(0xFF8B5CF6)
                  : widget.isDark
                  ? Colors.white54
                  : Colors.black54,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: Color(0xFF8B5CF6),
                width: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LumaLogo extends StatelessWidget {
  const _LumaLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.38),
            blurRadius: 34,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 45,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  final bool isDark;

  const _AnimatedBackground({required this.isDark});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;

        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              color: widget.isDark
                  ? const Color(0xFF070A12)
                  : const Color(0xFFF7F7FB),
            ),
            Positioned(
              left: -110 + (value * 80),
              top: -90 + (value * 45),
              child: _glow(
                const Color(0xFF7C3AED),
                270,
                widget.isDark ? 0.16 : 0.10,
              ),
            ),
            Positioned(
              right: -100 - (value * 55),
              top: 220 + (value * 80),
              child: _glow(
                const Color(0xFF06B6D4),
                250,
                widget.isDark ? 0.14 : 0.08,
              ),
            ),
            Positioned(
              left: 60 + (value * 40),
              bottom: -160 + (value * 35),
              child: _glow(
                const Color(0xFF4C1D95),
                290,
                widget.isDark ? 0.16 : 0.07,
              ),
            ),
            Positioned(
              right: 70 + (value * 20),
              top: 100 + (value * 25),
              child: _smallOrb(const Color(0xFF22D3EE)),
            ),
            Positioned(
              left: 50 + (value * 25),
              bottom: 180 + (value * 20),
              child: _smallOrb(const Color(0xFF8B5CF6)),
            ),
          ],
        );
      },
    );
  }

  Widget _glow(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: min(opacity + 0.05, 1)),
            blurRadius: 110,
            spreadRadius: 35,
          ),
        ],
      ),
    );
  }

  Widget _smallOrb(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 18,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}
