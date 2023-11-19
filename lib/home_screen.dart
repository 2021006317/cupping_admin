import 'dart:async';
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
    Map<String, dynamic> alarmData(){
      database.DatabaseReference firstRef = database.FirebaseDatabase.instance.ref("distance").child("warn");
      database.DatabaseReference secondRef = database.FirebaseDatabase.instance.ref("distance").child("critical");
      Map<String, dynamic> returnData = {};
      secondRef.onValue.listen((event) {
        Map<String, dynamic> data = event.snapshot.value! as Map<String, dynamic>;
        if(data["alarm"] == true){
          returnData = {
            "degree": "critical",
            "title": "2차 경고",
            "content": "2차 경고가 발생했습니다.",
            "createdAt": DateTime.now()
          };
        } else {
          returnData = {};
        }
      });
      if(returnData== {}){
        firstRef.onValue.listen((event) {
          Map<String, dynamic> data = event.snapshot.value! as Map<String, dynamic>;
          if(data["alarm"] == true){
            returnData = {
              "degree": "warn",
              "title": "1차 경고",
              "content": "1차 경고가 발생했습니다.",
              "createdAt": DateTime.now()
            };
          } else {
            returnData = {};
          }
        });
      }
      return returnData;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("cupping_admin")),
      body: StreamBuilder(
        stream: getDocumentCountStream(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple,),);
          }
          if(snapshot.hasError){
            return Center(child: Text("에러발생: ${snapshot.error}"),);
          }
          double totalHistoryCount = (snapshot.data == null) ? 0 :snapshot.data!["totalCount"];
          double todayHistoryCount = (snapshot.data==null) ? 0 : snapshot.data!["todayCount"];
          double currentCount = (snapshot.data==null) ? 0 : snapshot.data!["currentWeight"];
          double firstDistance = (snapshot.data==null) ? 0 : snapshot.data!["firstDistance"];
          double secondDistance = (snapshot.data==null) ? 0 : snapshot.data!["secondDistance"];
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(GlobalVariable.place, style: TextStyle(fontSize: 30), textAlign: TextAlign.center,),
                GestureDetector(
                  onTap: (){
                    Navigator.pushNamed(context, AlarmScreen.routeName);
                  },
                  child: alarm(alarmData())
                ),
                const Text("weight"),
                Text("$currentCount g / ${GlobalVariable.maxWeight}g"),
                const Text("distance"),
                Text("1차(warn): $firstDistance cm / ${GlobalVariable.maxDistance}cm"),
                Text("2차(critical): $secondDistance cm / ${GlobalVariable.maxDistance}cm"),
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

  Widget alarm(Map<String, dynamic> data) {
    if(data.isEmpty || data==null){
      return const Text("알림이 없습니다.");
    }
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

  Stream<Map<String, dynamic>> getDocumentCountStream() async* {
    double totalCount=0, todayCount =0;
    double firstDistance=0, secondDistance=0;
    double currentWeight = 0;
    database.DatabaseReference firstRef = database.FirebaseDatabase.instance.ref("distance").child("warn");
    Map<String, dynamic> data = (await firstRef.once()).snapshot.value! as Map<String, dynamic>;
    firstDistance = data['value'];
    if(firstDistance >= GlobalVariable.maxDistance){
      firstRef.set({
        "alarm": true,
      });
      firstRef.onChildChanged.listen((event) {
        if(event.snapshot.key == "value" && event.snapshot.value as int >= GlobalVariable.maxDistance){
          firstRef.set({
            "alarm": true,
          });
        }
      });
    }

    database.DatabaseReference secondRef = database.FirebaseDatabase.instance.ref("distance").child("critical");
    Map<String, dynamic> secondData = (await secondRef.once()).snapshot.value! as Map<String, dynamic>;
    secondDistance = secondData['value'];
    if(secondDistance >= GlobalVariable.maxDistance){
      secondRef.set({
        "alarm": true,
      });
      secondRef.onChildChanged.listen((event) {
        if(event.snapshot.key == "value" && event.snapshot.value as int >= GlobalVariable.maxDistance){
          secondRef.set({
            "alarm": true,
          });
        }
      });
    }

    database.DatabaseReference weightRef = database.FirebaseDatabase.instance.ref("weight");
    Map<String, dynamic> weightData = (await weightRef.once()).snapshot.value! as Map<String, dynamic>;
    currentWeight = weightData['value'];
    print("currentWeight: $currentWeight");
    firestore.Query<Map<String, dynamic>> historyRef = firestore.FirebaseFirestore.instance.collection("history");
    for(var doc in (await historyRef.get()).docs){
      totalCount += doc.data()!["count"];
      if(doc.id == DateTime.now().toString().substring(0, 10)){
        todayCount = doc.data()!["count"];
      }
    }

    yield {
      "totalCount": totalCount,
      "todayCount": todayCount,
      "firstDistance": firstDistance,
      "secondDistance": secondDistance,
      "currentWeight": currentWeight
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
