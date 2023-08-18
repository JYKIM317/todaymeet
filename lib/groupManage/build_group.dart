import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bottom_drawer/bottom_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

String? selectedPlace;
LocationPermission? permission;

String gMapApiKey = 'AIzaSyDsSSYPK-JDNVA04nKQC9yrcGsNzLkOfNc';
User? _user = FirebaseAuth.instance.currentUser;
DocumentReference _roomAdress =
    FirebaseFirestore.instance.collection('activateRoom').doc('${_user!.uid}');
DocumentReference _chatRoom =
    FirebaseFirestore.instance.collection('chatRoom').doc('available');
DocumentReference _madeRoom = FirebaseFirestore.instance
    .collection('users')
    .doc('${_user!.uid}')
    .collection('room')
    .doc('made');
var _userinfo =
    FirebaseFirestore.instance.collection('users').doc('${_user!.uid}');

double lat = 37.52, lng = 127.04;
List<String> selectedCategory = [];
List<dynamic> requestUID = [];
TextEditingController titleController = TextEditingController();
TextEditingController infoController = TextEditingController();
String? titleParameter, infoParameter;
late String selectedNoon;
bool today = false,
    tomorrow = false,
    dat = false,
    inprogress = false,
    shown = true;
int? d_Year = today
    ? d_Year = DateTime.now().year
    : tomorrow
        ? d_Year = DateTime.now().add(Duration(days: 1)).year
        : d_Year = DateTime.now().add(Duration(days: 2)).year;
int? d_Month = today
    ? d_Month = DateTime.now().month
    : tomorrow
        ? d_Month = DateTime.now().add(Duration(days: 1)).month
        : d_Month = DateTime.now().add(Duration(days: 2)).month;
int? d_Day = today
    ? d_Day = DateTime.now().day
    : tomorrow
        ? d_Day = DateTime.now().add(Duration(days: 1)).day
        : d_Day = DateTime.now().add(Duration(days: 2)).day;
int? selectedHour, selectedMinute, selectedPeople;
BottomDrawerController categoryController = BottomDrawerController();

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  double? selectLat, selectLng;
  late Position position;
  Future<Position> getCurrentLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  late GoogleMapController _selectedmap;
  CameraPosition _initialPosition =
      CameraPosition(target: LatLng(lat, lng), zoom: 14);
  Set<Marker> markers = {};
  _addMarker(cordinate) {
    setState(() {
      markers.add(Marker(position: cordinate, markerId: MarkerId('1024')));
    });
  }

  static Future<String>? getPlaceAddress(lat, lng) async {
    var url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$gMapApiKey&language=ko';
    var response = await http.get(
        Uri.parse(url)); //google maps에서 restrictions가 android일 경우에 ip 제한 발생해버림
    List<String> place = [];
    place.add(jsonDecode(response.body)['results'][0]['address_components'][3]
        ['long_name']);
    place.add(jsonDecode(response.body)['results'][0]['address_components'][2]
        ['long_name']);
    String selectPlace = place.join(' ');
    return selectPlace;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid)
      gMapApiKey = 'AIzaSyDsSSYPK-JDNVA04nKQC9yrcGsNzLkOfNc';
    if (Platform.isIOS) gMapApiKey = 'AIzaSyCGoLM2AaiC5sXXLMIA2BTpmL4qgj-80Tw';
    final progress = ProgressHUD.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('만날 동네 선택',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.w,
            )),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: GoogleMap(
        onTap: (cordinate) {
          _selectedmap.animateCamera(CameraUpdate.newLatLng(cordinate));
          _addMarker(cordinate);
          setState(() {
            selectLat = cordinate.latitude;
            selectLng = cordinate.longitude;
          });
        },
        onMapCreated: (controller) {
          setState(() {
            _selectedmap = controller;
          });
        },
        initialCameraPosition: _initialPosition,
        markers: markers,
        myLocationEnabled: true,
        mapType: MapType.normal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var gps = await getCurrentLocation();
          _selectedmap.animateCamera(
              CameraUpdate.newLatLng(LatLng(gps.latitude, gps.longitude)));
        },
        child: Icon(
          Icons.location_on,
          color: Color(0xFF51CF6D),
          size: 24.w,
        ),
        backgroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomAppBar(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 1,
            child: InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.w),
                color: Colors.white,
                child: Text(
                  '취소',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 22.w,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.w),
                color: Color(0xFF51CF6D),
                child: Text(
                  '확인',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.w,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              onTap: () async {
                await {progress?.show()};
                if (selectLat != null && selectLng != null) {
                  selectedPlace = await getPlaceAddress(selectLat, selectLng);
                  progress?.dismiss();
                  Navigator.pop(context);
                  return;
                } else {
                  if (lat != 37.52 && lng != 127.04) {
                    selectedPlace = await getPlaceAddress(lat, lng);
                    progress?.dismiss();
                    Navigator.pop(context);
                    return;
                  } else {
                    progress?.dismiss();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        '위치를 선택해주세요',
                        style: TextStyle(color: Colors.black),
                      ),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.white,
                    ));
                  }
                }
              },
            ),
          ),
        ],
      )),
    );
  }
}

class BuildGroupPage extends StatefulWidget {
  const BuildGroupPage({Key? key}) : super(key: key);

  @override
  State<BuildGroupPage> createState() => _BuildGroupPageState();
}

class _BuildGroupPageState extends State<BuildGroupPage> {
  bool foodState = selectedCategory.contains('식사') ? true : false;
  bool alcoholState = selectedCategory.contains('술자리') ? true : false;
  bool cafeState = selectedCategory.contains('카페') ? true : false;
  bool conversationState = selectedCategory.contains('수다') ? true : false;
  bool movieState = selectedCategory.contains('영화') ? true : false;
  bool performanceState = selectedCategory.contains('공연') ? true : false;
  bool exhibitionState = selectedCategory.contains('전시회') ? true : false;
  bool musicState = selectedCategory.contains('음악') ? true : false;
  bool karaokeState = selectedCategory.contains('노래방') ? true : false;
  bool tripState = selectedCategory.contains('여행') ? true : false;
  bool workoutState = selectedCategory.contains('운동') ? true : false;
  bool walkState = selectedCategory.contains('산책') ? true : false;
  bool driveState = selectedCategory.contains('드라이브') ? true : false;
  bool onlineState = selectedCategory.contains('온라인') ? true : false;
  bool gameState = selectedCategory.contains('게임') ? true : false;
  bool boardgameState = selectedCategory.contains('보드게임') ? true : false;
  bool etcState = selectedCategory.contains('기타') ? true : false;

  final hour = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  final minute = [00, 05, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
  final noon = ['오전', '오후'];
  final limitpeople = [2, 3, 4, 5, 6, 7, 8, 9, 10];

  InterstitialAd? _interstitialAd;
  void interstitialAd() {
    InterstitialAd.load(
        //id 테스트ID -> 실제 Ad ID로 변경해야함
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
        }, onAdFailedToLoad: (LoadAdError error) {
          debugPrint('$error');
        }));
  }

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _roomAdress = FirebaseFirestore.instance
        .collection('activateRoom')
        .doc('${_user!.uid}');
    _madeRoom = FirebaseFirestore.instance
        .collection('users')
        .doc('${_user!.uid}')
        .collection('room')
        .doc('made');
    _userinfo =
        FirebaseFirestore.instance.collection('users').doc('${_user!.uid}');
    _chatRoom = _chatRoom =
        FirebaseFirestore.instance.collection('chatRoom').doc('available');
    today = false;
    tomorrow = false;
    dat = false;
    selectedNoon = noon.last;
    selectedPeople = limitpeople.first;
    selectedHour = null;
    selectedMinute = null;
    selectedCategory = [];
    selectedPlace = null;
    titleController = TextEditingController();
    infoController = TextEditingController();
    shown = true;
    interstitialAd();
  }

  @override
  void dispose() {
    foodState = false;
    alcoholState = false;
    cafeState = false;
    conversationState = false;
    movieState = false;
    performanceState = false;
    exhibitionState = false;
    musicState = false;
    karaokeState = false;
    tripState = false;
    workoutState = false;
    walkState = false;
    driveState = false;
    onlineState = false;
    gameState = false;
    boardgameState = false;
    etcState = false;
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<List<dynamic>> getUserData() async {
    DocumentSnapshot<Map<String, dynamic>> userData = await _userinfo.get();
    Map<String, dynamic> userInfoData = userData.data()!;
    String photoUrl =
        userInfoData['photoUrl'] ?? 'assets/images/defaultProfile.jpg';
    String fcmToken = userInfoData['pushToken'];
    List<dynamic> responseUserdata = [photoUrl, fcmToken];
    return responseUserdata;
  }

  Widget buildBottomDrawer(BuildContext context) {
    return BottomDrawer(
      cornerRadius: 14.w,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 14.w, 0, 0),
            alignment: Alignment.centerLeft,
            color: Colors.transparent,
            child: Text('카테고리 선택',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.w,
                )),
          ),
          Container(
              padding: EdgeInsets.fromLTRB(0, 14.w, 14.w, 0),
              alignment: Alignment.centerRight,
              child: IconButton(
                  onPressed: () {
                    categoryController.close();
                  },
                  icon: Icon(
                    Icons.close,
                    size: 24.w,
                  )))
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 14.w, 10.w, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        foodState == true
                            ? {selectedCategory.remove('식사'), foodState = false}
                            : {selectedCategory.add('식사'), foodState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          foodState = false;
                        }
                        setState(() {});
                      },
                      child: Text('식사',
                          style: TextStyle(
                            color: foodState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        alcoholState == true
                            ? {
                                selectedCategory.remove('술자리'),
                                alcoholState = false
                              }
                            : {
                                selectedCategory.add('술자리'),
                                alcoholState = true
                              };
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          alcoholState = false;
                        }
                        setState(() {});
                      },
                      child: Text('술자리',
                          style: TextStyle(
                            color: alcoholState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        cafeState == true
                            ? {selectedCategory.remove('카페'), cafeState = false}
                            : {selectedCategory.add('카페'), cafeState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          cafeState = false;
                        }
                        setState(() {});
                      },
                      child: Text('카페',
                          style: TextStyle(
                            color: cafeState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        conversationState == true
                            ? {
                                selectedCategory.remove('수다'),
                                conversationState = false
                              }
                            : {
                                selectedCategory.add('수다'),
                                conversationState = true
                              };
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          conversationState = false;
                        }
                        setState(() {});
                      },
                      child: Text('수다',
                          style: TextStyle(
                            color: conversationState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                ],
              ),
              SizedBox(height: 8.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        movieState == true
                            ? {
                                selectedCategory.remove('영화'),
                                movieState = false
                              }
                            : {selectedCategory.add('영화'), movieState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          movieState = false;
                        }
                        setState(() {});
                      },
                      child: Text('영화',
                          style: TextStyle(
                            color: movieState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        performanceState == true
                            ? {
                                selectedCategory.remove('공연'),
                                performanceState = false
                              }
                            : {
                                selectedCategory.add('공연'),
                                performanceState = true
                              };
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          performanceState = false;
                        }
                        setState(() {});
                      },
                      child: Text('공연',
                          style: TextStyle(
                            color: performanceState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        exhibitionState == true
                            ? {
                                selectedCategory.remove('전시회'),
                                exhibitionState = false
                              }
                            : {
                                selectedCategory.add('전시회'),
                                exhibitionState = true
                              };
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          exhibitionState = false;
                        }
                        setState(() {});
                      },
                      child: Text('전시회',
                          style: TextStyle(
                            color: exhibitionState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                ],
              ),
              SizedBox(height: 8.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        musicState == true
                            ? {
                                selectedCategory.remove('음악'),
                                musicState = false
                              }
                            : {selectedCategory.add('음악'), musicState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          musicState = false;
                        }
                        setState(() {});
                      },
                      child: Text('음악',
                          style: TextStyle(
                            color: musicState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        karaokeState == true
                            ? {
                                selectedCategory.remove('노래방'),
                                karaokeState = false
                              }
                            : {
                                selectedCategory.add('노래방'),
                                karaokeState = true
                              };
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          karaokeState = false;
                        }
                        setState(() {});
                      },
                      child: Text('노래방',
                          style: TextStyle(
                            color: karaokeState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                ],
              ),
              SizedBox(height: 8.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        tripState == true
                            ? {selectedCategory.remove('여행'), tripState = false}
                            : {selectedCategory.add('여행'), tripState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          tripState = false;
                        }
                        setState(() {});
                      },
                      child: Text('여행',
                          style: TextStyle(
                            color: tripState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        workoutState == true
                            ? {
                                selectedCategory.remove('운동'),
                                workoutState = false
                              }
                            : {selectedCategory.add('운동'), workoutState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          workoutState = false;
                        }
                        setState(() {});
                      },
                      child: Text('운동',
                          style: TextStyle(
                            color: workoutState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        walkState == true
                            ? {selectedCategory.remove('산책'), walkState = false}
                            : {selectedCategory.add('산책'), walkState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          walkState = false;
                        }
                        setState(() {});
                      },
                      child: Text('산책',
                          style: TextStyle(
                            color: walkState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        driveState == true
                            ? {
                                selectedCategory.remove('드라이브'),
                                driveState = false
                              }
                            : {selectedCategory.add('드라이브'), driveState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          driveState = false;
                        }
                        setState(() {});
                      },
                      child: Text('드라이브',
                          style: TextStyle(
                            color: driveState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                ],
              ),
              SizedBox(height: 8.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        onlineState == true
                            ? {
                                selectedCategory.remove('온라인'),
                                onlineState = false
                              }
                            : {selectedCategory.add('온라인'), onlineState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          onlineState = false;
                        }
                        setState(() {});
                      },
                      child: Text('온라인',
                          style: TextStyle(
                            color: onlineState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        gameState == true
                            ? {selectedCategory.remove('게임'), gameState = false}
                            : {selectedCategory.add('게임'), gameState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          gameState = false;
                        }
                        setState(() {});
                      },
                      child: Text('게임',
                          style: TextStyle(
                            color: gameState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                  TextButton(
                      onPressed: () {
                        boardgameState == true
                            ? {
                                selectedCategory.remove('보드게임'),
                                boardgameState = false
                              }
                            : {
                                selectedCategory.add('보드게임'),
                                boardgameState = true
                              };
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          boardgameState = false;
                        }
                        setState(() {});
                      },
                      child: Text('보드게임',
                          style: TextStyle(
                            color: boardgameState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                ],
              ),
              SizedBox(height: 8.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        etcState == true
                            ? {selectedCategory.remove('기타'), etcState = false}
                            : {selectedCategory.add('기타'), etcState = true};
                        if (selectedCategory.length > 5) {
                          categoryLimit(context);
                          selectedCategory.removeLast();
                          etcState = false;
                        }
                        setState(() {});
                      },
                      child: Text('기타',
                          style: TextStyle(
                            color: etcState == true
                                ? Color(0xFF51CF6D)
                                : Colors.grey,
                            fontSize: 18.w,
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
      headerHeight: 0,
      drawerHeight: 500.h,
      controller: categoryController,
    );
  }

  categoryLimit(BuildContext context) {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.w)),
            content: Text("카테고리는 최대 5개까지 선택 가능합니다."),
          );
        });
  }

  limitCreateHour() {
    return showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.w)),
            content: Text("약속 시간은 현재 시간보다\n1시간 이후로 설정 가능합니다."),
          );
        });
  }

  guide(BuildContext context) {
    shown = false;
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.w)),
            content: Text.rich(TextSpan(
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                text: '방 개설 시 주의사항\n\n',
                children: <TextSpan>[
                  TextSpan(
                      style: TextStyle(fontWeight: FontWeight.w500),
                      text: '- 약속 시간은 현재 시간보다 1시간 이후로 설정 가능합니다.\n\n'
                          '- 방 개설 이후에는 자신을 제외한 멤버가 있을 경우 약속 시간 30분 전 기준으로부터 방 해체 및 멤버 내보내기가 불가능합니다.\n\n'
                          '건전하고 매너있는 모임을 즐겨주세요!')
                ])),
            actions: [
              Center(
                child: TextButton(
                    child: Text('알겠습니다',
                        style: TextStyle(
                          color: Color(0xFF51CF6D),
                          fontSize: 16.w,
                        )),
                    onPressed: () {
                      Navigator.of(context).pop();
                    }),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressHUD.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shown) guide(context);
    });
    String categoryTextH = selectedCategory.join('  ');
    List<dynamic> memberPhotoUrl = [];
    return WillPopScope(
      onWillPop: () async {
        final value = await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.w)),
                content: Text("작성하시던 내용이 저장되지 않습니다.\n정말 나가시겠습니까?"),
                actions: [
                  TextButton(
                      child: Text('취소', style: TextStyle(color: Colors.grey)),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      }),
                  TextButton(
                      child: Text('확인',
                          style: TextStyle(color: Color(0xFF51CF6D))),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      })
                ],
              );
            });
        return value == true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
              onPressed: () {
                showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.w)),
                        content: Text("작성하시던 내용이 저장되지 않습니다.\n정말 나가시겠습니까?"),
                        actions: [
                          TextButton(
                              child: Text('취소',
                                  style: TextStyle(color: Colors.grey)),
                              onPressed: () {
                                Navigator.of(context).pop();
                              }),
                          TextButton(
                              child: Text('확인',
                                  style: TextStyle(color: Color(0xFF51CF6D))),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              })
                        ],
                      );
                    });
              },
              icon: Icon(
                Icons.close,
                color: Colors.black,
                weight: 1,
                size: 24.w,
              )),
          title: Text(
            '모임개설',
            style: TextStyle(color: Colors.black, fontSize: 20.w),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            categoryController.close();
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 32.w, 16.w, 10.w),
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 6.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(6.w)),
                          border:
                              Border.all(width: 1, color: Color(0xFF51CF6D)),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                              labelText: '모임 제목',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              labelStyle: TextStyle(
                                  color: Color(0xFF51CF6D), fontSize: 18.w)),
                          maxLength: 40,
                          controller: titleController,
                          onChanged: (value) {
                            setState(() {
                              titleParameter = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 14.w),
                      InkWell(
                        child: Container(
                            padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 6.w),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6.w)),
                              border: Border.all(
                                  width: 1, color: Color(0xFF51CF6D)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                    padding: EdgeInsets.only(right: 5),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Color(0xFF51CF6D),
                                      size: 24.w,
                                    )),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('만날 동네',
                                          style: TextStyle(
                                            color: Color(0xFF51CF6D),
                                            fontSize: 14.w,
                                          )),
                                      selectedPlace != null
                                          ? Text(
                                              '$selectedPlace',
                                              style: TextStyle(fontSize: 16.w),
                                            )
                                          : Text('눌러서 위치를 선택해주세요',
                                              style: TextStyle(
                                                fontSize: 16.w,
                                                color: Colors.grey,
                                              )),
                                    ])
                              ],
                            )),
                        onTap: () async {
                          await {progress?.show()};
                          permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            progress?.dismiss();
                            permission = await Geolocator.requestPermission();
                            setState(() {});
                            if (permission ==
                                LocationPermission.deniedForever) {
                              progress?.dismiss();
                              return;
                            } else if (permission ==
                                LocationPermission.unableToDetermine) {
                              progress?.dismiss();
                              return;
                            } else if (permission ==
                                LocationPermission.denied) {
                              progress?.dismiss();
                              return;
                            } else {
                              var position =
                                  await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high);
                              lat = position.latitude;
                              lng = position.longitude;
                              progress?.dismiss();
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ProgressHUD(child: MapView())));
                              setState(() {}); //주소 받아와서 화면 갱신용
                              return;
                            }
                          } else if (permission ==
                              LocationPermission.deniedForever) {
                            progress?.dismiss();
                            permission = await Geolocator.requestPermission();
                            return;
                          } else if (permission ==
                              LocationPermission.unableToDetermine) {
                            progress?.dismiss();
                            return;
                          } else {
                            var position = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high);
                            lat = position.latitude;
                            lng = position.longitude;
                            progress?.dismiss();
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ProgressHUD(child: MapView())));
                            setState(() {});
                            return;
                          }
                        },
                      ),
                      SizedBox(height: 14.w),
                      Container(
                          padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 6.w),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(6.w)),
                            border:
                                Border.all(width: 1, color: Color(0xFF51CF6D)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                      padding: EdgeInsets.only(right: 5),
                                      child: Icon(
                                        Icons.query_builder,
                                        color: Color(0xFF51CF6D),
                                        size: 24.w,
                                      )),
                                  Text(
                                    '약속 시간',
                                    style: TextStyle(
                                        color: Color(0xFF51CF6D),
                                        fontSize: 16.w),
                                  ),
                                ],
                              ),
                              Container(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                        onPressed: () {
                                          setState(() {
                                            today = true;
                                            tomorrow = false;
                                            dat = false;
                                          });
                                        },
                                        child: Text('오늘',
                                            style: TextStyle(
                                              color: today == true
                                                  ? Color(0xFF51CF6D)
                                                  : Colors.grey,
                                              fontSize: 18.w,
                                            ))),
                                    SizedBox(width: 4.w),
                                    TextButton(
                                        onPressed: () {
                                          setState(() {
                                            today = false;
                                            tomorrow = true;
                                            dat = false;
                                          });
                                        },
                                        child: Text('내일',
                                            style: TextStyle(
                                              color: tomorrow == true
                                                  ? Color(0xFF51CF6D)
                                                  : Colors.grey,
                                              fontSize: 18.w,
                                            ))),
                                    SizedBox(width: 4.w),
                                    TextButton(
                                        onPressed: () {
                                          setState(() {
                                            today = false;
                                            tomorrow = false;
                                            dat = true;
                                          });
                                        },
                                        child: Text('모레',
                                            style: TextStyle(
                                              color: dat == true
                                                  ? Color(0xFF51CF6D)
                                                  : Colors.grey,
                                              fontSize: 18.w,
                                            ))),
                                  ],
                                ),
                              )
                            ],
                          )),
                      SizedBox(height: 8.w),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                padding:
                                    EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 6.w),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6.w)),
                                  border: Border.all(
                                      width: 1, color: Color(0xFF51CF6D)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                        padding: EdgeInsets.only(right: 5),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: Color(0xFF51CF6D),
                                          size: 24.w,
                                        )),
                                    Text(
                                      '인원 수 ',
                                      style: TextStyle(
                                          color: Color(0xFF51CF6D),
                                          fontSize: 16.w),
                                    ),
                                    DropdownButton(
                                      alignment: Alignment.center,
                                      value: selectedPeople,
                                      items: limitpeople.map((int item) {
                                        return DropdownMenuItem<int>(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '$item',
                                            style: TextStyle(fontSize: 16.w),
                                          ),
                                          value: item,
                                        );
                                      }).toList(),
                                      onChanged: (dynamic value) {
                                        setState(() {
                                          selectedPeople = value;
                                        });
                                      },
                                      iconEnabledColor: Colors.transparent,
                                      iconSize: 0,
                                      underline: Container(
                                          color: Colors.transparent,
                                          height: double.minPositive,
                                          width: double.maxFinite),
                                    ),
                                    Text('명',
                                        style: TextStyle(
                                          color: Color(0xFF51CF6D),
                                          fontSize: 16.w,
                                        )),
                                  ],
                                )),
                            Row(children: [
                              Container(
                                  alignment: Alignment.center,
                                  width: 50.w,
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            width: 1,
                                            color: Color(0xFF51CF6D))),
                                  ),
                                  child: DropdownButton(
                                    alignment: Alignment.center,
                                    value: selectedNoon,
                                    items: noon.map((String item) {
                                      return DropdownMenuItem<String>(
                                        alignment: Alignment.centerRight,
                                        child: Text('$item',
                                            style: TextStyle(fontSize: 16.w)),
                                        value: item,
                                      );
                                    }).toList(),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        selectedNoon = value;
                                      });
                                    },
                                    iconEnabledColor: Colors.transparent,
                                    underline: Container(
                                        color: Colors.transparent,
                                        height: double.minPositive,
                                        width: double.maxFinite),
                                    iconSize: 0,
                                  )),
                              SizedBox(width: 4.w),
                              Container(
                                  alignment: Alignment.center,
                                  width: 40.w,
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            width: 1,
                                            color: Color(0xFF51CF6D))),
                                  ),
                                  child: DropdownButton(
                                    alignment: Alignment.centerRight,
                                    value: selectedHour,
                                    items: hour.map((int item) {
                                      return DropdownMenuItem<int>(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '$item',
                                          style: TextStyle(fontSize: 16.w),
                                        ),
                                        value: item,
                                      );
                                    }).toList(),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        selectedHour = value;
                                      });
                                    },
                                    iconEnabledColor: Colors.transparent,
                                    iconSize: 0,
                                    underline: Container(
                                        color: Colors.transparent,
                                        height: double.minPositive,
                                        width: double.maxFinite),
                                  )),
                              Text('시', style: TextStyle(fontSize: 16.w)),
                              SizedBox(width: 4.w),
                              Container(
                                  alignment: Alignment.center,
                                  width: 40.w,
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            width: 1,
                                            color: Color(0xFF51CF6D))),
                                  ),
                                  child: DropdownButton(
                                    alignment: Alignment.centerRight,
                                    value: selectedMinute,
                                    items: minute.map((int item) {
                                      return DropdownMenuItem<int>(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '$item',
                                          style: TextStyle(fontSize: 16.w),
                                        ),
                                        value: item,
                                      );
                                    }).toList(),
                                    onChanged: (dynamic value) {
                                      setState(() {
                                        selectedMinute = value;
                                      });
                                    },
                                    iconEnabledColor: Colors.transparent,
                                    iconSize: 0,
                                    underline: Container(
                                        color: Colors.transparent,
                                        height: double.minPositive,
                                        width: double.maxFinite),
                                  )),
                              Text('분', style: TextStyle(fontSize: 16.w)),
                            ])
                          ]),
                      SizedBox(height: 14.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('모임 설명',
                              style: TextStyle(
                                color: Color(0xFF51CF6D),
                                fontSize: 16.w,
                              )),
                          TextField(
                            controller: infoController,
                            maxLines: null,
                            minLines: 2,
                            maxLength: 100,
                            onChanged: (value) {
                              setState(() {
                                infoParameter = value;
                              });
                            },
                            onTap: () => categoryController.close(),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.w),
                      InkWell(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('모임 카테고리',
                                    style: TextStyle(
                                      color: Color(0xFF51CF6D),
                                      fontSize: 16.w,
                                    )),
                                SizedBox(width: 2.w),
                                Text('최대 5개',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12.w,
                                    )),
                              ],
                            ),
                            SizedBox(height: 6.w),
                            Container(
                                alignment: Alignment.centerLeft,
                                child: selectedCategory.isEmpty
                                    ? Container(
                                        child: Text('카테고리 추가하기 +',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 18.w)))
                                    : Container(
                                        child: Text('$categoryTextH',
                                            style: TextStyle(fontSize: 18.w)))),
                          ],
                        ),
                        onTap: () {
                          categoryController.open();
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 38.w),
                      InkWell(
                        child: Container(
                          width: double.infinity,
                          height: 42.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.w),
                            color: Color(0xFF51CF6D),
                          ),
                          child: Center(
                            child: Text(
                              '모임 만들기',
                              style: TextStyle(
                                  fontSize: 18.w, color: Colors.white),
                            ),
                          ),
                        ),
                        onTap: () async {
                          if (_interstitialAd != null) _interstitialAd?.show();
                          final String chatRoomName =
                              '${DateTime.now().month.toString()}${DateTime.now().day.toString()}${DateTime.now().hour.toString()}${DateTime.now().minute.toString()}_${_user!.uid}';
                          List<dynamic> responseUserData = await getUserData();
                          String hostUID = _user!.uid;
                          List<dynamic> memberUID = [hostUID];
                          if (titleParameter != null &&
                              selectedPlace != null &&
                              selectedHour != null &&
                              selectedMinute != null &&
                              (today || tomorrow || dat) == true &&
                              infoParameter != null &&
                              selectedCategory.isEmpty != true) {
                            progress?.show();
                            if (today == true) {
                              if ((selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12)! <
                                  DateTime.now().hour + 1) {
                                progress?.dismiss();
                                return limitCreateHour();
                              } else if ((selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12)! ==
                                  DateTime.now().hour + 1) {
                                if (selectedMinute! < DateTime.now().minute) {
                                  progress?.dismiss();
                                  return limitCreateHour();
                                } else {
                                  await _roomAdress.set({
                                    'title': titleParameter,
                                    'place': selectedPlace,
                                    'info': infoParameter,
                                    'headcount': selectedPeople,
                                    'targetDay': d_Day,
                                    'targetMonth': d_Month,
                                    'targetYear': d_Year,
                                    'targetHour': selectedNoon == '오전'
                                        ? selectedHour == 12
                                            ? selectedHour! - 12
                                            : selectedHour
                                        : selectedHour == 12
                                            ? selectedHour
                                            : selectedHour! + 12,
                                    'targetMinute': selectedMinute,
                                    'Categories': selectedCategory,
                                    'hostPhotoUrl': responseUserData[0],
                                    'memberTokenList': [responseUserData[1]],
                                    'hostUID': hostUID,
                                    'memberPhotoUrl': memberPhotoUrl,
                                    'memberUID': memberUID,
                                    'inProgress': inprogress,
                                    'chatRoom': chatRoomName,
                                  });
                                  await _madeRoom.set({
                                    'title': titleParameter,
                                    'place': selectedPlace,
                                    'info': infoParameter,
                                    'headcount': selectedPeople,
                                    'targetDay': d_Day,
                                    'targetMonth': d_Month,
                                    'targetYear': d_Year,
                                    'targetHour': selectedNoon == '오전'
                                        ? selectedHour == 12
                                            ? selectedHour! - 12
                                            : selectedHour
                                        : selectedHour == 12
                                            ? selectedHour
                                            : selectedHour! + 12,
                                    'targetMinute': selectedMinute,
                                    'Categories': selectedCategory,
                                    'hostPhotoUrl': responseUserData[0],
                                    'memberTokenList': [responseUserData[1]],
                                    'hostUID': hostUID,
                                    'memberPhotoUrl': memberPhotoUrl,
                                    'memberUID': memberUID,
                                    'requestUID': requestUID,
                                    'inProgress': inprogress,
                                    'chatRoom': chatRoomName,
                                  });
                                  await _chatRoom
                                      .collection(chatRoomName)
                                      .doc('info')
                                      .set({
                                    'title': [titleParameter, titleParameter],
                                    'hostUID': hostUID,
                                    'hostPhotoUrl': responseUserData[0],
                                    'memberTokenList': [responseUserData[1]],
                                    'chatRoom': chatRoomName,
                                    'targetDay': d_Day,
                                    'targetMonth': d_Month,
                                    'targetYear': d_Year,
                                    'targetHour': selectedNoon == '오전'
                                        ? selectedHour == 12
                                            ? selectedHour! - 12
                                            : selectedHour
                                        : selectedHour == 12
                                            ? selectedHour
                                            : selectedHour! + 12,
                                    'targetMinute': selectedMinute,
                                    'newestMessage': ' ',
                                    'member': memberUID,
                                    'isGroup': true,
                                    'memberPhotoUrl': [],
                                  });
                                  await _userinfo
                                      .collection('chat')
                                      .doc(chatRoomName)
                                      .set({
                                    'read': 0,
                                    'recent': DateTime(2099, 1, 1, 1, 1),
                                  });
                                  progress?.dismiss();
                                  Navigator.pop(context);
                                }
                              } else {
                                await _roomAdress.set({
                                  'title': titleParameter,
                                  'place': selectedPlace,
                                  'info': infoParameter,
                                  'headcount': selectedPeople,
                                  'targetDay': d_Day,
                                  'targetMonth': d_Month,
                                  'targetYear': d_Year,
                                  'targetHour': selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12,
                                  'targetMinute': selectedMinute,
                                  'Categories': selectedCategory,
                                  'hostPhotoUrl': responseUserData[0],
                                  'memberTokenList': [responseUserData[1]],
                                  'hostUID': hostUID,
                                  'memberPhotoUrl': memberPhotoUrl,
                                  'memberUID': memberUID,
                                  'inProgress': inprogress,
                                  'chatRoom': chatRoomName,
                                });
                                await _madeRoom.set({
                                  'title': titleParameter,
                                  'place': selectedPlace,
                                  'info': infoParameter,
                                  'headcount': selectedPeople,
                                  'targetDay': d_Day,
                                  'targetMonth': d_Month,
                                  'targetYear': d_Year,
                                  'targetHour': selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12,
                                  'targetMinute': selectedMinute,
                                  'Categories': selectedCategory,
                                  'hostPhotoUrl': responseUserData[0],
                                  'memberTokenList': [responseUserData[1]],
                                  'hostUID': hostUID,
                                  'memberPhotoUrl': memberPhotoUrl,
                                  'memberUID': memberUID,
                                  'requestUID': requestUID,
                                  'inProgress': inprogress,
                                  'chatRoom': chatRoomName,
                                });
                                await _chatRoom
                                    .collection(chatRoomName)
                                    .doc('info')
                                    .set({
                                  'title': [titleParameter, titleParameter],
                                  'hostUID': hostUID,
                                  'hostPhotoUrl': responseUserData[0],
                                  'memberTokenList': [responseUserData[1]],
                                  'chatRoom': chatRoomName,
                                  'targetDay': d_Day,
                                  'targetMonth': d_Month,
                                  'targetYear': d_Year,
                                  'targetHour': selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12,
                                  'targetMinute': selectedMinute,
                                  'newestMessage': ' ',
                                  'member': memberUID,
                                  'isGroup': true,
                                  'memberPhotoUrl': [],
                                });
                                await _userinfo
                                    .collection('chat')
                                    .doc(chatRoomName)
                                    .set({
                                  'read': 0,
                                  'recent': DateTime(2099, 1, 1, 1, 1),
                                });
                                progress?.dismiss();
                                Navigator.pop(context);
                              }
                            } else if (tomorrow == true &&
                                DateTime.now().hour >= 23) {
                              if (selectedNoon == '오전' && selectedHour == 12) {
                                if (selectedMinute! < DateTime.now().minute) {
                                  progress?.dismiss();
                                  return limitCreateHour();
                                } else {
                                  await _roomAdress.set({
                                    'title': titleParameter,
                                    'place': selectedPlace,
                                    'info': infoParameter,
                                    'headcount': selectedPeople,
                                    'targetDay': d_Day,
                                    'targetMonth': d_Month,
                                    'targetYear': d_Year,
                                    'targetHour': selectedNoon == '오전'
                                        ? selectedHour == 12
                                            ? selectedHour! - 12
                                            : selectedHour
                                        : selectedHour == 12
                                            ? selectedHour
                                            : selectedHour! + 12,
                                    'targetMinute': selectedMinute,
                                    'Categories': selectedCategory,
                                    'hostPhotoUrl': responseUserData[0],
                                    'memberTokenList': [responseUserData[1]],
                                    'hostUID': hostUID,
                                    'memberPhotoUrl': memberPhotoUrl,
                                    'memberUID': memberUID,
                                    'inProgress': inprogress,
                                    'chatRoom': chatRoomName,
                                  });
                                  await _madeRoom.set({
                                    'title': titleParameter,
                                    'place': selectedPlace,
                                    'info': infoParameter,
                                    'headcount': selectedPeople,
                                    'targetDay': d_Day,
                                    'targetMonth': d_Month,
                                    'targetYear': d_Year,
                                    'targetHour': selectedNoon == '오전'
                                        ? selectedHour == 12
                                            ? selectedHour! - 12
                                            : selectedHour
                                        : selectedHour == 12
                                            ? selectedHour
                                            : selectedHour! + 12,
                                    'targetMinute': selectedMinute,
                                    'Categories': selectedCategory,
                                    'hostPhotoUrl': responseUserData[0],
                                    'memberTokenList': [responseUserData[1]],
                                    'hostUID': hostUID,
                                    'memberPhotoUrl': memberPhotoUrl,
                                    'memberUID': memberUID,
                                    'requestUID': requestUID,
                                    'inProgress': inprogress,
                                    'chatRoom': chatRoomName,
                                  });
                                  await _chatRoom
                                      .collection(chatRoomName)
                                      .doc('info')
                                      .set({
                                    'title': [titleParameter, titleParameter],
                                    'hostUID': hostUID,
                                    'hostPhotoUrl': responseUserData[0],
                                    'memberTokenList': [responseUserData[1]],
                                    'chatRoom': chatRoomName,
                                    'targetDay': d_Day,
                                    'targetMonth': d_Month,
                                    'targetYear': d_Year,
                                    'targetHour': selectedNoon == '오전'
                                        ? selectedHour == 12
                                            ? selectedHour! - 12
                                            : selectedHour
                                        : selectedHour == 12
                                            ? selectedHour
                                            : selectedHour! + 12,
                                    'targetMinute': selectedMinute,
                                    'newestMessage': ' ',
                                    'member': memberUID,
                                    'isGroup': true,
                                    'memberPhotoUrl': [],
                                  });
                                  await _userinfo
                                      .collection('chat')
                                      .doc(chatRoomName)
                                      .set({
                                    'read': 0,
                                    'recent': DateTime(2099, 1, 1, 1, 1),
                                  });
                                  progress?.dismiss();
                                  Navigator.pop(context);
                                }
                              } else {
                                await _roomAdress.set({
                                  'title': titleParameter,
                                  'place': selectedPlace,
                                  'info': infoParameter,
                                  'headcount': selectedPeople,
                                  'targetDay': d_Day,
                                  'targetMonth': d_Month,
                                  'targetYear': d_Year,
                                  'targetHour': selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12,
                                  'targetMinute': selectedMinute,
                                  'Categories': selectedCategory,
                                  'hostPhotoUrl': responseUserData[0],
                                  'memberTokenList': [responseUserData[1]],
                                  'hostUID': hostUID,
                                  'memberPhotoUrl': memberPhotoUrl,
                                  'memberUID': memberUID,
                                  'inProgress': inprogress,
                                  'chatRoom': chatRoomName,
                                });
                                await _madeRoom.set({
                                  'title': titleParameter,
                                  'place': selectedPlace,
                                  'info': infoParameter,
                                  'headcount': selectedPeople,
                                  'targetDay': d_Day,
                                  'targetMonth': d_Month,
                                  'targetYear': d_Year,
                                  'targetHour': selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12,
                                  'targetMinute': selectedMinute,
                                  'Categories': selectedCategory,
                                  'hostPhotoUrl': responseUserData[0],
                                  'memberTokenList': [responseUserData[1]],
                                  'hostUID': hostUID,
                                  'memberPhotoUrl': memberPhotoUrl,
                                  'memberUID': memberUID,
                                  'requestUID': requestUID,
                                  'inProgress': inprogress,
                                  'chatRoom': chatRoomName,
                                });
                                await _chatRoom
                                    .collection(chatRoomName)
                                    .doc('info')
                                    .set({
                                  'title': [titleParameter, titleParameter],
                                  'hostUID': hostUID,
                                  'hostPhotoUrl': responseUserData[0],
                                  'memberTokenList': [responseUserData[1]],
                                  'chatRoom': chatRoomName,
                                  'targetDay': d_Day,
                                  'targetMonth': d_Month,
                                  'targetYear': d_Year,
                                  'targetHour': selectedNoon == '오전'
                                      ? selectedHour == 12
                                          ? selectedHour! - 12
                                          : selectedHour
                                      : selectedHour == 12
                                          ? selectedHour
                                          : selectedHour! + 12,
                                  'targetMinute': selectedMinute,
                                  'newestMessage': ' ',
                                  'member': memberUID,
                                  'isGroup': true,
                                  'memberPhotoUrl': [],
                                });
                                await _userinfo
                                    .collection('chat')
                                    .doc(chatRoomName)
                                    .set({
                                  'read': 0,
                                  'recent': DateTime(2099, 1, 1, 1, 1),
                                });
                                progress?.dismiss();
                                Navigator.pop(context);
                              }
                            } else {
                              await _roomAdress.set({
                                'title': titleParameter,
                                'place': selectedPlace,
                                'info': infoParameter,
                                'headcount': selectedPeople,
                                'targetDay': d_Day,
                                'targetMonth': d_Month,
                                'targetYear': d_Year,
                                'targetHour': selectedNoon == '오전'
                                    ? selectedHour == 12
                                        ? selectedHour! - 12
                                        : selectedHour
                                    : selectedHour == 12
                                        ? selectedHour
                                        : selectedHour! + 12,
                                'targetMinute': selectedMinute,
                                'Categories': selectedCategory,
                                'hostPhotoUrl': responseUserData[0],
                                'memberTokenList': [responseUserData[1]],
                                'hostUID': hostUID,
                                'memberPhotoUrl': memberPhotoUrl,
                                'memberUID': memberUID,
                                'inProgress': inprogress,
                                'chatRoom': chatRoomName,
                              });
                              await _madeRoom.set({
                                'title': titleParameter,
                                'place': selectedPlace,
                                'info': infoParameter,
                                'headcount': selectedPeople,
                                'targetDay': d_Day,
                                'targetMonth': d_Month,
                                'targetYear': d_Year,
                                'targetHour': selectedNoon == '오전'
                                    ? selectedHour == 12
                                        ? selectedHour! - 12
                                        : selectedHour
                                    : selectedHour == 12
                                        ? selectedHour
                                        : selectedHour! + 12,
                                'targetMinute': selectedMinute,
                                'Categories': selectedCategory,
                                'hostPhotoUrl': responseUserData[0],
                                'memberTokenList': [responseUserData[1]],
                                'hostUID': hostUID,
                                'memberPhotoUrl': memberPhotoUrl,
                                'memberUID': memberUID,
                                'requestUID': requestUID,
                                'inProgress': inprogress,
                                'chatRoom': chatRoomName,
                              });
                              await _chatRoom
                                  .collection(chatRoomName)
                                  .doc('info')
                                  .set({
                                'title': [titleParameter, titleParameter],
                                'hostUID': hostUID,
                                'hostPhotoUrl': responseUserData[0],
                                'memberTokenList': [responseUserData[1]],
                                'chatRoom': chatRoomName,
                                'targetDay': d_Day,
                                'targetMonth': d_Month,
                                'targetYear': d_Year,
                                'targetHour': selectedNoon == '오전'
                                    ? selectedHour == 12
                                        ? selectedHour! - 12
                                        : selectedHour
                                    : selectedHour == 12
                                        ? selectedHour
                                        : selectedHour! + 12,
                                'targetMinute': selectedMinute,
                                'newestMessage': ' ',
                                'member': memberUID,
                                'isGroup': true,
                                'memberPhotoUrl': [],
                              });
                              await _userinfo
                                  .collection('chat')
                                  .doc(chatRoomName)
                                  .set({
                                'read': 0,
                                'recent': DateTime(2099, 1, 1, 1, 1),
                              });
                              progress?.dismiss();
                              Navigator.pop(context);
                            }
                          } else {
                            progress?.dismiss();
                            showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.w)),
                                    content: Text("작성 혹은 선택되지 않은 내용이 있습니다."),
                                  );
                                });
                          }
                        },
                      )
                    ],
                  ),
                ),
              ),
              buildBottomDrawer(context),
            ],
          ),
        ),
      ),
    );
  }
}
