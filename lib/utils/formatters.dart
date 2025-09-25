import 'package:intl/intl.dart';

class Formatters {
  // Formatador de moeda brasileira
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  
  // Formatador de números
  static final NumberFormat _numberFormatter = NumberFormat('#,##0.00', 'pt_BR');
  
  // Formatador de data
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  
  /// Formata um valor monetário
  static String formatCurrency(double value) {
    return _currencyFormatter.format(value);
  }
  
  /// Formata um número
  static String formatNumber(double value) {
    return _numberFormatter.format(value);
  }
  
  /// Formata uma data
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }
  
  /// Formata data e hora
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }
  
  /// Formata apenas a hora
  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }
  
  /// Converte string para double (para valores monetários)
  static double? parseDouble(String value) {
    try {
      // Remove caracteres não numéricos exceto vírgula e ponto
      String cleanValue = value.replaceAll(RegExp(r'[^\d,.]'), '');
      // Substitui vírgula por ponto
      cleanValue = cleanValue.replaceAll(',', '.');
      return double.parse(cleanValue);
    } catch (e) {
      return null;
    }
  }
  
  /// Formata CPF
  static String formatCPF(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
  }
  
  /// Formata telefone
  static String formatPhone(String phone) {
    if (phone.length == 10) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6, 10)}';
    } else if (phone.length == 11) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7, 11)}';
    }
    return phone;
  }
  
  /// Remove formatação de string
  static String removeFormatting(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }
}