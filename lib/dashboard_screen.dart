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

  bool isLoading = true;
  double totalEntradas = 0;
  double totalSaidas = 0;
  List<Map<String, dynamic>> transactions = [];

  final List<Color> _catColors = [
    primaryGreen,
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFFFEB3B),
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = TransactionService();
    final data = await service.getTransactions();
    double ent = 0, sai = 0;
    for (var t in data) {
      final v = (t['value'] as num).toDouble();
      if (t['type'] == 'INCOME') ent += v; else sai += v;
    }
    setState(() {
      transactions = data;
      totalEntradas = ent;
      totalSaidas = sai;
      isLoading = false;
    });
  }

  String _formatCurrency(double v) {
    final formatted = v.abs().toStringAsFixed(2).replaceAll('.', ',');
    final parts = formatted.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }

  // Agrupa despesas por mês (últimos 8 meses)
  List<FlSpot> get _lineSpots {
    final now = DateTime.now();
    final Map<int, double> byMonth = {};
    for (var t in transactions) {
      if (t['type'] == 'EXPENSE') {
        final date = DateTime.tryParse(t['date'] ?? '');
        if (date != null) {
          final diff = (now.year - date.year) * 12 + (now.month - date.month);
          if (diff >= 0 && diff < 8) {
            byMonth[7 - diff] = (byMonth[7 - diff] ?? 0) + (t['value'] as num).toDouble();
          }
        }
      }
    }
    return List.generate(8, (i) => FlSpot(i.toDouble(), byMonth[i] ?? 0));
  }

  // Agrupa por categoria
  List<Map<String, dynamic>> get _categoryData {
    final Map<String, double> map = {};
    for (var t in transactions) {
      if (t['type'] == 'EXPENSE') {
        final cat = t['category'] ?? 'Outros';
        map[cat] = (map[cat] ?? 0) + (t['value'] as num).toDouble();
      }
    }
    final total = map.values.fold(0.0, (a, b) => a + b);
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.asMap().entries.map((e) => {
      'name': e.value.key,
      'value': e.value.value,
      'percent': total > 0 ? (e.value.value / total * 100).round() : 0,
      'color': _catColors[e.key % _catColors.length],
    }).toList();
  }

  Widget _buildLineChart() {
    final spots = _lineSpots;
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final labels = _last8MonthLabels();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 7,
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.2 : 100,
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
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(labels[i], style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
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
                colors: [primaryGreen.withOpacity(0.35), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _last8MonthLabels() {
    final months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    final now = DateTime.now();
    return List.generate(8, (i) {
      final month = DateTime(now.year, now.month - (7 - i));
      return months[month.month - 1];
    });
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Text("Sem dados ainda", style: TextStyle(color: Colors.white54));
    }
    return Row(
      children: [
        // Legenda
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((s) => Padding(
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
                      "${s['name']} ${s['percent']}%",
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
              sections: data.map((s) => PieChartSectionData(
                color: s['color'],
                value: s['value'] as double,
                title: "${s['percent']}%",
                titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                radius: 55,
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final catData = _categoryData;
    final top3 = catData.take(3).toList();

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : RefreshIndicator(
                color: primaryGreen,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        "Dashboard",
                        style: TextStyle(color: primaryGreen, fontSize: 26, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16),

                      // Gráfico de Linha
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Resumo de Gastos",
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            SizedBox(height: 140, child: _buildLineChart()),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.arrow_upward, color: primaryGreen, size: 16),
                                const SizedBox(width: 4),
                                Text(_formatCurrency(totalEntradas),
                                    style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 20),
                                const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                                const SizedBox(width: 4),
                                Text(_formatCurrency(totalSaidas),
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Top Categorias
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Top Categorias",
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            if (top3.isEmpty)
                              const Text("Sem dados ainda", style: TextStyle(color: Colors.white54))
                            else
                              Row(
                                children: top3.asMap().entries.map((e) {
                                  final cat = e.value;
                                  final color = cat['color'] as Color;
                                  return Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(cat['name'],
                                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(_formatCurrency(cat['value'] as double),
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          Text("${cat['percent']}%",
                                              style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Distribuição dos Gastos
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Distribuição dos Gastos",
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _buildPieChart(catData),
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