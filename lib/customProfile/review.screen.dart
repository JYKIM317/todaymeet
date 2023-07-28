import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatefulWidget {
  final roomname;
  final roomNum;
  const ReviewPage({Key? key, required this.roomname, required this.roomNum}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  TextEditingController reviewController = TextEditingController();
  String? reviewParameter;
  User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> reviewValue = {};
  @override
  void initState() {
    reviewController = TextEditingController();
    reviewParameter = ' ';
    reviewValue = {};
    _user = FirebaseAuth.instance.currentUser;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 32.w, 14.w, 10.w),
          child: Column(
            children: [
              SizedBox(height: 24.w),
              FutureBuilder<DocumentSnapshot>(
                  future: widget.roomname.get(),
                  builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
                    if(snapshot.hasError) return Text('오류가 발생했습니다.');
                    if(snapshot.connectionState == ConnectionState.waiting) return Center(child: Text(''));
                    Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                    List<dynamic> headcount = data['memberUID'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 48.w,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 15.w),
                          child: Text(
                            '어떤 모임에 참가했나요?',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF51CF6D),
                              fontSize: 16.w,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.w),
                        Text('${data['title']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.w,
                            )
                        ),
                        SizedBox(height: 4.w),
                        Row(
                          children: [
                            Text('장소: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.w,
                              ),
                            ),
                            Text('${data['place']}', style: TextStyle(fontSize: 12.w,)),
                          ],
                        ),
                        SizedBox(height: 2.w),
                        Row(
                          children: [
                            Text('약속시간: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.w,
                              ),
                            ),
                            Text('${data['targetYear']}년${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                              style: TextStyle(fontSize: 12.w,),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.w),
                        Container(
                          height: 48.w,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 15.w),
                          child: Text(
                            '한 줄 후기를 남겨주세요',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF51CF6D),
                              fontSize: 16.w,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.w),
                        TextField(
                          controller: reviewController,
                          maxLength: 30,
                          onChanged: (value) { reviewParameter = value; },
                        ),
                        SizedBox(height: 18.w),
                        Container(
                          height: 48.w,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(top: 15.w),
                          child: Text(
                            '어떠셨나요?',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF51CF6D),
                              fontSize: 16.w,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.w),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: BouncingScrollPhysics(),
                          itemCount: headcount.length,
                          itemBuilder: (BuildContext context, int index){
                            return headcount[index] != _user!.uid ?
                              FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc('${headcount[index]}').get(),
                                  builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
                                    if(snapshot.hasError) return Text('오류가 발생했습니다.');
                                    if(snapshot.connectionState == ConnectionState.waiting) return Center(child: Text(''));
                                    Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
                                    if(data == null) return SizedBox(height: 0);
                                    String name = data['username'] ?? '';
                                    reviewValue['${headcount[index]}manner'] = data['manner'] ?? 0;
                                    return name != '' && name.isNotEmpty ?
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.grey,
                                              radius: 32.w,
                                              backgroundImage: NetworkImage('${data['photoUrl']}'),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text('${data['username']}', style: TextStyle(fontSize: 26.w),),
                                          ],
                                        ),
                                        SizedBox(height: 6.w),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            InkWell(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.mood_bad, size: 42.w,
                                                    color: reviewValue['${headcount[index]}'] == 1 ? Color(0xFF51CF6D) : Colors.grey ),
                                                  Text('별로였어요', style: TextStyle(fontSize: 12.w),),
                                                ],
                                              ),
                                              onTap: (){
                                                reviewValue['${headcount[index]}'] = 1;
                                                setState(() {});
                                              },
                                            ),
                                            SizedBox(width: 10.w),
                                            InkWell(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.sentiment_very_dissatisfied, size: 42.w,
                                                    color: reviewValue['${headcount[index]}'] == 2 ? Color(0xFF51CF6D) : Colors.grey ),
                                                  Text('애매했어요', style: TextStyle(fontSize: 12.w),),
                                                ],
                                              ),
                                              onTap: (){
                                                reviewValue['${headcount[index]}'] = 2;
                                                setState(() {});
                                              },
                                            ),
                                            SizedBox(width: 10.w),
                                            InkWell(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.sentiment_neutral, size: 42.w,
                                                    color: reviewValue['${headcount[index]}'] == 3 ? Color(0xFF51CF6D) : Colors.grey ),
                                                  Text('괜찮았어요', style: TextStyle(fontSize: 12.w),),
                                                ],
                                              ),
                                              onTap: (){
                                                reviewValue['${headcount[index]}'] = 3;
                                                setState(() {});
                                              },
                                            ),
                                            SizedBox(width: 10.w),
                                            InkWell(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.sentiment_satisfied, size: 42.w,
                                                    color: reviewValue['${headcount[index]}'] == 4 ? Color(0xFF51CF6D) : Colors.grey ),
                                                  Text('좋았어요', style: TextStyle(fontSize: 12.w),),
                                                ],
                                              ),
                                              onTap: (){
                                                reviewValue['${headcount[index]}'] = 4;
                                                setState(() {});
                                              },
                                            ),
                                            SizedBox(width: 10.w),
                                            InkWell(
                                              child: Column(
                                                children: [
                                                  Icon(Icons.mood, size: 42.w,
                                                    color: reviewValue['${headcount[index]}'] == 5 ? Color(0xFF51CF6D) : Colors.grey ),
                                                  Text('최고였어요', style: TextStyle(fontSize: 12.w),),
                                                ],
                                              ),
                                              onTap: (){
                                                reviewValue['${headcount[index]}'] = 5;
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8.w),
                                        Container(height: 1, width: double.infinity, color: Colors.grey,)
                                      ],
                                    ): SizedBox(height: 0);
                                  }
                              ): SizedBox(height: 0);
                          },
                          separatorBuilder: (context, index){
                            return SizedBox(height: 8.w);
                          },
                        ),

                      ],
                    );
                  }
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: FutureBuilder<DocumentSnapshot>(
        future: widget.roomname.get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
          if(snapshot.hasError) return Text('오류가 발생했습니다.');
          if(snapshot.connectionState == ConnectionState.waiting) return Center(child: Text(''));
          Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;
          List<dynamic> memberUID = data!['memberUID'];
          return InkWell(
            child: BottomAppBar(
              height: 42.w,
              color: Color(0xFF51CF6D),
              child: Center(
                child: Text('작성완료',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.w
                    )
                ),
              ),
            ),
            onTap: ()async{
              if(!reviewParameter!.contains(RegExp(r'\S'))){
                return showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context){
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.w)
                        ),
                        content: Text("입력하신 후기에 공백만 있습니다."),
                      );
                    }
                );
              }
              for(int i = 0; i<memberUID.length; i++){
                if(memberUID[i]!=_user!.uid){
                  await FirebaseFirestore.instance
                      .collection('users').doc('${memberUID[i]}')
                      .collection('review').doc('${widget.roomNum}_${_user!.uid}').set({
                    'review': reviewParameter
                  });
                  if(reviewValue['${memberUID[i]}'] == 1){
                    var manner = reviewValue['${memberUID[i]}manner'];
                    manner = manner - 0.2;
                    reviewValue['${memberUID[i]}manner'] = manner;
                  }else if(reviewValue['${memberUID[i]}'] == 2){
                    var manner = reviewValue['${memberUID[i]}manner'];
                    manner = manner - 0.1;
                    reviewValue['${memberUID[i]}manner'] = manner;
                  }else if(reviewValue['${memberUID[i]}'] == 4){
                    var manner = reviewValue['${memberUID[i]}manner'];
                    manner = manner + 0.1;
                    reviewValue['${memberUID[i]}manner'] = manner;
                  }else if(reviewValue['${memberUID[i]}'] == 5){
                    var manner = reviewValue['${memberUID[i]}manner'];
                    manner = manner + 0.2;
                    reviewValue['${memberUID[i]}manner'] = manner;
                  }

                  await FirebaseFirestore.instance
                      .collection('users').doc('${memberUID[i]}').update({'manner':reviewValue['${memberUID[i]}manner']});
                }
              }
              await widget.roomname.update({'reviewState':true});
              Navigator.pop(context);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
