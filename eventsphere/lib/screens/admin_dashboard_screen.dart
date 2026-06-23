import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/admin.dart';
import 'edit_user_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Admin admin;

  const AdminDashboardScreen({super.key, required this.admin});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _usersData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService().getUsersWithBookings();
      setState(() {
        _usersData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _usersData.length;
    final totalBookings = _usersData.fold<int>(
        0,
        (sum, u) =>
            sum + ((u['bookings'] as List?)?.length ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh'),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Welcome card
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[800],
                            radius: 30,
                            child: const Icon(Icons.admin_panel_settings,
                                color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome, ${widget.admin.username}!',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              Text('Admin Dashboard',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _statCard('Total Users', '$totalUsers',
                            Icons.people, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _statCard('Total Bookings',
                                '$totalBookings', Icons.bookmark, Colors.green)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.list),
                        const SizedBox(width: 8),
                        const Text('Users & Bookings',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // User list
                  _usersData.isEmpty
                      ? const SizedBox(
                          height: 200,
                          child: Center(
                              child: Text('No users found',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _usersData.length,
                          itemBuilder: (_, index) {
                            final item = _usersData[index];
                            final bookings =
                                (item['bookings'] as List?) ?? [];
                            final hasBooking = bookings.isNotEmpty;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasBooking
                                      ? Colors.blue[800]
                                      : Colors.grey,
                                  child: Icon(
                                    hasBooking
                                        ? Icons.event_available
                                        : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  item['full_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${item['email'] ?? 'N/A'}'),
                                    Text('Phone: ${item['phone'] ?? 'N/A'}'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: hasBooking
                                            ? Colors.blue[800]
                                            : Colors.grey.withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        hasBooking
                                            ? '${bookings.length} Booking(s)'
                                            : 'No Bookings',
                                        style: TextStyle(
                                          color: hasBooking
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  // Bookings list
                                  ...bookings.map<Widget>((booking) =>
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 8, 16, 0),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.grey[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    booking['courts']?[
                                                            'court_name'] ??
                                                        'Court #${booking['id']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: booking[
                                                                  'status'] ==
                                                              'cancelled'
                                                          ? Colors.red
                                                          : Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Text(
                                                      (booking['status'] ??
                                                              'confirmed')
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  'Date: ${booking['booking_date'] ?? 'N/A'}  ${booking['start_time'] ?? ''} – ${booking['end_time'] ?? ''}',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700])),
                                              Text(
                                                  'Total: RM ${(booking['total_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700])),
                                            ],
                                          ),
                                        ),
                                      )),

                                  // Edit / Delete buttons
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditUserScreen(
                                                  userData: item),
                                            ),
                                          ).then((_) => _loadData()),
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.black),
                                          child: const Text('Edit'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text(
                                                    'Delete User'),
                                                content: const Text(
                                                    'Delete this user and all their bookings?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child:
                                                        const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await SupabaseService()
                                                  .deleteUser(item['id']);
                                              _loadData();
                                            }
                                          },
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
