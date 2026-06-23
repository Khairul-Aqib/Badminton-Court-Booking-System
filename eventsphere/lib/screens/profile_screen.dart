import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/user.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user.fullName);
    _emailController =
        TextEditingController(text: widget.user.email);
    _phoneController =
        TextEditingController(text: widget.user.phone);
    _usernameController =
        TextEditingController(text: widget.user.username);
    _passwordController =
        TextEditingController(text: widget.user.password);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = widget.user.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      await SupabaseService().updateUser(updated);
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[800]!, Colors.grey[50]!],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!]),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: const Icon(Icons.person,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(widget.user.fullName,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal Information',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _nameController.text = widget.user.fullName;
                                _emailController.text = widget.user.email;
                                _phoneController.text = widget.user.phone;
                                _usernameController.text =
                                    widget.user.username;
                                _passwordController.text =
                                    widget.user.password;
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.black),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      _formField(_nameController, 'Full Name',
                          validator: (v) => (v?.isEmpty ?? true)
                              ? 'Enter name'
                              : null),
                      const SizedBox(height: 16),
                      _formField(_emailController, 'Email',
                          validator: (v) =>
                              !(v?.contains('@') ?? false)
                                  ? 'Enter valid email'
                                  : null),
                      const SizedBox(height: 16),
                      _formField(_phoneController, 'Phone',
                          validator: (v) => (v?.length ?? 0) < 9
                              ? 'Enter valid phone'
                              : null),
                      const SizedBox(height: 16),
                      _formField(_usernameController, 'Username',
                          validator: (v) => (v?.length ?? 0) < 4
                              ? 'Too short'
                              : null),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        enabled: _isEditing,
                        validator: (v) => (v?.length ?? 0) < 6
                            ? 'Password too short'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(TextEditingController controller, String label,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      enabled: _isEditing,
      validator: validator,
    );
  }
}
