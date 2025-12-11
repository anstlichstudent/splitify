import 'package:flutter/material.dart';
import '../../../services/activity_service.dart';
import 'manual_input_screen.dart';
import '../../../data/models/bill_item.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ActivityService _activityService = ActivityService();
  late Future<Map<String, dynamic>?> _activityFuture;

  @override
  void initState() {
    super.initState();
    _activityFuture = _activityService.getActivityById(widget.activityId);
  }

  // Helper function untuk konversi number yang aman
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas?'),
        content: const Text('Aktivitas yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _activityService.deleteActivity(widget.activityId);
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aktivitas berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Detail Aktivitas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _activityFuture,
            builder: (context, snapshot) {
              final isCompleted =
                  snapshot.data != null &&
                  snapshot.data!['status'] == 'completed';

              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    // Copied edit logic... (omitted for brevity, assume existing logic)
                    // Get current activity data
                    final activity = await _activityFuture;
                    if (activity == null || !mounted) return;

                    final members = List<String>.from(
                      activity['members'] ?? [],
                    );
                    List<BillItem> billItems = [];
                    if (activity['items'] != null) {
                      for (var item in activity['items']) {
                        if (item is Map<String, dynamic>) {
                          billItems.add(
                            BillItem(
                              member: item['member'] ?? 'Unknown',
                              name: item['name'] ?? 'Item',
                              price: _toDouble(item['price']),
                            ),
                          );
                        }
                      }
                    }

                    final taxPercent = _toDouble(activity['taxPercent']);
                    final servicePercent = _toDouble(
                      activity['servicePercent'],
                    );
                    final discountNominal = _toDouble(
                      activity['discountNominal'],
                    );
                    final activityName =
                        activity['activityName'] ?? 'Aktivitas';

                    DateTime activityDate;
                    try {
                      if (activity['activityDate'] is DateTime) {
                        activityDate = activity['activityDate'];
                      } else if (activity['activityDate'] != null) {
                        try {
                          activityDate = activity['activityDate'].toDate();
                        } catch (e) {
                          activityDate = DateTime.parse(
                            activity['activityDate'].toString(),
                          );
                        }
                      } else {
                        activityDate = DateTime.now();
                      }
                    } catch (e) {
                      activityDate = DateTime.now();
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManualInputScreen(
                          activityId: widget.activityId,
                          activityName: activityName,
                          activityDate: activityDate,
                          members: members,
                          memberUids: const [],
                          initialItems: billItems,
                          initialTax: taxPercent,
                          initialService: servicePercent,
                          initialDiscount: discountNominal,
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        _activityFuture = _activityService.getActivityById(
                          widget.activityId,
                        );
                      });
                    });
                  } else if (value == 'toggle_status') {
                    final activity = await _activityFuture;
                    if (activity == null || !mounted) return;

                    final currentIsCompleted =
                        activity['status'] == 'completed';
                    await _activityService.updateActivityStatus(
                      widget.activityId,
                      currentIsCompleted ? 'active' : 'completed',
                    );

                    setState(() {
                      _activityFuture = _activityService.getActivityById(
                        widget.activityId,
                      );
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            currentIsCompleted
                                ? 'Aktivitas ditandai aktif kembali'
                                : 'Aktivitas ditandai selesai',
                          ),
                          backgroundColor: currentIsCompleted
                              ? Colors.blue
                              : Colors.green,
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context);
                  }
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(
                        isCompleted ? 'Tandai Aktif' : 'Tandai Selesai',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Aktivitas tidak ditemukan',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final activity = snapshot.data!;
          final activityName = activity['activityName'] ?? 'Aktivitas';

          // Handle Firestore Timestamp
          DateTime activityDate;
          try {
            if (activity['activityDate'] is DateTime) {
              activityDate = activity['activityDate'];
            } else if (activity['activityDate'] != null) {
              // Jika Firestore Timestamp, akses toDate()
              try {
                activityDate = activity['activityDate'].toDate();
              } catch (e) {
                // Fallback: try to parse as string
                activityDate = DateTime.parse(
                  activity['activityDate'].toString(),
                );
              }
            } else {
              activityDate = DateTime.now();
            }
          } catch (e) {
            activityDate = DateTime.now();
          }

          // Ambil data langsung dari Firestore (sudah dihitung saat save)
          final members = List<String>.from(activity['members'] ?? []);
          final items = (activity['items'] ?? []).cast<Map<String, dynamic>>();

          // Data yang sudah tersimpan di Firestore
          final taxPercent = _toDouble(activity['taxPercent']);
          final servicePercent = _toDouble(activity['servicePercent']);
          final discountNominal = _toDouble(activity['discountNominal']);
          final subtotal = _toDouble(activity['subtotal']);
          final grandTotal = _toDouble(activity['grandTotal']);

          // Hitung tax dan service untuk ditampilkan
          final tax = subtotal * (taxPercent / 100);
          final service = subtotal * (servicePercent / 100);

          // Group items by member untuk ditampilkan
          final itemsByMember = <String, List<Map<String, dynamic>>>{};
          for (final item in items) {
            final member = item['member'] as String? ?? 'Unknown';
            itemsByMember.putIfAbsent(member, () => []);
            itemsByMember[member]!.add(item);
          }

          // Ambil member totals dari Firestore (jika ada) atau hitung dari items
          final memberTotals = <String, double>{};
          if (activity['memberTotals'] != null) {
            // Gunakan data yang sudah dihitung
            final savedTotals = Map<String, dynamic>.from(
              activity['memberTotals'],
            );
            savedTotals.forEach((key, value) {
              memberTotals[key] = _toDouble(value);
            });
          } else {
            // Fallback: hitung dari items (untuk kompatibilitas data lama)
            for (final member in members) {
              memberTotals[member] = 0;
            }
            for (final item in items) {
              final member = item['member'] as String? ?? 'Unknown';
              final price = _toDouble(item['price']);
              memberTotals[member] = (memberTotals[member] ?? 0) + price;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama & Tanggal
                Text(
                  activityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${activityDate.day} ${_getMonthName(activityDate.month)} ${activityDate.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (activity['inputMethod'] != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: activity['inputMethod'] == 'scan'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: activity['inputMethod'] == 'scan'
                                ? Colors.green.withOpacity(0.5)
                                : Colors.blue.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              activity['inputMethod'] == 'scan'
                                  ? Icons.qr_code_scanner
                                  : Icons.edit,
                              size: 14,
                              color: activity['inputMethod'] == 'scan'
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activity['inputMethod'] == 'scan'
                                  ? 'Scan Struk'
                                  : 'Input Manual',
                              style: TextStyle(
                                color: activity['inputMethod'] == 'scan'
                                    ? Colors.green
                                    : Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Members
                const Text(
                  'Peserta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: members
                      .map(
                        (member) => Chip(
                          label: Text(member),
                          backgroundColor: primaryColor.withOpacity(0.3),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),

                // Items
                const Text(
                  'Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...itemsByMember.entries.map((entry) {
                  final member = entry.key;
                  final memberItems = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B5BFF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member,
                          style: const TextStyle(
                            color: Color(0xFF3B5BFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...memberItems.map((item) {
                        final itemName = item['name'] as String? ?? 'Item';
                        final itemPrice = _toDouble(item['price']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                itemName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Rp ${itemPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),

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
                      _buildSummaryRow('Subtotal', subtotal),
                      _buildSummaryRow('Pajak', tax),
                      _buildSummaryRow('Service', service),
                      if (discountNominal > 0)
                        _buildSummaryRow('Diskon', -discountNominal),
                      const Divider(color: Colors.white30),
                      _buildSummaryRow('TOTAL', grandTotal, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Per Member Total
                const Text(
                  'Total Per Peserta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...memberTotals.entries.map((entry) {
                  return Card(
                    color: const Color(0xFF1B2A41),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${entry.value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF3B5BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
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
