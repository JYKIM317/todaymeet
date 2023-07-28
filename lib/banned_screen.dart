import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart' as main;

class BannedPage extends StatelessWidget {
  final bannedUser;
  const BannedPage({Key? key, required this.bannedUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bannedUsers').doc(bannedUser).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
          if(snapshot.hasError) return Text('');
          if(snapshot.connectionState == ConnectionState.waiting) return Text('');
          Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
          if(data == null){
            if(Platform.isAndroid) SystemNavigator.pop();
            if(Platform.isIOS) exit(0);
          }
          DateTime bannedFrom = data!['from'].toDate();
          DateTime bannedTo = data['to'].toDate();
          String? reason = data['reason'];
          String fromTime = '${bannedFrom.year}년${bannedFrom.month}월${bannedFrom.day}일 ${bannedFrom.hour}:${bannedFrom.minute.toString().length == 1 ? '0${bannedFrom.minute.toString()}': bannedFrom.minute}';
          String toTime = '${bannedTo.year}년${bannedTo.month}월${bannedTo.day}일 ${bannedTo.hour}:${bannedTo.minute.toString().length == 1 ? '0${bannedTo.minute.toString()}': bannedTo.minute}';
          if(bannedTo.isBefore(DateTime.now())){
            FirebaseFirestore.instance.collection('bannedUsers').doc(bannedUser).delete();
            if(Platform.isAndroid) SystemNavigator.pop();
            if(Platform.isIOS) exit(0);
          }
          return Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            padding: EdgeInsets.fromLTRB(24.w, 12.w, 24.w, 12.w),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.block, size: 160.w, color: Color(0xFFEF5350).withOpacity(0.5),),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 12.w,),
                    Text('이용수칙 위반으로\n서비스 이용이 정지되었습니다.',
                      style: TextStyle(fontSize: 18.w, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.w),
                    Text('정지사유',
                      style: TextStyle(fontSize: 18.w, fontWeight: FontWeight.w700),
                    ),
                    Text('$reason',
                        style: TextStyle(fontSize: 18.w),
                    ),
                    SizedBox(height: 12.w),
                    Text('정지기간',
                      style: TextStyle(fontSize: 18.w, fontWeight: FontWeight.w700),
                    ),
                    Text('$fromTime 부터\n~\n$toTime 까지',
                      style: TextStyle(fontSize: 18.w),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      )
    );
  }
}
