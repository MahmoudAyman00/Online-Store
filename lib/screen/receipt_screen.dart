import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home_screen.dart';

class ReceiptScreen extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  const ReceiptScreen({required this.orderId, required this.cartItems, required this.totalPrice});

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  int _rating = 0;
  String _comment = "";

  // Adding feedback to Firestore
  Future<void> _addFeedbackToFirestore(String orderId, int rating, String comment) async {
    // Get current user
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) return;

    try {
      final feedbacksRef = FirebaseFirestore.instance.collection('Feedbacks');

      final feedbackData = {
        'userId': currentUser.uid,
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        'timestamp': Timestamp.now(),
      };

      await feedbacksRef.add(feedbackData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback added successfully')));
    } catch (e) {
      print('Error adding feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding feedback')));
    }
  }

  Future<bool> _onWillPop() async {
    return false; // Prevent back navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Order Receipt', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueGrey[700],
          actions: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Order ID
                Text(
                  'Order ID: ${widget.orderId}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                ),
                SizedBox(height: 20),
                // Order Summary
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                SizedBox(height: 10),
                // Displaying Cart Items with images
                ...widget.cartItems.map((item) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      leading: CachedNetworkImage(
                        imageUrl: item['imageUrl'],
                        width: 60,
                        height: 60,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                      title: Text(
                        item['name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Price: \$${item['price']} x ${item['quantity']}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                SizedBox(height: 10),
                Text(
                  'Total: \$${widget.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 30),
                // Rating section
                Text('Rate your experience:', style: TextStyle(fontSize: 16, color: Colors.blueGrey[600])),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                SizedBox(height: 20),
                // Comment input field
                TextField(
                  onChanged: (value) {
                    _comment = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Leave a comment',
                    labelStyle: TextStyle(color: Colors.blueGrey),
                    hintText: 'Enter your comment here...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueGrey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a rating')));
                    } else if (_comment.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide a comment')));
                    } else {
                      _addFeedbackToFirestore(widget.orderId, _rating, _comment);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Submit Feedback'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
