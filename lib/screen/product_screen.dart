import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ProductScreen extends StatefulWidget {
  final String? categoryId;
  final String categoryName;

  const ProductScreen({Key? key, this.categoryId, required this.categoryName})
      : super(key: key);

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? searchQuery;
  final _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('categoryId', isEqualTo: widget.categoryId)
          .get();

      var products = snapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['name'],
            'imageUrl': doc['imageUrl'],
            'price': doc['price'],
          }).toList();

      if (searchQuery != null && searchQuery!.isNotEmpty) {
        products = products
            .where((product) =>
                product['name'].toLowerCase().contains(searchQuery!))
            .toList();
      }

      return products;
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  void addToCart(String productId, String productName, double productPrice, String imageUrl) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final cartRef = FirebaseFirestore.instance
          .collection('Users Collection')
          .doc(currentUser.uid)
          .collection('Cart');

      try {
        final existingItem = await cartRef.where('productId', isEqualTo: productId).limit(1).get();

        if (existingItem.docs.isEmpty) {
          // إضافة منتج جديد إلى السلة
          await cartRef.add({
            'productId': productId,
            'name': productName,
            'price': productPrice,
            'quantity': 1,
            'imageUrl': imageUrl,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$productName added to cart successfully!')),
          );
        } else {
          // تحديث الكمية للمنتج الحالي
          final docId = existingItem.docs[0].id;
          final currentQuantity = existingItem.docs[0]['quantity'];
          await cartRef.doc(docId).update({
            'quantity': currentQuantity + 1,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated quantity of $productName in cart.')),
          );
        }
      } catch (e) {
        print('Error adding to cart: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add $productName to cart. Please try again.')),
        );
      }
    }
  }

  // بحث بالصوت
  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(onResult: (result) {
          setState(() {
            searchQuery = result.recognizedWords.toLowerCase();
            _searchController.text = searchQuery!;
          });
        });
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  // مسح الباركود
  Future<void> _scanBarcode() async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666', // اللون
      'Cancel',  // نص الزر
      true,      // إظهار مصباح الكاميرا
      ScanMode.BARCODE,
    );

    if (barcode != '-1') {
      setState(() {
        searchQuery = barcode;
        _searchController.text = searchQuery!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.categoryName),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh), // استبدال الأيقونة هنا
          onPressed: () {
            FocusScope.of(context).requestFocus(FocusNode());
            // أو تضيف كود التحديث هنا
          },
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0), // تباعد داخلي
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search products',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>( 
            future: _fetchProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No products found.'));
              }

              List<Map<String, dynamic>> products = snapshot.data!;

              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var product = products[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      title: Text(
                        product['name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Price: \$${product['price']}',
                        style: TextStyle(fontSize: 18),
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product['imageUrl'] ?? 'https://via.placeholder.com/150',
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          addToCart(product['id'], product['name'], product['price'], product['imageUrl']);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
}
