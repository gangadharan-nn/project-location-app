import 'package:flutter/material.dart';

class SelectedUsersScreen extends StatelessWidget {
  final List<String> selectedUsers;
  final String hostUser;

  SelectedUsersScreen({required this.selectedUsers, required this.hostUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected Users'),
      ),
      body: Column(
        children: [
          const Text(
            'Host:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: Text(hostUser),
            leading: const Icon(Icons.person),
          ),
          const Text(
            'Selected Users:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: selectedUsers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(selectedUsers[index]),
                  leading: const Icon(Icons.person),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}