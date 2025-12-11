import 'package:flutter/material.dart';
import 'package:splitify/services/user_service.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _friends = [];

  // Color scheme
  static const Color darkBlue = Color(0xFF000518);
  static const Color primaryColor = Color(0xFF3B5BFF);
  static const Color cardColor = Color(0xFF1A1F2E);
  static const Color dividerColor = Color(0xFF2A3142);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final friends = await _userService.getFriendsData();
      final pendingRaw = await _userService.getOutgoingFriendRequests();

      // Map pending requests to match friend structure somewhat, using receiverData
      final pending = pendingRaw.map((r) {
        final receiver = r['receiverData'] ?? {};
        return {
          'uid': r['toUid'],
          'name': receiver['name'] ?? 'Unknown',
          'email': receiver['email'] ?? '',
          'photoUrl': receiver['photoUrl'],
          'isPending': true,
        };
      }).toList();

      setState(() {
        _friends = friends;
        _pendingRequests = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // Alias for refresh
  Future<void> _loadFriends() => _loadData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Daftar Teman',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _friends.isEmpty && _pendingRequests.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryColor,
              backgroundColor: cardColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_pendingRequests.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Menunggu Konfirmasi',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._pendingRequests.map(
                      (req) => _buildFriendCard(req, isPending: true),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: dividerColor),
                    const SizedBox(height: 10),
                  ],
                  if (_friends.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Teman Saya',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._friends.map((friend) => _buildFriendCard(friend)),
                  ] else if (_pendingRequests.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "Belum ada teman yang aktif.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Teman',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai tambahkan teman untuk memulai berbagi',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(
    Map<String, dynamic> friend, {
    bool isPending = false,
  }) {
    final name = friend['name'] ?? 'Unknown User';
    final email = friend['email'] ?? '';
    final photoUrl = friend['photoUrl'];

    // Create initials for avatar
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 2,
                ),
                color: primaryColor.withOpacity(0.2),
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: photoUrl == null
                  ? Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Action Icon
            if (isPending)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              )
            else
              Icon(
                Icons.check_circle,
                color: primaryColor.withOpacity(0.7),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
