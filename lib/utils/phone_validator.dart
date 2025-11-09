import 'package:flutter/services.dart';

bool isValidVietnamPhone(String value) {
  final normalized = value.trim();
  return RegExp(r'^0\d{9}$').hasMatch(normalized);
}

List<TextInputFormatter> buildPhoneInputFormatters() {
  return [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];
}
