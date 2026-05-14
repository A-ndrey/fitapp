import 'package:flutter/services.dart';

final RegExp _positiveDecimalPattern = RegExp(r'^\d*\.?\d*$');

const List<TextInputFormatter> positiveDecimalInputFormatters =
    <TextInputFormatter>[_PositiveDecimalTextInputFormatter()];

class _PositiveDecimalTextInputFormatter extends TextInputFormatter {
  const _PositiveDecimalTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_positiveDecimalPattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
