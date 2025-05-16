import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final Future<void> Function(String email, String password, {String? name})
  onSubmit;

  const AuthForm({Key? key, required this.isLogin, required this.onSubmit})
    : super(key: key);

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isPasswordVisible = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (widget.isLogin) {
        await widget.onSubmit(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await widget.onSubmit(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isLogin) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: theme.primaryColor.withOpacity(0.7),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: theme.primaryColor.withOpacity(0.7),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: theme.primaryColor.withOpacity(0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: theme.primaryColor.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!widget.isLogin && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                elevation: 3,
                shadowColor: theme.primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child:
                  authProvider.isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isLogin ? Icons.login : Icons.person_add,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isLogin ? 'Sign In' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
