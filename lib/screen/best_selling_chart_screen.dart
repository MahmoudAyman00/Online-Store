import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BestSellingChartScreen extends StatefulWidget {
  @override
  _BestSellingChartScreenState createState() => _BestSellingChartScreenState();
}

class _BestSellingChartScreenState extends State<BestSellingChartScreen> {
  // دالة جلب البيانات من Firestore
  Future<Map<String, int>> _getBestSellingProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('Transactions').get();

    Map<String, int> productSales = {};

    snapshot.docs.forEach((doc) {
      List<dynamic> items = doc['items'];
      for (var item in items) {
        String productName = item['name']; // استخدام اسم المنتج
        int quantity = item['quantity'];

        if (productSales.containsKey(productName)) {
          productSales[productName] = productSales[productName]! + quantity;
        } else {
          productSales[productName] = quantity;
        }
      }
    });

    return productSales;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Best Selling Products'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _getBestSellingProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // تحميل البيانات
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available.'));
          } else {
            // تحويل البيانات إلى تنسيق مناسب للـ fl_chart
            Map<String, int> productSales = snapshot.data!;
            List<String> productNames = productSales.keys.toList(); // أسماء المنتجات
            List<BarChartGroupData> barGroups = productSales.entries.map((entry) {
              return BarChartGroupData(
                x: productNames.indexOf(entry.key),
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: Colors.blue,
                    width: 15,
                  ),
                ],
              );
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 70, // تباعد أكبر بين العناوين والمحور
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < productNames.length) {
                            // تقسيم الاسم الطويل على سطرين
                            String productName = productNames[index];
                            List<String> splitName = productName.split(' ');

                            // إذا كان الاسم طويلًا يتم تقسيمه إلى سطرين
                            String firstLine = splitName.take(2).join(' ');
                            String secondLine = splitName.skip(2).join(' ');

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  firstLine,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                if (secondLine.isNotEmpty)
                                  Text(
                                    secondLine,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            );
                          } else {
                            return Text('');
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
