import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_feeder/utils/colors.dart';
import 'package:pet_feeder/widgets/drawer_widget.dart';
import 'package:pet_feeder/widgets/text_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> data = [
    {
      "Timestamp": "2025-04-03 12:00",
      "Distance": "10 km",
      "Temperature": "25 °C",
      "Weight": "70 kg",
    },
    {
      "Timestamp": "2025-04-03 13:00",
      "Distance": "12 km",
      "Temperature": "28 °C",
      "Weight": "72 kg",
    },
    {
      "Timestamp": "2025-04-03 14:00",
      "Distance": "15 km",
      "Temperature": "30 °C",
      "Weight": "75 kg",
    },
  ];
  bool showTodayOnly = false;
  String sortField = 'dateTime';
  bool sortAscending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Pet Feeder',
          fontSize: 18,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete All History'),
                  content: const Text('Are you sure you want to delete all feeding history?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final snapshot = await FirebaseFirestore.instance.collection('Feed').get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ToggleButtons(
                    isSelected: [showTodayOnly],
                    onPressed: (index) {
                      setState(() {
                        showTodayOnly = !showTodayOnly;
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortField + (sortAscending ? '_asc' : '_desc'),
                  items: [
                    DropdownMenuItem(
                      value: 'dateTime_desc',
                      child: Text('Time (Descending)'),
                    ),
                    DropdownMenuItem(
                      value: 'dateTime_asc',
                      child: Text('Time (Ascending)'),
                    ),
                    DropdownMenuItem(
                      value: 'grams_desc',
                      child: Text('Fed Grams (Descending)'),
                    ),
                    DropdownMenuItem(
                      value: 'grams_asc',
                      child: Text('Fed Grams (Ascending)'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      if (val!.startsWith('dateTime')) {
                        sortField = 'dateTime';
                        sortAscending = val.endsWith('asc');
                      } else {
                        sortField = 'grams';
                        sortAscending = val.endsWith('asc');
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Feed')
                      .snapshots(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                    List<Map<String, dynamic>> items = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      data['dateTimeRaw'] = doc['dateTime'];
                      return data;
                    }).toList();
                    if (showTodayOnly) {
                      final today = DateTime.now();
                      items = items.where((item) {
                        final dt = item['dateTimeRaw'] is Timestamp
                            ? (item['dateTimeRaw'] as Timestamp).toDate()
                            : DateTime.tryParse(item['dateTimeRaw'].toString()) ?? DateTime(2000);
                        return dt.year == today.year && dt.month == today.month && dt.day == today.day;
                      }).toList();
                    }
                    items.sort((a, b) {
                      dynamic aVal;
                      dynamic bVal;
                      if (sortField == 'dateTime') {
                        aVal = a['dateTimeRaw'] is Timestamp ? (a['dateTimeRaw'] as Timestamp).toDate() : DateTime.tryParse(a['dateTimeRaw'].toString()) ?? DateTime(2000);
                        bVal = b['dateTimeRaw'] is Timestamp ? (b['dateTimeRaw'] as Timestamp).toDate() : DateTime.tryParse(b['dateTimeRaw'].toString()) ?? DateTime(2000);
                      } else {
                        aVal = a['grams'] ?? 0;
                        bVal = b['grams'] ?? 0;
                      }
                      if (sortAscending) {
                        return Comparable.compare(aVal, bVal);
                      } else {
                        return Comparable.compare(bVal, aVal);
                      }
                    });
                    if (items.isEmpty) {
                      return const Center(child: Text('No feeding history'));
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final grams = items[i]['grams'];
                        final dateTimeRaw = items[i]['dateTimeRaw'];
                        String dateStr = '';
                        String timeStr = '';
                        if (dateTimeRaw is Timestamp) {
                          dateStr = DateFormat('dd MMM yyyy').format(dateTimeRaw.toDate());
                          timeStr = DateFormat('hh:mm a').format(dateTimeRaw.toDate());
                        } else {
                          final dt = DateTime.tryParse(dateTimeRaw.toString());
                          if (dt != null) {
                            dateStr = DateFormat('dd MMM yyyy').format(dt);
                            timeStr = DateFormat('hh:mm a').format(dt);
                          }
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Fed ${grams ?? 0} grams'),
                            subtitle: Text(dateStr),
                            trailing: Text(timeStr),
                          ),
                        );
                      },
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
