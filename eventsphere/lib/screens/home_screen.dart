import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/court.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    ..._courts.map((court) => _CourtCard(
                          court: court,
                          onTap: () => _showCourtDetails(context, court),
                        )),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Login',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue[800],
                              side: BorderSide(
                                  color: Colors.blue[800]!, width: 2),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Register',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
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
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Login Required'),
              content: const Text('Please login to book a court.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
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
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[600])),
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
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[600])),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
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
