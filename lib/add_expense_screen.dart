import 'package:flutter/material.dart';
import 'services/transaction_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1A1A1A);

  String _amountStr = "0";
  String? _selectedCategory;
  String? _selectedPayment;
  DateTime _selectedDate = DateTime.now();
  bool isLoading = false;
  String? successMessage;
  String? errorMessage;

  final List<String> _categories = [
    'Alimentação', 'Contas Fixas', 'Transporte', 'Lazer',
    'Saúde', 'Educação', 'Outros'
  ];

  final List<String> _paymentMethods = [
    'Dinheiro', 'Cartão de Crédito', 'Cartão de Débito', 'Pix'
  ];

  // Formata a string de centavos para exibição
  String get _formattedAmount {
    final padded = _amountStr.padLeft(3, '0');
    final intPart = padded.substring(0, padded.length - 2);
    final decPart = padded.substring(padded.length - 2);
    final cleaned = intPart.replaceAll(RegExp(r'^0+'), '');
    final display = cleaned.isEmpty ? '0' : cleaned;
    final withDots = display.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $withDots,$decPart';
  }

  // Formata a data para exibição
  String get _formattedDate {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;
    final prefix = isToday ? 'Hoje, ' : '';
    return '$prefix${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  // Formata a data para enviar ao backend (ISO 8601: yyyy-MM-dd)
  String get _dateForApi =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  void _onKey(String key) {
    setState(() {
      successMessage = null;
      errorMessage = null;
      if (key == '<') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (key == ',') {
        // Decimais já estão fixos nas últimas 2 casas
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else if (_amountStr.length < 10) {
          _amountStr += key;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primaryGreen,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A1A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final amountCents = int.tryParse(_amountStr) ?? 0;

    if (amountCents == 0) {
      setState(() => errorMessage = "Digite um valor maior que zero");
      return;
    }
    if (_selectedCategory == null) {
      setState(() => errorMessage = "Selecione uma categoria");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final transactionService = TransactionService();
      final value = amountCents / 100.0;

      final result = await transactionService.addTransaction(
        value: value,
        category: _selectedCategory!,
        paymentMethod: _selectedPayment ?? 'Outros',
        type: 'EXPENSE',
        date: _dateForApi,
      );

      if (result) {
        setState(() {
          successMessage = "Gasto adicionado com sucesso! ✓";
          _amountStr = "0";
          _selectedCategory = null;
          _selectedPayment = null;
          _selectedDate = DateTime.now();
        });
      } else {
        setState(() => errorMessage = "Erro ao salvar. Verifique sua conexão.");
      }
    } catch (e) {
      setState(() => errorMessage = "Erro no servidor: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _keyButton(String label) {
    final isBackspace = label == '<';
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKey(label),
        child: Container(
          margin: const EdgeInsets.all(4),
          height: 56,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, color: Colors.white70, size: 22)
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _selectorTile({
    required String hint,
    required IconData icon,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
    GestureTapCallback? onTapOverride,
  }) {
    return GestureDetector(
      onTap: onTapOverride ?? () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: cardBg,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 12),
              ...options.map((o) => ListTile(
                title: Text(o, style: const TextStyle(color: Colors.white)),
                trailing: selected == o
                    ? const Icon(Icons.check, color: primaryGreen)
                    : null,
                onTap: () => Navigator.pop(context, o),
              )),
              const SizedBox(height: 12),
            ],
          ),
        );
        if (result != null) onSelected(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected ?? hint,
                style: TextStyle(
                  color: selected != null ? Colors.white : Colors.white54,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.close, color: Colors.white70),
                  const Expanded(
                    child: Text(
                      "Adicionar Gasto",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.add, color: primaryGreen),
                ],
              ),
            ),

            // Valor
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _formattedAmount,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Campos seletores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Categoria
                  _selectorTile(
                    hint: "Categoria   Selecione",
                    icon: Icons.layers_outlined,
                    options: _categories,
                    selected: _selectedCategory,
                    onSelected: (v) => setState(() => _selectedCategory = v),
                  ),

                  const SizedBox(height: 8),

                  // Data — abre o date picker nativo
                  _selectorTile(
                    hint: _formattedDate,
                    icon: Icons.calendar_today_outlined,
                    options: [],
                    selected: _formattedDate,
                    onSelected: (_) {},
                    onTapOverride: _pickDate,
                  ),

                  const SizedBox(height: 8),

                  // Método de pagamento
                  _selectorTile(
                    hint: "Método de Pagamento   Selecione",
                    icon: Icons.attach_money,
                    options: _paymentMethods,
                    selected: _selectedPayment,
                    onSelected: (v) => setState(() => _selectedPayment = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Teclado numérico
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(children: ['1', '2', '3'].map(_keyButton).toList()),
                  Row(children: ['4', '5', '6'].map(_keyButton).toList()),
                  Row(children: ['7', '8', '9'].map(_keyButton).toList()),
                  Row(children: [',', '0', '<'].map(_keyButton).toList()),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Feedback
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            if (successMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  successMessage!,
                  style: const TextStyle(color: primaryGreen, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 8),

            // Botão Adicionar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Adicionar",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}