import 'dart:convert';
import 'dart:io';

import 'package:famet/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'signinLabel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customProfile/custom_Profile.dart';
import 'customSignIn/custom_sign_in_screen.dart';
import 'customSignIn/build_account.dart';
import 'package:famet/groupManage/group_manage.dart';
import 'package:famet/roomType/member_room_screen.dart';
import 'package:famet/roomType/host_room_screen.dart';
import 'package:famet/groupSearch/group_Search.dart';
import 'package:famet/community/chatRoom_view.dart';
import 'banned_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yaml/yaml.dart';

var _user = FirebaseAuth.instance.currentUser;
var _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
var _roomlist = FirebaseFirestore.instance.collection('activateRoom');

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

const fetchBackground = 'fetchBackground';
const fcmServerKey =
    'AAAA8cL90wc:APA91bF-RBJ3dRn0d_1uSIoJE1BNIzaA8weml0I-3xVH44Zshxqgo7342rmr5TT1JDE-aNNej6DekBinmbSTQ2llvBCBxE4EqHTSQ1x-UwxphCorQWAUcrb_c3jaNiQfEu04IhgETBQf';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message ${message.messageId}');
  print('this is fcm data field details : ${message.data['status']}');
}

Future<void> sendMessage({
  required String userToken,
  required String title,
  required String body,
}) async {
  http.Response response;
  try {
    response = await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmServerKey', //http v1으로 마이그레이션 해야함
        },
        body: jsonEncode({
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'app',
            "action": '테스트',
          },
          'to': userToken, // 'registration_ids': tokenList
          'content_available': true,
          'priority': 'high',
        }));
  } catch (e) {
    print('error $e');
  }
}

void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();
    switch (task) {
      case fetchBackground:
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          var userFcmToken;
          final joinCheck = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('room')
              .doc('join')
              .get();
          Map<String, dynamic>? joindata =
              joinCheck.data() as Map<String, dynamic>?;
          final madeCheck = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('room')
              .doc('made')
              .get();
          Map<String, dynamic>? madedata =
              madeCheck.data() as Map<String, dynamic>?;

          if (joindata != null || madedata != null) {
            final currentUserData = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
            Map<String, dynamic>? userToken =
                currentUserData.data() as Map<String, dynamic>?;
            userFcmToken = userToken!['pushToken'];
            if (userFcmToken == null) {
              userFcmToken = await FirebaseMessaging.instance.getToken();
            }
          }

          if (joindata != null) {
            final joinRoom = await FirebaseFirestore.instance
                .collection('activateRoom')
                .doc(joindata['hostUID'])
                .get();
            Map<String, dynamic>? joinRoomdata =
                joinRoom.data() as Map<String, dynamic>?;
            if (joinRoomdata == null) {
              final joinRoomI = await FirebaseFirestore.instance
                  .collection('inProgressRoom')
                  .doc(joindata['hostUID'])
                  .get();
              joinRoomdata = joinRoomI.data() as Map<String, dynamic>?;
            }
            if (joinRoomdata != null) {
              final targetTime = DateTime(
                joinRoomdata['targetYear'],
                joinRoomdata['targetMonth'],
                joinRoomdata['targetDay'],
                joinRoomdata['targetHour'],
                joinRoomdata['targetMinute'],
              );
              if (targetTime.difference(DateTime.now()).inMinutes >= 40 &&
                  targetTime.difference(DateTime.now()).inMinutes <= 55) {
                await sendMessage(
                  userToken: userFcmToken,
                  title: '오늘모임',
                  body: '모임 시작 30분 전부터는 모임 탈퇴가 불가능합니다 \n지금 참가한 모임을 확인해보세요!',
                );
              }
              if (targetTime.difference(DateTime.now()).inMinutes >= 15 &&
                  targetTime.difference(DateTime.now()).inMinutes <= 30) {
                await sendMessage(
                  userToken: userFcmToken,
                  title: '오늘모임',
                  body: '곧 모임이 시작됩니다! \n지금은 모임을 탈퇴할 수 없어요',
                );
              }
              if (DateTime.now().difference(targetTime).inMinutes >= 0 &&
                  DateTime.now().difference(targetTime).inMinutes <= 15) {
                await sendMessage(
                  userToken: userFcmToken,
                  title: '오늘모임',
                  body: '모임이 시작되었습니다! \n꼭 상대의 출석체크를 진행해주세요',
                );
              }
            }
          }

          if (madedata != null) {
            final targetTime = DateTime(
              madedata['targetYear'],
              madedata['targetMonth'],
              madedata['targetDay'],
              madedata['targetHour'],
              madedata['targetMinute'],
            );
            if (targetTime.difference(DateTime.now()).inMinutes >= 40 &&
                targetTime.difference(DateTime.now()).inMinutes <= 55) {
              await sendMessage(
                userToken: userFcmToken,
                title: '오늘모임',
                body: '모임 시작 30분 전부터는 모임 탈퇴가 불가능합니다 \n지금 참가한 모임을 확인해보세요!',
              );
            }
            if (targetTime.difference(DateTime.now()).inMinutes >= 15 &&
                targetTime.difference(DateTime.now()).inMinutes <= 30) {
              await sendMessage(
                userToken: userFcmToken,
                title: '오늘모임',
                body: '곧 모임이 시작됩니다! \n지금은 모임을 탈퇴할 수 없어요',
              );
            }
            if (DateTime.now().difference(targetTime).inMinutes >= 10 &&
                DateTime.now().difference(targetTime).inMinutes <= 25 &&
                madedata['inProgress'] == true) {
              await sendMessage(
                userToken: userFcmToken,
                title: '오늘모임',
                body: '모임이 시작되었습니다! \n꼭 상대의 출석체크를 진행해주세요',
              );
            }
          }
        }
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  /*auth.FirebaseUIAuth.configureProviders([
    auth.PhoneAuthProvider(),
  ]);*/
  await ScreenUtil.ensureScreenSize();

  await Workmanager().initialize(callbackDispatcher);
  if (Platform.isAndroid) {
    await Workmanager().registerPeriodicTask('checkGroup', fetchBackground,
        frequency: Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected));
  }
  var initialzationSettingsIOS = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );
  var initialzationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: false,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  var initializationSettings = InitializationSettings(
    android: initialzationSettingsAndroid,
    iOS: initialzationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (FirebaseAuth.instance.currentUser?.uid != null) {
    var pushtoken = await FirebaseMessaging.instance.getToken();
    _userinfo.update({'pushToken': pushtoken});
  }
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(),
    theme: ThemeData(
      fontFamily: 'Pretendard',
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
              foregroundColor:
                  MaterialStateProperty.all<Color>(Color(0xFF51CF6D)),
              overlayColor:
                  MaterialStateProperty.all<Color>(Colors.transparent))),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: Color(0xFF51CF6D)),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF51CF6D)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(Color(0xFF51CF6D)))),
    ),
    localizationsDelegates: [
      //FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides())
      FlutterFireUILocalizations.withDefaultOverrides(const LabelOverrides())
    ],
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

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

  void _onBottomTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _roomlist = FirebaseFirestore.instance.collection('activateRoom');
    _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    _user = FirebaseAuth.instance.currentUser;

    interstitialAd();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      var androidNotiDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
      );
      var iOSNotiDetails = const DarwinNotificationDetails();
      var details = NotificationDetails(
        android: androidNotiDetails,
        iOS: iOSNotiDetails,
      );
      if (notification != null) {
        if (message.data['status'] == 'app') {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            details,
          );
        }
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print(message);
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      _userinfo.update({'pushToken': fcmToken});
    });
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        const value = true;
        if (_interstitialAd != null) _interstitialAd?.show();
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.w)),
                  content: Text(""),
                  actions: [
                    TextButton(
                        child: Text('취소',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12.w,
                            )),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                    TextButton(
                        child: Text('종료',
                            style: TextStyle(
                              color: Color(0xFF51CF6D),
                              fontSize: 12.w,
                            )),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                  ]);
            });
        return value;
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Text(
                  ['오늘모임.', '모임찾기', '채팅방', '모임관리', '프로필'][_selectedIndex],
                  style: TextStyle(
                    color:
                        _selectedIndex == 0 ? Color(0xFF51CF6D) : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontFamily: _selectedIndex == 0 ? 'room703' : 'Pretendard',
                    fontSize: _selectedIndex == 0 ? 22.w : 18.w,
                  )),
            ),
            actions: [
              StreamBuilder(
                  stream: _userinfo.collection('notification').snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) return Text('');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Text('');
                    List<DocumentSnapshot> notificationList =
                        snapshot.data!.docs;
                    if (notificationList.isEmpty) {
                      _userinfo
                          .collection('notification')
                          .doc('1nfo')
                          .set({'recent': DateTime.now()});
                    }
                    DateTime recentRead =
                        notificationList.first.get('recent').toDate();
                    DateTime lastNotification =
                        notificationList.last.get('timeStamp').toDate();
                    return Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              color: Color(0xFF51CF6D),
                              size: 22.w,
                            ),
                            onPressed: () async {
                              Scaffold.of(context).openEndDrawer();
                              await _userinfo
                                  .collection('notification')
                                  .doc('1nfo')
                                  .update({
                                'recent': DateTime.now(),
                              });
                            },
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                          if (recentRead.isBefore(lastNotification))
                            Transform.translate(
                                offset: Offset(22.w, 20.w),
                                child: CircleAvatar(
                                  backgroundColor: Color(0xFFFFA000),
                                  radius: 4.w,
                                ))
                        ],
                      ),
                    );
                  })
            ],
          ),
          endDrawer: Drawer(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: 100.w,
                child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text('알림', style: TextStyle(fontSize: 24.w)))),
              ),
              Expanded(
                  child: Padding(
                padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 6.w),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _userinfo.collection('notification').snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) return Text('오류가 발생했습니다.');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Text('');
                    final List<DocumentSnapshot> notificationList =
                        snapshot.data!.docs.reversed.toList();
                    notificationList.removeAt(notificationList.length - 1);
                    return notificationList.isNotEmpty
                        ? ListView.separated(
                            physics: BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: notificationList.length,
                            itemBuilder: (BuildContext ctx, int idx) {
                              return FutureBuilder(
                                future: _userinfo
                                    .collection('notification')
                                    .doc('${notificationList[idx].id}')
                                    .get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (snapshot.hasError)
                                    return Text('오류가 발생했습니다.');
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) return Text('');
                                  Map<String, dynamic>? data = snapshot.data
                                      ?.data() as Map<String, dynamic>?;
                                  DateTime notificatedTime =
                                      data!['timeStamp'].toDate();
                                  String sendTime =
                                      '${notificatedTime.month}월${notificatedTime.day}일 ${notificatedTime.hour}:${notificatedTime.minute.toString().length == 1 ? '0${notificatedTime.minute}' : notificatedTime.minute}';
                                  return InkWell(
                                    child: Container(
                                      height: 70.w,
                                      width: double.infinity,
                                      padding: EdgeInsets.only(left: 4.w),
                                      decoration: BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                        width: 1,
                                        color: Colors.grey.withOpacity(0.7),
                                      ))),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${data['title']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14.w,
                                              )),
                                          if (data['state'] == 'request')
                                            Text('모임에 새로운 가입요청이 있습니다',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          if (data['state'] == 'exit')
                                            Text('모임에서 일부 참가자가 탈퇴했습니다',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          if (data['state'] == 'accept')
                                            Text('모임에 가입요청이 수락되었습니다',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          if (data['state'] == 'denied')
                                            Text('모임에 가입요청이 거절되었습니다',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          if (data['state'] == 'kick')
                                            Text('모임에서 내보내기 되었습니다',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          if (data['state'] == 'dismiss')
                                            Text('모임이 해체되었습니다',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          if (data['state'] == 'notEnough')
                                            Text('모임이 인원 미충족으로 해체되었습니다',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          if (data['state'] == 'start')
                                            Text('모임이 시작되었습니다.',
                                                style:
                                                    TextStyle(fontSize: 12.w)),
                                          SizedBox(height: 4.w),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              if (data['state'] != 'denied' &&
                                                  data['state'] != 'kick' &&
                                                  data['state'] != 'dismiss' &&
                                                  data['state'] != 'notEnough')
                                                Text('눌러서 자세히보기',
                                                    style: TextStyle(
                                                        fontSize: 12.w,
                                                        color: Colors.grey)),
                                              if (data['state'] != 'denied' &&
                                                  data['state'] != 'kick' &&
                                                  data['state'] != 'dismiss' &&
                                                  data['state'] != 'notEnough')
                                                SizedBox(width: 4.w),
                                              Text('$sendTime',
                                                  style: TextStyle(
                                                      fontSize: 10.w,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      if (data['state'] == 'request' ||
                                          data['state'] == 'exit') {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    HostRoomPage()) //모임 자세히보기
                                            );
                                      }
                                      if (data['state'] == 'accept' ||
                                          data['state'] == 'start') {
                                        Scaffold.of(context).closeEndDrawer();
                                        setState(() {
                                          _selectedIndex = 3;
                                        });
                                      }
                                    },
                                  );
                                },
                              );
                            },
                            separatorBuilder: (ctx, idx) {
                              return SizedBox(height: 8.w);
                            },
                          )
                        : SizedBox(height: 0);
                  },
                ),
              )),
            ],
          )),
          body: [
            HomePage(),
            GroupSearch(),
            ChatRoomView(),
            GroupManagePage(),
            ProfilePage()
          ][_selectedIndex],
          bottomNavigationBar: SizedBox(
            height: 48.w,
            child: Theme(
              data: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent),
              child: BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home_filled), label: '홈'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_search), label: '모임찾기'),
                  BottomNavigationBarItem(
                      icon: Stack(
                        children: [
                          Icon(Icons.forum_outlined),
                          StreamBuilder(
                            stream: _userinfo
                                .collection('chat')
                                .where('read', isEqualTo: 1)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) return Text('');
                              if (snapshot.hasError) return Text('');
                              final List<DocumentSnapshot> newChat =
                                  snapshot.data!.docs;
                              return newChat.isNotEmpty
                                  ? Transform.translate(
                                      offset: Offset(15.w, 3.w),
                                      child: CircleAvatar(
                                        backgroundColor: Color(0xFFFFA000),
                                        radius: 4.w,
                                      ))
                                  : SizedBox(height: 0);
                            },
                          )
                        ],
                      ),
                      label: '채팅방'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.auto_awesome_motion_outlined),
                      label: '모임관리'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline), label: '프로필'),
                ],
                currentIndex: _selectedIndex,
                onTap: _onBottomTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Color(0xFFB9F6CA),
                selectedItemColor: Color(0xFF51CF6D),
                unselectedFontSize: 0,
                selectedFontSize: 10.w,
                iconSize: 22.w,
                showUnselectedLabels: false,
                selectedLabelStyle: TextStyle(fontFamily: 'Pretendard'),
              ),
            ),
          )),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget bannerAd() {
    BannerAdListener bannerAdListener =
        BannerAdListener(onAdWillDismissScreen: (ad) {
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
    super.initState();
    _roomlist = FirebaseFirestore.instance.collection('activateRoom');
    _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    super.dispose();
  }

  marketingAgree() {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.w))),
              contentPadding: EdgeInsets.only(top: 10.w),
              content: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        "광고성 정보 수신 동의",
                        style: TextStyle(fontSize: 16.w),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Divider(
                      color: Colors.grey,
                      height: 4.h,
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(10.w, 20.h, 10.w, 20.h),
                      child: Text(
                          "'오늘모임' 의 마케팅 활용 및 광고성 정보(유입목적의 푸시알림 및 이벤트에 대한 내용)에 대한 내용을 수신하는데 동의하십니까?\n\n본 내용에 대한 동의는 언제든 앱 내 설정에서 바꿀 수 있습니다.\n\n거부 시에는 앱에서 진행하는 이벤트 혹은 프로모션에 관한 내용을 전달받지 못할 수 있습니다."),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: InkWell(
                            child: Container(
                              padding: EdgeInsets.only(top: 14.w, bottom: 14.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12.w),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "거부",
                                    style: TextStyle(color: Color(0xFF51CF6D)),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              final setTime = DateTime.now();
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .collection('marketingInfo')
                                  .doc('agreement')
                                  .set({
                                'setTime': setTime,
                                'agreement': 'disagree',
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    "'오늘모임'의 광고성 정보 수신을 '비동의'하셨습니다.\n일시 : ${setTime.year}년 ${setTime.month}월${setTime.day}일",
                                    style: TextStyle(color: Colors.white)),
                                duration: Duration(seconds: 5),
                                backgroundColor: Colors.black,
                              ));
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            child: Container(
                              padding: EdgeInsets.only(top: 14.w, bottom: 14.w),
                              decoration: BoxDecoration(
                                color: Color(0xFF51CF6D),
                                borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(12.w)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "동의",
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              final setTime = DateTime.now();
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .collection('marketingInfo')
                                  .doc('agreement')
                                  .set({
                                'setTime': setTime,
                                'agreement': 'agree',
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    "'오늘모임'의 광고성 정보 수신을 '동의'하셨습니다.\n일시 : ${setTime.year}년 ${setTime.month}월${setTime.day}일",
                                    style: TextStyle(color: Colors.white)),
                                duration: Duration(seconds: 5),
                                backgroundColor: Colors.black,
                              ));
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 10.w),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                    child: Text(
                      '혹시 이런 모임은 어떠신가요?',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.w),
                    ),
                    height: 34.w,
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Color(0xFF51CF6D), width: 1)))),
                SizedBox(height: 12.w),
                FutureBuilder<DocumentSnapshot>(
                  future: _userinfo.collection('other').doc('block').get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) return Text('오류가 발생했습니다.');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Text('');
                    Map<String, dynamic>? blocked =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    List<dynamic> blocklist = blocked?['blocked'] ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      bool firstLogin;
                      final agreeData = await _userinfo
                          .collection('marketingInfo')
                          .doc('agreement')
                          .get();
                      final agreementCheck = agreeData.get('agreement');
                      if (agreementCheck == 'agree' ||
                          agreementCheck == 'disagree') {
                        firstLogin = false;
                      } else {
                        firstLogin = true;
                      }
                      if (firstLogin) {
                        marketingAgree();
                      }
                    });
                    return FutureBuilder<QuerySnapshot>(
                      future: _roomlist.get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) return Text('오류가 발생했습니다.');
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return Text('');
                        if (!snapshot.hasData) return Text('만들어진 모임이 없습니다.');
                        final List<DocumentSnapshot> activateRoom =
                            snapshot.data!.docs;
                        activateRoom.shuffle();
                        return ListView.separated(
                          physics: BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: activateRoom.length,
                          itemBuilder: (BuildContext ctx, int idx) {
                            return FutureBuilder<DocumentSnapshot>(
                              future: _roomlist
                                  .doc('${activateRoom[idx].id}')
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError)
                                  return Text('오류가 발생했습니다.');
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) return Text('');
                                Map<String, dynamic>? data = snapshot.data
                                    ?.data() as Map<String, dynamic>?;
                                if (data == null) return SizedBox(height: 0);
                                String host = activateRoom[idx].id;
                                List<dynamic> headcount =
                                    data['memberUID'] ?? [];
                                bool blockmember = false;
                                String categoryTextH =
                                    data['Categories'].join('  ');
                                final targetTime = DateTime(
                                    data['targetYear'] as int,
                                    data['targetMonth'] as int,
                                    data['targetDay'] as int,
                                    data['targetHour'] as int,
                                    data['targetMinute'] as int);
                                if (targetTime.isBefore(DateTime.now()) &&
                                    headcount.length == 1) {
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${activateRoom[idx].id}')
                                      .collection('chat')
                                      .doc('${data['chatRoom']}')
                                      .delete();
                                  FirebaseFirestore.instance
                                      .collection('chatRoom')
                                      .doc('available')
                                      .collection('${data['chatRoom']}')
                                      .get()
                                      .then((snapshot) {
                                    for (DocumentSnapshot doc
                                        in snapshot.docs) {
                                      doc.reference.delete();
                                    }
                                  });
                                  sendMessage(
                                    userToken: data['memberTokenList'][0],
                                    title: '오늘모임',
                                    body: '개설하신 모임이 인원 미충족으로 해체되었습니다.',
                                  );
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${activateRoom[idx].id}')
                                      .collection('notification')
                                      .doc('${targetTime}_${data['hostUID']}')
                                      .set({
                                    'uid': data['hostUID'],
                                    'title': data['title'],
                                    'timeStamp': targetTime,
                                    'state': 'notEnough',
                                  });
                                  _roomlist
                                      .doc('${activateRoom[idx].id}')
                                      .delete();
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${activateRoom[idx].id}')
                                      .collection('room')
                                      .doc('made')
                                      .delete();
                                  return SizedBox(height: 0);
                                }
                                for (int b = 0; b < headcount.length; b++) {
                                  if (blocklist.contains(headcount[b]))
                                    blockmember = true;
                                }
                                if (targetTime.isBefore(DateTime.now()) &&
                                    headcount.length >= 2) {
                                  for (int h = 0; h < headcount.length; h++) {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc('${headcount[h]}')
                                        .collection('notification')
                                        .doc('${targetTime}_${data['hostUID']}')
                                        .set({
                                      'uid': data['hostUID'],
                                      'title': data['title'],
                                      'timeStamp': targetTime,
                                      'state': 'start',
                                    });
                                  }
                                  FirebaseFirestore.instance
                                      .collection('inProgressRoom')
                                      .doc('${activateRoom[idx].id}')
                                      .set({
                                    'Categories': data['Categories'],
                                    'headcount': data['headcount'],
                                    'hostPhotoUrl': data['hostPhotoUrl'],
                                    'hostUID': data['hostUID'],
                                    'info': data['info'],
                                    'memberPhotoUrl': data['memberPhotoUrl'],
                                    'memberUID': data['memberUID'],
                                    'absent': data['memberUID'],
                                    'place': data['place'],
                                    'targetDay': data['targetDay'],
                                    'targetHour': data['targetHour'],
                                    'targetMinute': data['targetMinute'],
                                    'targetMonth': data['targetMonth'],
                                    'targetYear': data['targetYear'],
                                    'title': data['title'],
                                    'inProgress': true,
                                    'memberTokenList': data['memberTokenList'],
                                  });
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${activateRoom[idx].id}')
                                      .collection('room')
                                      .doc('made')
                                      .update({
                                    'inProgress': true,
                                    'absent': data['memberUID'],
                                  });
                                  _roomlist
                                      .doc('${activateRoom[idx].id}')
                                      .delete();
                                  return SizedBox(height: 0);
                                }
                                return headcount.isNotEmpty &&
                                        blockmember != true
                                    ? Container(
                                        height: 94.w,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey, width: 1)),
                                        child: Padding(
                                          padding: EdgeInsets.all(8.w),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 70.w,
                                                      child: Stack(
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundColor:
                                                                Colors.grey,
                                                            radius: 32.w,
                                                            backgroundImage:
                                                                NetworkImage(
                                                                    '${data['hostPhotoUrl']}'),
                                                          ),
                                                          if (headcount
                                                                  .length >=
                                                              2)
                                                            Transform.translate(
                                                              offset: headcount
                                                                          .length ==
                                                                      2
                                                                  ? Offset(35.w,
                                                                      35.w)
                                                                  : Offset(25.w,
                                                                      35.w),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.grey,
                                                                radius: 18.w,
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                        '${data['memberPhotoUrl'][0]}'),
                                                              ),
                                                            ),
                                                          if (headcount
                                                                  .length >=
                                                              3)
                                                            Transform.translate(
                                                              offset: Offset(
                                                                  35.w, 35.w),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.white
                                                                        .withOpacity(
                                                                            0.8),
                                                                radius: 18.w,
                                                                child: Center(
                                                                  child: Text(
                                                                    '+${headcount.length - 2}',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontSize:
                                                                          12.w,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 6.w),
                                                    SizedBox(
                                                      width: 210.w,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              '${data['title']}',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              softWrap: false,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12.w,
                                                              )),
                                                          SizedBox(height: 2.w),
                                                          Text(
                                                              '장소: ${data['place']}',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      10.w)),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                  '약속시간: ${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          10.w)),
                                                              Text(
                                                                  '인원:${headcount.length}/${data['headcount']}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          10.w))
                                                            ],
                                                          ),
                                                          Text(
                                                            '$categoryTextH',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            softWrap: false,
                                                            style: TextStyle(
                                                                fontSize: 10.w),
                                                          ),
                                                          SizedBox(height: 3.w),
                                                          Text('눌러서 자세히 보기',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize:
                                                                      10.w))
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              MemberRoomPage(
                                                                host: host,
                                                                inProgress:
                                                                    false,
                                                              )) //모임 자세히보기
                                                      );
                                                },
                                              ),
                                              SizedBox(width: 4.w),
                                              StreamBuilder<DocumentSnapshot>(
                                                stream: _userinfo
                                                    .collection('room')
                                                    .doc('attention')
                                                    .snapshots(),
                                                builder: (BuildContext context,
                                                    AsyncSnapshot<
                                                            DocumentSnapshot>
                                                        snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting)
                                                    return Text('');
                                                  Map<String, dynamic>? data =
                                                      snapshot.data?.data()
                                                          as Map<String,
                                                              dynamic>?;
                                                  List<dynamic> attention =
                                                      data != null
                                                          ? data['attention'] ??
                                                              []
                                                          : [];
                                                  return attention.contains(
                                                              '${activateRoom[idx].id}') !=
                                                          true
                                                      ? Container(
                                                          width: 14.w,
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                          child: InkWell(
                                                              child: Icon(
                                                                Icons
                                                                    .favorite_outline,
                                                                color: Color(
                                                                    0xFFEF5350),
                                                                size: 16.w,
                                                              ),
                                                              onTap: () async {
                                                                attention.add(
                                                                    '${activateRoom[idx].id}');
                                                                await _userinfo
                                                                    .collection(
                                                                        'room')
                                                                    .doc(
                                                                        'attention')
                                                                    .set({
                                                                  'attention':
                                                                      attention,
                                                                });
                                                              }),
                                                        )
                                                      : Container(
                                                          width: 14.w,
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                          child: InkWell(
                                                              child: Icon(
                                                                Icons.favorite,
                                                                color: Color(
                                                                    0xFFEF5350),
                                                                size: 16.w,
                                                              ),
                                                              onTap: () async {
                                                                final int
                                                                    indexToRemove =
                                                                    attention
                                                                        .indexOf(
                                                                            '${activateRoom[idx].id}');
                                                                attention.removeAt(
                                                                    indexToRemove);
                                                                await _userinfo
                                                                    .collection(
                                                                        'room')
                                                                    .doc(
                                                                        'attention')
                                                                    .set({
                                                                  'attention':
                                                                      attention,
                                                                });
                                                              }),
                                                        );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : SizedBox(height: 0);
                              },
                            );
                          },
                          separatorBuilder: (ctx, idx) {
                            return idx % 5 == 0
                                ? Column(
                                    children: [
                                      SizedBox(height: 8.w),
                                      bannerAd(),
                                      SizedBox(height: 8.w),
                                    ],
                                  )
                                : SizedBox(height: 8.w);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          )),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    _user = FirebaseAuth
        .instance.currentUser; //widget rebuild 시 currentuser cached repair
    var currentVersion;
    showUpdateAlert(bool required) {
      return showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.w))),
                contentPadding: EdgeInsets.only(top: 10.w),
                content: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          "신규 업데이트 알림",
                          style: TextStyle(fontSize: 16.w),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Divider(
                        color: Colors.grey,
                        height: 4.h,
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(10.w, 20.h, 10.w, 20.h),
                        child: required
                            ? Text("중요한 업데이트가 있습니다.\n\n업데이트를 진행하고 이용해주세요!")
                            : Text("신규 업데이트가 있습니다.\n\n업데이트를 진행할까요?"),
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: InkWell(
                              child: Container(
                                padding:
                                    EdgeInsets.only(top: 14.w, bottom: 14.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12.w),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      "나중에",
                                      style:
                                          TextStyle(color: Color(0xFF51CF6D)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              child: Container(
                                padding:
                                    EdgeInsets.only(top: 14.w, bottom: 14.w),
                                decoration: BoxDecoration(
                                  color: Color(0xFF51CF6D),
                                  borderRadius: BorderRadius.only(
                                      bottomRight: Radius.circular(12.w)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      "업데이트",
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
    }

    return ScreenUtilInit(
      designSize: Size(360, 800),
      minTextAdapt: true,
      builder: (context, child) => StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: _user,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CustomSignInScreen(
              providerConfigs: [
                PhoneProviderConfiguration(),
              ],
              headerBuilder: (context, constraints, shirinkOffset) {
                return Center(
                    child: Text(
                  '오늘\n모임.',
                  style: TextStyle(
                    color: Color(0xFF51CF6D),
                    fontSize: 72.w,
                    fontFamily: 'room703',
                  ),
                ));
              },
              showAuthActionSwitch: false,
              headerMaxExtent: 500.h,
            );
          }
          _user = FirebaseAuth.instance.currentUser;
          _userinfo =
              FirebaseFirestore.instance.collection('users').doc(_user!.uid);
          return FutureBuilder<DocumentSnapshot>(
              future: _userinfo.get(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                _user = FirebaseAuth.instance.currentUser;
                _userinfo = FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid);
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Color(0xFF51CF6D),
                        child: Center(
                            child: Text(
                          '오늘\n모임.',
                          style: TextStyle(
                            fontSize: 48.w,
                            color: Colors.white,
                            decorationStyle: null,
                            fontFamily: 'room703',
                          ),
                        ))),
                  );
                } else if (snapshot.hasError) {
                  return LoginPage();
                } else if (!snapshot.hasData || snapshot.data!.data() == null) {
                  return AccountBuild();
                }
                Map<String, dynamic>? infoData =
                    snapshot.data?.data() as Map<String, dynamic>?;
                if (infoData == null) return AccountBuild();
                final accountPhoneNum = infoData['phonenumber'];
                DateTime currentDay = DateTime(DateTime.now().year,
                    DateTime.now().month, DateTime.now().day);
                var lastConnect = infoData['lastConnect'];
                if (lastConnect != null) lastConnect = lastConnect.toDate();
                lastConnect ??= DateTime(2000, 1, 1);
                if (lastConnect.isBefore(currentDay)) {
                  if (lastConnect.day <= 31 && currentDay.day >= 1) {
                    _userinfo.update({
                      'lastConnect': currentDay,
                      'canMessage': 5,
                    });
                  } else {
                    _userinfo.update({
                      'lastConnect': currentDay,
                    });
                  }
                }
                //version check
                rootBundle.loadString("pubspec.yaml").then((value) {
                  var yamlData = loadYaml(value);
                  currentVersion = yamlData['version'];
                });
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final versionData = await FirebaseFirestore.instance
                      .collection('appInfo')
                      .doc('version')
                      .get();
                  var newestVersion = versionData.get('newest');
                  var requiredVersion = versionData.get('required');
                  currentVersion = currentVersion
                      .toString()
                      .replaceAll('.', '')
                      .replaceAll('+', '');
                  currentVersion = int.parse(currentVersion);
                  newestVersion = newestVersion
                      .toString()
                      .replaceAll('.', '')
                      .replaceAll('+', '');
                  newestVersion = int.parse(newestVersion);
                  requiredVersion = requiredVersion
                      .toString()
                      .replaceAll('.', '')
                      .replaceAll('+', '');
                  requiredVersion = int.parse(requiredVersion);
                  if (currentVersion < newestVersion) {
                    late bool requiredExist;
                    currentVersion < requiredVersion
                        ? requiredExist = true
                        : requiredExist = false;
                    showUpdateAlert(requiredExist);
                  }
                });

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('bannedUsers')
                      .doc(accountPhoneNum)
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    Map<String, dynamic>? blockUserData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    if (blockUserData == null) {
                      return ProgressHUD(child: MyApp());
                    } else {
                      return BannedPage(bannedUser: accountPhoneNum);
                    }
                  },
                );
              });
        },
      ),
    );
  }
}
