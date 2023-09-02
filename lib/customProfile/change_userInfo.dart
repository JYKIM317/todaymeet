import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

int? yearParameter, monthParameter, dayParameter, genderstate;
String? genderParameter;
User? _user = FirebaseAuth.instance.currentUser;
var _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);

class BirthDayChange extends StatefulWidget {
  const BirthDayChange({super.key});

  @override
  State<BirthDayChange> createState() => _BirthDayChangeState();
}

class _BirthDayChangeState extends State<BirthDayChange> {
  TextEditingController yearController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController dayController = TextEditingController();

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int _thisyear = int.parse(DateTime.now().year.toString());
    yearController.text = yearParameter?.toString() ?? '';
    monthController.text = monthParameter?.toString() ?? '';
    dayController.text = dayParameter?.toString() ?? '';

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(26.w, 32.w, 26.w, 16.w),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  child: SizedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: Colors.grey,
                          size: 18.w,
                        ),
                        Text(
                          '뒤로가기',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.w,
                          ),
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                    child: SizedBox(
                  child: Text(
                    '생년월일을 입력해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 24.w,
                    ),
                  ),
                )),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '년도',
                      ),
                      controller: yearController,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '월',
                      ),
                      controller: monthController,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '일',
                      ),
                      controller: dayController,
                    ),
                  ),
                ],
              ),
              Expanded(flex: 2, child: SizedBox()),
              InkWell(
                child: Container(
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: 32.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.w),
                    color: Color(0xFF51CF6D),
                  ),
                  child: Center(
                    child: Text(
                      '다음',
                      style: TextStyle(color: Colors.white, fontSize: 18.w),
                    ),
                  ),
                ),
                onTap: () {
                  print('year type is ${yearController.text.runtimeType}');
                  yearParameter = int.parse(yearController.text);
                  print('exchange year type is ${yearParameter.runtimeType}');
                  monthParameter = int.parse(monthController.text);
                  dayParameter = int.parse(dayController.text);
                  if (yearParameter.toString().length == 4 &&
                      monthParameter.toString().length < 3 &&
                      dayParameter.toString().length < 3 &&
                      yearParameter! <= _thisyear &&
                      monthParameter! <= 12 &&
                      dayParameter! <= 31 &&
                      monthParameter! >= 1 &&
                      dayParameter! >= 1 &&
                      yearParameter! > _thisyear - 100) {
                    if (monthParameter == 2 && dayParameter! > 29) {
                      showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.w)),
                              content:
                                  Text('생년월일이 잘못 입력되었습니다.\n입력하신 정보를 확인해주세요'),
                              actions: [
                                TextButton(
                                    child: Text('뒤로가기',
                                        style: TextStyle(color: Colors.grey)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }),
                              ],
                            );
                          });
                    } else {
                      showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.w)),
                              content: Text(
                                  "생일은 한 번 설정하면 \n변경할 수 없습니다.\n설정하신 생일이 \n'$yearParameter.$monthParameter.$dayParameter' 맞습니까?"),
                              actions: [
                                TextButton(
                                    child: Text('취소',
                                        style: TextStyle(color: Colors.grey)),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }),
                                TextButton(
                                    child: Text('확인',
                                        style: TextStyle(
                                            color: Color(0xFF51CF6D))),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _userinfo.update({
                                        'year': yearParameter,
                                        'month': monthParameter,
                                        'day': dayParameter,
                                      });
                                      Navigator.of(context).pop();
                                    })
                              ],
                            );
                          });
                    }
                  } else {
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.w)),
                            content: Text('생년월일이 잘못 입력되었습니다.\n입력하신 정보를 확인해주세요'),
                            actions: [
                              TextButton(
                                  child: Text('뒤로가기',
                                      style: TextStyle(color: Colors.grey)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  }),
                            ],
                          );
                        });
                  }
                },
              ),
              SizedBox(height: 10.w)
            ],
          ),
        ),
      ),
    );
  }
}

class GenderChange extends StatefulWidget {
  const GenderChange({super.key});

  @override
  State<GenderChange> createState() => _GenderChangeState();
}

class _GenderChangeState extends State<GenderChange> {
  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(26.w, 32.w, 26.w, 16.w),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  child: SizedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: Colors.grey,
                          size: 18.w,
                        ),
                        Text(
                          '뒤로가기',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.w,
                          ),
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    '성별을 선택해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 24.w,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () {
                        genderstate = 1;
                        setState(() {});
                      },
                      child: Text(
                        '남성',
                        style: TextStyle(
                            fontSize: 28.w,
                            color: genderstate == 1
                                ? Color(0xFF51CF6D)
                                : Colors.grey),
                      )),
                  TextButton(
                      onPressed: () {
                        genderstate = 2;
                        setState(() {});
                      },
                      child: Text(
                        '여성',
                        style: TextStyle(
                            fontSize: 28.w,
                            color: genderstate == 2
                                ? Color(0xFF51CF6D)
                                : Colors.grey),
                      )),
                ],
              ),
              Expanded(flex: 2, child: SizedBox()),
              InkWell(
                child: Container(
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: 32.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.w),
                    color: Color(0xFF51CF6D),
                  ),
                  child: Center(
                    child: Text(
                      '다음',
                      style: TextStyle(color: Colors.white, fontSize: 18.w),
                    ),
                  ),
                ),
                onTap: () {
                  if (genderstate == 1) genderParameter = '남성';
                  if (genderstate == 2) genderParameter = '여성';
                  if (genderstate != 1 && genderstate != 2) {
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Text('성별을 선택해주세요'),
                            actions: [
                              TextButton(
                                  child: Text('뒤로가기',
                                      style: TextStyle(color: Colors.grey)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  }),
                            ],
                          );
                        });
                  } else {
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.w)),
                            content: Text(
                                "성별은 한 번 선택하면 변경할 수 없습니다.\n선택하신 성별이 '$genderParameter' 맞습니까?"),
                            actions: [
                              TextButton(
                                  child: Text('취소',
                                      style: TextStyle(color: Colors.grey)),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  }),
                              TextButton(
                                  child: Text('확인',
                                      style:
                                          TextStyle(color: Color(0xFF51CF6D))),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _userinfo.update({
                                      'gender': genderParameter,
                                    });
                                    Navigator.of(context).pop();
                                  })
                            ],
                          );
                        });
                  }
                },
              ),
              SizedBox(height: 10.w)
            ],
          ),
        ),
      ),
    );
  }
}
