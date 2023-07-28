import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final _user = FirebaseAuth.instance.currentUser;

class MyCategory extends StatefulWidget {
  const MyCategory({Key? key}) : super(key: key);
  @override
  State<MyCategory> createState() => _MyCategoryState();
}

class _MyCategoryState extends State<MyCategory> {
  bool? seoulState = false, gyeonggiState = false, incheonState = false,
      busanState = false, daeguState = false, daejeonState = false,
      gwangjuState = false, ulsanState = false, jejuState = false;
  bool? foodState = false, alcoholState = false, cafeState = false,
      conversationState = false, movieState = false, performanceState = false,
      exhibitionState = false, musicState = false, karaokeState = false,
      tripState = false, workoutState = false, walkState = false,
      driveState = false, onlineState = false, gameState = false,
      boardgameState = false, etcState = false;
  List<String> regionCategory = [], hobbyCategory = [];

  final _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF51CF6D)),
                overlayColor: MaterialStateProperty.all<Color>(Colors.transparent)
            )
        ),
        fontFamily: 'Pretendard',
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(15.w, 30.w, 15.w, 30.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 36.w),
                Text('관심 지역',style: TextStyle(fontSize: 28.w,)),
                SizedBox(height: 18.w),
                Column(
                  children: [
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          seoulState == true ? {seoulState = false, regionCategory.remove('서울')} : {seoulState = true, regionCategory.add('서울')};
                          setState(() {});
                        }, child: Text('서울', style: TextStyle(color: seoulState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          gyeonggiState == true ? {gyeonggiState = false, regionCategory.remove('경기')} : {gyeonggiState = true, regionCategory.add('경기')};
                          setState(() {});
                        }, child: Text('경기', style: TextStyle(color: gyeonggiState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          incheonState == true ? {incheonState = false, regionCategory.remove('인천')} : {incheonState = true, regionCategory.add('인천')};
                          setState(() {});
                        }, child: Text('인천', style: TextStyle(color: incheonState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          busanState == true ? {busanState = false, regionCategory.remove('부산')} : {busanState = true, regionCategory.add('부산')};
                          setState(() {});
                        }, child: Text('부산', style: TextStyle(color: busanState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          daeguState == true ? {daeguState = false, regionCategory.remove('대구')} : {daeguState = true, regionCategory.add('대구')};
                          setState(() {});
                        }, child: Text('대구', style: TextStyle(color: daeguState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          ulsanState == true ? {ulsanState = false, regionCategory.remove('울산')} : {ulsanState = true, regionCategory.add('울산')};
                          setState(() {});
                        }, child: Text('울산', style: TextStyle(color: ulsanState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          daejeonState == true ? {daejeonState = false, regionCategory.remove('대전')} : {daejeonState = true, regionCategory.add('대전')};
                          setState(() {});
                        }, child: Text('대전', style: TextStyle(color: daejeonState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          gwangjuState == true ? {gwangjuState = false, regionCategory.remove('광주')} : {gwangjuState = true, regionCategory.add('광주')};
                          setState(() {});
                        }, child: Text('광주', style: TextStyle(color: gwangjuState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          jejuState == true ? {jejuState = false, regionCategory.remove('제주')} : {jejuState = true, regionCategory.add('제주')};
                          setState(() {});
                        }, child: Text('제주', style: TextStyle(color: jejuState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 36.w),
                Text('관심 취미',style: TextStyle(fontSize: 28.w,)),
                SizedBox(height: 18.w),
                Column(
                  children: [
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          foodState == true ? {foodState = false, hobbyCategory.remove('식사')} : {foodState = true, hobbyCategory.add('식사')};
                          setState(() {});
                        }, child: Text('식사', style: TextStyle(color: foodState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          alcoholState == true ? {alcoholState = false, hobbyCategory.remove('술자리')} : {alcoholState = true, hobbyCategory.add('술자리')};
                          setState(() {});
                        }, child: Text('술자리', style: TextStyle(color: alcoholState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          cafeState == true ? {cafeState = false, hobbyCategory.remove('카페')} : {cafeState = true, hobbyCategory.add('카페')};
                          setState(() {});
                        }, child: Text('카페', style: TextStyle(color: cafeState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          conversationState == true ? {conversationState = false, hobbyCategory.remove('수다')} : {conversationState = true, hobbyCategory.add('수다')};
                          setState(() {});
                        }, child: Text('수다', style: TextStyle(color: conversationState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          movieState == true ? {movieState = false, hobbyCategory.remove('영화')} : {movieState = true, hobbyCategory.add('영화')};
                          setState(() {});
                        }, child: Text('영화', style: TextStyle(color: movieState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          performanceState == true ? {performanceState = false, hobbyCategory.remove('공연')} : {performanceState = true, hobbyCategory.add('공연')};
                          setState(() {});
                        }, child: Text('공연', style: TextStyle(color: performanceState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          exhibitionState == true ? {exhibitionState = false, hobbyCategory.remove('전시회')} : {exhibitionState = true, hobbyCategory.add('전시회')};
                          setState(() {});
                        }, child: Text('전시회', style: TextStyle(color: exhibitionState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          musicState == true ? {musicState = false, hobbyCategory.remove('음악')} : {musicState = true, hobbyCategory.add('음악')};
                          setState(() {});
                        }, child: Text('음악', style: TextStyle(color: musicState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          karaokeState == true ? {karaokeState = false, hobbyCategory.remove('노래방')} : {karaokeState = true, hobbyCategory.add('노래방')};
                          setState(() {});
                        }, child: Text('노래방', style: TextStyle(color: karaokeState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          tripState == true ? {tripState = false, hobbyCategory.remove('여행')} : {tripState = true, hobbyCategory.add('여행')};
                          setState(() {});
                        }, child: Text('여행', style: TextStyle(color: tripState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          workoutState == true ? {workoutState = false, hobbyCategory.remove('운동')} : {workoutState = true, hobbyCategory.add('운동')};
                          setState(() {});
                        }, child: Text('운동', style: TextStyle(color: workoutState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          walkState == true ? {walkState = false, hobbyCategory.remove('산책')} : {walkState = true, hobbyCategory.add('산책')};
                          setState(() {});
                        }, child: Text('산책', style: TextStyle(color: walkState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          driveState == true ? {driveState = false, hobbyCategory.remove('드라이브')} : {driveState = true, hobbyCategory.add('드라이브')};
                          setState(() {});
                        }, child: Text('드라이브', style: TextStyle(color: driveState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          onlineState == true ? {onlineState = false, hobbyCategory.remove('온라인')} : {onlineState = true, hobbyCategory.add('온라인')};
                          setState(() {});
                        }, child: Text('온라인', style: TextStyle(color: onlineState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          gameState == true ? {gameState = false, hobbyCategory.remove('게임')} : {gameState = true, hobbyCategory.add('게임')};
                          setState(() {});
                        }, child: Text('게임', style: TextStyle(color: gameState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: (){
                          boardgameState == true ? {boardgameState = false, hobbyCategory.remove('보드게임')} : {boardgameState = true, hobbyCategory.add('보드게임')};
                          setState(() {});
                        }, child: Text('보드게임', style: TextStyle(color: boardgameState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    SizedBox(height: 8.w),
                    Row(
                      children: [
                        TextButton(onPressed: (){
                          etcState == true ? {etcState = false, hobbyCategory.remove('기타')} : {etcState = true, hobbyCategory.add('기타')};
                          setState(() {});
                        }, child: Text('기타', style: TextStyle(color: etcState == true ? Color(0xFF51CF6D) : Colors.grey, fontSize: 22.w, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 42.w),
              ],
            ),
          ),
        ),
        bottomSheet: BottomAppBar(
          height: 52.w,
          child: Expanded(
            child: SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: InkWell(
                        child: Container(
                          alignment: Alignment.center,
                          color: Colors.transparent,
                          child: Text('취소',
                            style: TextStyle(
                              color: Color(0xFF51CF6D),
                              fontSize: 24.w,
                            ),
                          ),
                        ),
                      onTap: (){
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                        child: Container(
                          alignment: Alignment.center,
                          color: Color(0xFF51CF6D),
                          child: Text('완료',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.w,
                            ),
                          ),
                        ),
                      onTap: (){
                        if(regionCategory.length != 0 || hobbyCategory.length != 0){
                          _userinfo.update({
                            'regioncategory': regionCategory,
                            'hobbycategory': hobbyCategory,
                          });
                          Navigator.pop(context);
                        }
                        else{
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}