import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:user_profile_manager/screens/authentication_screen.dart';
import 'package:user_profile_manager/screens/home_screen.dart';
import 'package:user_profile_manager/widgets/user_image_picker.dart';

class ProfileEditingScreen extends StatefulWidget {
  const ProfileEditingScreen({super.key});

  @override
  State<ProfileEditingScreen> createState() => _ProfileEditingScreenState();
}

class _ProfileEditingScreenState extends State<ProfileEditingScreen> {
  final _form = GlobalKey<FormState>();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  var _enteredUsername = '';
  String? imageUrl;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false; // New saving flag

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the widget is initialized
  }

  Future<void> _fetchUserData() async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      var userData = userSnapshot.data();
      if (userData != null) {
        setState(() {
          _enteredUsername = userData['username'] ?? ''; // Get the username
          imageUrl = userData['image_url']; // Get the image URL
          _isLoading = false; // Set loading to false
        });
      }
    } else {
      setState(() {
        _isLoading = false; // Handle case where user does not exist
      });
    }
  }

  _save() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();

    setState(() {
      _isSaving = true; // Set saving state to true
    });

    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('$userId.jpg');

      await storageRef.putFile(_selectedImage!);
      imageUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'username': _enteredUsername,
      'image_url': imageUrl,
    });

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const HomeScreen()));
  }

  String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    if (value.length > 15) {
      return 'Username must not exceed 15 characters';
    }
    final regex =
        RegExp(r'^[a-zA-Z0-9_]+$'); // Only letters, numbers, and underscores
    if (!regex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null; // If all conditions are met
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isSaving) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator())); // Show loading indicator
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(
          'Profile Editing Screen',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AuthenticationScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserImagePicker(
                  onPickedImage: (pickedImage) {
                    _selectedImage = pickedImage;
                  },
                  existingImageUrl: imageUrl,
                ),
                const SizedBox(
                  height: 30,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Enter your Username',
                  ),
                  initialValue: _enteredUsername,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  enableSuggestions: false,
                  validator: usernameValidator,
                  onSaved: (value) {
                    _enteredUsername = value!;
                  },
                ),
                const SizedBox(
                  height: 50,
                ),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary),
                  child: Text(
                    'Save',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
