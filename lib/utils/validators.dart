import 'package:email_validator/email_validator.dart';
import '../utils/formatters.dart';
import '../constants/app_strings.dart';

class Validators {
  /// Valida se o campo não está vazio
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }
  
  /// Valida e-mail
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (!EmailValidator.validate(value.trim())) {
      return AppStrings.invalidEmail;
    }
    
    return null;
  }
  
  /// Valida senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    
    return null;
  }
  
  /// Valida confirmação de senha
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value != originalPassword) {
      return AppStrings.passwordsDontMatch;
    }
    
    return null;
  }
  
  /// Valida nome
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    
    return null;
  }
  
  /// Valida CPF
  static String? cpf(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    // Remove formatação
    String cleanCPF = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanCPF.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cleanCPF)) {
      return 'CPF inválido';
    }
    
    // Validação do algoritmo do CPF
    List<int> digits = cleanCPF.split('').map(int.parse).toList();
    
    // Primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    int firstDigit = 11 - (sum % 11);
    if (firstDigit >= 10) firstDigit = 0;
    
    if (digits[9] != firstDigit) {
      return 'CPF inválido';
    }
    
    // Segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i);
    }
    int secondDigit = 11 - (sum % 11);
    if (secondDigit >= 10) secondDigit = 0;
    
    if (digits[10] != secondDigit) {
      return 'CPF inválido';
    }
    
    return null;
  }
  
  /// Valida telefone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    
    return null;
  }
  
  /// Valida valor monetário
  static String? currency(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    // Remove formatação e tenta converter para double
    String cleanValue = value.replaceAll(RegExp(r'[^\d,.]'), '');
    cleanValue = cleanValue.replaceAll(',', '.');
    
    try {
      double amount = double.parse(cleanValue);
      if (amount <= 0) {
        return 'Valor deve ser maior que zero';
      }
    } catch (e) {
      return 'Valor inválido';
    }
    
    return null;
  }
  
  /// Combina múltiplos validadores
  static String? combine(List<String? Function()> validators) {
    for (var validator in validators) {
      final result = validator();
      if (result != null) return result;
    }
    return null;
  }

  /// Valida nome completo
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    
    // Verifica se tem pelo menos nome e sobrenome
    final parts = value.trim().split(' ');
    if (parts.length < 2) {
      return AppStrings.fullNameRequired;
    }
    
    // Verifica se cada parte tem pelo menos 2 caracteres
    for (final part in parts) {
      if (part.length < 2) {
        return AppStrings.fullNameRequired;
      }
    }
    
    return null;
  }

  /// Valida título de transação
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Título é obrigatório';
    }
    
    if (value.trim().length < 3) {
      return 'Título deve ter pelo menos 3 caracteres';
    }
    
    if (value.trim().length > 50) {
      return 'Título deve ter no máximo 50 caracteres';
    }
    
    return null;
  }

  /// Valida valor monetário
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Valor é obrigatório';
    }
    
    final amount = Formatters.parseDouble(value);
    if (amount == null) {
      return 'Digite um valor válido';
    }
    if (amount <= 0) {
      return 'Valor deve ser maior que zero';
    }
    if (amount > 1000000) {
      return 'Valor muito alto (máximo R\$ 1.000.000)';
    }
    return null;
  }

  /// Valida descrição de transação
  static String? validateDescription(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 200) {
        return 'Descrição deve ter no máximo 200 caracteres';
      }
    }
    return null;
  }

  /// Valida data de transação
  static String? validateTransactionDate(DateTime? date) {
    if (date == null) {
      return 'Data é obrigatória';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    // Não permite datas futuras além de hoje
    if (selectedDate.isAfter(today)) {
      return 'Data não pode ser no futuro';
    }
    
    // Não permite datas muito antigas (mais de 5 anos)
    final fiveYearsAgo = DateTime(now.year - 5, now.month, now.day);
    if (selectedDate.isBefore(fiveYearsAgo)) {
      return 'Data não pode ser anterior a 5 anos';
    }
    
    return null;
  }
}