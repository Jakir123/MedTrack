import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast{
  CustomToast._();
  static showGeneralToast(String message) {
    _showToast(message);
  }

  static showErrorToast(String message) {
    _showToast(message,bgColor: Colors.red);
  }

  static showSuccessToast(String message) {
    _showToast(message,bgColor: Colors.green);
  }

  static _showToast(
  String message,
  {Color bgColor = Colors.black54,
    Color textColor = Colors.white,
    ToastGravity gravity = ToastGravity.CENTER,
    Toast length = Toast.LENGTH_LONG
  }){
    Fluttertoast.showToast(
        msg: message,
        toastLength: length,
        gravity: gravity,
        backgroundColor: bgColor,
        textColor: textColor);
  }
}
