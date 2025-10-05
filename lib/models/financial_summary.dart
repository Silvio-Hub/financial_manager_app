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

  factory FinancialSummary.fromTransactions(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;

    final filteredTransactions = transactions
        .where(
          (t) =>
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();

    double totalIncome = 0;
    double totalExpense = 0;
    Map<TransactionCategory, double> expensesByCategory = {};
    Map<TransactionCategory, double> incomesByCategory = {};

    for (final transaction in filteredTransactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
        incomesByCategory[transaction.category] =
            (incomesByCategory[transaction.category] ?? 0) + transaction.amount;
      } else {
        totalExpense += transaction.amount;
        expensesByCategory[transaction.category] =
            (expensesByCategory[transaction.category] ?? 0) +
            transaction.amount;
      }
    }

    // Gera monthlyData respeitando o período selecionado e apenas com transações filtradas
    final monthlyData = _generateMonthlyDataForPeriod(
      filteredTransactions,
      start,
      end,
    );

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

  static List<MonthlyData> _generateMonthlyDataForPeriod(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Normaliza para o primeiro dia de cada mês
    DateTime normalizedStart = DateTime(startDate.year, startDate.month, 1);
    DateTime normalizedEnd = DateTime(endDate.year, endDate.month, 1);

    // Garante ordem correta
    if (normalizedStart.isAfter(normalizedEnd)) {
      final tmp = normalizedStart;
      normalizedStart = normalizedEnd;
      normalizedEnd = tmp;
    }

    final months = <MonthlyData>[];
    DateTime current = normalizedStart;
    while (!current.isAfter(normalizedEnd)) {
      final nextMonth = DateTime(current.year, current.month + 1, 1);

      // Transações do mês corrente
      final monthTransactions = transactions.where((t) {
        return t.date.isAfter(current.subtract(const Duration(days: 1))) &&
            t.date.isBefore(nextMonth);
      }).toList();

      double income = 0;
      double expense = 0;
      for (final transaction in monthTransactions) {
        if (transaction.type == TransactionType.income) {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      months.add(
        MonthlyData(
          month: current,
          income: income,
          expense: expense,
          balance: income - expense,
        ),
      );

      current = nextMonth;
    }

    return months;
  }

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
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return months[month.month - 1];
  }

  @override
  String toString() {
    return 'MonthlyData(month: $monthName, income: $income, expense: $expense, balance: $balance)';
  }
}

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
