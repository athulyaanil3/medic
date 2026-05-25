import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(

      appBar: AppBar(
        title: const Text("MediVoice AI"),
      ),

      body: FutureBuilder<DocumentSnapshot>(

        future:
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {

            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final data =
          snapshot.data!.data()
          as Map<String, dynamic>;

          return Center(

            child: Column(

              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [

                const Text(

                  "Welcome",

                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 10),

                Text(

                  data['username'],

                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}