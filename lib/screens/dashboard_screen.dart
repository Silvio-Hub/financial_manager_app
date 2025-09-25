import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../providers/financial_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_pie_chart.dart';
import '../widgets/animated_line_chart.dart';
import '../widgets/animated_bar_chart.dart';
import '../models/financial_summary.dart';
import 'transactions_list_screen.dart';
import 'add_edit_transaction_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late AnimationController _chartsAnimationController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;
  late Animation<double> _chartsAnimation;
  
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de animação
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
      value: 0.0,
    );
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
      value: 0.0,
    );
    _chartsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
      value: 0.0,
    );

    // Configurar animações
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutQuart,
    );
    _cardsAnimation = CurvedAnimation(
      parent: _cardsAnimationController,
      curve: Curves.easeOutCubic,
    );
    _chartsAnimation = CurvedAnimation(
      parent: _chartsAnimationController,
      curve: Curves.easeOutQuint,
    );

    // Carregar dados e iniciar animações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancialProvider>().loadTransactionsFromFirestore();
      _startAnimations();
    });
  }

  void _startAnimations() async {
    await _headerAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _cardsAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _chartsAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    _chartsAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Financeiro'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _navigateToTransactions(context),
            icon: const Icon(Icons.list_alt, color: Colors.white),
            tooltip: 'Ver todas as transações',
          ),
          IconButton(
            onPressed: () => _showProfileMenu(context),
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: Consumer<FinancialProvider>(
        builder: (context, provider, child) {
          final summary = provider.currentSummary;
          if (summary == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return CustomScrollView(
            slivers: [
              _buildAnimatedHeader(context, summary),
              _buildAnimatedSummaryCards(context, summary),
              _buildTabSelector(),
              _buildAnimatedCharts(context, summary),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context, FinancialSummary summary) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _headerAnimation.value)),
            child: Opacity(
              opacity: _headerAnimation.value.clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá!',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                final user = authProvider.user;
                                return Text(
                                  user?.email != null ? user!.email.split('@').first : 'Usuário',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _showProfileMenu(context),
                          icon: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Saldo Total',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      'R\$ ${summary.balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedSummaryCards(BuildContext context, FinancialSummary summary) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardsAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * _cardsAnimation.value),
            child: Opacity(
              opacity: _cardsAnimation.value.clamp(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildSummaryCard(
                        'Receitas',
                        summary.totalIncome,
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: _buildSummaryCard(
                        'Despesas',
                        summary.totalExpense,
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'R\$ ${value.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            _buildTabButton('Visão Geral', 0, Icons.dashboard),
            _buildTabButton('Categorias', 1, Icons.pie_chart),
            _buildTabButton('Tendências', 2, Icons.show_chart),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected 
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCharts(BuildContext context, FinancialSummary summary) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _chartsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _chartsAnimation.value)),
            child: Opacity(
              opacity: _chartsAnimation.value.clamp(0.0, 1.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 300,
                  maxHeight: 400,
                ),
                child: PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return SharedAxisTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                  child: _buildCurrentChart(summary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentChart(FinancialSummary summary) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewChart(summary);
      case 1:
        return _buildCategoriesChart(summary);
      case 2:
        return _buildTrendsChart(summary);
      default:
        return _buildOverviewChart(summary);
    }
  }

  Widget _buildOverviewChart(FinancialSummary summary) {
    return Padding(
      key: const ValueKey('overview'),
      padding: const EdgeInsets.all(16),
      child: AnimatedPieChart(
        data: summary.expensesByCategory,
        title: 'Distribuição de Despesas',
      ),
    );
  }

  Widget _buildCategoriesChart(FinancialSummary summary) {
    return Padding(
      key: const ValueKey('categories'),
      padding: const EdgeInsets.all(16),
      child: AnimatedBarChart(
        categoryData: summary.expensesPieChartData,
        title: 'Despesas por Categoria',
        isExpense: true,
      ),
    );
  }

  Widget _buildTrendsChart(FinancialSummary summary) {
    return Padding(
      key: const ValueKey('trends'),
      padding: const EdgeInsets.all(16),
      child: AnimatedLineChart(
        monthlyData: summary.monthlyData,
        title: 'Tendências Mensais',
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddTransactionDialog(),
      icon: const Icon(Icons.add),
      label: const Text('Nova Transação'),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _navigateToTransactions(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TransactionsListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditTransactionScreen(),
      ),
    );
    
    // Se uma transação foi adicionada, recarregar os dados
    if (result == true && mounted) {
      context.read<FinancialProvider>().loadTransactionsFromFirestore();
    }
  }
}