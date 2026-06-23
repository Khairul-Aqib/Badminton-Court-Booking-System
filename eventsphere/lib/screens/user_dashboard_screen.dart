import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/user.dart';
import '../models/court.dart';
import 'booking_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final User user;

  const UserDashboardScreen({super.key, required this.user});

  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _DashboardHome(user: widget.user),
      MyBookingsScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark), label: 'My Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatefulWidget {
  final User user;

  const _DashboardHome({required this.user});

  @override
  _DashboardHomeState createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  List<Court> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    try {
      final courts = await SupabaseService().getCourts();
      setState(() {
        _courts = courts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load courts: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BadmintonSphere',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text('Hi, ${widget.user.fullName.split(' ').first}',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: Icon(Icons.person,
                      color: Colors.blue[800], size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Courts',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_courts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('No courts available.',
                                style: TextStyle(color: Colors.grey[600])),
                          ),
                        )
                      else
                        ..._courts.map((court) => _CourtCard(
                              court: court,
                              onTap: () =>
                                  _showCourtDetails(context, court),
                            )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showCourtDetails(BuildContext context, Court court) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourtDetailSheet(
        court: court,
        onBook: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingScreen(
                user: widget.user,
                selectedCourt: court,
              ),
            ),
          ).then((_) => _loadCourts());
        },
      ),
    );
  }
}

// ── Reusable court card ──────────────────────────────────────────────────────

class _CourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback onTap;

  const _CourtCard({required this.court, required this.onTap});

  Widget _courtImage(String courtName) {
    final name = courtName.trim().toLowerCase();
    String? asset;
    if (name.contains('court a') || name == 'a') {
      asset = 'assets/courtA.jpg';
    } else if (name.contains('court b') || name == 'b') {
      asset = 'assets/courtB.webp';
    } else if (name.contains('court c') || name == 'c') {
      asset = 'assets/courtC.jpeg';
    } else if (name.contains('court d') || name == 'd') {
      asset = 'assets/courtD.jpg';
    }

    if (asset != null) {
      return Image.asset(
        asset,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
      );
    }

    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue[300]!, Colors.blue[600]!]),
      ),
      child: const Icon(Icons.sports_tennis, size: 60, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: _courtImage(court.courtName),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(court.courtName,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    if (court.courtType != null) ...[
                      const SizedBox(height: 4),
                      Text(court.courtType!,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'RM ${court.pricePerHour.toStringAsFixed(0)}/hour',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[600]),
                    ),
                    const SizedBox(height: 4),
                    Text('Capacity: ${court.capacity} players',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtDetailSheet extends StatelessWidget {
  final Court court;
  final VoidCallback onBook;

  const _CourtDetailSheet({required this.court, required this.onBook});

  Widget _courtImage(String courtName) {
    final name = courtName.trim().toLowerCase();
    String? asset;
    if (name.contains('court a') || name == 'a') {
      asset = 'assets/courtA.jpg';
    } else if (name.contains('court b') || name == 'b') {
      asset = 'assets/courtB.webp';
    } else if (name.contains('court c') || name == 'c') {
      asset = 'assets/courtC.jpeg';
    } else if (name.contains('court d') || name == 'd') {
      asset = 'assets/courtD.jpg';
    }

    if (asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          asset,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue[300]!, Colors.blue[600]!]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.sports_tennis, size: 70, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _courtImage(court.courtName),
                  const SizedBox(height: 20),
                  Text(court.courtName,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800])),
                  if (court.courtType != null) ...[
                    const SizedBox(height: 4),
                    Text(court.courtType!,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600])),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'RM ${court.pricePerHour.toStringAsFixed(0)}/hour',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[600]),
                  ),
                  const SizedBox(height: 8),
                  Text('Capacity: ${court.capacity} players',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey[600])),
                  if (court.facilities != null) ...[
                    const SizedBox(height: 16),
                    Text('Facilities:',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    const SizedBox(height: 8),
                    Text(court.facilities!,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[700])),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Book Now',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
