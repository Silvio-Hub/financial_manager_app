import 'package:flutter/material.dart';
import 'transaction.dart';

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<TransactionCategory, double> expensesByCategory;
  final Map<TransactionCategory, double> incomesByCategory;
  final List<MonthlyData> monthlyData;
  final DateTime periodStart;
  final DateTime periodEnd;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.expensesByCategory,
    required this.incomesByCategory,
    required this.monthlyData,
    required this.periodStart,
    required this.periodEnd,
  });

  // Getter para dados do gráfico de pizza de despesas
  List<PieChartData> get expensesPieChartData {
    if (totalExpense == 0) return [];
    
    return expensesByCategory.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100;
      return PieChartData(
        label: entry.key.displayName,
        value: entry.value,
        category: entry.key.displayName,
        color: entry.key.color,
        percentage: percentage,
      );
    }).toList();
  }

  // Getter para dados do gráfico de pizza de receitas
  List<PieChartData> get incomesPieChartData {
    if (totalIncome == 0) return [];
    
    return incomesByCategory.entries.map((entry) {
      final percentage = (entry.value / totalIncome) * 100;
      return PieChartData(
        label: entry.key.displayName,
        value: entry.value,
        category: entry.key.displayName,
        color: entry.key.color,
        percentage: percentage,
      );
    }).toList();
  }

  // Criar resumo a partir de lista de transações
  factory FinancialSummary.fromTransactions(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, 1);
    final end = endDate ?? DateTime(now.year, now.month + 1, 0);

    // Filtrar transações por período
    final filteredTransactions = transactions.where((t) =>
        t.date.isAfter(start.subtract(const Duration(days: 1))) &&
        t.date.isBefore(end.add(const Duration(days: 1)))).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    Map<TransactionCategory, double> expensesByCategory = {};
    Map<TransactionCategory, double> incomesByCategory = {};

    // Calcular totais e categorias
    for (final transaction in filteredTransactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
        incomesByCategory[transaction.category] =
            (incomesByCategory[transaction.category] ?? 0) + transaction.amount;
      } else {
        totalExpense += transaction.amount;
        expensesByCategory[transaction.category] =
            (expensesByCategory[transaction.category] ?? 0) + transaction.amount;
      }
    }

    // Gerar dados mensais (últimos 6 meses)
    final monthlyData = _generateMonthlyData(transactions, 6);

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      expensesByCategory: expensesByCategory,
      incomesByCategory: incomesByCategory,
      monthlyData: monthlyData,
      periodStart: start,
      periodEnd: end,
    );
  }

  static List<MonthlyData> _generateMonthlyData(
    List<Transaction> transactions,
    int monthsCount,
  ) {
    final now = DateTime.now();
    final monthlyData = <MonthlyData>[];

    for (int i = monthsCount - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final monthTransactions = transactions.where((t) =>
          t.date.isAfter(month.subtract(const Duration(days: 1))) &&
          t.date.isBefore(nextMonth)).toList();

      double income = 0;
      double expense = 0;

      for (final transaction in monthTransactions) {
        if (transaction.type == TransactionType.income) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      monthlyData.add(MonthlyData(
        month: month,
        income: income,
        expense: expense,
        balance: income - expense,
      ));
    }

    return monthlyData;
  }

  // Getters úteis
  double get savingsRate {
    if (totalIncome == 0) return 0;
    return (balance / totalIncome) * 100;
  }

  TransactionCategory? get topExpenseCategory {
    if (expensesByCategory.isEmpty) return null;
    return expensesByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  TransactionCategory? get topIncomeCategory {
    if (incomesByCategory.isEmpty) return null;
    return incomesByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  bool get isPositiveBalance => balance >= 0;

  @override
  String toString() {
    return 'FinancialSummary(income: $totalIncome, expense: $totalExpense, balance: $balance)';
  }
}

class MonthlyData {
  final DateTime month;
  final double income;
  final double expense;
  final double balance;

  MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
  });

  String get monthName {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[month.month - 1];
  }

  @override
  String toString() {
    return 'MonthlyData(month: $monthName, income: $income, expense: $expense, balance: $balance)';
  }
}

// Classe para dados de gráfico de pizza
class PieChartData {
  final String label;
  final double value;
  final String category;
  final Color color;
  final double percentage;

  PieChartData({
    required this.label,
    required this.value,
    required this.category,
    required this.color,
    required this.percentage,
  });
}

// Classe para dados de gráfico de linha
class FinancialLineChartData {
  final DateTime date;
  final double value;
  final String type;

  FinancialLineChartData({
    required this.date,
    required this.value,
    required this.type,
  });
}