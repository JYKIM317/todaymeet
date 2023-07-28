import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:famet/customProfile/custom_MBTI_builder.dart';
import 'package:famet/customProfile/profile_CategoryBuild.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'simple_Review.dart';
import 'block_Member_Manage.dart';
import 'tos_view.dart';
import 'full_ProfilePhoto.dart';
import 'notice_view.dart';
import 'setting_view.dart' as setting;
import 'package:famet/main.dart' as main;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final _picker = ImagePicker();
  User? _user = FirebaseAuth.instance.currentUser;
  File? _image;

  Widget bannerAd() {
    BannerAdListener bannerAdListener = BannerAdListener(onAdWillDismissScreen: (ad){
      ad.dispose();
    });

    BannerAd _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      listener: bannerAdListener,
      request: AdRequest(),
    );

    _bannerAd.load();

    return SizedBox(
      height: 60.h,
      width: double.infinity,
      child: AdWidget(ad: _bannerAd),
    );
  }

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          _user = user;
        });
      }
    });
    super.initState();
  }

  bool introState = false, categoryState = false;
  Widget _buildUserInfo(){
    TextEditingController introduceController = TextEditingController();
    String? introduceparameter;
    final _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    return FutureBuilder<DocumentSnapshot>(
        future: _userinfo.get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
        if(snapshot.hasError) return Text('오류가 발생했습니다.');
        if(snapshot.connectionState == ConnectionState.waiting) return Text('');
        Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
        List<dynamic>? regionCategory = data?['regioncategory'] as List<dynamic>?;
        List<dynamic>? hobbyCategory = data?['hobbycategory'] as List<dynamic>?;
        String categoryTextR = regionCategory?.join('  ') ?? '';
        String categoryTextH = hobbyCategory?.join('  ') ?? '';
        var attendCount = data?['attend'];
        introduceController.text = data?['introduce'] ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    InkWell(
                      child: Hero(
                        tag: 'profilePhoto',
                        child: CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 90.w,
                            backgroundImage: NetworkImage(data?['photoUrl'])
                        ),
                      ),
                      onTap: (){
                        Navigator.push(
                            context, MaterialPageRoute(
                            builder: (context)=> FullScreenPhoto(photo: data?['photoUrl'])
                        ));
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                      child: IconButton(
                        onPressed: (){
                          _getImage();
                        },
                        icon: Icon(Icons.collections, size: 20.w,),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 42.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48.w,
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 15.w),
                      child: Text(
                          '이름',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF51CF6D),
                          fontSize: 16.w,
                        ),
                      ),
                    ),
                    SizedBox(
                      child: Text(
                          data?['username'] ?? '이름이 없습니다.',
                        style: TextStyle(
                            fontSize: 22.w,
                            fontWeight: FontWeight.w700
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48.w,
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 15.w),
                      child: Text(
                        '생년월일',
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF51CF6D),
                            fontSize: 16.w
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130.w,
                      child: Text(
                          "${data?['year']}.${data?['month']}",
                        style: TextStyle(
                            fontSize: 22.w,
                            fontWeight: FontWeight.w700
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48.w,
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 15.w),
                      child: Text(
                        '성별',
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF51CF6D),
                            fontSize: 16.w
                        ),
                      ),
                    ),
                    SizedBox(
                      child: Text(
                        data?['gender'] ?? "null",
                        style: TextStyle(
                            fontSize: 22.w,
                            fontWeight: FontWeight.w700
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48.w,
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 15.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('매너점수',
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF51CF6D),
                                fontSize: 16.w
                            ),
                          ),
                          IconButton(onPressed: (){
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context){
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.w)
                                    ),
                                    title: Text('매너점수는 어떻게 올리나요?',
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF51CF6D),
                                        fontSize: 20.w
                                      ),
                                    ),
                                    content: Text('모임 참가자 간 리뷰를 통해\n점수가 오르거나 떨어지게 됩니다\n배려있는 모임활동을 통해 매너점수를 올려보세요!\n\n초기 점수는 50점으로 시작합니다.',
                                      style: TextStyle(fontSize: 16.w),
                                    ),
                                  );
                                }
                            );
                          }, icon: Icon(Icons.help_center_outlined, size: 18.w,),
                            alignment: Alignment.centerLeft,
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 130.w,
                      child: Text(
                        "${data?['manner'] >= 100 ? 100 : data?['manner'] <= 0 ? 0 : data?['manner']} 점",
                        style: TextStyle(
                            fontSize: 22.w,
                            fontWeight: FontWeight.w700
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  child: InkWell(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 48.w,
                          alignment: Alignment.center,
                          padding: EdgeInsets.fromLTRB(0, 15.w, 0, 10.w),
                          child: Text(
                            '자기소개',
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF51CF6D),
                                fontSize: 16.w
                            ),
                          ),
                        ),
                        Icon(Icons.edit, size: 18.w,)
                      ],
                    ),
                    onTap: (){
                      introState = true;
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  child:
                  introState == false
                      ? data!['introduce']!=null && data['introduce']!=""
                      ? Text(data['introduce'],
                          style: TextStyle(
                            fontSize: 18.w,
                            fontWeight: FontWeight.w500,
                          ),
                  ) :Text(
                    "자기소개가 작성되지 않았습니다.\n자기소개를 작성해주세요",
                    style: TextStyle(
                        fontSize: 18.w,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.withOpacity(0.8)
                    ),
                  )
                      : Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: Column(
                            children: [
                              TextField(
                                controller: introduceController,
                                maxLines: null,
                              ),
                              SizedBox(height: 6.w),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(onPressed: (){
                                    setState(() {
                                      introState = false;
                                    });
                                    }, child: Text('취소하기', style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18.w,))
                                  ),
                                  SizedBox(width: 8.w),
                                  TextButton(onPressed:()async{
                                    introduceparameter = introduceController.text;
                                    await _userinfo.update({
                                      'introduce':introduceparameter,
                                    });
                                    setState(() { introState = false; });
                                    }, child: Text('수정하기', style: TextStyle(fontSize: 18.w,))
                                  ),
                                ],
                              )
                            ],
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  child: InkWell(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 48.w,
                          alignment: Alignment.center,
                          padding: EdgeInsets.only(top: 15.w),
                          child: Text(
                            '관심 카테고리',
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF51CF6D),
                                fontSize: 16.w
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 15.w),
                          child: Icon(Icons.edit, size: 18.w,),
                        )
                      ],
                    ),
                    onTap: ()async{
                      await Navigator.push(
                          context, MaterialPageRoute(
                          builder: (context)=> MyCategory()
                      ));
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                    child:
                    (categoryTextR != '' && data!['regioncategory'] != null) || (categoryTextH != '' && data!['hobbycategory'] != null)
                        ? Text(
                      '$categoryTextR  $categoryTextH',
                      style: TextStyle(
                        fontSize: 22.w,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF51CF6D),
                      ),
                    )
                        :Text(
                      "관심 카테고리를 설정하지 않았습니다.\n관심있는 카테고리를 선택해주세요",
                      style: TextStyle(
                          fontSize: 18.w,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.withOpacity(0.8)
                      ),
                    )
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  child: InkWell(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 48.w,
                          alignment: Alignment.center,
                          padding: EdgeInsets.only(top: 15.w),
                          child: Text(
                            'MBTI',
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF51CF6D),
                                fontSize: 16.w
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 15.w),
                          child: Icon(Icons.edit, size: 20.w,),
                        )
                      ],
                    ),
                    onTap: ()async{
                      await Navigator.push(
                          context, MaterialPageRoute(
                          builder: (context)=> MBTIbuilder()
                      ));
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  child: data?['mbti'] != null
                      ? Text(
                    data?['mbti'],
                    style: TextStyle(
                        fontSize: 22.w,
                        fontWeight: FontWeight.w700
                    ),
                  )
                      :Text(
                    "MBTI를 설정해주세요.",
                    style: TextStyle(
                        fontSize: 18.w,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.withOpacity(0.8)
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48.w,
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 15.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('참석률',
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF51CF6D),
                                fontSize: 16.w
                            ),
                          ),
                          IconButton(onPressed: (){
                            showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context){
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.w)
                                    ),
                                    title: Text('참석률이 무엇인가요?',
                                      style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          decorationColor: Color(0xFF51CF6D),
                                          fontSize: 20.w
                                      ),
                                    ),
                                    content: Text('모임이 정상적으로 시작되고,\n실제로 모임에 참가한 비율을 알려줍니다.\n약속을 지키는 것은 서로에 대한 배려이니\n모임을 약속했다면 지키도록 노력해야합니다.',
                                        style: TextStyle(fontSize: 16.w)),
                                  );
                                }
                            );
                          }, icon: Icon(Icons.help_center_outlined, size: 18.w,),
                            alignment: Alignment.centerLeft,
                          )
                        ],
                      ),
                    ),
                    FutureBuilder(
                      future: _userinfo.collection('done').get(),
                      builder: (context, snapshot){
                        if(snapshot.hasError) return Text('');
                        if(snapshot.connectionState == ConnectionState.waiting) return Text('');
                        final List<DocumentSnapshot> doneRoomCount = snapshot.data!.docs;
                        double attendPercent = attendCount / doneRoomCount.length * 100;
                        return SizedBox(
                          child: doneRoomCount.isNotEmpty
                              ? Text(
                            "${attendPercent.round()}%",
                            style: TextStyle(
                                fontSize: 22.w,
                                fontWeight: FontWeight.w700
                            ),
                          )
                              :Text(
                            "-",
                            style: TextStyle(
                                fontSize: 22.w,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.withOpacity(0.8)
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                FutureBuilder<QuerySnapshot>(
                    future: _userinfo.collection('review').get(),
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                      if(snapshot.hasError) return Text('오류가 발생했습니다.');
                      if(snapshot.connectionState == ConnectionState.waiting) return Text('');
                      List<DocumentSnapshot>? data = snapshot.data!.docs.reversed.toList();
                      int fieldCount = data.length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            child: InkWell(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 48.w,
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.only(top: 15.w),
                                    child: Text(
                                      '한 줄 후기',
                                      style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          decorationColor: Color(0xFF51CF6D),
                                          fontSize: 16.w
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(top: 15.w),
                                    child: Icon(Icons.folder_open, size: 20.w,),
                                  )
                                ],
                              ),
                              onTap: (){
                                Navigator.push(context,
                                    MaterialPageRoute(builder:
                                        (context) => SimpleReview(member: _user!.uid, reviews: data))
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 130.w,
                            child: Text('$fieldCount 건',
                                style: TextStyle(
                                    fontSize: 22.w,
                                    fontWeight: FontWeight.w700
                                )
                            ),
                          ),
                        ],
                      );
                    }),
              ],
            ),
            SizedBox(height: 24.w),
            bannerAd(),
          ],
        );
      }
    );
  }

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
          .update({'photoUrl': url});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 10.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 14.w, width: double.infinity,),
                _buildUserInfo(),
                SizedBox(height: 24.w,),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.5),
                  width: 2.w,
                ))
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 0, width: double.infinity,),
                Row(
                  children: [
                    InkWell(
                      child: SizedBox(
                        width: 100.w,
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 20.w, color: Colors.grey,),
                            SizedBox(width: 4.w),
                            Text('설정', style: TextStyle(fontSize: 14.w),),
                          ],
                        ),
                      ),
                      onTap: (){
                        Navigator.push(context,
                            MaterialPageRoute(builder:
                                (context) => setting.Setting())
                        );
                      },
                    ),
                    SizedBox(width: 40.w),
                    InkWell(
                      child: SizedBox(
                        width: 120.w,
                        child: Row(
                          children: [
                            Icon(Icons.person_off, size: 20.w, color: Colors.grey,),
                            SizedBox(width: 4.w),
                            Text('차단회원 관리', style: TextStyle(fontSize: 14.w),),
                          ],
                        ),
                      ),
                      onTap: (){
                        Navigator.push(context,
                            MaterialPageRoute(builder:
                                (context) => BlockManage())
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 14.w),
                InkWell(
                  child: SizedBox(
                    width: 100.w,
                    child: Row(
                      children: [
                        Icon(Icons.campaign_outlined, size: 20.w, color: Colors.grey,),
                        SizedBox(width: 4.w),
                        Text('공지사항', style: TextStyle(fontSize: 14.w),),
                      ],
                    ),
                  ),
                  onTap: (){
                    Navigator.push(context,
                        MaterialPageRoute(builder:
                            (context) => NoticeView())
                    );
                  },
                ),
                SizedBox(height: 14.w),
                InkWell(
                  child: SizedBox(
                    width: 100.w,
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 20.w, color: Colors.grey,),
                        SizedBox(width: 4.w),
                        Text('이용약관', style: TextStyle(fontSize: 14.w),),
                      ],
                    ),
                  ),
                  onTap: (){
                    Navigator.push(context,
                        MaterialPageRoute(builder:
                            (context) => ToSView())
                    );
                  },
                ),
                SizedBox(height: 14.w),
                InkWell(
                  child: SizedBox(
                    width: 100.w,
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, size: 20.w, color: Colors.grey,),
                        SizedBox(width: 4.w),
                        Text('문의하기', style: TextStyle(fontSize: 14.w),),
                      ],
                    ),
                  ),
                  onTap: () async{
                    final Email email = Email(
                      recipients: ['delivalue100@gmail.com'],
                      subject: '페멧 서비스 문의',
                      body: '사용자 : ${_user!.uid}\n\n내용:',
                    );
                    try{
                      await FlutterEmailSender.send(email);
                    } catch (error){
                      showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context){
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.w)
                              ),
                              content: Container(
                                padding: EdgeInsets.fromLTRB(6.w, 8.w, 6.w, 8.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('휴대폰 내의 메일 앱을 이용할 수 없어 앱에서 문의가 어렵습니다.\n'),
                                    Text('아래 이메일로 연락주시면\n빠른 시일내에 답장드리겠습니다!'),
                                    SizedBox(height: 24.h),
                                    Row(
                                      children: [
                                        Text('delivalue100@gmail.com', style: TextStyle(fontWeight: FontWeight.w700),),
                                        SizedBox(width: 4.w),
                                        IconButton(onPressed: (){
                                          Clipboard.setData(ClipboardData(text: 'delivalue100@gmail.com'));
                                        }, icon: Icon(Icons.content_copy, color: Colors.grey, size: 22.w))
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            );
                          }
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 14.w),
        ],
      ),
    );
  }
}
