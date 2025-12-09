import 'package:flutter/material.dart';
import '../../../data/models/bill_item.dart';
import '../../../services/activity_service.dart';

class ManualInputScreen extends StatefulWidget {
  final String activityName;
  final DateTime activityDate;
  final List<String> members;
  final List<String> memberUids;

  const ManualInputScreen({
    super.key,
    required this.activityName,
    required this.activityDate,
    required this.members,
    required this.memberUids,
  });

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final ActivityService _activityService = ActivityService();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _taxValueController = TextEditingController();
  final TextEditingController _serviceValueController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  List<BillItem> _items = [];
  String? _selectedPayer;
  double _taxPercent = 0;
  double _taxNominal = 0;
  double _servicePercent = 0;
  double _serviceNominal = 0;
  double _discountNominal = 0;
  bool _isSaving = false;

  // Tax & Service type: true = persen, false = nominal
  bool _taxIsPersen = true;
  bool _serviceIsPersen = true;

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _taxValueController.dispose();
    _serviceValueController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_selectedPayer == null || _selectedPayer!.isEmpty) {
      _selectedPayer = widget.members.isNotEmpty ? widget.members.first : null;
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
      _items.add(BillItem(member: payer, name: name, price: price));
      _itemNameController.clear();
      _itemPriceController.clear();
    });
  }

  Future<void> _saveActivity() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambah minimal 1 item pesanan.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Hitung pajak dan service berdasarkan tipe (persen atau nominal)
      double finalTaxPercent = _taxIsPersen ? _taxPercent : 0;
      double finalServicePercent = _serviceIsPersen ? _servicePercent : 0;
      double finalDiscount = _discountNominal;

      // Jika nominal, convert ke persen berdasarkan subtotal
      final subtotal = _items.fold<double>(0, (s, i) => s + i.price);
      if (!_taxIsPersen && _taxNominal > 0) {
        finalTaxPercent = ((_taxNominal / subtotal) * 100);
      }
      if (!_serviceIsPersen && _serviceNominal > 0) {
        finalServicePercent = ((_serviceNominal / subtotal) * 100);
      }

      await _activityService.createActivity(
        activityName: widget.activityName,
        activityDate: widget.activityDate,
        members: widget.members,
        memberUids: widget.memberUids,
        items: _items,
        taxPercent: finalTaxPercent,
        servicePercent: finalServicePercent,
        discountNominal: finalDiscount,
        inputMethod: 'manual',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivitas berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double get _subtotal => _items.fold<double>(0, (s, i) => s + i.price);

  double get _tax {
    if (_taxIsPersen) {
      return _subtotal * (_taxPercent / 100);
    } else {
      return _taxNominal;
    }
  }

  double get _service {
    if (_serviceIsPersen) {
      return _subtotal * (_servicePercent / 100);
    } else {
      return _serviceNominal;
    }
  }

  double get _grandTotal => _subtotal + _tax + _service - _discountNominal;

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Input Manual',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.white10,
                  color: primaryColor,
                ),
                const SizedBox(height: 20),

                // Tambah Item
                const Text(
                  'Tambah Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Dropdown Pemesan
                DropdownButtonFormField<String>(
                  value: _selectedPayer,
                  dropdownColor: const Color(0xFF0D172A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Dipesan oleh',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: widget.members
                      .map(
                        (member) => DropdownMenuItem(
                          value: member,
                          child: Text(member),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPayer = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Nama Item
                TextField(
                  controller: _itemNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nama Item',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Harga
                TextField(
                  controller: _itemPriceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Harga',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Tambah
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Tambah Item',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Daftar Items
                if (_items.isNotEmpty) ...[
                  const Text(
                    'Daftar Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        color: const Color(0xFF1B2A41),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Oleh: ${item.member}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rp ${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Pajak & Service
                const Text(
                  'Pajak & Layanan (Opsional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // PAjak
                const Text(
                  'Pajak',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Persen (%)'),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Nominal (Rp)'),
                          ),
                        ],
                        selected: <bool>{_taxIsPersen},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _taxIsPersen = newSelection.first;
                            _taxValueController.clear();
                            _taxPercent = 0;
                            _taxNominal = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _taxValueController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _taxIsPersen ? 'Pajak (%))' : 'Pajak (Rp)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() {
                    if (_taxIsPersen) {
                      _taxPercent = double.tryParse(val) ?? 0;
                      _taxNominal = 0;
                    } else {
                      _taxNominal = double.tryParse(val) ?? 0;
                      _taxPercent = 0;
                    }
                  }),
                ),
                const SizedBox(height: 16),

                // Service
                const Text(
                  'Service',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Persen (%)'),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Nominal (Rp)'),
                          ),
                        ],
                        selected: <bool>{_serviceIsPersen},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _serviceIsPersen = newSelection.first;
                            _serviceValueController.clear();
                            _servicePercent = 0;
                            _serviceNominal = 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _serviceValueController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _serviceIsPersen
                        ? 'Service (%)'
                        : 'Service (Rp)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() {
                    if (_serviceIsPersen) {
                      _servicePercent = double.tryParse(val) ?? 0;
                      _serviceNominal = 0;
                    } else {
                      _serviceNominal = double.tryParse(val) ?? 0;
                      _servicePercent = 0;
                    }
                  }),
                ),
                const SizedBox(height: 16),

                // Diskon
                const Text(
                  'Diskon',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Diskon (Rp)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF0D172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(
                    () => _discountNominal = double.tryParse(val) ?? 0,
                  ),
                ),
                const SizedBox(height: 24),

                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2A41),
                    borderRadius: BorderRadius.circular(12),
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
                      if (_discountNominal > 0)
                        _buildSummaryRow('Diskon', -_discountNominal),
                      const Divider(color: Colors.white30),
                      _buildSummaryRow('TOTAL', _grandTotal, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Save Button
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
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveActivity,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Aktivitas',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 50),
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
}
