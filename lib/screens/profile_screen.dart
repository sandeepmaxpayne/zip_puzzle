import 'package:flutter/material.dart';

import '../app_scope.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _photoController;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _photoController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = AppScope.of(context).authProfile;
    _nameController.text = profile?.displayName ?? '';
    _photoController.text = profile?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = AppScope.of(context);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await controller.updateProfile(
        displayName: _nameController.text.trim(),
        photoUrl: _photoController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Profile updated successfully.';
      });
    } catch (error) {
      setState(() {
        _message = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final profile = controller.authProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFF39D5B3).withValues(alpha: 0.16),
                      backgroundImage: profile?.photoUrl != null &&
                              profile!.photoUrl!.isNotEmpty
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child: profile?.photoUrl == null || profile!.photoUrl!.isEmpty
                          ? const Icon(Icons.person_rounded, size: 34)
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile?.shortName ?? 'Player',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile?.email ?? 'No email on this account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _photoController,
              decoration: const InputDecoration(
                labelText: 'Photo URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save Profile'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
          ],
        ),
      ),
    );
  }
}
