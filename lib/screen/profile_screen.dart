import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'package:intl/intl.dart'; // إضافة هذه المكتبة لتنسيق التاريخ

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('Users Collection')
          .doc(currentUser.uid)
          .get();

      return userDoc.data();
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.teal, // تغيير لون الـ AppBar
        actions: [
          // إضافة أيقونة home في الـ AppBar
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              // الانتقال إلى شاشة HomeScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>( 
        future: _fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Error loading profile information.'));
          }

          final userData = snapshot.data!;
          
          String formattedBirthdate = 'N/A';
if (userData['birthDate'] != null && userData['birthDate'] is Timestamp) {
  Timestamp timestamp = userData['birthDate'];
  DateTime birthDate = timestamp.toDate();
  formattedBirthdate = DateFormat('yyyy-MM-dd').format(birthDate); // تنسيق التاريخ حسب الحاجة
} else {
  formattedBirthdate = 'N/A'; // في حالة عدم وجود قيمة أو النوع غير صحيح
}



          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(Icons.person, color: Colors.teal),
                    title: Text(
                      'Name: ${userData['username'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(Icons.email, color: Colors.teal),
                    title: Text(
                      'Email: ${userData['email'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(Icons.phone, color: Colors.teal),
                    title: Text(
                      'Phone: ${userData['phone'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(Icons.cake, color: Colors.teal),
                    title: Text(
                      'Birthdate: $formattedBirthdate',
                      style: TextStyle(fontSize: 18),
                    ),
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

