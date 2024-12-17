import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'add_product_screen.dart';
import 'add_category_screen.dart';
import 'update_category_screen.dart';
import 'update_product_screen.dart';
import 'delete_category_screen.dart';
import 'delete_product_screen.dart';
import 'best_selling_chart_screen.dart';
import 'transaction_screen.dart'; 
import 'feedback_screen.dart'; 


class AdminScreen extends StatelessWidget {
  Future<String> _fetchUsername() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'Admin';

      final userDoc = await FirebaseFirestore.instance
          .collection('Users Collection')
          .doc(currentUser.uid)
          .get();

      return userDoc.data()?['username']?.isNotEmpty == true
          ? userDoc.data()!['username']
          : 'Admin';
    } catch (e) {
      print('Error fetching username: $e');
      return 'Admin';
    }
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome to the Admin Panel',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black54,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 4.0,
      ),
      drawer: FutureBuilder<String?>(
        future: _fetchUsername(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final username = snapshot.data ?? 'Admin';

          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal, Colors.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  accountName: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  accountEmail: SizedBox.shrink(),
                  currentAccountPicture: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.teal,
                      size: 50,
                    ),
                  ),
                ),
                // Add Product
                ListTile(
                  leading: Icon(Icons.add, color: Colors.teal),
                  title: Text('Add Product', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddProductScreen()),
                    );
                  },
                ),
                // Add Category
                ListTile(
                  leading: Icon(Icons.category, color: Colors.teal),
                  title: Text('Add Category', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddCategoryScreen()),
                    );
                  },
                ),
                // Update Category
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.teal),
                  title: Text('Update Category', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UpdateCategoryScreen()),
                    );
                  },
                ),
                // Update Product
                ListTile(
                  leading: Icon(Icons.update, color: Colors.teal),
                  title: Text('Update Product', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UpdateProductScreen()),
                    );
                  },
                ),
                // Delete Category
                ListTile(
                  leading: Icon(Icons.category, color: Colors.red),
                  title: Text('Delete Category', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeleteCategoryScreen()),
                    );
                  },
                ),
                // Delete Product
                ListTile(
                  leading: Icon(Icons.production_quantity_limits, color: Colors.red),
                  title: Text('Delete Product', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DeleteProductScreen()),
                    );
                  },
                ),
                Divider(),
                // View Transaction Report
                ListTile(
                  leading: Icon(Icons.report, color: Colors.blue),
                  title: Text('Transaction Report', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TransactionScreen()),
                    );
                  },
                ),
                // Manage Feedback
                ListTile(
                  leading: Icon(Icons.feedback, color: Colors.orange),
                  title: Text('Manage Feedback', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackScreen()),
                    );
                  },
                ),
                // Best Selling Products Chart
                ListTile(
                  leading: Icon(Icons.bar_chart, color: Colors.purple),
                  title: Text('Best Selling Products', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BestSellingChartScreen()),
                    );
                  },
                ),
                Divider(),
                // Log out
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.teal),
                  title: Text('Logout', style: TextStyle(fontSize: 16)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          );
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
