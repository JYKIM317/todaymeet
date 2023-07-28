import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famet/main.dart' as main;
import 'package:yaml/yaml.dart';

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);
  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool pushdetail = false, userdetail = false, grouppush = true, marketing = true;
  User? _user = FirebaseAuth.instance.currentUser;
  var _userinfo;
  late bool eventpush;
  var currentVersion;

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    rootBundle.loadString("pubspec.yaml").then((value){
      var yamlData = loadYaml(value);
      currentVersion = yamlData['version'];
      setState(() {});
    });
    super.initState();
  }
  @override
  void dispose() {
    pushdetail = false;
    userdetail = false;
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
            padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.w),
                SizedBox(
                  child: InkWell(
                    child: Icon(Icons.arrow_back_ios,color: Colors.grey, size: 18.w),
                    onTap: (){Navigator.pop(context);},
                  ),
                ),
                SizedBox(height: 32.w),
                Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('앱 버전',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20.w,
                        ),
                      ),
                      Text('$currentVersion',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.w,
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(4.w, 6.w, 4.w, 8.w),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                ),
                SizedBox(height: 16.w),
                InkWell(
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('푸시 알림 설정',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20.w
                              ),
                            ),
                            Icon(pushdetail ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey, size: 24.w,),
                          ],
                        ),
                        pushdetail ? Container(
                          padding: EdgeInsets.fromLTRB(6.w, 30.h, 6.w, 4.w),
                          alignment: Alignment.topCenter,
                          height: 130.h,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('마케팅 수신 동의',
                                    style: TextStyle(fontSize: 16.w,),),
                                  InkWell(
                                    child: Container(
                                      width: 50.w, height: 24.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(Radius.circular(20.w)),
                                        border: Border.all(width: 1, color: eventpush ? Color(0xFF51CF6D): Colors.grey),
                                        color: eventpush ? Color(0xFF51CF6D): Colors.grey,
                                      ),
                                      padding: EdgeInsets.fromLTRB(eventpush ? 26.w : 2.w, 2.w, eventpush ? 2.w : 26.w, 2.w),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(20.w)),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    onTap: (){
                                      DateTime setTime = DateTime.now();
                                      if(eventpush){
                                        FirebaseFirestore.instance
                                            .collection('users').doc(_user!.uid)
                                            .collection('marketingInfo').doc('agreement').update({
                                          'agreement':'disagree',
                                          'setTime':setTime,
                                        });
                                        eventpush = false;
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "'오늘모임'의 광고성 정보 수신을 '비동의'하셨습니다.\n일시 : ${setTime.year}년 ${setTime.month}월${setTime.day}일"
                                                  , style: TextStyle(color: Colors.white)),
                                              duration: Duration(seconds: 5),
                                              backgroundColor: Colors.black,
                                            )
                                        );
                                      }else if(!eventpush){
                                        FirebaseFirestore.instance
                                            .collection('users').doc(_user!.uid)
                                            .collection('marketingInfo').doc('agreement').update({
                                          'agreement':'agree',
                                          'setTime':setTime,
                                        });
                                        eventpush = true;
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "'오늘모임'의 광고성 정보 수신을 '동의'하셨습니다.\n일시 : ${setTime.year}년 ${setTime.month}월${setTime.day}일"
                                                  , style: TextStyle(color: Colors.white)),
                                              duration: Duration(seconds: 5),
                                              backgroundColor: Colors.black,
                                            )
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ) : SizedBox(height: 0)
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(4.w, 6.w, 4.w, 8.w),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                  ),
                  onTap: () async{
                    final pushAgreement = await FirebaseFirestore.instance
                        .collection('users').doc(_user!.uid)
                        .collection('marketingInfo').doc('agreement').get();
                    var agreement = pushAgreement.get('agreement');
                    if(agreement == 'agree'){
                      eventpush = true;
                    }else{
                      eventpush = false;
                    }
                    pushdetail ? pushdetail = false : pushdetail = true;
                    setState(() {});
                  },
                ),
                SizedBox(height: 16.w),
                InkWell(
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('유저정보',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20.w
                              ),
                            ),
                            Icon(userdetail ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey, size: 24.w,),
                          ],
                        ),
                        userdetail ? Container(
                          padding: EdgeInsets.fromLTRB(6.w, 24.h, 6.w, 4.w),
                          alignment: Alignment.topCenter,
                          height: 280.h,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text('UID',
                                        style: TextStyle(fontSize: 16.w,),),
                                      SizedBox(width: 6.w),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: 210.w),
                                        child: Text(_user!.uid,
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.w,
                                            ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                    ],
                                  ),
                                  IconButton(onPressed: (){
                                    Clipboard.setData(ClipboardData(text: _user!.uid));
                                  },icon: Icon(Icons.content_copy, color: Colors.grey, size: 18.w,),
                                    padding: EdgeInsets.fromLTRB(6.w, 4.w, 6.w, 4.w),
                                  )
                                ],
                              ),
                              SizedBox(height: 50.h),
                              InkWell(
                                child: Container(
                                    padding: EdgeInsets.fromLTRB(8.w, 10.w, 8.w, 10.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(6.w)),
                                      border: Border.all(width: 1, color: Color(0xFFEF5350)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('회원탈퇴')
                                ),
                                onTap: (){
                                  showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context){
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6.w)
                                          ),
                                          content: Text('정말 계정을 탈퇴 하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                                child: Text('취소',
                                                    style: TextStyle(color: Colors.grey)
                                                ),
                                                onPressed: (){Navigator.of(context).pop();}
                                            ),
                                            TextButton(
                                                child: Text('탈퇴',
                                                    style: TextStyle(color: Color(0xFFEF5350))
                                                ),
                                                onPressed: () async{
                                                  Navigator.pop(context);
                                                  final quitData = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
                                                  Map<String, dynamic> quitSave = quitData.data() as Map<String, dynamic>;
                                                  await FirebaseFirestore.instance.collection('quitUsers').doc(_user!.uid).set(quitSave);
                                                  final List subCollectionList = ['chat', 'done', 'marketingInfo', 'notification', 'other', 'review', 'room'];
                                                  for(String collectionName in subCollectionList){
                                                    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection(collectionName).get().then((collectionSnapshot){
                                                      for(DocumentSnapshot doc in collectionSnapshot.docs){
                                                        Map<String, dynamic> subCollectionData = doc.data() as Map<String, dynamic>;
                                                        FirebaseFirestore.instance
                                                            .collection('quitUsers').doc(_user!.uid)
                                                            .collection(collectionName).doc('${doc.id}').set(subCollectionData);
                                                        doc.reference.delete();
                                                      }
                                                    });
                                                  }
                                                  /*Navigator.pushAndRemoveUntil(
                                                    context, MaterialPageRoute(
                                                      builder: (context) => main.LoginPage()),
                                                        (route) => false,
                                                  );*/ //일단 login 페이지로 이동 대신 exit 코드로 앱 종료 처리함
                                                  FirebaseFirestore.instance.collection('users').doc(_user!.uid).delete();
                                                  FirebaseStorage.instance.ref()
                                                      .child('users').child(_user!.uid).child('profile.jpg').delete();
                                                  FirebaseAuth.instance.currentUser!.delete();
                                                  exit(0);
                                                }
                                            )
                                          ],
                                        );
                                      }
                                  );
                                },
                              ),
                              SizedBox(height: 28.h),
                              InkWell(
                                child: Container(
                                    padding: EdgeInsets.fromLTRB(8.w, 10.w, 8.w, 10.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(6.w)),
                                      border: Border.all(width: 1, color: Color(0xFF51CF6D)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('로그아웃')
                                ),
                                onTap: () async{
                                  showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context){
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6.w)
                                          ),
                                          content: Text('정말 로그아웃 하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                                child: Text('취소',
                                                    style: TextStyle(color: Colors.grey)
                                                ),
                                                onPressed: (){Navigator.of(context).pop();}
                                            ),
                                            TextButton(
                                                child: Text('로그아웃',
                                                    style: TextStyle(color: Color(0xFF51CF6D))
                                                ),
                                                onPressed: () async{
                                                  await FirebaseAuth.instance.signOut();
                                                  Navigator.pushAndRemoveUntil(
                                                    context, MaterialPageRoute(
                                                      builder: (context) => main.LoginPage()),
                                                        (route) => false,
                                                  );
                                                }
                                            )
                                          ],
                                        );
                                      }
                                  );
                                },
                              ),
                            ],
                          ),
                        ) : SizedBox(height: 0)
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(4.w, 6.w, 4.w, 8.w),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                  ),
                  onTap: (){
                    userdetail ? userdetail = false : userdetail = true;
                    setState(() {});
                  },
                ),
              ],
            )
        ),
      ),
    );
  }
}
