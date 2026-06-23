import 'package:flutter/material.dart';
import '../database/supabase_service.dart';
import '../models/user.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditUserScreen({super.key, required this.userData});

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.userData['full_name']);
    emailController =
        TextEditingController(text: widget.userData['email']);
    phoneController =
        TextEditingController(text: widget.userData['phone']);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      final fullUser =
          await SupabaseService().getUserById(widget.userData['id']);
      if (fullUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found.')));
        return;
      }

      final updated = User(
        id: fullUser.id,
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        username: fullUser.username,
        password: fullUser.password,
        role: fullUser.role,
      );

      await SupabaseService().updateUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully.')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                  labelText: 'Phone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save Changes',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
