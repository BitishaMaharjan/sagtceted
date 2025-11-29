import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [

          SizedBox(height: 70),

          // Header: icon + text + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.greenAccent, size: 20),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(width: 6),

              Icon(Icons.air_rounded, size: 27, color: Colors.greenAccent),
              SizedBox(width: 12),
              Text(
                "SAGTCETED HISTORY",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.greenAccent.withOpacity(0.6),
                      blurRadius: 6,
                      offset: Offset(0, 0),
                    ),
                    Shadow(
                      color: Colors.greenAccent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Transform.rotate(
                angle: 3.1416, // Rotate icon to face left
                child: Icon(Icons.air_rounded, size: 27, color: Colors.greenAccent),
              ),
            ],
          ),

          SizedBox(height: 20),

          // History list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('history')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var d = docs[index];
                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: Image.network(d['imageUrl'], width: 60),
                        title: Text(d['prediction'], style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          "Accuracy: ${(d['accuracy'] * 100).toStringAsFixed(2)}%",
                          style: TextStyle(color: Colors.white70),
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
