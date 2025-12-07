import 'package:flutter/material.dart';
import '../services/activity_service.dart';

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
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Edit'),
                onTap: () {
                  // TODO: Navigate to edit screen
                },
              ),
              PopupMenuItem(
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                onTap: () => _showDeleteConfirmation(context),
              ),
            ],
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

          final members = List<String>.from(activity['members'] ?? []);
          final items = (activity['items'] ?? []).cast<Map<String, dynamic>>();
          final taxPercent = (activity['taxPercent'] as num?)?.toDouble() ?? 0;
          final servicePercent =
              (activity['servicePercent'] as num?)?.toDouble() ?? 0;
          final discountNominal =
              (activity['discountNominal'] as num?)?.toDouble() ?? 0;

          final subtotal = items.fold<double>(
            0,
            (sum, item) => sum + (((item['price'] as num?)?.toDouble()) ?? 0),
          );
          final tax = subtotal * (taxPercent / 100);
          final service = subtotal * (servicePercent / 100);
          final grandTotal = subtotal + tax + service - discountNominal;

          // Group items by member
          final itemsByMember = <String, List<Map<String, dynamic>>>{};
          for (final item in items) {
            final member = item['member'] as String? ?? 'Unknown';
            itemsByMember.putIfAbsent(member, () => []);
            itemsByMember[member]!.add(item);
          }

          // Calculate total per member
          final memberTotals = <String, double>{};
          for (final member in members) {
            memberTotals[member] = 0;
          }

          for (final item in items) {
            final member = item['member'] as String? ?? 'Unknown';
            final price = (item['price'] as num?)?.toDouble() ?? 0;
            memberTotals[member] = (memberTotals[member] ?? 0) + price;
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
                Text(
                  '${activityDate.day} ${_getMonthName(activityDate.month)} ${activityDate.year}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                        final itemPrice =
                            (item['price'] as num?)?.toDouble() ?? 0;
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
