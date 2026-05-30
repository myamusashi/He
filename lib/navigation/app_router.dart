import 'package:flutter/material.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transaction/presentation/transaction_list_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/simulation/presentation/simulation_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/transaction/presentation/add_transaction_screen.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionListScreen(),
    const AnalyticsScreen(),
    const SimulationScreen(),
    const BudgetScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true) setState(() {});
        },
        backgroundColor: const Color(0xFF4527A0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, 'Beranda', 0),
            _navItem(Icons.receipt_outlined, 'Transaksi', 1),
            const SizedBox(width: 40),
            _navItem(Icons.bar_chart_outlined, 'Analisis', 2),
            _navItem(Icons.savings_outlined, 'Budget', 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF4527A0) : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF4527A0) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
