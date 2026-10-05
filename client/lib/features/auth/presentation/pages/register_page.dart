import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/auth/auth_scope.dart';
import '../../../../core/network/api_exception.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = AuthScope.of(context);
      await authController.register(
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký không thành công: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tạo tài khoản mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Điền thông tin tài khoản để bắt đầu',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Display Name field
                  AuthTextField(
                    controller: _displayNameController,
                    label: 'Tên hiển thị',
                    hintText: 'Nhập họ và tên hoặc biệt danh',
                    prefixIcon: HugeIcons.strokeRoundedUserCircle,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên hiển thị';
                      }
                      if (value.trim().length < 2) {
                        return 'Tên hiển thị phải có ít nhất 2 ký tự';
                      }
                      if (value.trim().length > 50) {
                        return 'Tên hiển thị không được vượt quá 50 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username field
                  AuthTextField(
                    controller: _usernameController,
                    label: 'Tên đăng nhập',
                    hintText: 'Nhập tên đăng nhập (chữ cái và số)',
                    prefixIcon: HugeIcons.strokeRoundedUser,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      final username = value.trim().toLowerCase();
                      if (username.length < 6) {
                        return 'Tên đăng nhập phải có ít nhất 6 ký tự';
                      }
                      if (username.length > 30) {
                        return 'Tên đăng nhập tối đa 30 ký tự';
                      }
                      final usernameRegex = RegExp(r'^[a-z0-9]+$');
                      if (!usernameRegex.hasMatch(username)) {
                        return 'Tên đăng nhập chỉ chứa chữ cái thường và số, không có ký tự đặc biệt';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: HugeIcons.strokeRoundedLockKey,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      if (value.length > 100) {
                        return 'Mật khẩu tối đa 100 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password field
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: HugeIcons.strokeRoundedSecurityCheck,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Register submit button
                  AuthButton(
                    text: 'Đăng ký tài khoản',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 20),

                  // Back to Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
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
