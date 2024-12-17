import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  Future<List<Map<String, dynamic>>> _fetchTransactions(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('Transactions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // إضافة orderId باستخدام doc.id كـ orderId
      data['orderId'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 5.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Button to select a date
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          primaryColor: Colors.teal,
                          buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                          colorScheme: ColorScheme.light(primary: Colors.teal).copyWith(secondary: Colors.tealAccent),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (selectedDate != null) {
                    final transactions = await _fetchTransactions(selectedDate);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                            'Transactions on ${selectedDate.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          content: transactions.isEmpty
                              ? Text(
                                  'No transactions found for the selected date.',
                                  style: TextStyle(fontSize: 16, color: Colors.redAccent),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    children: transactions.map((transaction) {
                                      final items = transaction['items'] as List<dynamic>;

                                      return Card(
                                        color: Colors.teal[50],
                                        elevation: 4.0,
                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.all(16.0),
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.teal,
                                            child: Icon(Icons.person, color: Colors.white),
                                          ),
                                          title: Text(
                                            'Order ID: ${transaction['orderId']}',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'User Id: ${transaction['userId']}',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              Text(
                                                'Total: \$${transaction['totalPrice']}',
                                                style: TextStyle(color: Colors.green, fontSize: 16),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Items:',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              ...items.map<Widget>((item) {
                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Name: ${item['name']}',
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                    Text(
                                                      'Price: \$${item['price']}',
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                    Text(
                                                      'Quantity: ${item['quantity']}',
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                    Text(
                                                      'Product ID: ${item['productId']}',
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                    Divider(color: Colors.teal),
                                                  ],
                                                );
                                              }).toList(),
                                            ],
                                          ),
                                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Close',
                                style: TextStyle(color: Colors.teal),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.date_range, size: 20),
                label: Text(
                  'Select Date',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Placeholder for future content or status
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 60),
                    SizedBox(height: 10),
                    Text(
                      'Select a date to view transactions',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
