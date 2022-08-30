import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:emojart/bottomrow.dart';
import 'package:emojart/centergrid.dart';
import 'package:emojart/cloud.dart';
import 'package:emojart/okhsl.dart';
import 'package:emojart/save.dart';
import 'package:emojart/toprow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:url_launcher/url_launcher.dart';

import 'appcommon.dart';
import 'brushbareditor.dart';
import 'glass_effect.dart';
import 'logic.dart';
import 'ads.dart';
import 'account.dart';
import 'purchase.dart';

//1.4.5 changes
// add eula and policies links ✓
// -- revise UI design to include the links in the subscription page ✓
// add apple login
// -- enable apple login ✓
// -- implement delete account
// -- -- cloud function ✓
// -- -- client code
// -- -- -- save refresh token to user profile ✓
// -- -- -- implement revoke token ✓
// -- -- front end
// family and ads
// -- no multiple banner on one page ✓
// -- add the word 'ad' next to reward video icons ✓

//1.4 changes
//ipad aspect ratio related ui changes
//add cancel in subscription box
//premium version box centering ✓
//cloud empty tab display issue ✓
// - ads in no-item tab? ✓
//brush bar editor length limit? ✓

//test list and status -- android:
//facebook login: tester only
//google login: should be ok
//payment: sandbox tested
//ads: should be ok

//test list and status -- ios:
//facebook login: tester only
//google login: should be ok
//payment: sandbox tested
//ads: should be ok

//epilogue:
//change upload page to page route
//drawing animation
//search function in gallery
//- display drawing name (pending)
//app updater
//change glass container to be more flexible to accomodate drawing size and purchase dialogs

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = await AppTrackingTransparency.requestTrackingAuthorization();
  await MobileAds.instance.initialize();
  final RequestConfiguration requestConfiguration = RequestConfiguration(
      // tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
      maxAdContentRating: 'PG');
  await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

  // print(await AppTrackingTransparency.getAdvertisingIdentifier());

  logic = MainLogic();
  await logic.init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => logic,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'emojART',
      theme: ThemeData(
        colorSchemeSeed: mainPageSeed,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  @override
  State<Home> createState() => _HomeState();
}

// class _HomeState extends State<Home> with WidgetsBindingObserver {
class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    //preload new ad
    newAds.init();
  }

  @override
  void dispose() {
    newAds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double appBarScale = min(1, 0.125 * screenSize.height / 85);
    double appBarHeight = 85 * appBarScale;

    Color mainBackgroundBGColor = colorWithOkHSL(mainPageBGSeed, s: .4, l: .95);
    Color mainBackgroundColor =
        colorWithOkHSL(mainPageBGSeed, s: .4, l: .95).withOpacity(.7);

    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.white));

    return Scaffold(
      drawerScrimColor: Colors.black.withOpacity(0.1),
      // drawerScrimColor: Colors.transparent,
      drawer: SafeArea(
        child: Container(
          color: Colors.grey.shade50,
          child: Consumer<MainLogic>(
            builder: (context, _, __) => Drawer(
              elevation: 0,
              backgroundColor: Colors.transparent,
              // backgroundColor: Colors.white,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 10),
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                    contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 35),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        // color: Colors.red,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade400))),
                    child: GestureDetector(
                      onTap: () {
                        showAccountPage(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                logic.user?.displayName ?? 'Guest user',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '${logic.payUnlocked ? 'Premium' : 'Standard'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            height: 45,
                            width: 45,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: FittedBox(
                              child: getProfilePicture(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    minLeadingWidth: 30,
                    leading: Icon(Icons.local_florist),
                    title: Text(
                      'Premium version',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog2(context, PurchaseDialog());
                    },
                  ),
                  ListTile(
                    minLeadingWidth: 30,
                    leading: Icon(Icons.cloud_outlined),
                    title: Text(
                      'Public gallery',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showCloudPage(context);
                    },
                  ),
                  ListTile(
                    minLeadingWidth: 30,
                    leading: Icon(Icons.save),
                    title: Text(
                      'Saved drawings',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showSavePage(context);
                    },
                  ),
                  ListTile(
                    minLeadingWidth: 30,
                    leading: Icon(Icons.brush),
                    title: Text(
                      'Brush bar editor',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showBrushBarEditorPage(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        // actions: [
        // ],
        centerTitle: true,
        title: Stack(
          children: [
            Container(
              height: appBarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "emojART",
                    style: GoogleFonts.boogaloo(fontSize: 38 * appBarScale),
                  ),
                  Text(
                    "create & share your emoji ART",
                    style: GoogleFonts.caveat(fontSize: 18 * appBarScale),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        toolbarHeight: appBarHeight,
      ),
      backgroundColor: mainBackgroundBGColor,
      // backgroundColor: Colors.red,
      body: CustomPaint(
        painter: BackgroundPainter(),
        child: Container(
          decoration: BoxDecoration(
            color: mainBackgroundColor,
            backgroundBlendMode: BlendMode.luminosity,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: mainBackgroundColor,
            ),
            alignment: Alignment.topCenter,
            padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
            child: SafeArea(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  width: screenSize.width > 500
                      ? (screenSize.height > 400 ? 450 : 400)
                      : 400, //width 400 is set to be a bit wide for most devices, and then we use boxfit.scaleDown to squeeze it within the display. for larger displays, we use a larger width setting
                  child: Column(
                    children: const [
                      TopRow(),
                      CenterGrid(),
                      BottomRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  Map<Size, Picture> pictureMap = Map<Size, Picture>();
  Size? lastSize;
  Picture? picture;
  Picture generateBackground(size) {
    // print(size);
    var pr = PictureRecorder();
    var canvas = Canvas(pr, Rect.fromLTWH(0, 0, size.width, size.height));
    var emlist = "😀🤣😅😊😍😗😚😎🥰".characters.toList();

    //generate pos on roughly uniform table
    // int nEmojiSeed = 30; //only approx seed
    // double approxCellWidth = sqrt(size.width * size.height / nEmojiSeed);
    double approxCellWidth = 84;
    // if (!approxCellWidth.isFinite) print('HEREEREREREREREtodo');
    int _nrow = (size.height / approxCellWidth).round();
    int _ncol = (size.width / approxCellWidth).round();
    double cellWidth = size.width / _ncol;
    double cellHeight = size.height / _nrow;
    emlist.shuffle();
    var emlistIt = emlist.iterator;
    for (int r = 0; r < _nrow; r++) {
      for (int c = 0; c < _ncol; c++) {
        while (!emlistIt.moveNext()) emlistIt = emlist.iterator;
        var textPainter = TextPainter(
          text: TextSpan(
            text: emlistIt.current,
            style: TextStyle(fontSize: 40 + rng.nextDouble() * 100),
            // style: GoogleFonts.notoColorEmojiCompat(
            //     fontSize: 40 + rng.nextDouble() * 100),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        var textSize = textPainter.size;
        drawRotated(
          rotate: rng.nextDouble() * pi / 4 - pi / 8,
          canvas: canvas,
          itemSize: textSize,
          targetCenterPos: Offset((c + rng.nextDouble()) * cellWidth,
              (r + rng.nextDouble()) * cellHeight),
          drawCallback: (canvas) {
            textPainter.paint(canvas, Offset.zero);
          },
        );
      }
    }
    return pr.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size != Size.zero) {
      if (!pictureMap.containsKey(size)) {
        pictureMap[size] = generateBackground(size);
      }
      canvas.drawPicture(pictureMap[size]!);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => false;
}
