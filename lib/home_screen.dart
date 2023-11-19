import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cupping_admin/GlobalVariable.dart';
import 'package:firebase_database/firebase_database.dart' as database;
import 'package:flutter/material.dart';

import 'alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = "/home_screen";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("cupping_admin")),
      body: StreamBuilder(
        stream: getDocumentCountStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          print(snapshot.data!);
          double totalHistoryCount = snapshot.data!["totalCount"];
          double todayHistoryCount = snapshot.data!["todayCount"];
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(GlobalVariable.place, style: TextStyle(fontSize: 30), textAlign: TextAlign.center,),
                GestureDetector(
                  onTap: (){
                    Navigator.pushNamed(context, AlarmScreen.routeName);
                  },
                  child: alarm(),
                ),
                const Text("weight"),
                Text("${snapshot.data!["currentWeight"]}g / ${GlobalVariable.maxWeight}g"),
                const Text("distance"),
                Text("1차(warn): ${snapshot.data!["firstDistance"]}cm / ${GlobalVariable.maxDistance}cm"),
                Text("2차(critical): ${snapshot.data!["secondDistance"]}cm / ${GlobalVariable.maxDistance}cm"),
                const Text("사용량"),
                Text("총 누적 사용량: $totalHistoryCount"),
                Text("오늘의 사용량: $todayHistoryCount")
              ],
            ),
          );
        }
      )
    );
  }

  Widget alarm(){
    firestore.Query<Map<String, dynamic>> q = firestore.FirebaseFirestore.instance.collection("alarm").orderBy("createdAt", descending: true);
    q.get().then((value) {
      if(value.docs.isNotEmpty){
        var data = value.docs.first.data();
        String degree = data['degree'];
        String content = data['content'];
        DateTime createdAt = data['createdAt'].toDate();
        Text alarmTitle = (degree=="warn") ? Text("경고: ${data['title']}") :  Text("위험: ${data['title']}");
        Color alarmColor = (degree=="warn") ? Colors.yellow : Colors.red;
        return Container(
          color: alarmColor,
          child: Column(
            children: [
              alarmTitle,
              Text(content),
              Text(createdAt.toString())
            ]
          )
        );
      }
    });
    return Container();
  }

  Stream<Map<String, dynamic>> getDocumentCountStream() async* {
    double totalCount=0, todayCount =0;
    double firstDistance=0, secondDistance=0;
    double currentWeight = 0;
    int index = 0;
    Object alarmData = {};

    database.DatabaseReference firstRef = database.FirebaseDatabase.instance.ref("distance").child("warn");
    firstRef.onValue.listen((event) {
      if(event.snapshot.value !=null){
        var data = event.snapshot.value as Map<String, dynamic>;
        firstDistance = data['value'];
      }
    });

    database.DatabaseReference distanceRef = database.FirebaseDatabase.instance.ref("distance").child("critical");
    distanceRef.onValue.listen((event) {
      if(event.snapshot.value !=null){
        var data = event.snapshot.value as Map<String, dynamic>;
        secondDistance = data['value'];
      }
    });

    database.DatabaseReference weightRef = database.FirebaseDatabase.instance.ref("weight");
    weightRef.onValue.listen((event) {
      if(event.snapshot.value != null){
        var data = event.snapshot.value as Map<String, dynamic>;
        currentWeight = data['value'];
      }
    });

    firestore.Query<Map<String, dynamic>> alarmRef = firestore.FirebaseFirestore.instance.collection("alarm").orderBy("createdAt", descending: true);
    alarmRef.snapshots().listen((event) {
      if(event.docs.isNotEmpty){
        alarmData = event.docs.first.data();
      }
    });

    firestore.Query<Map<String, dynamic>> historyRef = firestore.FirebaseFirestore.instance.collection("history");
    historyRef.snapshots().listen((event) {
      if(event.docs.isNotEmpty){
        for (var doc in event.docs){
          totalCount += doc.data()!["count"];
          if (doc.id == DateTime.now().toString().substring(0,10)){
            todayCount = doc.data()!["count"];
          }
        }
      }
    });

    yield {
      "totalCount": totalCount,
      "todayCount": todayCount,
      "firstDistance": firstDistance,
      "secondDistance": secondDistance,
      "currentWeight": currentWeight,
      "alarmData": alarmData
    };
  }

  void scaffoldMessage(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
