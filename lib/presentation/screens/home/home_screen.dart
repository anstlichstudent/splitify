import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitify/presentation/screens/friends/add-friends-screen.dart';
import 'package:splitify/presentation/screens/friends/friends_list_screen.dart';
import 'package:splitify/services/activity_service.dart';
import 'package:splitify/config/app_theme.dart';
import '../activities/create_activity_screen.dart';
import '../activities/activity_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ActivityService _activityService = ActivityService();
  List<Map<String, dynamic>> _activeActivities = [];
  bool _isLoading = true;

  final String _userName =
      FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ??
      'Pengguna';

  @override
  void initState() {
    super.initState();
    _loadActivities();
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

  // Load aktivitas dari Firestore
  Future<void> _loadActivities() async {
    try {
      final activities = await _activityService.getUserActivities();
      setState(() {
        _activeActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading activities: $e')));
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete aktivitas
  Future<void> _deleteActivity(String activityId) async {
    try {
      await _activityService.deleteActivity(activityId);
      await _loadActivities();
      if (mounted) {
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
        ).showSnackBar(SnackBar(content: Text('Error deleting activity: $e')));
      }
    }
  }

  // Konfirmasi delete dengan dialog
  void _showDeleteConfirmation(String activityId, String activityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A41),
        title: const Text(
          'Hapus Aktivitas',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Yakin ingin menghapus "$activityName"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteActivity(activityId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateAndCreateActivity(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateActivity()),
    );
    // Refresh data setelah create activity
    if (result != null) {
      await _loadActivities();
    }
  }

  // Helper Widget untuk setiap item aktivitas
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final String activityId = activity['id'] ?? '';
    final String activityName = activity['activityName'] ?? 'Unnamed Activity';
    final double grandTotal = _toDouble(activity['grandTotal']);
    final DateTime activityDate =
        activity['activityDate']?.toDate() ?? DateTime.now();
    final String formattedDate =
        '${activityDate.day} ${_getMonthName(activityDate.month)} ${activityDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Debug: cek activityId
            if (activityId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error: Activity ID tidak ditemukan'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ActivityDetailScreen(activityId: activityId),
              ),
            ).then((_) {
              // Refresh aktivitas setelah kembali dari detail/edit
              _loadActivities();
            });
          },
          onLongPress: () {
            _showActivityMenu(context, activityId, activityName);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Rp ${_formatCurrency(grandTotal.toInt())}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show menu edit/delete untuk activity
  void _showActivityMenu(
    BuildContext context,
    String activityId,
    String activityName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2A41),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text(
              'Edit Aktivitas',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to edit activity screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Hapus Aktivitas',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(activityId, activityName);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Format currency
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Get month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // Hapus AppBar karena kita akan menggunakan custom header di Body
      body: Stack(
        children: [
          // --- 1. Content List ---
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: 100,
            ), // Padding bawah untuk tombol FAB
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Custom Header Greeting ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Halo $_userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Ikon untuk Add Friend & Friends List
                    Row(
                      children: [
                        IconButton(
                          icon: const CircleAvatar(
                            backgroundColor: AppTheme.surface,
                            child: Icon(
                              Icons.people_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FriendsListScreen(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const CircleAvatar(
                            backgroundColor: AppTheme.surface,
                            child: Icon(
                              Icons.group_add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddFriendScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Daftar Kegiatan
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else if (_activeActivities.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.white30,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada aktivitas',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Buat aktivitas baru untuk memulai',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activeActivities.length,
                    itemBuilder: (context, index) {
                      return _buildActivityCard(_activeActivities[index]);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton.icon(
                onPressed: () => _navigateAndCreateActivity(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Buat Aktivitas Baru',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
