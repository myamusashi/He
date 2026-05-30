import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _frequency = 'Harian';
  Map<String, dynamic>? _result;

  final List<String> _frequencies = ['Harian', 'Mingguan', 'Bulanan'];

  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double _toDailyAmount(double amount, String freq) {
    switch (freq) {
      case 'Mingguan':
        return amount / 7;
      case 'Bulanan':
        return amount / 30;
      default:
        return amount;
    }
  }

  void _calculate() {
    final name = _nameController.text.trim();

    final amount = double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (name.isEmpty || amount <= 0) return;

    final daily = _toDailyAmount(amount, _frequency);
    final weekly = daily * 7;
    final monthly = daily * 30;
    final yearly = daily * 365;

    const r = 0.08 / 12;
    const n = 10 * 12;
    final monthlyDeposit = daily * 30;

    double powVal = 1;
    for (int i = 0; i < n; i++) {
      powVal *= (1 + r);
    }

    final invest10y = monthlyDeposit * ((powVal - 1) / r);
    final savedPerYear = daily * 3 * 52;

    setState(() {
      _result = {
        'name': name,
        'weekly': weekly,
        'monthly': monthly,
        'yearly': yearly,
        'invest10y': invest10y,
        'savedPerYear': savedPerYear,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInputCard(),
              const SizedBox(height: 24),
              if (_result != null) _buildResultGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F2EEA), Color(0xFF9B7BFF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulasi Keuangan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Lihat masa depan dari kebiasaan kecilmu ✨',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // 🔥 INPUT CARD
  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardStyle(),
      child: Column(
        children: [
          _inputField(_nameController, 'Nama Kebiasaan'),
          const SizedBox(height: 12),
          _inputField(_amountController, 'Nominal', isNumber: true),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _frequency,
            decoration: _inputDecoration('Frekuensi'),
            items: _frequencies
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _frequency = val!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF5F2EEA),
              ),
              child: const Text(
                'Hitung Sekarang',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 RESULT GRID
  Widget _buildResultGrid() {
    return Column(
      children: [
        Row(
          children: [
            _resultItem('Mingguan', _result!['weekly']),
            const SizedBox(width: 12),
            _resultItem('Bulanan', _result!['monthly']),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _resultItem('Tahunan', _result!['yearly']),
            const SizedBox(width: 12),
            _resultItem('Investasi', _result!['invest10y']),
          ],
        ),
        const SizedBox(height: 12),
        _highlightCard(),
      ],
    );
  }

  Widget _resultItem(String title, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardStyle(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              currency.format(value),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Kalau kamu hemat 3x/minggu, kamu bisa saving ${currency.format(_result!['savedPerYear'])} per tahun 🚀',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // 🔧 INPUT
  Widget _inputField(
    TextEditingController c,
    String label, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [CurrencyInputFormatter()] : [],
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF1F3F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
      ],
    );
  }
}

// 🔥 FORMATTER RUPIAH
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    int number = int.parse(digits);
    String newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
