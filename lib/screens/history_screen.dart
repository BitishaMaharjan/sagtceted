import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = const FlutterSecureStorage();
  String? _userId;
  String _searchText = "";
  DateTime? _startDate;
  DateTime? _endDate;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _historyStream;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _storage.read(key: 'userId') ?? "unknown";
    setState(() {
      _userId = userId;
      _historyStream = FirebaseFirestore.instance
          .collection('predictions')
          .where('userId', isEqualTo: _userId)
          .orderBy('timestamp', descending: false)
          .snapshots();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null || _historyStream == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 50),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.greenAccent),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.air_rounded, size: 27, color: Colors.greenAccent),
              const SizedBox(width: 12),
              const Text(
                "SAGTCETED HISTORY",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              Transform.rotate(
                angle: 3.1416,
                child: const Icon(Icons.air_rounded,
                    size: 27, color: Colors.greenAccent),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Search + Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search prediction...",
                      hintStyle: TextStyle(
                          color: Colors.greenAccent.withOpacity(0.6)),
                      filled: true,
                      fillColor: Colors.grey[900],
                      prefixIcon:
                      const Icon(Icons.search, color: Colors.greenAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchText = val),
                  ),
                ),
                const SizedBox(width: 10),

                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                    const Icon(Icons.date_range, color: Colors.greenAccent),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _historyStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                      CircularProgressIndicator(color: Colors.greenAccent));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No predictions found",
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                var docs = snapshot.data!.docs;

                // Apply search filter in memory
                if (_searchText.isNotEmpty) {
                  docs = docs.where((d) {
                    final pred =
                        d['prediction']?.toString().toLowerCase() ?? "";
                    return pred.contains(_searchText.toLowerCase());
                  }).toList();
                }

                // Apply date filter in memory
                if (_startDate != null && _endDate != null) {
                  docs = docs.where((d) {
                    final ts = d['timestamp'] as Timestamp?;
                    if (ts == null) return false;
                    final date = ts.toDate();
                    return date.isAfter(
                        _startDate!.subtract(const Duration(days: 1))) &&
                        date.isBefore(_endDate!.add(const Duration(days: 1)));
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("No predictions found",
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var d = docs[index];

                    Uint8List? imageBytes;
                    try {
                      imageBytes = base64Decode(d['image']);
                    } catch (_) {}

                    final timestamp = d['timestamp'] != null
                        ? (d['timestamp'] as Timestamp).toDate()
                        : null;

                    return Dismissible(
                      key: Key(d.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child:
                        const Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      onDismissed: (direction) async {
                        await FirebaseFirestore.instance
                            .collection('predictions')
                            .doc(d.id)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Deleted successfully"),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: imageBytes != null
                              ? Image.memory(imageBytes,
                              width: 60, height: 60, fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported,
                              color: Colors.redAccent, size: 40),
                          title: Text(d['prediction'] ?? "Unknown",
                              style: const TextStyle(color: Colors.white)),
                          subtitle: timestamp != null
                              ? Text(
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(timestamp),
                            style:
                            const TextStyle(color: Colors.white70),
                          )
                              : null,
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
