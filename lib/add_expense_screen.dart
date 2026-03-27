import 'package:flutter/material.dart';
import 'services/transaction_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  final VoidCallback? onSuccess;

  const AddExpenseScreen({super.key, this.transaction, this.onSuccess});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1A1A1A);

  late String _type;

  String _amountStr = '0';
  String? _selectedCategory;
  String? _selectedPayment;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  final _descController = TextEditingController();

  bool get _isEditing => widget.transaction != null;

  final _expenseCategories = const [
    'Alimentação', 'Contas Fixas', 'Transporte',
    'Lazer', 'Saúde', 'Educação', 'Outros',
  ];

  final _incomeCategories = const [
    'Salário', 'Freelance', 'Investimentos',
    'Presente', 'Reembolso', 'Outros',
  ];

  final _paymentMethods = const [
    'Dinheiro', 'Cartão de Crédito', 'Cartão de Débito', 'Pix', 'VR/VA',
  ];

  List<String> get _categories =>
      _type == 'INCOME' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    if (t != null) {
      _type = t['type'] as String? ?? 'EXPENSE';
      final amount = (t['amount'] as num).toDouble();
      _amountStr = (amount * 100).round().toString();
      _descController.text = t['description'] as String? ?? '';
      _selectedCategory = t['category'] as String?;
      final raw = t['date'];
      if (raw is String) {
        _selectedDate = DateTime.tryParse(raw) ?? DateTime.now();
      }
    } else {
      _type = 'EXPENSE';
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  String get _formattedAmount {
    final padded = _amountStr.padLeft(3, '0');
    final intPart = padded.substring(0, padded.length - 2);
    final decPart = padded.substring(padded.length - 2);
    final clean = intPart.replaceAll(RegExp(r'^0+'), '');
    final display = clean.isEmpty ? '0' : clean;
    final withDots = display.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $withDots,$decPart';
  }

  String get _formattedDate {
    final months = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
        'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
    final now = DateTime.now();
    final isToday = _selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year;
    final prefix = isToday ? 'Hoje, ' : '';
    return '$prefix${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  String get _dateForApi =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  void _onKey(String key) {
    setState(() {
      _successMessage = null;
      _errorMessage = null;
      if (key == '<') {
        _amountStr = _amountStr.length > 1
            ? _amountStr.substring(0, _amountStr.length - 1)
            : '0';
      } else if (key != ',') {
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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: primaryGreen,
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF1A1A1A),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final cents = int.tryParse(_amountStr) ?? 0;
    final desc = _descController.text.trim();

    if (cents == 0) {
      setState(() => _errorMessage = 'Digite um valor maior que zero');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Selecione uma categoria');
      return;
    }
    if (desc.isEmpty) {
      setState(() => _errorMessage = 'Informe uma descrição');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      bool ok;

      if (_isEditing) {
        ok = await TransactionService().updateTransaction(
          id: widget.transaction!['id'] as int,
          amount: cents / 100.0,
          description: desc,
          category: _selectedCategory!,
          type: _type,
          date: _dateForApi,
        );
      } else {
        ok = await TransactionService().addTransaction(
          amount: cents / 100.0,
          description: desc,
          category: _selectedCategory!,
          type: _type,
          date: _dateForApi,
        );
      }

      if (ok) {
        widget.onSuccess?.call();
        if (_isEditing) {
          if (mounted) Navigator.pop(context);
        } else {
          setState(() {
            _successMessage = _type == 'INCOME'
                ? 'Ganho adicionado com sucesso! ✓'
                : 'Gasto adicionado com sucesso! ✓';
            _amountStr = '0';
            _selectedCategory = null;
            _selectedPayment = null;
            _selectedDate = DateTime.now();
            _descController.clear();
          });
        }
      } else {
        setState(() => _errorMessage = 'Erro ao salvar. Verifique sua conexão.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro no servidor: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Excluir transação',
            style: TextStyle(color: Colors.white)),
        content: const Text('Tem certeza que deseja excluir esta transação?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final ok = await TransactionService()
          .deleteTransaction(widget.transaction!['id'] as int);
      if (ok) {
        widget.onSuccess?.call();
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _errorMessage = 'Erro ao excluir. Tente novamente.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro no servidor: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _keyBtn(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKey(label),
        child: Container(
          margin: const EdgeInsets.all(4),
          height: 52,
          decoration: BoxDecoration(
              color: cardBg, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: label == '<'
              ? const Icon(Icons.backspace_outlined,
                  color: Colors.white70, size: 22)
              : Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _tile({
    required String hint,
    required IconData icon,
    String? selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: cardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selected ?? hint,
              style: TextStyle(
                  color: selected != null ? Colors.white : Colors.white54,
                  fontSize: 15),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ]),
      ),
    );
  }

  Future<void> _pickFromList(
      List<String> options, ValueChanged<String> onPick) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 12),
          ...options.map((o) => ListTile(
                title: Text(o, style: const TextStyle(color: Colors.white)),
                trailing: _selectedCategory == o
                    ? const Icon(Icons.check, color: primaryGreen)
                    : null,
                onTap: () => Navigator.pop(context, o),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
    if (result != null) onPick(result);
  }

  @override
  Widget build(BuildContext context) {
    final isModal = _isEditing;

    final body = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (isModal || Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Icon(Icons.close, color: Colors.white70),
              ),
              Expanded(
                child: Text(
                  _isEditing
                      ? 'Editar Transação'
                      : (_type == 'INCOME'
                          ? 'Adicionar Ganho'
                          : 'Adicionar Gasto'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _isLoading ? null : _confirmDelete,
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                )
              else
                const SizedBox(width: 24),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  if (!_isEditing) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          _typeBtn('EXPENSE', 'Gasto', Colors.red),
                          _typeBtn('INCOME', 'Ganho', primaryGreen),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Text(
                      _formattedAmount,
                      style: TextStyle(
                          color:
                              _type == 'INCOME' ? primaryGreen : Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Campos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.edit_outlined,
                              color: Colors.white54, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _descController,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Descrição',
                                hintStyle:
                                    TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      _tile(
                        hint: 'Categoria   Selecione',
                        icon: Icons.layers_outlined,
                        selected: _selectedCategory,
                        onTap: () => _pickFromList(
                          _categories,
                          (v) => setState(() => _selectedCategory = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _tile(
                        hint: _formattedDate,
                        icon: Icons.calendar_today_outlined,
                        selected: _formattedDate,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 8),
                      _tile(
                        hint: 'Método de Pagamento   Selecione',
                        icon: Icons.attach_money,
                        selected: _selectedPayment,
                        onTap: () => _pickFromList(
                          _paymentMethods,
                          (v) => setState(() => _selectedPayment = v),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(children: [
                      Row(children: ['1', '2', '3'].map(_keyBtn).toList()),
                      Row(children: ['4', '5', '6'].map(_keyBtn).toList()),
                      Row(children: ['7', '8', '9'].map(_keyBtn).toList()),
                      Row(children: [',', '0', '<'].map(_keyBtn).toList()),
                    ]),
                  ),

                  const SizedBox(height: 6),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center),
                    ),
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(_successMessage!,
                          style: const TextStyle(
                              color: primaryGreen, fontSize: 13),
                          textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _type == 'INCOME' ? primaryGreen : Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isEditing ? 'Salvar alterações' : 'Adicionar',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );

    if (isModal) {
      return Scaffold(backgroundColor: darkBg, body: body);
    }
    return body;
  }

  Widget _typeBtn(String type, String label, Color activeColor) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategory = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? activeColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: activeColor, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? activeColor : Colors.white38,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}