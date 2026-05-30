import 'package:flutter/material.dart';
import 'package:finansa_new/core/constants/app_colors.dart';
import 'package:finansa_new/core/database/database_helper.dart';
import 'add_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filtered = [];
  String _filterType = 'all'; // 'all', 'income', 'expense'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() {
      _transactions = data;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_filterType == 'all') {
      _filtered = List.from(_transactions);
    } else {
      _filtered = _transactions.where((t) => t['type'] == _filterType).toList();
    }
  }

  Future<void> _deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _loadTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi dihapus'),
          backgroundColor: AppColors.expenseRed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTransaction(id);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.expenseRed),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000)
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  // Kelompokkan transaksi berdasarkan tanggal
  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final t in _filtered) {
      final date = _formatDate(t['date']);
      grouped.putIfAbsent(date, () => []).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        title: const Text('Riwayat Transaksi'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPurple,
                    ),
                  )
                : _filtered.isEmpty
                ? _buildEmptyState()
                : _buildTransactionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true) _loadTransactions();
        },
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Summary Bar ───────────────────────────────────────────
  Widget _buildSummaryBar() {
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in _transactions) {
      if (t['type'] == 'income') totalIncome += (t['amount'] as num).toDouble();
      if (t['type'] == 'expense')
        totalExpense += (t['amount'] as num).toDouble();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.primaryPurple,
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Pemasukan',
              totalIncome,
              AppColors.incomeGreen,
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(
            child: _summaryItem('Pengeluaran', totalExpense, Colors.redAccent),
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(
            child: _summaryItem(
              'Saldo',
              totalIncome - totalExpense,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          _formatAmount(amount),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Filter Chips ──────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          _filterChip('Semua', 'all'),
          const SizedBox(width: 8),
          _filterChip('Pemasukan', 'income'),
          const SizedBox(width: 8),
          _filterChip('Pengeluaran', 'expense'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String type) {
    final isActive = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _filterType = type;
        _applyFilter();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPurple : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryPurple : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Transaction List ──────────────────────────────────────
  Widget _buildTransactionList() {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final items = grouped[date]!;
          return _buildDateGroup(date, items);
        },
      ),
    );
  }

  Widget _buildDateGroup(String date, List<Map<String, dynamic>> items) {
    // Total per hari
    double dayIncome = items
        .where((t) => t['type'] == 'income')
        .fold(0, (sum, t) => sum + (t['amount'] as num).toDouble());
    double dayExpense = items
        .where((t) => t['type'] == 'expense')
        .fold(0, (sum, t) => sum + (t['amount'] as num).toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header tanggal
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (dayIncome > 0)
                Text(
                  '+${_formatAmount(dayIncome)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.incomeGreen,
                  ),
                ),
              if (dayIncome > 0 && dayExpense > 0)
                const Text('  ', style: TextStyle(fontSize: 11)),
              if (dayExpense > 0)
                Text(
                  '-${_formatAmount(dayExpense)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.expenseRed,
                  ),
                ),
            ],
          ),
        ),
        // Item transaksi
        ...items.map((t) => _buildTransactionItem(t)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> t) {
    final isIncome = t['type'] == 'income';
    final amount = (t['amount'] as num).toDouble();
    final icon = t['category_icon'] ?? '💸';
    final catName = t['category_name'] ?? 'Lainnya';
    final emotion = t['emotion_type'] ?? '';
    final note = t['note'] ?? '';

    return Dismissible(
      key: Key(t['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expenseRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _confirmDelete(t['id']);
        return false; // Biarkan dialog yang handle
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon kategori
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isIncome
                    ? AppColors.incomeGreen.withOpacity(0.1)
                    : AppColors.expenseRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            // Info transaksi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        catName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (emotion.isNotEmpty)
                        Text(emotion, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Nominal
            Text(
              '${isIncome ? '+' : '-'}${_formatAmount(amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧾', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap tombol + untuk mencatat transaksi pertama',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
              if (result == true) _loadTransactions();
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Transaksi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
