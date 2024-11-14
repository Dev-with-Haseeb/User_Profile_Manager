import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_profile_manager/screens/authentication_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:user_profile_manager/screens/home_screen.dart';
import 'package:user_profile_manager/screens/loading_screen.dart';
import 'package:user_profile_manager/screens/profile_editing_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData().copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 128, 128),
          ),
          textTheme: GoogleFonts.latoTextTheme()),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (authSnapshot.hasData) {
            final userId = authSnapshot.data!.uid;
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingScreen();
                }
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  var userData = userSnapshot.data!.data();
                  if (userData != null &&
                      userData.containsKey('username') &&
                      userData['username'] != null) {
                    return const HomeScreen();
                  }
                }
                return const ProfileEditingScreen();
              },
            );
          }
          return const AuthenticationScreen();
        },
      ),
    );
  }
}
