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
  String _name = "";
  String _email = "";
  bool _isLoading = true;

  double _balance = 0;
  double _income = 0;
  double _expense = 0;

  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _pieData = [];

  static const _catColors = [
    Color(0xFF1DB954),
    Color(0xFF2196F3),
    Color(0xFFFF5722),
    Color(0xFFFFEB3B),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF9800),
    Color(0xFF8BC34A),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final auth = AuthService();
    final ts = TransactionService();

    final results = await Future.wait([
      auth.getUser(),
      ts.getDashboard(),
      ts.getTransactions(size: 10),
      ts.getCategorySummary(),
    ]);

    final user = results[0] as Map<String, dynamic>?;
    final dashboard = results[1] as Map<String, dynamic>?;
    final recent = results[2] as List<Map<String, dynamic>>;
    final cats = results[3] as List<Map<String, dynamic>>;

    final totalCat =
        cats.fold(0.0, (s, c) => s + (c['total'] as num).toDouble());
    final pie = cats.asMap().entries.map((e) => {
          'label': e.value['category'] as String,
          'value': (e.value['total'] as num).toDouble(),
          'percent': totalCat > 0
              ? ((e.value['total'] as num).toDouble() / totalCat * 100).round()
              : 0,
          'color': _catColors[e.key % _catColors.length],
        }).toList();

    if (!mounted) return;
    setState(() {
      _name = (user?['name'] ?? user?['username'] ?? '').toString().trim();
      _email = (user?['email'] ?? '').toString().trim();
      _balance = (dashboard?['balance'] as num?)?.toDouble() ?? 0;
      _income = (dashboard?['income'] as num?)?.toDouble() ?? 0;
      _expense = (dashboard?['expense'] as num?)?.toDouble() ?? 0;
      _recent = recent;
      _pieData = pie;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openEdit(Map<String, dynamic> transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          transaction: transaction,
          onSuccess: _loadAll,
        ),
      ),
    );
  }

  void _showProfileModal() {
    final firstName = _name.isNotEmpty ? _name.trim().split(RegExp(r'\s+')).first : 'U';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor: primaryGreen,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 30),
              ),
            ),
            const SizedBox(height: 16),
            Text(_name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_email,
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _profileStat('Saldo', _fmt(_balance), Colors.white),
                _profileStat('Entradas', _fmt(_income), primaryGreen),
                _profileStat('Saídas', _fmt(_expense), Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair da conta',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _profileStat(String label, String value, Color valueColor) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ]);
  }

  String _fmt(double v) {
    final s = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final parts = s.split(',');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final prefix = v < 0 ? '-R\$ ' : 'R\$ ';
    return '$prefix$intPart,${parts[1]}';
  }

  IconData _icon(String? cat) {
    switch ((cat ?? '').toLowerCase()) {
      case 'alimentação': return Icons.shopping_cart_outlined;
      case 'transporte': return Icons.directions_car_outlined;
      case 'contas fixas': return Icons.wifi;
      case 'lazer': return Icons.sports_esports_outlined;
      case 'saúde': return Icons.favorite_outline;
      case 'educação': return Icons.school_outlined;
      case 'salário': return Icons.account_balance_wallet_outlined;
      case 'freelance': return Icons.work_outline;
      case 'investimentos': return Icons.trending_up;
      default: return Icons.attach_money;
    }
  }

  Widget _buildPie() {
    if (_pieData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sem gastos registrados',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }
    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _pieData
              .map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                              color: s['color'] as Color,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${s['label']} ${s['percent']}%',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ))
              .toList(),
        ),
      ),
      SizedBox(
        width: 110, height: 110,
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 0,
          sections: _pieData
              .map((s) => PieChartSectionData(
                    color: s['color'] as Color,
                    value: s['value'] as double,
                    title: '${s['percent']}%',
                    titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    radius: 55,
                  ))
              .toList(),
        )),
      ),
    ]);
  }

  Widget _homeTab() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryGreen));
    }

    final firstName = _name.isNotEmpty ? _name.trim().split(RegExp(r'\s+')).first : '';

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Olá $firstName!',
                      style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Text('Bem-Vindo de volta!',
                      style: TextStyle(
                          color: primaryGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w500)),
                ]),
                GestureDetector(
                  onTap: _showProfileModal,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryGreen,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Atual',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(_fmt(_balance),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: _infoCard(
                  icon: Icons.arrow_upward,
                  iconColor: primaryGreen,
                  label: 'Entradas',
                  value: _fmt(_income),
                  valueColor: primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  icon: Icons.arrow_downward,
                  iconColor: Colors.red,
                  label: 'Saídas',
                  value: _fmt(_expense),
                  valueColor: Colors.red,
                ),
              ),
            ]),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPie(),
                  const SizedBox(height: 10),
                  const Text('Gastos do Mês',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Últimas Movimentações',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const Text('toque para editar',
                          style: TextStyle(
                              color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_recent.isEmpty)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Nenhuma movimentação ainda',
                          style: TextStyle(color: Colors.white54)),
                    ))
                  else
                    ..._recent.map((t) {
                      final isIncome = t['type'] == 'INCOME';
                      final valor = (t['amount'] as num).toDouble();
                      return InkWell(
                        onTap: () => _openEdit(t),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: (isIncome ? primaryGreen : Colors.red)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_icon(t['category']),
                                  color:
                                      isIncome ? primaryGreen : Colors.red,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['description'] ??
                                        t['category'] ??
                                        'Transação',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(t['category'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}${_fmt(valor)}',
                                  style: TextStyle(
                                    color: isIncome
                                        ? primaryGreen
                                        : Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Icon(Icons.edit_outlined,
                                    color: Colors.white24, size: 13),
                              ],
                            ),
                          ]),
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _homeTab(),
      AddExpenseScreen(onSuccess: _loadAll),
      const DashboardScreen(),
    ];
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(child: tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: cardBg,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.white38,
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) _loadAll();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Adicionar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Dashboard'),
        ],
      ),
    );
  }
}