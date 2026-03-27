import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/transaction_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1A1A1A);

  bool _isLoading = true;
  double _income = 0;
  double _expense = 0;
  double _balance = 0;

  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _transactions = [];

  static const _colors = [
    Color(0xFF1DB954), // verde spotify
    Color(0xFF2196F3), // azul
    Color(0xFFFF5722), // laranja-vermelho
    Color(0xFFFFEB3B), // amarelo
    Color(0xFFE91E63), // rosa
    Color(0xFF9C27B0), // roxo
    Color(0xFF00BCD4), // ciano
    Color(0xFFFF9800), // laranja
    Color(0xFF8BC34A), // verde-limão
    Color(0xFF795548), // marrom
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final ts = TransactionService();

    final results = await Future.wait([
      ts.getDashboard(),
      ts.getCategorySummary(),
      ts.getTransactions(size: 500),
    ]);

    final dash = results[0] as Map<String, dynamic>?;
    final cats = results[1] as List<Map<String, dynamic>>;
    final txs = results[2] as List<Map<String, dynamic>>;

    if (!mounted) return;
    setState(() {
      _income = (dash?['income'] as num?)?.toDouble() ?? 0;
      _expense = (dash?['expense'] as num?)?.toDouble() ?? 0;
      _balance = (dash?['balance'] as num?)?.toDouble() ?? 0;
      _cats = cats;
      _transactions = txs;
      _isLoading = false;
    });
  }

  String _fmt(double v) {
    final s = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final parts = s.split(',');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }

  List<String> get _monthLabels {
    const abbr = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final now = DateTime.now();
    return List.generate(8, (i) {
      final m = DateTime(now.year, now.month - (7 - i));
      return abbr[m.month - 1];
    });
  }

  List<FlSpot> get _lineSpots {
    final now = DateTime.now();
    final Map<int, double> byMonth = {};
    for (var t in _transactions) {
      if (t['type'] == 'EXPENSE') {
        final raw = t['date'];
        DateTime? d;
        if (raw is String) d = DateTime.tryParse(raw);
        if (d != null) {
          final diff = (now.year - d.year) * 12 + (now.month - d.month);
          if (diff >= 0 && diff < 8) {
            final idx = 7 - diff;
            byMonth[idx] =
                (byMonth[idx] ?? 0) + (t['amount'] as num).toDouble();
          }
        }
      }
    }
    return List.generate(8, (i) => FlSpot(i.toDouble(), byMonth[i] ?? 0));
  }

  Widget _buildLineChart() {
    final spots = _lineSpots;
    final labels = _monthLabels;
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return LineChart(LineChartData(
      minX: 0,
      maxX: 7,
      minY: 0,
      maxY: maxY > 0 ? maxY * 1.25 : 100,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= labels.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(labels[i],
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: primaryGreen,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: primaryGreen,
              strokeWidth: 0,
              strokeColor: Colors.transparent,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryGreen.withOpacity(0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildPie() {
    if (_cats.isEmpty) {
      return const Text('Sem dados ainda',
          style: TextStyle(color: Colors.white54));
    }

    final total =
        _cats.fold(0.0, (s, c) => s + (c['total'] as num).toDouble());

    final sections = _cats.asMap().entries.map((e) {
      final val = (e.value['total'] as num).toDouble();
      final pct = total > 0 ? (val / total * 100).round() : 0;
      return PieChartSectionData(
        color: _colors[e.key % _colors.length],
        value: val,
        title: '$pct%',
        titleStyle: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 55,
      );
    }).toList();

    return Row(children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _cats.asMap().entries.map((e) {
            final val = (e.value['total'] as num).toDouble();
            final pct = total > 0 ? (val / total * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: _colors[e.key % _colors.length],
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${e.value['category']} $pct%',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            );
          }).toList(),
        ),
      ),
      SizedBox(
        width: 110,
        height: 110,
        child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 0,
            sections: sections)),
      ),
    ]);
  }

  Widget _buildTopCats() {
    final sorted = [..._cats]
      ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));
    final top3 = sorted.take(3).toList();
    final total =
        _cats.fold(0.0, (s, c) => s + (c['total'] as num).toDouble());

    if (top3.isEmpty) {
      return const Text('Sem dados ainda',
          style: TextStyle(color: Colors.white54));
    }

    return Row(
      children: top3.asMap().entries.map((e) {
        final cat = e.value;
        final val = (cat['total'] as num).toDouble();
        final pct = total > 0 ? (val / total * 100).round() : 0;

        final originalIdx = _cats.indexWhere(
            (c) => c['category'] == cat['category']);
        final color = _colors[(originalIdx >= 0 ? originalIdx : e.key) % _colors.length];

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: color.withOpacity(0.4), width: 0.5),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat['category'],
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_fmt(val),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  Text('$pct%',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ]),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen))
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dashboard',
                          style: TextStyle(
                              color: primaryGreen,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Resumo de Gastos',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            SizedBox(
                                height: 140, child: _buildLineChart()),
                            const SizedBox(height: 12),
                            Row(children: [
                              const Icon(Icons.arrow_upward,
                                  color: primaryGreen, size: 16),
                              const SizedBox(width: 4),
                              Text(_fmt(_income),
                                  style: const TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 20),
                              const Icon(Icons.arrow_downward,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text(_fmt(_expense),
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Top Categorias
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Top Categorias',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _buildTopCats(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Distribuição dos Gastos',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _buildPie(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}