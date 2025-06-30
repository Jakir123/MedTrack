import 'package:flutter/material.dart';
import 'package:med_track/features/authentication/sign_in_screen.dart';
import 'package:med_track/features/authentication/sign_up_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isDark;

  const AuthScreen({
    super.key,
    required this.isDark,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showSignUp = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _showSignUp
        ? SignUpScreen(isDark: widget.isDark, showSignIn: toggleScreen,)
        : SignInScreen(isDark: widget.isDark, showSignUp: toggleScreen,);
  }

  void toggleScreen() {
    setState(() {
      _showSignUp = !_showSignUp;
    });
  }
}
