import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famet/customProfile/people_Profile_View.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:famet/customProfile/review.screen.dart';
import 'dart:math' as math;

User? _user = FirebaseAuth.instance.currentUser;
late DocumentReference _roominfoD;

class DoneRoomPage extends StatefulWidget {
  final roomname;
  const DoneRoomPage({Key? key, required this.roomname}) : super(key: key);
  @override
  State<DoneRoomPage> createState() => _DoneRoomPageState();
}

class _DoneRoomPageState extends State<DoneRoomPage> {
  List member = [], memberphoto = [];

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    _roominfoD = FirebaseFirestore.instance.collection('users').doc('${_user!.uid}').collection('done').doc('${widget.roomname}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 32.w, 20.w, 10.w),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        child: InkWell(
                          child: Icon(Icons.arrow_back_ios,color: Colors.grey, size: 18.w),
                          onTap: (){Navigator.pop(context);},
                        ),
                      ),
                      SizedBox(height: 24.w),
                      FutureBuilder<DocumentSnapshot>(
                          future: _roominfoD.get(),
                          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
                            if(snapshot.hasError) return Text('');
                            if(snapshot.connectionState == ConnectionState.waiting) return Center(child: Text(''));
                            Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
                            if(data == null) return SizedBox(height: 0);
                            List<dynamic> headcount = data['memberUID'];
                            member = headcount;
                            String? categoryTextH = data['Categories'].join('  ');
                            List<dynamic> memberPhotoUrl = data['memberPhotoUrl'];
                            memberphoto = memberPhotoUrl;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border:Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1
                                          )
                                      )
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(10.w),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${data['title']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16.w,
                                            ),
                                          ),
                                          SizedBox(height: 10.w),
                                          Row(
                                            children: [
                                              Text('장소: ',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.w,
                                                  )
                                              ),
                                              Text('${data['place']}',
                                                  style: TextStyle(fontSize: 12.w)
                                              )
                                            ],
                                          ),
                                          SizedBox(height: 4.w),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text('약속시간: ',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 12.w,
                                                      )
                                                  ),
                                                  Text('${data['targetYear']}년${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                                                      style: TextStyle(fontSize: 12.w)
                                                  )
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text('인원: ',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 12.w,
                                                      )
                                                  ),
                                                  Text('${headcount.length}/${data['headcount']}',
                                                      style: TextStyle(fontSize: 12.w)
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ]
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border:Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1
                                          )
                                      )
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(10.w, 20.w, 10.w, 20.w),
                                    child: Text('${data['info']}',
                                        style: TextStyle(fontSize: 12.w)
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border:Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1
                                          )
                                      )
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(10.w, 20.w, 10.w, 10.w),
                                    child: Text('$categoryTextH',
                                        style: TextStyle(fontSize: 12.w)
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24.w),
                                Container(
                                  padding: EdgeInsets.all(5.w),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border:Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1
                                          )
                                      )
                                  ),
                                  child: Row(
                                    children: [
                                      Text('현재 참가중인 멤버',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.w,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text('사진을 클릭하여 프로필 보기',
                                        style: TextStyle(
                                          fontSize: 8.w,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.w),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            child: CircleAvatar(
                                              backgroundColor: Colors.grey,
                                              radius: 34.w,
                                              backgroundImage: NetworkImage('${data['hostPhotoUrl']}'),
                                            ),
                                            onTap: (){
                                              Navigator.push(context,
                                                  MaterialPageRoute(builder: (context) => OtherProfile(user: data['hostUID']))
                                              );
                                            }, //해당 유저 프로필로 이동
                                          ),
                                          SizedBox(width: 8.w),
                                          if(memberPhotoUrl!.length >= 1)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][0]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][1]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if(memberPhotoUrl.length >= 2)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][1]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][2]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if(memberPhotoUrl.length >= 3)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][2]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][3]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8.w),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          if(memberPhotoUrl!.length >= 4)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][3]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][4]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if(memberPhotoUrl!.length >= 5)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][4]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][5]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if(memberPhotoUrl.length >= 6)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][5]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][6]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if(memberPhotoUrl.length >= 7)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][6]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][7]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8.w),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          if(memberPhotoUrl.length >= 8)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][7]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][8]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if(memberPhotoUrl.length >= 9)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage('${data['memberPhotoUrl'][8]}'),
                                              ),
                                              onTap: (){
                                                Navigator.push(context,
                                                    MaterialPageRoute(builder: (context) => OtherProfile(user: data['memberUID'][9]))
                                                );
                                              }, //해당 유저 프로필로 이동
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                      ),
                    ],
                  ),
                  Center(
                      child: Transform.rotate(
                        angle: 320 * math.pi/180,
                        child: DottedBorder(
                          color: Color(0xFFD32F2F),
                          strokeWidth: 6.w,
                          dashPattern: [46.w, 8.w, 34.w, 4.w], // 22 , 10 / 8 ,  4
                          child: Container(
                            alignment: Alignment.center,
                            width: 280.w,
                            height: 56.w,
                            color: Colors.transparent,
                            child: Text('모임 완료',
                                style: TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28.w)),
                          ),
                        ),
                      )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
        StreamBuilder(
          stream: _roominfoD.snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
            if(snapshot.hasError) return Text('');
            if(snapshot.connectionState == ConnectionState.waiting) return Center(child: Text(''));
            Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
            if(data == null) return SizedBox(height: 0);
            List<dynamic> absentUsers = data['absent'] ?? [];
            return data['reviewState'] == false ?
            InkWell(
              child: BottomAppBar(
                height: 42.w,
                color: Color(0xFF51CF6D),
                child: Center(
                  child: Text('후기작성',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.w
                      )
                  ),
                ),
              ),
              onTap: (){
                if(absentUsers.contains(_user!.uid)){
                  showDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context){
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.w)
                          ),
                          content: Text("참석하지 않은 모임은\n후기를 작성할 수 없습니다."),
                        );
                      }
                  );
                }else{
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ReviewPage(roomname: _roominfoD, roomNum: widget.roomname,))
                  );
                }
              },
            ): BottomAppBar(
              height: 42.w,
              color: Colors.grey,
              child: Center(
                child: Text('작성완료',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.w
                    )
                ),
              ),
            );
          },
        )
    );
  }
}