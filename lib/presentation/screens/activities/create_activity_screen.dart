import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk memformat tanggal
import 'choose_method_screen.dart';
import '../../../core/constants/colors.dart'; // Asumsikan path constants
import 'widget/activity_input_field.dart'; // Asumsikan path widget kustom
import '../../../services/user_service.dart';

class CreateActivity extends StatefulWidget {
  const CreateActivity({super.key});

  @override
  State<CreateActivity> createState() => _CreateActivityState();
}

class _CreateActivityState extends State<CreateActivity> {
  final TextEditingController _activityNameController = TextEditingController();
  final UserService _userService = UserService();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _selectedMembers =
      []; // Store friend data {uid, name, email, photoUrl}
  List<Map<String, dynamic>> _friendsList = []; // All friends list
  bool _isLoadingFriends = false;

  // Menggunakan Formatter untuk tanggal
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final friends = await _userService.getFriendsData();
      setState(() {
        _friendsList = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFriends = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar teman: $e')),
        );
      }
    }
  }

  // --- Methods ---

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // Tambahkan konfigurasi tema untuk date picker agar sesuai dengan tema dark
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryColor, // Warna header/selected
              onPrimary: Colors.white,
              surface: inputFillColor, // Background picker
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: darkBlue,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddMemberDialog() {
    if (_friendsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anda belum memiliki teman. Tambahkan teman terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkBlue,
        title: const Text('Pilih Teman', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _friendsList.length,
            itemBuilder: (context, index) {
              final friend = _friendsList[index];
              final isSelected = _selectedMembers.any(
                (member) => member['uid'] == friend['uid'],
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend['photoUrl'] != null
                      ? NetworkImage(friend['photoUrl'])
                      : null,
                  backgroundColor: primaryColor,
                  child: friend['photoUrl'] == null
                      ? Text(
                          friend['name'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(
                  friend['name'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  friend['email'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: primaryColor)
                    : const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white54,
                      ),
                onTap: () {
                  if (isSelected) {
                    setState(() {
                      _selectedMembers.removeWhere(
                        (member) => member['uid'] == friend['uid'],
                      );
                    });
                  } else {
                    setState(() {
                      _selectedMembers.add(friend);
                    });
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _removeMember(Map<String, dynamic> member) {
    setState(() {
      _selectedMembers.removeWhere((m) => m['uid'] == member['uid']);
    });
  }

  void _continueToNext() {
    if (_activityNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan nama aktivitas')));
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambah minimal 1 member dari daftar teman'),
        ),
      );
      return;
    }

    // Convert selected members to list of names dan UIDs untuk ChooseMethodScreen
    List<String> memberNames = ['Anda'];
    memberNames.addAll(
      _selectedMembers.map((m) => m['name'] as String).toList(),
    );

    List<String> memberUids = _selectedMembers
        .map((m) => m['uid'] as String)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseMethodScreen(
          activityName: _activityNameController.text.trim(),
          activityDate: _selectedDate,
          members: memberNames,
          memberUids: memberUids,
        ),
      ),
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        title: const Text(
          'Create Activity',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: 0.33,
              backgroundColor: Colors.white10,
              color: primaryColor,
            ),
            const SizedBox(height: 20),

            // 1. Nama Aktivitas
            ActivityInputField(
              label: 'Nama Aktivitas',
              child: TextField(
                controller: _activityNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contoh: Makan bersama, Liburan, dll',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            // SizedBox(height: 30) sudah ada di dalam ActivityInputField

            // 2. Tanggal Aktivitas
            ActivityInputField(
              label: 'Tanggal Aktivitas',
              child: InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: inputFillColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dateFormat.format(
                          _selectedDate,
                        ), // Menggunakan formatter
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: primaryColor),
                    ],
                  ),
                ),
              ),
            ),
            // SizedBox(height: 30) sudah ada di dalam ActivityInputField

            // 3. Tambah Member dari Daftar Teman
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Member Aktivitas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoadingFriends ? null : _showAddMemberDialog,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Tambah Teman'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Info: Anda adalah member default
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anda otomatis menjadi member aktivitas ini',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Daftar Members (Chip List)
            if (_selectedMembers.isNotEmpty) ...[
              const Text(
                'Teman yang Ditambahkan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMembers
                    .map(
                      (member) => Chip(
                        avatar: CircleAvatar(
                          backgroundImage: member['photoUrl'] != null
                              ? NetworkImage(member['photoUrl'])
                              : null,
                          backgroundColor: Colors.white,
                          child: member['photoUrl'] == null
                              ? Text(
                                  member['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                        label: Text(member['name'] ?? 'Unknown'),
                        onDeleted: () => _removeMember(member),
                        backgroundColor: primaryColor.withOpacity(0.3),
                        labelStyle: const TextStyle(color: Colors.white),
                        deleteIconColor: Colors.white,
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada teman yang ditambahkan',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 50),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continueToNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lanjut',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
