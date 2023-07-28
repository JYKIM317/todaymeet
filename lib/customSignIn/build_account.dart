import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:famet/main.dart' as main;
import 'package:firebase_messaging/firebase_messaging.dart';

User? _user = FirebaseAuth.instance.currentUser;
File? _image;
final _picker = ImagePicker();
final _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
final phoneNum = FirebaseAuth.instance.currentUser?.phoneNumber;
String? nameParameter, genderParameter, introduceParameter, mbtiParameter;
int? yearParameter, monthParameter, dayParameter, genderstate;
double? mannerParameter = 50.0, attend = 0;
bool photostate = false;
List<String>? category = [];

class _photobuild extends StatefulWidget {
  const _photobuild({Key? key}) : super(key: key);
  @override
  State<_photobuild> createState() => _photobuildState();
}

class _photobuildState extends State<_photobuild> {

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null){
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
      setState(() {});
    }
  }
  Future<void> _uploadImage() async {
    if (_user != null && _image != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_user!.uid)
          .child('profile.jpg');
      final uploadTask = ref.putFile(_image!);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({'photoUrl': url});
      photostate = true;
    }
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios,color: Colors.grey, size: 18.w,),
                      Text('뒤로가기',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.w,
                        ),
                      )
                    ],
                  ),
                  onTap: (){
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text('프로필 사진을\n등록해주세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 24.w,
                    ),
                  ),
                ),
              ),
              FutureBuilder(
                future: FirebaseStorage.instance
                  .ref()
                  .child('users')
                  .child(_user!.uid)
                  .child('profile.jpg')
                  .getDownloadURL(),
                  initialData: 'assets/images/defaultProfile.jpg',
                  builder: (BuildContext context, AsyncSnapshot<String> snapshot){
                  if(snapshot.hasData){
                    return InkWell(
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 90.w,
                        backgroundImage: NetworkImage(snapshot.data!),
                      ),
                      onTap: (){
                        _getImage();
                        },
                    );
                  }else {
                    return InkWell(
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 90.w,
                        backgroundImage: AssetImage('assets/images/defaultProfile.jpg') as ImageProvider<Object>,
                      ),
                      onTap: (){
                        _getImage();
                      },
                    );
                  }
                }
              ),
              Expanded(
                  flex: 2,
                  child: SizedBox()
              ),
              InkWell(
                child: Container(
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: 32.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.w),
                    color: Color(0xFF51CF6D),
                  ),
                  child:
                  Center(
                    child: Text('시작하기',
                      style: TextStyle(color: Colors.white, fontSize: 18.w),
                    ),
                  ),
                ),
                onTap: ()async{
                  final fcmToken = await FirebaseMessaging.instance.getToken();
                  if(photostate == true){
                    await _userinfo.collection('other').doc('block').set({'block':[], 'blocked':[]});
                    await _userinfo.collection('other').doc('favorite').set({'list':[]});
                    await _userinfo.collection('marketingInfo').doc('agreement').set({'agreement':'null'});
                    await _userinfo.collection('notification').doc('1nfo').set({
                      'recent':DateTime.now(),
                      'timeStamp':DateTime.now(),
                    });
                    await _userinfo.update({
                      'username':nameParameter,
                      'year': yearParameter,
                      'month': monthParameter,
                      'day': dayParameter,
                      'gender': genderParameter,
                      'manner': mannerParameter,
                      'introduce': introduceParameter,
                      'mbti': mbtiParameter,
                      'regioncategory': category,
                      'hobbycategory': category,
                      'phonenumber': phoneNum,
                      'attend': attend,
                      'canMessage':5,
                      'pushToken':fcmToken,
                    }).then((_){
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context){
                            return Center(
                              child: AlertDialog(
                                alignment: Alignment.center,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.w)
                                ),
                                content: Center(
                                    child: Text("회원가입에 감사드립니다!\n건전하고 즐거운 모임 즐겨주세요\n\n\n\n")),
                                actions: [
                                  Center(
                                    child: TextButton(
                                        child: Text('알겠습니다!',
                                            style: TextStyle(
                                              color: Color(0xFF51CF6D),
                                              fontSize: 18,
                                            )
                                        ),
                                        onPressed: (){
                                          Navigator.of(context).pop();
                                          Navigator.pushAndRemoveUntil(
                                            context, MaterialPageRoute(
                                              builder: (BuildContext context) => main.LoginPage()),
                                                (route) => false,
                                          );
                                        }
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                      );
                    });
                  }else{
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.w)
                            ),
                            content: Text("프로필 사진을 등록하지 않으셨습니다.\n다음으로 넘어가시겠습니까?"),
                            actions: [
                              TextButton(
                                  child: Text('취소',
                                      style: TextStyle(color: Colors.grey)
                                  ),
                                  onPressed: (){Navigator.of(context).pop();}
                              ),
                              TextButton(
                                  child: Text('확인',
                                      style: TextStyle(color: Color(0xFF51CF6D))
                                  ),
                                  onPressed: ()async{
                                    await _userinfo.collection('other').doc('block').set({'block':[], 'blocked':[]});
                                    await _userinfo.collection('other').doc('favorite').set({'list':[]});
                                    await _userinfo.collection('marketingInfo').doc('agreement').set({'agreement':'null'});
                                    await _userinfo.collection('notification').doc('1nfo').set({
                                      'recent':DateTime.now(),
                                      'timeStamp':DateTime.now(),
                                    });
                                    await _userinfo.set({
                                      'username':nameParameter,
                                      'year': yearParameter,
                                      'month': monthParameter,
                                      'day': dayParameter,
                                      'gender': genderParameter,
                                      'manner': mannerParameter,
                                      'introduce': introduceParameter,
                                      'mbti': mbtiParameter,
                                      'regioncategory': category,
                                      'hobbycategory': category,
                                      'phonenumber': phoneNum,
                                      'attend': attend,
                                      'photoUrl': 'https://firebasestorage.googleapis.com/v0/b/famat-c5559.appspot.com/o/defaultProfile.jpg?alt=media&token=f3475822-d392-4177-a161-94ea70391cff&_gl=1*19otzw7*_ga*NjQxOTA0NTkwLjE2Nzc4NDYzOTA.*_ga_CW55HF8NVT*MTY4NjA0NTczMi45OC4xLjE2ODYwNDYwMTkuMC4wLjA.',
                                      'canMessage':5,
                                      'pushToken':fcmToken,
                                    }).then((_){
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (BuildContext context){
                                            return Center(
                                              child: AlertDialog(
                                                alignment: Alignment.center,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(6.w)
                                                ),
                                                content: Center(
                                                    child: Text("회원가입에 감사드립니다!\n건전하고 즐거운 모임 즐겨주세요\n\n\n\n")),
                                                actions: [
                                                  Center(
                                                    child: TextButton(
                                                        child: Text('알겠습니다!',
                                                            style: TextStyle(
                                                              color: Color(0xFF51CF6D),
                                                              fontSize: 16.w,
                                                            )
                                                        ),
                                                        onPressed: (){
                                                          Navigator.of(context).pop();
                                                          Navigator.pushAndRemoveUntil(
                                                              context, MaterialPageRoute(
                                                              builder: (BuildContext context) => main.LoginPage()),
                                                                (route) => false,
                                                          );
                                                        }
                                                    ),
                                                  )
                                                ],
                                              ),
                                            );
                                          }
                                      );
                                    });
                                  }
                              )
                            ],
                          );
                        }
                    );
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


class _genderbuild extends StatefulWidget {
  const _genderbuild({Key? key}) : super(key: key);
  @override
  State<_genderbuild> createState() => _genderbuildState();
}
class _genderbuildState extends State<_genderbuild> {
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios,color: Colors.grey, size: 18.w,),
                      Text('뒤로가기',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.w,
                        ),
                      )
                    ],
                  ),
                  onTap: (){
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text('성별을 선택해주세요',
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
                  TextButton(onPressed: (){
                    genderstate = 1;
                    setState(() {});
                  }, child: Text('남성',
                    style: TextStyle(
                        fontSize: 28.w,
                        color: genderstate == 1 ? Color(0xFF51CF6D) : Colors.grey
                    ),
                  )),
                  TextButton(onPressed: (){
                    genderstate = 2;
                    setState(() {});
                  }, child: Text('여성',
                    style: TextStyle(
                        fontSize: 28.w,
                        color: genderstate == 2 ? Color(0xFF51CF6D) : Colors.grey
                    ),
                  )),
                ],
              ),
              Expanded(
                  flex: 2,
                  child: SizedBox()
              ),
              InkWell(
                child: Container(
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: 32.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.w),
                    color: Color(0xFF51CF6D),
                  ),
                  child:
                  Center(
                    child: Text('다음',
                      style: TextStyle(color: Colors.white, fontSize: 18.w),
                    ),
                  ),
                ),
                onTap: (){
                  if(genderstate == 1) genderParameter = '남성';
                  if(genderstate == 2) genderParameter = '여성';
                  if(genderstate != 1 && genderstate != 2){
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            content: Text('성별을 선택해주세요'),
                            actions: [
                              TextButton(
                                  child: Text('뒤로가기',
                                      style: TextStyle(color: Colors.grey)
                                  ),
                                  onPressed: (){Navigator.of(context).pop();}
                              ),
                            ],
                          );
                        }
                    );
                  }else{
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.w)
                            ),
                            content: Text("성별은 한 번 선택하면 변경할 수 없습니다.\n선택하신 성별이 '$genderParameter' 맞습니까?"),
                            actions: [
                              TextButton(
                                  child: Text('취소',
                                      style: TextStyle(color: Colors.grey)
                                  ),
                                  onPressed: (){Navigator.of(context).pop();}
                              ),
                              TextButton(
                                  child: Text('확인',
                                      style: TextStyle(color: Color(0xFF51CF6D))
                                  ),
                                  onPressed: (){
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                        context, MaterialPageRoute(
                                        builder: (BuildContext context) => _photobuild()
                                    ));
                                  }
                              )
                            ],
                          );
                        }
                    );
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

class AccountBuild extends StatefulWidget {
  const AccountBuild({Key? key}) : super(key: key);
  @override
  State<AccountBuild> createState() => _AccountBuildState();
}

class _AccountBuildState extends State<AccountBuild> {


  TextEditingController nameController = TextEditingController();
  TextEditingController yearController = TextEditingController();
  TextEditingController monthController = TextEditingController();
  TextEditingController dayController = TextEditingController();

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    super.initState();
  }

  Widget _birthdaybuild(){
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios,color: Colors.grey, size: 18.w,),
                      Text('뒤로가기',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.w,
                        ),
                      )
                    ],
                  ),
                  onTap: (){
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child:SizedBox(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('생년월일을 입력해주세요',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 24.w,
                          ),
                        ),
                        Text('거의 다 왔습니다 힘내요!',
                          style: TextStyle(
                              fontSize: 18.w,
                              color: Colors.grey
                          ),
                        )
                      ],
                    ),
                  )
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
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
                      decoration: InputDecoration(
                        labelText: '일',
                      ),
                      controller: dayController,
                    ),
                  ),
                ],
              ),
              Expanded(
                  flex: 2,
                  child: SizedBox()
              ),
              InkWell(
                child: Container(
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: 32.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.w),
                    color: Color(0xFF51CF6D),
                  ),
                  child:
                  Center(
                    child: Text('다음',
                      style: TextStyle(color: Colors.white, fontSize: 18.w),
                    ),
                  ),
                ),
                onTap: (){
                  yearParameter = int.parse(yearController.text);
                  monthParameter = int.parse(monthController.text);
                  dayParameter = int.parse(dayController.text);
                  if(
                  yearParameter.toString().length == 4 && monthParameter.toString().length < 3 && dayParameter.toString().length < 3 &&
                  yearParameter! <= _thisyear && monthParameter! <= 12 && dayParameter! <= 31 &&
                  monthParameter! >= 1 && dayParameter! >= 1 && yearParameter! > _thisyear-100
                  ){
                    if(monthParameter == 2 && dayParameter! > 29){
                      showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context){
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.w)
                              ),
                              content: Text('생년월일이 잘못 입력되었습니다.\n입력하신 정보를 확인해주세요'),
                              actions: [
                                TextButton(
                                    child: Text('뒤로가기',
                                        style: TextStyle(color: Colors.grey)
                                    ),
                                    onPressed: (){Navigator.of(context).pop();}
                                ),
                              ],
                            );
                          }
                      );
                    }
                    else{
                      showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.w)
                            ),
                            content: Text("생일은 한 번 설정하면 \n변경할 수 없습니다.\n설정하신 생일이 \n'$yearParameter.$monthParameter.$dayParameter' 맞습니까?"),
                            actions: [
                              TextButton(
                                  child: Text('취소',
                                      style: TextStyle(color: Colors.grey)
                                  ),
                                  onPressed: (){Navigator.of(context).pop();}
                              ),
                              TextButton(
                                  child: Text('확인',
                                      style: TextStyle(color: Color(0xFF51CF6D))
                                  ),
                                  onPressed: (){
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                        context, MaterialPageRoute(
                                        builder: (BuildContext context) => _genderbuild()
                                    ));
                                  }
                              )
                            ],
                          );
                        }
                        );
                    }
                  }else{
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.w)
                            ),
                            content: Text('생년월일이 잘못 입력되었습니다.\n입력하신 정보를 확인해주세요'),
                            actions: [
                              TextButton(
                                  child: Text('뒤로가기',
                                      style: TextStyle(color: Colors.grey)
                                  ),
                                  onPressed: (){Navigator.of(context).pop();}
                              ),
                            ],
                          );
                        }
                    );
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

  @override
  Widget build(BuildContext context) {
    nameController.text = nameParameter ?? '';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cafe',
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF51CF6D)),
                overlayColor: MaterialStateProperty.all<Color>(Colors.transparent)
            )
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFF51CF6D)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: Color(0xFF51CF6D)
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF51CF6D)))
        ),
      ),

      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.fromLTRB(26.w, 32.w, 26.w, 16.w),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 18.w),
                Expanded(
                  flex: 2,
                  child: Center(
                    child:
                    Text('이름을 설정해주세요',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 24.w,
                      ),
                    ),
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: '이름',
                    hintText: '2~6글자로 설정 가능합니다.',
                  ),
                  controller: nameController,
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox()
                ),
                InkWell(
                    child: Container(
                      alignment: Alignment.topCenter,
                      width: double.infinity,
                      height: 32.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.w),
                        color: Color(0xFF51CF6D),
                      ),
                      child:
                        Center(
                          child: Text('다음',
                            style: TextStyle(color: Colors.white, fontSize: 18.w),
                          ),
                        ),
                    ),
                  onTap: () async{
                      final quitCheck = await FirebaseFirestore.instance
                          .collection('quitUsers').where('phonenumber', isEqualTo: phoneNum).get();
                      if(quitCheck.docs.isNotEmpty){
                        final userCheck = quitCheck.docs.first.id;
                        final quitUserCheck = await FirebaseFirestore.instance.collection('quitUsers').doc(userCheck).get();
                        Map<String, dynamic>? quitUserData = quitUserCheck.data() as Map<String, dynamic>?;
                        if(quitUserData!=null){
                          FirebaseFirestore.instance.collection('users').doc(_user!.uid).set(quitUserData);
                          Navigator.pushAndRemoveUntil(
                            context, MaterialPageRoute(
                              builder: (context) => main.LoginPage()),
                                (route) => false,
                          );
                          final List subCollectionList = ['chat', 'done', 'marketingInfo', 'notification', 'other', 'review', 'room'];
                          for(String collectionName in subCollectionList){
                            await FirebaseFirestore.instance.collection('quitUsers').doc(userCheck).collection(collectionName).get().then((collectionSnapshot){
                              for(DocumentSnapshot doc in collectionSnapshot.docs){
                                Map<String, dynamic> subCollectionData = doc.data() as Map<String, dynamic>;
                                FirebaseFirestore.instance
                                    .collection('users').doc(_user!.uid)
                                    .collection(collectionName).doc('${doc.id}').set(subCollectionData);
                                doc.reference.delete();
                              }
                            });
                          }
                          FirebaseFirestore.instance.collection('quitUsers').doc(userCheck).delete();
                        }
                      }
                        nameParameter = nameController.text;
                        if(nameParameter!.length > 1 && nameParameter!.length < 7 ){
                          if(!nameParameter!.contains(' ')){
                            showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context){
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.w)
                                    ),
                                    content: Text("이름은 한 번 설정하면 변경할 수 없습니다.\n설정하신 이름이 '$nameParameter' 맞습니까?"),
                                    actions: [
                                      TextButton(
                                          child: Text('취소',
                                              style: TextStyle(color: Colors.grey)
                                          ),
                                          onPressed: (){Navigator.of(context).pop();}
                                      ),
                                      TextButton(
                                          child: Text('확인',
                                              style: TextStyle(color: Color(0xFF51CF6D))
                                          ),
                                          onPressed: (){
                                            Navigator.pop(context);
                                            Navigator.push(
                                                context, MaterialPageRoute(
                                                builder: (BuildContext context) => _birthdaybuild()
                                            ));
                                          }
                                          )
                                    ],
                                  );
                                });
                          }else{
                            showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context){
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.w)
                                    ),
                                    content: Text("이름에 공백이 들어갈 수 없습니다.\n입력하신 정보를 확인해주세요"),
                                    actions: [
                                      TextButton(
                                          child: Text('뒤로가기',
                                              style: TextStyle(color: Colors.grey)
                                          ),
                                          onPressed: (){Navigator.of(context).pop();}
                                      ),
                                    ],
                                  );
                                }
                            );
                          }
                        }else{
                          showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context){
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6.w)
                                  ),
                                  content: Text('닉네임은 2~6글자로 설정 가능합니다.'),
                                  actions: [
                                    TextButton(
                                        child: Text('뒤로가기',
                                            style: TextStyle(color: Colors.grey)
                                        ),
                                        onPressed: (){Navigator.of(context).pop();}
                                    ),
                                  ],
                                );
                              }
                          );
                        }},
                ),
                SizedBox(height: 10.w)
              ],
            ),
          ),
        ),
      ),

    );
  }
}
