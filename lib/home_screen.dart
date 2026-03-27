import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/transaction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1A1A1A);

  int _currentIndex = 0;
  String name = "";
  bool isLoading = true;
  double saldo = 0;
  double entradas = 0;
  double saidas = 0;
  List<Map<String, dynamic>> ultimasMovimentacoes = [];
  List<Map<String, dynamic>> _pieData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = AuthService();
    final transactionService = TransactionService();
    final user = await authService.getUser();

    if (user != null) {
      final transactions = await transactionService.getTransactions();
      double totalEntradas = 0, totalSaidas = 0;
      final Map<String, double> categoryMap = {};

      for (var t in transactions) {
        final valor = (t['value'] as num).toDouble();
        if (t['type'] == 'INCOME') {
          totalEntradas += valor;
        } else {
          totalSaidas += valor;
          final cat = t['category'] ?? 'Outros';
          categoryMap[cat] = (categoryMap[cat] ?? 0) + valor;
        }
      }

      // Monta dados do gráfico de pizza
      final colors = [
        primaryGreen,
        const Color(0xFF4CAF50),
        const Color(0xFF2196F3),
        const Color(0xFFFFEB3B),
        Colors.grey,
      ];
      final sorted = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final total = categoryMap.values.fold(0.0, (a, b) => a + b);

      if (!mounted) return;
      setState(() {
        name = user['name'] ?? "";
        entradas = totalEntradas;
        saidas = totalSaidas;
        saldo = totalEntradas - totalSaidas;
        ultimasMovimentacoes = transactions.take(4).toList();
        _pieData = sorted.asMap().entries.map((e) => {
          'label': e.value.key,
          'value': e.value.value,
          'percent': total > 0 ? (e.value.value / total * 100).round() : 0,
          'color': colors[e.key % colors.length],
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _formatCurrency(double value) {
    final formatted = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'mercado':
      case 'alimentação': return Icons.shopping_cart_outlined;
      case 'mecânico':
      case 'transporte': return Icons.build_outlined;
      case 'internet':
      case 'contas fixas': return Icons.wifi;
      case 'lazer': return Icons.sports_esports_outlined;
      default: return Icons.attach_money;
    }
  }

  Widget _buildPieChart() {
    if (_pieData.isEmpty) {
      return const Center(
        child: Text("Sem gastos registrados", style: TextStyle(color: Colors.white54)),
      );
    }

    return Row(
      children: [
        // Legenda
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _pieData.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: s['color'], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${s['label']} ${s['percent']}%",
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        // Pizza
        SizedBox(
          width: 110,
          height: 110,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 0,
              sections: _pieData.map((s) => PieChartSectionData(
                color: s['color'],
                value: (s['value'] as double),
                title: "${s['percent']}%",
                titleStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                radius: 55,
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }

    final firstName = name.split(' ').first;

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Olá $firstName!",
                      style: const TextStyle(color: primaryGreen, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Bem-Vindo de volta!",
                      style: TextStyle(color: primaryGreen, fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _logout,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryGreen,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : "U",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Card Saldo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Saldo Atual", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(saldo),
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Entradas / Saídas
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Icon(Icons.arrow_upward, color: primaryGreen, size: 18),
                          SizedBox(width: 4),
                          Text("Entradas", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ]),
                        const SizedBox(height: 6),
                        Text(_formatCurrency(entradas),
                            style: const TextStyle(color: primaryGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                          SizedBox(width: 4),
                          Text("Saídas", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ]),
                        const SizedBox(height: 6),
                        Text(_formatCurrency(saidas),
                            style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Gráfico Pizza
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPieChart(),
                  const SizedBox(height: 10),
                  const Text("Gastos do Mês",
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Últimas Movimentações
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Últimas Movimentações",
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (ultimasMovimentacoes.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("Nenhuma movimentação ainda", style: TextStyle(color: Colors.white54)),
                      ),
                    )
                  else
                    ...ultimasMovimentacoes.map((t) {
                      final isIncome = t['type'] == 'INCOME';
                      final valor = (t['value'] as num).toDouble();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(_categoryIcon(t['category']), color: Colors.white54, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t['description'] ?? t['category'] ?? "Transação",
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                            Text(
                              "${isIncome ? '+' : '-'}${_formatCurrency(valor)}",
                              style: TextStyle(
                                color: isIncome ? primaryGreen : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      const AddExpenseScreen(),
      const DashboardScreen(),
    ];

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(child: tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.white38,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Adicionar"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Dashboard"),
        ],
      ),
    );
  }
}