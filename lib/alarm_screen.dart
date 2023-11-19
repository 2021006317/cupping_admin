import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  static const routeName = "/alarm_screen";
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Widget alarmList(List<QueryDocumentSnapshot<Map<String, dynamic>>> alarmDocs){
    if (alarmDocs.isNotEmpty){
      return ListView.builder(
        itemCount: alarmDocs.length,
        itemBuilder: (context, index){
          return Card(
            child: ListTile(
              tileColor: alarmDocs[index]['degree'] == "critical" ? Colors.redAccent : Colors.yellowAccent,
                title: Text("${alarmDocs[index]['degree']}: ${alarmDocs[index]['title']} (${alarmDocs[index]['createdAt'].toDate().toString().substring(0,16)})"),
                subtitle: Text(alarmDocs[index]['content']),
            ),
          );
        },
      );
    } else {
      return const Center(child: Text("기록이 없습니다."));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("alarms").orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator(color: Colors.deepPurple,),);
        }
        final alarmDocs = snapshot.data!.docs;
        return Scaffold(
          appBar: AppBar(
            title: Text("총 ${alarmDocs.length}건"),
          ),
          body: alarmList(alarmDocs),
        );
      },
    );
  }
}
