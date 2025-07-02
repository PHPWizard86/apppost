import 'package:flutter/material.dart';
import 'user.dart';

class UserPanel extends StatelessWidget {
  final User currentUser;
  final VoidCallback onLogout;
  const UserPanel({
    required this.currentUser,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('پنل کاربر: ${currentUser.username}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
        ],
      ),
      body: Center(child: Text('خوش آمدید ${currentUser.fullName}')),
    );
  }
}
