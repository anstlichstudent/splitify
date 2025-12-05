import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();

  // State untuk tanggal dan anggota
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedMembers = ['Arya', 'Bryan', 'Nawwaf']; // Dummy members

  // State item dan pembagian biaya
  String? _selectedPayer;
  final List<_BillItem> _items = [];
  double _taxPercent = 0;
  double _servicePercent = 0;
  double _discountNominal = 0;

  Map<String, double> get _memberTotals {
    final totals = <String, double>{};
    if (_items.isEmpty) return totals;
    final subtotal = _items.fold<double>(0, (s, i) => s + i.price);
    if (subtotal == 0) return totals;

    final tax = subtotal * (_taxPercent / 100);
    final service = subtotal * (_servicePercent / 100);
    final discount = _discountNominal;

    // hitung kontribusi per member
    final memberSub = <String, double>{};
    for (final it in _items) {
      memberSub[it.member] = (memberSub[it.member] ?? 0) + it.price;
    }

    memberSub.forEach((member, sub) {
      final prop = sub / subtotal;
      final memberTax = tax * prop;
      final memberService = service * prop;
      final memberDiscount = discount * prop;
      totals[member] = sub + memberTax + memberService - memberDiscount;
    });

    return totals;
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _memberSearchController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      // Styling untuk Date Picker
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B5BFF), // primaryColor
              onPrimary: Colors.white,
              surface: Color(0xFF1B2A41), // inputFieldColor
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0D172A), // darkBlue
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- Logic Tambah Anggota (Dummy) ---
  void _addMember() {
    final newMember = _memberSearchController.text.trim();
    if (newMember.isNotEmpty && !_selectedMembers.contains(newMember)) {
      setState(() {
        _selectedMembers.add(newMember);
        _memberSearchController.clear();
      });
    } else if (_selectedMembers.contains(newMember)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$newMember sudah ada di daftar anggota.')),
      );
    }
  }

  // --- Logic Hapus Anggota ---
  void _removeMember(String member) {
    setState(() {
      _selectedMembers.remove(member);
    });
  }

  // --- Logic Lanjut (Simpan Aktivitas) ---
  void _continueActivity() {
    if (_formKey.currentState!.validate()) {
      if (_selectedMembers.isEmpty) {
        // Asumsi minimal 1 anggota selain diri sendiri
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambahkan minimal 1 anggota.')),
        );
        return;
      }

      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambah minimal 1 item pesanan.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas dibuat. Lanjut ke Bill Review.'),
        ),
      );
    }
  }

  Widget _buildLabeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildSummaryRow(String title, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            'Rp ${value.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    if ((_selectedPayer ?? '').isEmpty) {
      _selectedPayer = _selectedMembers.isNotEmpty
          ? _selectedMembers.first
          : null;
    }
    final name = _itemNameController.text.trim();
    final price = double.tryParse(_itemPriceController.text.trim()) ?? 0;
    final payer = _selectedPayer;
    if (name.isEmpty || price <= 0 || payer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama item, harga > 0, dan pilih pemesan.'),
        ),
      );
      return;
    }
    setState(() {
      _items.add(_BillItem(member: payer, name: name, price: price));
      _itemNameController.clear();
      _itemPriceController.clear();
    });
  }

  Future<void> _scanReceipt() async {
    // Navigate ke scan struk page dan tunggu result
    final result = await Navigator.of(context).pushNamed('/scan-struk');

    if (result != null && result is Map<String, dynamic>) {
      _processScannedReceipt(result);
    }
  }

  void _processScannedReceipt(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final tax = (data['tax'] as num?)?.toDouble() ?? 0;
    final service = (data['service_charge'] as num?)?.toDouble() ?? 0;
    final discount = (data['discount'] as num?)?.toDouble() ?? 0;

    setState(() {
      // Add items
      for (final item in items) {
        final name = item['name'] as String? ?? '';
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;

        if (name.isNotEmpty && price > 0) {
          final payer =
              _selectedPayer ??
              (_selectedMembers.isNotEmpty ? _selectedMembers.first : null);
          if (payer != null) {
            _items.add(
              _BillItem(member: payer, name: '$name x$qty', price: price * qty),
            );
          }
        }
      }

      // Update charges
      _taxPercent = tax > 0
          ? ((tax /
                        (_items.fold<double>(0, (s, i) => s + i.price) -
                            tax -
                            service +
                            discount)) *
                    100)
                .clamp(0, 100)
          : 0;
      _servicePercent = service > 0
          ? ((service /
                        (_items.fold<double>(0, (s, i) => s + i.price) -
                            tax -
                            service +
                            discount)) *
                    100)
                .clamp(0, 100)
          : 0;
      _discountNominal = discount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${items.length} item berhasil ditambahkan dari struk'),
        backgroundColor: const Color(0xFF3B5BFF),
      ),
    );
  }

  double get _subtotal => _items.fold<double>(0, (s, i) => s + i.price);
  double get _tax => _subtotal * (_taxPercent / 100);
  double get _service => _subtotal * (_servicePercent / 100);
  double get _grandTotal => _subtotal + _tax + _service - _discountNominal;

  // Helper Widget untuk Input Field
  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF0D172A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF3B5BFF).withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Color(0xFF3B5BFF).withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3B5BFF), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Wajib diisi.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);

    final String formattedDate = DateFormat(
      'dd MMMM yyyy',
    ).format(_selectedDate);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Buat Aktivitas Baru',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Nama Aktivitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInputField(
                    hint: 'Contoh: Makan Malam Angkatan',
                    controller: _activityNameController,
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'Tanggal Aktivitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.35)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: primaryColor,
                      ),
                      title: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text(
                          'Ubah',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Anggota Aktivitas Label
                  const Text(
                    'Anggota Aktivitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberSearchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Cari nama teman...',
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: darkBlue,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.35),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _addMember,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _selectedMembers
                        .map(
                          (member) => Chip(
                            backgroundColor: primaryColor.withOpacity(0.2),
                            label: Text(
                              member,
                              style: const TextStyle(color: Colors.white),
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white70,
                            ),
                            onDeleted: () => _removeMember(member),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  // Status Anggota Minimal
                  Text(
                    '* minimal 1 anggota untuk lanjut',
                    style: TextStyle(
                      color: _selectedMembers.isEmpty
                          ? Colors.redAccent
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- Items Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tambah Pesanan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _scanReceipt,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Scan Struk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value:
                                    _selectedPayer ??
                                    (_selectedMembers.isNotEmpty
                                        ? _selectedMembers.first
                                        : null),
                                dropdownColor: const Color(0xFF0D172A),
                                decoration: InputDecoration(
                                  labelText: 'Pemesan',
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF0D172A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: primaryColor.withOpacity(0.35),
                                    ),
                                  ),
                                ),
                                iconEnabledColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                                items: _selectedMembers
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedPayer = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildInputField(
                                hint: 'Nama item',
                                controller: _itemNameController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: _buildInputField(
                                hint: 'Harga',
                                controller: _itemPriceController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _addItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                        if (_items.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(color: Colors.white12),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Pemesan: ${item.member}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Rp ${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- Charges Section ---
                  const Text(
                    'Pajak & Layanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeled(
                          'Pajak (%)',
                          TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF0D172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: primaryColor.withOpacity(0.35),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _taxPercent = double.tryParse(val) ?? 0;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLabeled(
                          'Service (%)',
                          TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF0D172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: primaryColor.withOpacity(0.35),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _servicePercent = double.tryParse(val) ?? 0;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLabeled(
                    'Diskon (nominal)',
                    TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF0D172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(0.35),
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _discountNominal = double.tryParse(val) ?? 0;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Ringkasan ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Subtotal', _subtotal),
                        _buildSummaryRow('Pajak', _tax),
                        _buildSummaryRow('Service', _service),
                        _buildSummaryRow('Diskon', -_discountNominal),
                        const Divider(color: Colors.white12, height: 20),
                        _buildSummaryRow(
                          'Total Bayar',
                          _grandTotal,
                          isBold: true,
                        ),
                        if (_memberTotals.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Per orang:',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          ..._memberTotals.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    'Rp ${e.value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 80,
                  ), // Jarak untuk tombol Lanjut di bawah
                ],
              ),
            ),
          ),

          // --- 2. Tombol Lanjut (Fixed Bottom) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: darkBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: SafeArea(
                // Melindungi dari area sistem bawah
                child: ElevatedButton.icon(
                  onPressed: _continueActivity,
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    'Lanjut',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 50), // Lebar penuh
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillItem {
  final String member;
  final String name;
  final double price;

  _BillItem({required this.member, required this.name, required this.price});
}
