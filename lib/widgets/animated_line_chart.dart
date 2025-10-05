import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/financial_summary.dart';

class AnimatedLineChart extends StatefulWidget {
  final List<MonthlyData> monthlyData;
  final String title;
  final double height;
  final VoidCallback? onAddTransaction;

  const AnimatedLineChart({
    super.key,
    required this.monthlyData,
    required this.title,
    this.height = 300,
    this.onAddTransaction,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool showIncome = true;
  bool showExpense = true;
  bool showBalance = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyData.isEmpty) {
      return _buildEmptyState();
    }

    // Se nenhuma linha estiver habilitada, mostrar estado vazio
    final bars = _buildLineBarsData();
    if (bars.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildLegendToggle(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: _buildBottomTitles,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _calculateInterval(),
                            reservedSize: 60,
                            getTitlesWidget: _buildLeftTitles,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      minX: 0,
                      maxX: (widget.monthlyData.length - 1).toDouble(),
                      minY: _getMinY(),
                      maxY: _getMaxY(),
                      lineBarsData: bars,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: _buildTooltipItems,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> lines = [];

    if (showIncome) {
      lines.add(LineChartBarData(
        spots: widget.monthlyData.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            entry.value.income * _animation.value,
          );
        }).toList(),
        isCurved: true,
        color: Colors.green,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.green.withValues(alpha: 0.1),
        ),
      ));
    }

    if (showExpense) {
      lines.add(LineChartBarData(
        spots: widget.monthlyData.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            entry.value.expense * _animation.value,
          );
        }).toList(),
        isCurved: true,
        color: Colors.red,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.red.withValues(alpha: 0.1),
        ),
      ));
    }

    if (showBalance) {
      lines.add(LineChartBarData(
        spots: widget.monthlyData.asMap().entries.map((entry) {
          return FlSpot(
            entry.key.toDouble(),
            entry.value.balance * _animation.value,
          );
        }).toList(),
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        dashArray: [5, 5],
      ));
    }

    return lines;
  }

  Widget _buildBottomTitles(double value, TitleMeta meta) {
    if (value.toInt() >= 0 && value.toInt() < widget.monthlyData.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          widget.monthlyData[value.toInt()].monthName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLeftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        _formatCurrency(value),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  List<LineTooltipItem> _buildTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((LineBarSpot touchedSpot) {
      final monthData = widget.monthlyData[touchedSpot.x.toInt()];
      String label = '';
      Color color = Colors.black;

      if (touchedSpot.barIndex == 0 && showIncome) {
        label = 'Receita: ${_formatCurrency(monthData.income)}';
        color = Colors.green;
      } else if ((touchedSpot.barIndex == 1 && showIncome && showExpense) ||
                 (touchedSpot.barIndex == 0 && !showIncome && showExpense)) {
        label = 'Despesa: ${_formatCurrency(monthData.expense)}';
        color = Colors.red;
      } else {
        label = 'Saldo: ${_formatCurrency(monthData.balance)}';
        color = Colors.blue;
      }

      return LineTooltipItem(
        '${monthData.monthName}\\n$label',
        TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildLegendToggle() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'income':
              showIncome = !showIncome;
              break;
            case 'expense':
              showExpense = !showExpense;
              break;
            case 'balance':
              showBalance = !showBalance;
              break;
          }
        });
        _animationController.reset();
        _animationController.forward();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'income',
          child: Row(
            children: [
              Icon(
                showIncome ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              const Text('Receitas'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'expense',
          child: Row(
            children: [
              Icon(
                showExpense ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              const Text('Despesas'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'balance',
          child: Row(
            children: [
              Icon(
                showBalance ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text('Saldo'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showIncome)
          _buildLegendItem('Receitas', Colors.green, Icons.trending_up),
        if (showExpense)
          _buildLegendItem('Despesas', Colors.red, Icons.trending_down),
        if (showBalance)
          _buildLegendItem('Saldo', Colors.blue, Icons.account_balance),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sem dados em Tendências mensais ainda',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione uma transação para começar a ver o gráfico.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.onAddTransaction != null)
              ElevatedButton.icon(
                onPressed: widget.onAddTransaction,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar transação'),
              ),
          ],
        ),
      ),
    );
  }

  double _getMinY() {
    if (widget.monthlyData.isEmpty) return 0;
    
    double min = 0;
    for (final data in widget.monthlyData) {
      if (showBalance && data.balance < min) min = data.balance;
    }
    return min * 1.1; // 10% de margem
  }

  double _getMaxY() {
    if (widget.monthlyData.isEmpty) return 100;
    
    double max = 0;
    for (final data in widget.monthlyData) {
      if (showIncome && data.income > max) max = data.income;
      if (showExpense && data.expense > max) max = data.expense;
      if (showBalance && data.balance > max) max = data.balance;
    }
    return max * 1.1; // 10% de margem
  }

  double _calculateInterval() {
    final range = _getMaxY() - _getMinY();
    // Evitar intervalos zero/negativos que causam asserts no fl_chart
    if (range <= 0) {
      return 1; // intervalo mínimo seguro
    }
    return range / 5; // 5 linhas de grade
  }

  String _formatCurrency(double value) {
    if (value.abs() >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }
}