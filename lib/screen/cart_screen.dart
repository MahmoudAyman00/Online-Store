import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'receipt_screen.dart'; // استيراد شاشة الإيصال

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> _fetchCartItems() async {
    if (currentUser == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('Users Collection')
        .doc(currentUser!.uid)
        .collection('Cart')
        .get();

    return snapshot.docs.map((doc) => {
          'id': doc.id,
          'productId': doc['productId'],
          'name': doc['name'],
          'price': doc['price'],
          'quantity': doc['quantity'],
          'imageUrl': doc['imageUrl'],
        }).toList();
  }

  Future<void> _updateQuantity(String docId, int newQuantity) async {
    if (currentUser == null) return;

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('Users Collection')
          .doc(currentUser!.uid)
          .collection('Cart');

      if (newQuantity > 0) {
        await cartRef.doc(docId).update({'quantity': newQuantity});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quantity updated successfully.')),
        );
      } else {
        await cartRef.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item removed from cart.')),
        );
      }

      setState(() {}); // تحديث الواجهة
    } catch (e) {
      print('Error updating cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update cart. Please try again.')),
      );
    }
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

Future<String> _addTransactionToFirestore(List<Map<String, dynamic>> cartItems, double totalPrice) async {
  if (currentUser == null) return '';

  try {
    final transactionsRef = FirebaseFirestore.instance.collection('Transactions');

    final transactionData = {
      'userId': currentUser!.uid,
      'items': cartItems.map((item) => {
        'productId': item['productId'],
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
      }).toList(),
      'totalPrice': totalPrice,
      'timestamp': Timestamp.now(),
    };

    // أضف البيانات واحصل على `document ID`
    final docRef = await transactionsRef.add(transactionData);
    return docRef.id; // نعيد معرف الطلب
  } catch (e) {
    print('Error adding transaction: $e');
    return '';
  }
}


  Future<void> _checkout(List<Map<String, dynamic>> cartItems, double totalPrice) async {
  if (currentUser == null) return;

  try {
    // احصل على معرف الطلب
    final orderId = await _addTransactionToFirestore(cartItems, totalPrice);

    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process the transaction.')),
      );
      return;
    }

    // حذف جميع العناصر من السلة بعد إتمام الطلب
    final cartRef = FirebaseFirestore.instance
        .collection('Users Collection')
        .doc(currentUser!.uid)
        .collection('Cart');
    for (var item in cartItems) {
      await cartRef.doc(item['id']).delete();
    }

    // الانتقال إلى شاشة الإيصال مع تمرير `orderId`
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(
          cartItems: cartItems,
          totalPrice: totalPrice,
          orderId: orderId, // نمرر معرف الطلب هنا
        ),
      ),
    );
  } catch (e) {
    print('Error during checkout: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to complete checkout. Please try again.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        future: _fetchCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Your cart is empty.'));
          }

          final cartItems = snapshot.data!;
          final totalPrice = _calculateTotal(cartItems);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: item['imageUrl'],
                          width: 60,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                        title: Text(item['name']),
                        subtitle: Text('Price: \$${item['price']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => _updateQuantity(item['id'], item['quantity'] - 1),
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _updateQuantity(item['id'], item['quantity'] + 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _checkout(cartItems, totalPrice),
                  child: Text('Checkout'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
