import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactListScreen extends StatefulWidget {
  final User user;

  ContactListScreen({required this.user});

  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact List'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('contacts')
            .where('userId', isEqualTo: widget.user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No contacts available. Add a contact!'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final contact = snapshot.data!.docs[index];
              return ListTile(
                title: Text(contact['name']),
                subtitle: Text(contact['contactnumber']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Navigate to the edit contact screen with the contact data.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditContactScreen(contact: contact),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Show a confirmation dialog before deleting the contact.
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return DeleteContactDialog(
                                contactId: contact.id, context: context);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the new contact screen.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewContactScreen(user: widget.user),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditContactScreen extends StatefulWidget {
  final QueryDocumentSnapshot contact;

  EditContactScreen({required this.contact});

  @override
  _EditContactScreenState createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactnumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.contact['name'];
    _contactnumberController.text = widget.contact['contactnumber'];
  }

  Future<void> _updateContact() async {
    await widget.contact.reference.update({
      'name': _nameController.text,
      'contactnumber': _contactnumberController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _contactnumberController,
              decoration: const InputDecoration(labelText: 'contactnumber'),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _updateContact();
                Navigator.pop(context);
              },
              child: const Text('Update Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class NewContactScreen extends StatefulWidget {
  final User user;

  NewContactScreen({required this.user});

  @override
  _NewContactScreenState createState() => _NewContactScreenState();
}

class _NewContactScreenState extends State<NewContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactnumberController =
      TextEditingController();

  Future<void> _addContact() async {
    final newContact = {
      'name': _nameController.text,
      'contactnumber': _contactnumberController.text,
      'userId': widget.user.uid,
    };

    await FirebaseFirestore.instance.collection('contacts').add(newContact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _contactnumberController,
              decoration: const InputDecoration(labelText: 'Contact number'),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _addContact();
                Navigator.pop(context);
              },
              child: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteContactDialog extends StatelessWidget {
  final String contactId;

  const DeleteContactDialog(
      {required this.contactId, required BuildContext context});

  Future<void> _deleteContact(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('contacts')
        .doc(contactId)
        .delete(); // Close the dialog
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Contact'),
      content: const Text('Are you sure you want to delete this contact?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _deleteContact(context);
            Navigator.pop(context); // Pass the context here
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
