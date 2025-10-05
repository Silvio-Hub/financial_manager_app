import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class Formatters {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormatter = NumberFormat(
    '#,##0.00',
    'pt_BR',
  );

  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');

  static String formatCurrency(double value) {
    return _currencyFormatter.format(value);
  }

  static String formatNumber(double value) {
    return _numberFormatter.format(value);
  }

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  static double? parseDouble(String value) {
    try {
      String cleanValue = value.replaceAll(RegExp(r'[^\d,.]'), '');
      cleanValue = cleanValue.replaceAll('.', '');
      cleanValue = cleanValue.replaceAll(',', '.');
      return double.parse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  static String formatCPF(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
  }

  static String formatPhone(String phone) {
    if (phone.length == 10) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6, 10)}';
    } else if (phone.length == 11) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7, 11)}';
    }
    return phone;
  }

  static String removeFormatting(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }
}

class PtBrCurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _numberFormatter = NumberFormat('#,##0.00', 'pt_BR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final valueInCents = int.parse(digitsOnly);
    final value = valueInCents / 100.0;

    final formatted = _numberFormatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
