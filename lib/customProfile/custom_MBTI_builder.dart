import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _user = FirebaseAuth.instance.currentUser;
final _userinfo =
    FirebaseFirestore.instance.collection('users').doc(_user!.uid);

class MBTIbuilder extends StatefulWidget {
  const MBTIbuilder({Key? key}) : super(key: key);

  @override
  State<MBTIbuilder> createState() => _MBTIbuilderState();
}

class _MBTIbuilderState extends State<MBTIbuilder> {
  bool? eiState, snState, tfState, jpState;
  String? eiParameter, snParameter, tfParameter, jpParameter, mbtiparameter;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF51CF6D)),
                overlayColor:
                    MaterialStateProperty.all<Color>(Colors.transparent))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF51CF6D)))),
        fontFamily: 'Cafe',
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('MBTI를 선택해주세요',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                SizedBox(height: 48),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () {
                            eiState = true;
                            eiParameter = 'E';
                            setState(() {});
                          },
                          child: Text('E',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: eiState == true
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                      TextButton(
                          onPressed: () {
                            snState = true;
                            snParameter = 'S';
                            setState(() {});
                          },
                          child: Text('S',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: snState == true
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                      TextButton(
                          onPressed: () {
                            tfState = true;
                            tfParameter = 'T';
                            setState(() {});
                          },
                          child: Text('T',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: tfState == true
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                      TextButton(
                          onPressed: () {
                            jpState = true;
                            jpParameter = 'J';
                            setState(() {});
                          },
                          child: Text('J',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: jpState == true
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                    ]),
                SizedBox(height: 24),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () {
                            eiState = false;
                            eiParameter = 'I';
                            setState(() {});
                          },
                          child: Text('I',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: eiState == false
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                      TextButton(
                          onPressed: () {
                            snState = false;
                            snParameter = 'N';
                            setState(() {});
                          },
                          child: Text('N',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: snState == false
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                      TextButton(
                          onPressed: () {
                            tfState = false;
                            tfParameter = 'F';
                            setState(() {});
                          },
                          child: Text('F',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: tfState == false
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                      TextButton(
                          onPressed: () {
                            jpState = false;
                            jpParameter = 'P';
                            setState(() {});
                          },
                          child: Text('P',
                              style: TextStyle(
                                  fontSize: 32,
                                  color: jpState == false
                                      ? Color(0xFF51CF6D)
                                      : Colors.grey))),
                    ]),
                SizedBox(height: 56),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('취소',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 28))),
                    TextButton(
                        onPressed: () async {
                          mbtiparameter =
                              '$eiParameter$snParameter$tfParameter$jpParameter';
                          if (mbtiparameter?.length == 4) {
                            await _userinfo.update({
                              'mbti': mbtiparameter,
                            });
                            setState(() {});
                            Navigator.pop(context);
                          } else {
                            showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Text('선택되지 않은 항목이 있습니다.'),
                                    actions: [
                                      TextButton(
                                          child: Text('뒤로가기',
                                              style: TextStyle(
                                                  color: Colors.black
                                                      .withOpacity(0.7))),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          }),
                                    ],
                                  );
                                });
                          }
                        },
                        child: Text('완료', style: TextStyle(fontSize: 28)))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
