import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_textfield.dart';
import 'auth_viewmodel.dart';
import 'email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback showSignIn;
  final bool isDark;
  const SignUpScreen({
    super.key,
    required this.showSignIn,
    required this.isDark,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) => Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Image.asset(
                      'assets/icons/ic_logo.png',
                      width: 72,
                      height: 72,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Sign Up',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Use your credentials to create accounts',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        textEditingController: _emailController,
                        inputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        leftIcon: const Icon(Icons.email_outlined),
                        onValueChange: (value) {
                          vm.setSignUpEmail(value);
                        },
                      ),
                      if (vm.signUpEmailError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Text(vm.signUpEmailError!, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        textEditingController: _passwordController,
                        isPassword: _obscurePassword,
                        inputAction: TextInputAction.next,
                        leftIcon: const Icon(Icons.lock_outline),
                        rightIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        onValueChange: (value) {
                          vm.setSignUpPassword(value);
                        },
                      ),
                      if (vm.signUpPasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Text(vm.signUpPasswordError!, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        labelText: 'Confirm Password',
                        hintText: 'Enter your password again',
                        textEditingController: _confirmPasswordController,
                        isPassword: _obscureConfirmPassword,
                        inputAction: TextInputAction.done,
                        leftIcon: const Icon(Icons.lock_outline),
                        rightIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        onValueChange: (value) {
                          vm.setSignUpConfirmPassword(value);
                        },
                      ),
                      if (vm.signUpConfirmPasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Text(vm.signUpConfirmPasswordError!, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 24),
                      if (vm.authError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(vm.authError!, style: const TextStyle(color: Colors.red)),
                        ),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: vm.isLoading
                              ? null
                              : () async {
                            if (vm.validateSignUp()) {
                              final success = await vm.signUp();
                              // if (success && context.mounted) {
                              //   widget.onSignIn();
                              // }
                              if (context.mounted) {
                                if (!success && vm.authError == null) {
                                  _showVerificationBottomSheet();
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  vm.setSignUpEmail('');
                                  vm.setSignUpPassword('');
                                  vm.setSignUpConfirmPassword('');
                                }
                              }
                            }
                          },
                          child: vm.isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          widget.showSignIn();
                        },
                        child: Text(
                          'Sign in.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    ));
  }
  // Add this method in your _SignUpScreenState class
  void _showVerificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmailVerificationSheet(
        email: _emailController.text.trim(),
        onVerificationComplete: () {
          Navigator.of(context).pop(); // Close the bottom sheet
          widget.showSignIn(); // Proceed to sign in
        },
        onBackToSignIn: () {
          Navigator.of(context).pop(); // Close the bottom sheet
          widget.showSignIn(); // Go back to sign in
        },
      ),
    );
  }
}
