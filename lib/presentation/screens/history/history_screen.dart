import 'package:flutter/material.dart';
import '../../../services/activity_service.dart';
import '../activities/activity_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ActivityService _activityService = ActivityService();
  List<Map<String, dynamic>> _allActivities = [];
  bool _isLoading = true;

  String _selectedFilter = 'all'; // 'all', 'week', 'month', 'year'
  String _selectedStatus = 'all'; // 'all', 'active', 'completed'
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final activities = await _activityService.getUserActivities();
      setState(() {
        _allActivities = activities;
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

  bool _isWithinDateRange(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    switch (_selectedFilter) {
      case 'week':
        return difference <= 7;
      case 'month':
        return difference <= 30;
      case 'year':
        return difference <= 365;
      default:
        return true;
    }
  }

  bool _matchesStatus(Map<String, dynamic> activity) {
    if (_selectedStatus == 'all') return true;

    final status = activity['status'] ?? 'active';
    return _selectedStatus == status;
  }

  List<Map<String, dynamic>> get _filteredActivities {
    return _allActivities.where((activity) {
      final activityDate = activity['activityDate']?.toDate() ?? DateTime.now();
      final activityName = (activity['activityName'] ?? '').toLowerCase();

      final matchesDate = _isWithinDateRange(activityDate);
      final matchesStatus = _matchesStatus(activity);
      final matchesSearch = activityName.contains(_searchQuery);

      return matchesDate && matchesStatus && matchesSearch;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _groupedByDate {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final activity in _filteredActivities) {
      final date = activity['activityDate']?.toDate() ?? DateTime.now();
      final dateKey = _getDateGroup(date);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(activity);
    }

    // Sort dates by recency
    final sortedGroups = <String, List<Map<String, dynamic>>>{};
    final orderedKeys = grouped.keys.toList()
      ..sort((a, b) => _getDateGroupValue(b).compareTo(_getDateGroupValue(a)));

    for (final key in orderedKeys) {
      sortedGroups[key] = grouped[key]!;
    }

    return sortedGroups;
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hari Ini';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Kemarin';
    if (now.difference(dateOnly).inDays <= 7) return 'Minggu Ini';
    if (now.difference(dateOnly).inDays <= 30) return 'Bulan Ini';
    if (dateOnly.year == today.year) return 'Tahun Ini';

    return '${dateOnly.year}';
  }

  int _getDateGroupValue(String group) {
    switch (group) {
      case 'Hari Ini':
        return 0;
      case 'Kemarin':
        return 1;
      case 'Minggu Ini':
        return 2;
      case 'Bulan Ini':
        return 3;
      case 'Tahun Ini':
        return 4;
      default:
        return 5;
    }
  }

  double _calculateTotalSpent() {
    return _filteredActivities.fold<double>(
      0,
      (sum, activity) => sum + (_toDouble(activity['grandTotal'])),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

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
    const Color darkBlue = Color(0xFF000518);
    const Color primaryColor = Color(0xFF3B5BFF);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Riwayat Aktivitas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cari aktivitas...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1B2A41),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Date Filter
                        _buildFilterChip(
                          'Semua',
                          _selectedFilter == 'all',
                          () => setState(() => _selectedFilter = 'all'),
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Minggu Ini',
                          _selectedFilter == 'week',
                          () => setState(() => _selectedFilter = 'week'),
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Bulan Ini',
                          _selectedFilter == 'month',
                          () => setState(() => _selectedFilter = 'month'),
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Tahun Ini',
                          _selectedFilter == 'year',
                          () => setState(() => _selectedFilter = 'year'),
                          Icons.calendar_today,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Semua Status',
                          _selectedStatus == 'all',
                          () => setState(() => _selectedStatus = 'all'),
                          Icons.filter_list,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Aktif',
                          _selectedStatus == 'active',
                          () => setState(() => _selectedStatus = 'active'),
                          Icons.play_circle,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Selesai',
                          _selectedStatus == 'completed',
                          () => setState(() => _selectedStatus = 'completed'),
                          Icons.check_circle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Summary
                  if (_filteredActivities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Total Aktivitas',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_filteredActivities.length}',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: primaryColor.withOpacity(0.3),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Total Pengeluaran',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${_formatCurrency(_calculateTotalSpent().toInt())}',
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Timeline View
                  if (_filteredActivities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.white30),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada aktivitas',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _groupedByDate.entries.map((entry) {
                          final dateGroup = entry.key;
                          final activities = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Group Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  dateGroup,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Activities in this group
                              ...activities.map((activity) {
                                final activityName =
                                    activity['activityName'] ?? 'Aktivitas';
                                final activityDate =
                                    activity['activityDate']?.toDate() ??
                                    DateTime.now();
                                final grandTotal = _toDouble(
                                  activity['grandTotal'],
                                );
                                final formattedDate =
                                    '${activityDate.day} ${_getMonthName(activityDate.month)}';

                                return Card(
                                  color: const Color(0xFF1B2A41),
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ActivityDetailScreen(
                                                activityId: activity['id'],
                                              ),
                                        ),
                                      ).then((_) => _loadActivities());
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  activityName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.white54,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      formattedDate,
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    if (activity['inputMethod'] !=
                                                        null)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              activity['inputMethod'] ==
                                                                  'scan'
                                                              ? Colors.green
                                                                    .withOpacity(
                                                                      0.2,
                                                                    )
                                                              : Colors.blue
                                                                    .withOpacity(
                                                                      0.2,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          activity['inputMethod'] ==
                                                                  'scan'
                                                              ? 'Scan'
                                                              : 'Manual',
                                                          style: TextStyle(
                                                            color:
                                                                activity['inputMethod'] ==
                                                                    'scan'
                                                                ? Colors.green
                                                                : Colors.blue,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Rp ${_formatCurrency(grandTotal.toInt())}',
                                                style: const TextStyle(
                                                  color: Color(0xFF3B5BFF),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (activity['status'] ==
                                                          'completed')
                                                      ? Colors.green
                                                            .withOpacity(0.2)
                                                      : const Color(
                                                          0xFF3B5BFF,
                                                        ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  (activity['status'] ==
                                                          'completed')
                                                      ? 'Selesai'
                                                      : 'Aktif',
                                                  style: TextStyle(
                                                    color:
                                                        (activity['status'] ==
                                                            'completed')
                                                        ? Colors.green
                                                        : const Color(
                                                            0xFF3B5BFF,
                                                          ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onPressed,
    IconData icon,
  ) {
    const Color primaryColor = Color(0xFF3B5BFF);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.white54,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (_) => onPressed(),
      selected: isSelected,
      backgroundColor: Colors.transparent,
      selectedColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white54,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.white24,
        width: 1,
      ),
    );
  }
}
