import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter/services.dart' show portraitUp, rootBundle;

import 'package:fuzzy/data/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter/services.dart';

import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:markdown_widget/markdown_widget.dart';

void main() {
  runApp(
    ChangeNotifierProvider<AppThemeProvider>(
      create: (_) => AppThemeProvider(),
      child: MyApp(),
    ),
  );
}

double weight = 15;
int currentTab = 0;

List<String> toplevelEvents = [
  "Bradycardia",
  "Cardiac Arrest",
  "Hemorrhage",
  "Hyperkalemia",
  "Hypotension",
  "Hypoxemia",
  "Local Anesthetic Systemic Toxicity",
  "Prolonged Recovery",
  "Regurgitation",
  "Supraventricular Tachycardia",
  "Ventricular Tachycardia"
];

List<Color> colors = [
  Color(0xFFFF6961),
  Color(0xFFFF9500),
  Color(0xFFFFC0CB),
  Color(0xFFFFD700),
  Color(0xFFFFFF00),
  Color(0xFFAAF0D1),
  Color(0xFF87CEFA),
  Color(0xFF87CEEB),
  Color(0xFF1E90FF),
  Color(0xFF800080),
  Color(0xFFEE82EE),
];

bool preventRotation = false;
bool keepScreenOn = false;

ScrollController drugtabcontroller = ScrollController();

class AppThemeProvider with ChangeNotifier {
  double _textScaleFactor = 1.0;

  Brightness brightness = Brightness.light;

  ColorScheme colorscheme = ColorScheme.fromSeed(
      seedColor: Colors.grey[600]!, brightness: Brightness.light);

  double get textScaleFactor => _textScaleFactor;

  AppThemeProvider() {
    loadThemeSettings();
  }
  loadThemeSettings() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey("theme")) {
        if (prefs.getString("theme") == "dark") {
          brightness = Brightness.dark;
          colorscheme = ColorScheme.fromSeed(
              seedColor: Colors.grey[600]!, brightness: Brightness.dark);
        }
      }

      // text scale
      if (prefs.containsKey("textscale")) {
        _textScaleFactor = prefs.getDouble("textscale")!;
      }

      //drug concentrations
      if (prefs.containsKey("customconcentrations")) {
        customConcentrations =
            json.decode(prefs.getString("customconcentrations")!);
      }

      // rotation settings
      if (prefs.containsKey("preventRotation")) {
        preventRotation = prefs.getBool("preventRotation")!;
      }
      if (preventRotation) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      if (prefs.containsKey("keepScreenOn")) {
        keepScreenOn = prefs.getBool("keepScreenOn")!;
      }
      if (keepScreenOn) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }

      notifyListeners();
    });
  }

  void toggleTheme() {
    if (brightness == Brightness.light) {
      brightness = Brightness.dark;
      colorscheme = ColorScheme.fromSeed(
          seedColor: Colors.grey[600]!, brightness: Brightness.dark);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString("theme", "dark");
      });
    } else {
      brightness = Brightness.light;
      colorscheme = ColorScheme.fromSeed(
          seedColor: Colors.grey[600]!, brightness: Brightness.light);
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString("theme", "light");
      });
    }
    notifyListeners();
  }

  void NomalSize() {
    _textScaleFactor = 1;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble("textscale", _textScaleFactor);
    });
    notifyListeners();
  }

  void MediumSize() {
    _textScaleFactor = 1.5;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble("textscale", _textScaleFactor);
    });
    notifyListeners();
  }

  void LargeSize() {
    _textScaleFactor = 2;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble("textscale", _textScaleFactor);
    });
    notifyListeners();
  }
}

bool showVersionNumber = false;
String versionString = "unknown";
AppBar topbar(BuildContext context) {
  final toppadding = MediaQuery.of(context).padding.top;

  return AppBar(
    flexibleSpace: Container(
      child: Column(
        children: [
          Container(
            height: toppadding,
          ),
          Expanded(
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/vetact1024.png',
                      ),
                    ),
                    showVersionNumber
                        ? Expanded(child: FittedBox(child: Text(versionString)))
                        : Container()
                  ],
                ),
                Positioned(
                    top: 0,
                    right: 5,
                    child: StatefulBuilder(builder: (context, appbarsetstate) {
                      bannerSetter = appbarsetstate;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                            onTap: () {
                              toptabcontroller.animateTo(1);
                            },
                            child: Text(
                              "Weight:\n${weight} kg",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(fontSize: 15),
                            )),
                      );
                    }))
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

late StateSetter bannerSetter;
late StateSetter refresh;
late BuildContext globalcontext;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false, // Set this to false

      theme: ThemeData(
        textTheme: TextTheme(
          headlineMedium: TextStyle(
              fontSize: 18 * context.watch<AppThemeProvider>().textScaleFactor),
          bodyLarge: TextStyle(
              fontSize: 16 * context.watch<AppThemeProvider>().textScaleFactor),
          bodyMedium: TextStyle(
              fontSize: 14 * context.watch<AppThemeProvider>().textScaleFactor),
          bodySmall: TextStyle(
              fontSize: 10 * context.watch<AppThemeProvider>().textScaleFactor),
        ),
        colorScheme: context.watch<AppThemeProvider>().colorscheme,
        useMaterial3: true,
        brightness: context.watch<AppThemeProvider>().brightness,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

GlobalKey eventsKey = GlobalKey();
GlobalKey weightKey = GlobalKey();
GlobalKey settingsKey = GlobalKey();
GlobalKey clickKey = GlobalKey();
GlobalKey subtabKey = GlobalKey();
GlobalKey dxKey = GlobalKey();
GlobalKey txKey = GlobalKey();

GlobalKey drugTabKey = GlobalKey();
GlobalKey backKey = GlobalKey();
GlobalKey overlayKey = GlobalKey();

bool showTutorial = false;
int currentFocusIndex = 0;
late TabController toptabcontroller;
startTutorial(StateSetter setState) async {
  setState(() {
    showTutorial = true;
    currentTutorialFocus = Rect.fromLTWH(0, 400, 0, 0);

    _controller.reset();
  });
  selectedEvent = 'Bradycardia';
  _controller.forward();
  currentTutorialFocus = getRect(
      allFocusKeys[currentFocusIndex].currentContext!.findRenderObject()!);
  currentTutorialText = tutorialTexts[currentFocusIndex];
  currentTutorialTitle = tutorialTitles[currentFocusIndex];
}

Rect getRect(RenderObject renderObject) {
  if (overlayKey.currentContext == null) return Rect.zero;
  final RenderBox renderBox = renderObject as RenderBox;
  final Rect paintbox = renderBox.paintBounds;
  final Offset offset = renderBox.localToGlobal(Offset.zero);

  final Offset overlayOffset =
      (overlayKey.currentContext!.findRenderObject()! as RenderBox)
          .globalToLocal(Offset.zero);
  final Size size = renderBox.size;
  // return renderBox.paintBounds;
  return Rect.fromLTWH(offset.dx + overlayOffset.dx,
      offset.dy + overlayOffset.dy, paintbox.width, paintbox.height);
}

int animationLength = 500;
double tutorialBoxWidth = 200;
List<GlobalKey> allFocusKeys = [
  eventsKey,
  weightKey,
  settingsKey,
  clickKey,
  subtabKey,
  dxKey,
  txKey,
  drugTabKey,
  backKey
];
List<String> tutorialTexts = [
  "See a list of all events",
  "Quickly edit patient weight",
  "Light/dark mode, text size and more",
  "Click to see information about an event",
  "Select a section here to see more information",
  "Quick facts about diagnosis",
  "Steps for treatment",
  "List of drugs including weight and concentration calculations",
  "Click the arrows or swipe to move between the subtabs"
];
List<String> tutorialTitles = [
  "Events",
  "Weight",
  "Settings",
  "Select Event",
  "Event Sections",
  "Diagnosis",
  "Treatment",
  "Drugs",
  "Move"
];

late AnimationController _controller;
late Animation<double> _animation;

Rect currentTutorialFocus = Rect.fromLTRB(0, 200, 0, 500);
String currentTutorialTitle = "";
String currentTutorialText = "";
showDevelopmentWarning(BuildContext context) async {
  return;
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🚧 In Development 🚧"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "This app is in development and may contain bugs and errors. Please do let us know if you find any.\n\nWe would love to hear your feedback and suggestions. You can reach us at info@mynavas.org\n\nThank you for your patience and understanding.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
                child: Text("Don't show again"),
                onPressed: () {
                  Navigator.of(context).pop();
                  SharedPreferences.getInstance().then((prefs) =>
                      prefs.setBool("shownDevelopmentWarning", true));
                }),
            ElevatedButton(
                child: Text("Let's test!"),
                onPressed: () {
                  Navigator.of(context).pop();
                })
          ],
        );
      });
}

showLegalDisclaimer(BuildContext context) async {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Legal Disclaimer"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("""
This app is for educational and reference purposes only. It does not provide veterinary advice and is not a substitute for your veterinary judgment. All veterinary decisions remain entirely your responsibility. 
You must use this link to carefully review the NAVAS Veterinary Anesthesia Crisis Tool Terms of Service, which creates a contract between us, including limitations on your rights:
"""),
              TextButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                                actions: [
                                  TextButton(
                                      child: Text("Close"),
                                      onPressed: () =>
                                          Navigator.of(context).pop())
                                ],
                                content: Column(children: [
                                  Expanded(
                                      child: SingleChildScrollView(
                                          child: FutureBuilder(
                                              future: rootBundle
                                                  .loadString('assets/tos.md'),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return MarkdownBlock(
                                                      data: snapshot.data!);
                                                }
                                                return Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              }))),
                                ])));
                  },
                  child: Text("Terms of Service")),
              Text(
                  "By clicking below and using this App, you acknowledge you have read, understand, and agree to the full NAVAS Veterinary Anesthesia Crisis Tool Terms of Service."),
            ],
          ),
          actions: [
            TextButton(
                child: Text("I understand and agree"),
                onPressed: () {
                  Navigator.of(context).pop();
                  SharedPreferences.getInstance().then(
                      (prefs) => prefs.setBool("shownLegalDisclaimer", true));
                })
          ],
        );
      });
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  showVersionNumberFunction() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    versionString = packageInfo.version + " (" + packageInfo.buildNumber + ")";
    showVersionNumber = true;
    setState(() {});
  }

  var showAgainChecked = false;

  moveTabs(step) {
    if (step == 0) {
      tabController.animateTo(0);
      subtabController.animateTo(0);
      tutorialcontroller.animateTo(0);
    } else if (step == 1) {
      tabController.animateTo(1);
      subtabController.animateTo(0);
      tutorialcontroller.animateTo(0);
    } else if (step == 2) {
      tabController.animateTo(2);
      subtabController.animateTo(0);
      tutorialcontroller.animateTo(0);
    } else if (step == 3) {
      tabController.animateTo(0);
      subtabController.animateTo(0);
      tutorialcontroller.animateTo(0);
    } else if (step == 4) {
      tabController.animateTo(0);
      subtabController.animateTo(1);
      tutorialcontroller.animateTo(0);
    } else if (step == 5) {
      tabController.animateTo(0);
      subtabController.animateTo(1);
      tutorialcontroller.animateTo(0);
    } else if (step == 6) {
      tabController.animateTo(0);
      subtabController.animateTo(1);
      tutorialcontroller.animateTo(1);
    } else if (step == 7) {
      tabController.animateTo(0);
      subtabController.animateTo(1);
      tutorialcontroller.animateTo(2);
    } else if (step == 8) {
      tabController.animateTo(0);
      subtabController.animateTo(1);
      tutorialcontroller.animateTo(2);
    } else if (step == 9) {
      tabController.animateTo(0);
      subtabController.animateTo(0);
      tutorialcontroller.animateTo(0);
    }
  }

  previousTutorial() async {
    _controller.reverse();

    moveTabs(max(0, currentFocusIndex - 1));

    await Future.delayed(Duration(milliseconds: animationLength));
    currentFocusIndex = max(0, currentFocusIndex - 1);

    int iterationCount = 0;

    while (allFocusKeys[currentFocusIndex].currentContext == null) {
      await Future.delayed(Duration(milliseconds: 500));

      iterationCount++;
      if (iterationCount > 3) {
        showTutorial = false;
        break;
      }
    }

    _controller.forward();
    currentTutorialFocus = getRect(
        allFocusKeys[currentFocusIndex].currentContext!.findRenderObject()!);
    currentTutorialText = tutorialTexts[currentFocusIndex];
    currentTutorialTitle = tutorialTitles[currentFocusIndex];
  }

  nextTutorial() async {
    _controller.reverse();

    if (currentFocusIndex + 1 == allFocusKeys.length) {
      setState(() {
        showTutorial = false;
      });
      return;
    }

    moveTabs(currentFocusIndex + 1);

    await Future.delayed(Duration(milliseconds: animationLength));
    currentFocusIndex++;

    int iterationCount = 0;

    while (allFocusKeys[currentFocusIndex].currentContext == null) {
      await Future.delayed(Duration(milliseconds: 500));

      iterationCount++;
      if (iterationCount > 3) {
        showTutorial = false;
        break;
      }
    }

    _controller.forward();
    currentTutorialFocus = getRect(
        allFocusKeys[currentFocusIndex].currentContext!.findRenderObject()!);
    currentTutorialText = tutorialTexts[currentFocusIndex];
    currentTutorialTitle = tutorialTitles[currentFocusIndex];
  }

  @override
  void dispose() {
    _controller.dispose();
    _animation.removeListener(() {});

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: animationLength),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _animation.addListener(() {
      setState(() {
        if (allFocusKeys[currentFocusIndex].currentContext == null ||
            allFocusKeys[currentFocusIndex]
                    .currentContext!
                    .findRenderObject() ==
                null) {
        } else {
          currentTutorialFocus = getRect(allFocusKeys[currentFocusIndex]
              .currentContext!
              .findRenderObject()!);
        }
      });
    });
    _controller.forward();

    refresh = setState;

    tabController = TabController(length: 3, vsync: this);
    subtabController = TabController(length: 2, vsync: this);
    toptabcontroller = tabController;
    tutorialcontroller = TabController(length: 3, vsync: this);

    SharedPreferences.getInstance().then((prefs) {
      if (prefs.getBool("showVersionNumber") == true) {
        showVersionNumberFunction();
      } else {
        showVersionNumber = false;
        setState(() {});
      }

      if (prefs.getBool('hasStartedBefore') == null ||
          !prefs.getBool('hasStartedBefore')!) {
        // Show alert dialog on first startup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hi there! 👋'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text('Want to learn how to use this app?'),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        child: FilledButton(
                          child: const Text('Show Tutorial',
                              style: TextStyle(fontSize: 30)),
                          onPressed: () {
                            Navigator.of(context).pop();

                            startTutorial(setState);
                          },
                        ),
                      ),
                    )
                  ]),
                ),
                Divider(),
              ]),
              actions: [
                Row(children: [
                  Text("Don't ask again"),
                  StatefulBuilder(builder: (context, update) {
                    return Checkbox(
                      value: showAgainChecked,
                      onChanged: (value) {
                        showAgainChecked = value!;
                        update(() {});
                      },
                    );
                  }),
                  Expanded(
                    child: Container(),
                  ),
                  TextButton(
                    child: const Text('close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ])
              ],
            );
          },
        ).then((value) {
          if (showAgainChecked) {
            prefs.setBool('hasStartedBefore', true);
          }
        });
      }

      if (prefs.getBool("shownLegalDisclaimer") != true) {
        showLegalDisclaimer(context);
      }

      if (prefs.getBool("shownDevelopmentWarning") != true) {
        showDevelopmentWarning(context);
      }
    });
  }

  late TabController tabController;
  late TabController subtabController;

  Widget build(BuildContext context) {
    globalcontext = context;
    topLevelSetter = setState;

    return Stack(
      children: [
        Scaffold(
          appBar: topbar(context),
          body: TopView(
              tabController: tabController,
              subtabController: subtabController,
              vsync: this),
        ),
        showTutorial
            ? Stack(
                children: [
                  Container(
                    key: overlayKey,
                    width: double.infinity,
                    height: double.infinity,
                    child: CustomPaint(
                      painter:
                          HolePainter(currentTutorialFocus, _animation.value),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      currentFocusIndex == allFocusKeys.length - 1
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: ElevatedButton(
                                      style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.green.shade600),
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                          ))),
                                      onPressed: () {
                                        setState(() {
                                          showTutorial = false;
                                          subtabController.animateTo(0);
                                        });
                                        SharedPreferences.getInstance()
                                            .then((prefs) {
                                          prefs.setBool(
                                              'hasStartedBefore', true);
                                        });
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                            "done  🎉",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 30),
                                          ),
                                        ],
                                      )),
                                ),
                              ),
                            ])
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28.0),
                                    child: ElevatedButton(
                                        style: ButtonStyle(
                                            shape: MaterialStateProperty.all<
                                                    RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                        ))),
                                        onPressed: () {
                                          previousTutorial();
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text("previous"),
                                            Icon(Icons.arrow_back)
                                          ],
                                        )),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28.0),
                                    child: ElevatedButton(
                                        onPressed: () {
                                          nextTutorial();
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text("next"),
                                            Icon(Icons.arrow_forward)
                                          ],
                                        )),
                                  ),
                                ),
                              ],
                            ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(width: 2, color: Colors.red),
                        ),
                        onPressed: () {
                          setState(() {
                            showTutorial = false;
                          });
                        },
                        child:
                            Text("close", style: TextStyle(color: Colors.red)),
                      ),
                      Container(height: 50)
                    ],
                  ),
                  AnimatedPositioned(
                      duration: Duration(milliseconds: animationLength),
                      left: currentTutorialFocus.left + tutorialBoxWidth <
                              MediaQuery.of(context).size.width
                          ? currentTutorialFocus.left
                          : currentTutorialFocus.right - tutorialBoxWidth,
                      top: currentTutorialFocus.top + 50,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: animationLength),
                        child: Container(
                          width: tutorialBoxWidth,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text("${currentTutorialTitle}",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.none,
                                      )),
                                ],
                              ),
                              Container(height: 10),
                              Text("${currentTutorialText}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  )),
                            ],
                          ),
                        ),
                      ))
                ],
              )
            : Container()
      ],
    );
  }
}

bool startsWithNumber(String s) {
  return RegExp(r'^\d').hasMatch(s);
}

late StateSetter topLevelSetter;

class TopView extends StatelessWidget {
  @override
  TopView(
      {super.key,
      required this.tabController,
      required this.subtabController,
      required this.vsync});
  TabController tabController;
  TickerProvider vsync;
  TabController subtabController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          tabs: [
            Container(
                key: eventsKey,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Events',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
            // Text('Phonenumbers'),
            Container(
                key: weightKey,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Weight',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )),

            Container(
                key: settingsKey,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Settings',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )),
          ],
          controller: tabController,
          onTap: (value) {
            if (value == 0) {
              subtabController.animateTo(0);
            }
          },
        ),
        Expanded(
          child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              controller: tabController,
              children: [
                Eventlist(subtabController, vsync),
                // Phonenumbers(),
                Patientweight(),
                Settings()
              ]),
        ),
      ],
    );
  }
}

Widget Settings() {
  return StatefulBuilder(builder: (context, settingstate) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      child: SingleChildScrollView(
          child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 15,
          children: [Text("Text Size:")],
        ),
        Row(mainAxisAlignment: MainAxisAlignment.start, spacing: 15, children: [
          ElevatedButton(
            onPressed: () {
              context.read<AppThemeProvider>().NomalSize();
            },
            child: Text('Standard'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppThemeProvider>().MediumSize();
            },
            child: Text('Larger'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppThemeProvider>().LargeSize();
            },
            child: Text('Largest'),
          )
        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 15,
          children: [
            Expanded(child: Text("Prevent Screen Rotation:")),
            Switch(
                value: preventRotation,
                onChanged: (val) {
                  settingstate(() {
                    preventRotation = val;
                    if (preventRotation) {
                      SystemChrome.setPreferredOrientations(
                          [DeviceOrientation.portraitUp]);
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('preventRotation', preventRotation);
                      });
                    } else {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('preventRotation', preventRotation);
                      });
                    }
                  });
                })
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 15,
          children: [
            Expanded(child: Text("Keep Screen On (Prevent Sleep):")),
            Switch(
                value: keepScreenOn,
                onChanged: (val) {
                  settingstate(() {
                    keepScreenOn = val;
                    if (keepScreenOn) {
                      WakelockPlus.enable();
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('keepScreenOn', keepScreenOn);
                      });
                    } else {
                      WakelockPlus.disable();
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool('keepScreenOn', keepScreenOn);
                      });
                    }
                  });
                })
          ],
        ),
        Row(
          children: [Text("Theme:")],
        ),
        Row(children: [
          ElevatedButton(
            onPressed: () {
              context.read<AppThemeProvider>().toggleTheme();
            },
            child: Text('Light / Dark'),
          ),
        ]),
        Divider(),
        FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 15,
                  children: [
                    Expanded(child: Text("Hide startup tutorial")),
                    Text(
                        snapshot.data!.getBool('hasStartedBefore').toString() ??
                            'Null'),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setBool('hasStartedBefore', false);
                            settingstate(() {});
                          });
                        },
                        child: Text("Reset"),
                      ),
                    ),
                  ],
                );
              } else {
                return CircularProgressIndicator();
              }
            }),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 15,
          children: [
            Expanded(
                child: Text(
              "Show tutorial again?",
              overflow: TextOverflow.ellipsis,
            )),
            ElevatedButton(
                onPressed: () async {
                  topLevelSetter(() {
                    currentFocusIndex = 0;
                    toptabcontroller.animateTo(0);
                  });

                  await Future.delayed(Duration(seconds: 1));

                  startTutorial(topLevelSetter);
                },
                child: Text("Show Tutorial"))
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 15,
          children: [
            Expanded(child: Text("Show Legal Disclaimer")),
            ElevatedButton(
                onPressed: () async {
                  showLegalDisclaimer(context);
                },
                child: Text("Show Disclaimer"))
          ],
        ),
        FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 15,
                  children: [
                    Expanded(child: Text("Show Version Number: ")),
                    Text(
                        snapshot.data!.getBool('showVersionNumber').toString()),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Switch(
                        value: showVersionNumber,
                        onChanged: (currentval) async {
                          PackageInfo packageInfo =
                              await PackageInfo.fromPlatform();

                          versionString = packageInfo.version +
                              " (" +
                              packageInfo.buildNumber +
                              ")";
                          showVersionNumber = currentval;

                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setBool('showVersionNumber', currentval);
                            topLevelSetter(() {});
                          });
                        },
                      ),
                    ),
                  ],
                );
              } else {
                return CircularProgressIndicator();
              }
            }),
        Divider(),
        Row(
          children: [
            OutlinedButton(
              onPressed: () async {
                try {
                  final Email email = Email(
                    body: '',
                    subject: 'NAVAS crisis app feedback',
                    recipients: ['info@mynavas.org'],
                  );

                  await FlutterEmailSender.send(email);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending email: $e'),
                    ),
                  );
                }
              },
              child: Text("Send Feedback"),
            )
          ],
        )
      ])),
    );
  });
}

Widget Patientweight() {
  return StatefulBuilder(builder: (context, refresh) {
    return drugSlider('', Theme.of(context).primaryColor, context);
  });
}

List<String> numbers = [];
Widget Phonenumbers() {
  return StatefulBuilder(builder: (context, refresh) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          // Assuming you have stored a value with key 'key'
          numbers = snapshot.data!.getStringList('numbers') ?? [];
          return Stack(
            children: [
              SingleChildScrollView(
                  child: Column(
                      children: numbers
                          .map(
                            (number) => ListTile(
                              title: Text(number.contains("|")
                                  ? number.substring(0, number.indexOf("|"))
                                  : number),
                              subtitle: Text(number.contains("|")
                                  ? number.substring(number.indexOf("|") + 1)
                                  : ""),
                              onTap: () => {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: number.contains("|")
                                          ? number.substring(
                                              0, number.indexOf("|"))
                                          : number),
                                )
                              },
                            ),
                          )
                          .toList())),
              Positioned(
                  bottom: 10,
                  right: 10,
                  child: ElevatedButton(
                      onPressed: () async {
                        TextEditingController controller =
                            TextEditingController();
                        TextEditingController namecontroller =
                            TextEditingController();

                        await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Add Number'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        onTapOutside: (event) {
                                          FocusScope.of(context).unfocus();
                                        },
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Number',
                                        ),
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        onTapOutside: (event) {
                                          FocusScope.of(context).unfocus();
                                        },
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Name',
                                        ),
                                        controller: namecontroller,
                                        keyboardType: TextInputType.name,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      numbers.add(controller.text +
                                          "|" +
                                          namecontroller.text);

                                      await snapshot.data!
                                          .setStringList('numbers', numbers);
                                      refresh(() {});
                                      Navigator.pop(context);
                                    },
                                    child: Text('Add'),
                                  )
                                ],
                              );
                            });
                      },
                      child: Text('Add Number'))),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  });
}

String filter = '';
TextEditingController filtercontroller = TextEditingController();
bool editingFilter = false;
Widget Eventlist(subtabcontroller, vsync) {
  return TabBarView(
      physics: NeverScrollableScrollPhysics(),
      controller: subtabcontroller,
      children: [
        StatefulBuilder(builder: (context, statesett) {
          final bottomSafeSpace = MediaQuery.of(context).padding.bottom;
          // Fuzzy fuzzy = Fuzzy(toplevelEvents);
          var widgetsToShow = toplevelEvents;
          if (filter.length > 0) {
            // List<Result<dynamic>> results = fuzzy.search(filter);
            // results.sort((e1, e2) => e1.score.compareTo(e2.score));
            // widgetsToShow = results.map((e) => e.matches.first.value).toList();
            widgetsToShow = toplevelEvents.where(
              (element) {
                return element.toLowerCase().startsWith(filter.toLowerCase());
              },
            ).toList();
          }
          return Column(children: [
            Container(
              child: Stack(
                children: [
                  filter.length > 0 && !editingFilter
                      ? Positioned(
                          right: 10,
                          child: Row(
                            children: [
                              IconButton(
                                  onPressed: () {
                                    statesett(() {
                                      filter = '';
                                      filtercontroller.text = '';
                                    });
                                  },
                                  icon: Text('Clear Filter')),
                            ],
                          ),
                        )
                      : Container(),
                  filter.length > 0 && !editingFilter
                      ? Positioned(
                          left: 10,
                          child: Row(
                            children: [
                              Icon(FlutterIcons.warning_ant, color: Colors.red),
                              Container(
                                width: 5,
                              ),
                              Text(
                                'Filter:\n' + filter,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Container(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      editingFilter
                          ? Expanded(
                              child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: filtercontroller,
                                onChanged: (value) {
                                  filter = value;
                                  statesett(() {});
                                },
                                onSubmitted: (value) {
                                  editingFilter = false;
                                  statesett(() {});
                                },
                                autofocus: true,
                              ),
                            ))
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(
                                    0), // Make the background transparent
                              ),
                              onPressed: () {
                                editingFilter = true;
                                statesett(() {});
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Search'),
                                  Container(width: 5),
                                  Icon(Icons.search)
                                ],
                              )),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: widgetsToShow
                      .map(
                        (e) => InkWell(
                          onTap: () {
                            selectedEvent = e;
                            selectedColor = colors[toplevelEvents.indexOf(e)];
                            currentsubsubtab = 0;
                            subtabcontroller.animateTo(1);
                          },
                          child: TopItem(
                              e: e, color: colors[toplevelEvents.indexOf(e)]),
                          splashColor: colors[toplevelEvents.indexOf(e)],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ]);
        }),
        InfoPage(subtabcontroller, vsync)
      ]);
  ;
}

String selectedEvent = 'Bradycardia';
Color selectedColor = colors[0];
int currentsubsubtab = 0;
List<String> tallManWords = [
  "DOPamine",
  "DOBUTamine",
  "dilTIAZem",
  "ePHEDrine",
  "EPINEPHrine"
];
String tallMan(inputString) {
  for (String word in tallManWords) {
    inputString =
        inputString.replaceAll(RegExp(word, caseSensitive: false), word);
  }
  return inputString;
}

late TabController tutorialcontroller;

late StateSetter rebuildTopArrows;

Widget InfoPage(subtabcontroller, vsync) {
  return StatefulBuilder(builder: (context, ref) {
    return FutureBuilder(
      future: rootBundle.loadString('assets/' + selectedEvent + '.txt'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<String> sections = snapshot.data!
              .replaceAll('\r', '')
              .split('\n\n')
              .where((element) => element.length > 3)
              .toList();

          List<Widget> sectionWidgets = [];

          var subsub = TabController(
              length: sections.length,
              vsync: vsync,
              initialIndex: currentsubsubtab);
          subsub.addListener(() {
            currentsubsubtab = subsub.index;
            if (rebuildTopArrows != null) {
              rebuildTopArrows(() {});
            }
          });
          tutorialcontroller = subsub;

          var tabLabels = sections
              .map((e) => Tab(
                  icon: Text(
                    e.contains("**")
                        ? e.split("**")[1]
                        : e.split("\n")[0].replaceAll("Drug doses:", "Drugs"),
                  ),
                  key: !showTutorial
                      ? null
                      : e.startsWith("Dx")
                          ? dxKey
                          : e.startsWith("Tx")
                              ? txKey
                              : e.startsWith("Drug")
                                  ? drugTabKey
                                  : null))
              .toList();

          InlineSpan createLinks(String line, {bool isTitle = false}) {
            final titleStyle = Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.bold);
            if (!line.contains("[") || !line.contains("]")) {
              return TextSpan(text: line, style: isTitle ? titleStyle : null);
            }
            if (line.contains("[assets")) {
              return WidgetSpan(
                  child: Image.asset(line.substring(
                      line.indexOf('[') + 1, line.indexOf(']'))));
            }
            TextSpan makeLinkSpan(line) {
              return TextSpan(
                text: (line.substring(line.indexOf('[')).startsWith("[http")
                    ? "[" +
                        line.substring(line.indexOf(" ", line.indexOf('[')),
                            line.indexOf(']') + 1)
                    : line.contains("[Drugs")
                        ? line.substring(line.indexOf('(') + 1,
                            line.indexOf(')', line.indexOf(')')))
                        : line.substring(
                            line.indexOf('['), line.indexOf(']') + 1)),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    var togo = line.substring(
                        line.indexOf('[') + 1, line.indexOf(']'));
                    try {
                      if (togo.startsWith("Drugs")) {
                        final drugtabindex = tabLabels.indexWhere(
                          (element) => (element.icon as Text).data == 'Drugs',
                        );
                        subsub.animateTo(drugtabindex);

                        final scrollNumber = togo.substring(
                          togo.indexOf(")") + 1,
                        );

                        if (double.tryParse(scrollNumber.trim()) != null) {
                          await Future.delayed(Duration(milliseconds: 500));
                          drugtabcontroller.animateTo(
                              double.parse(scrollNumber.trim()),
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease);
                        } else {
                          print("Error parsing scroll number: $scrollNumber");
                        }
                      } else if (togo == "Causes") {
                        final drugtabindex = tabLabels.indexWhere(
                          (element) => (element.icon as Text).data == 'Causes',
                        );
                        subsub.animateTo(drugtabindex);
                      } else if (togo == "Calculations") {
                        subsub.animateTo(3);
                      } else if (togo == "Intralipid 20%") {
                        final drugtabindex = tabLabels.indexWhere(
                          (element) =>
                              (element.icon as Text).data == 'Intralipid 20%',
                        );
                        subsub.animateTo(drugtabindex);
                      } else if (togo.startsWith("http")) {
                        launchUrl(
                            Uri.parse(togo.substring(0, togo.indexOf(' '))));
                      } else {
                        ref(() {
                          selectedEvent = togo;

                          selectedColor = colors[toplevelEvents.indexOf(togo)];
                          currentsubsubtab = 0;
                        });
                      }
                    } catch (e) {
                      print(e);
                    }
                  },
                style: isTitle
                    ? titleStyle.copyWith(color: Colors.blue)
                    : TextStyle(color: Colors.blue),
              );
            }

            if (isTitle) {
              List<InlineSpan> spans = [
                TextSpan(text: line.substring(0, line.indexOf('[')))
              ];

              List<int> indices =
                  RegExp(r'\[').allMatches(line).map((m) => m.start).toList();

              List<String> parts = [];
              for (int j = 0; j < indices.length - 1; j++) {
                parts.add(line.substring(indices[j], indices[j + 1]));
              }

              parts.add(line.substring(indices.last));

              for (int i = 0; i < parts.length; i++) {
                spans.add(makeLinkSpan(
                    parts[i].substring(0, parts[i].indexOf(']') + 1)));

                spans.add(TextSpan(
                    text: parts[i].substring(parts[i].indexOf(']') + 1)));
              }

              return TextSpan(
                style: titleStyle,
                children: spans,
              );
            } else {
              return makeLinkSpan(line);
            }
          }

          List<InlineSpan> formatSubItalics(String text) {
            final List<InlineSpan> spans = [];
            final RegExp regExp = RegExp(r'O2');
            text = text.replaceAll("  ", "");
            final Iterable<RegExpMatch> matches = regExp.allMatches(text);

            int lastMatchEnd = 0;
            for (final match in matches) {
              final start = match.start;
              final end = match.end;

              // Add text before match as plain text
              if (start > lastMatchEnd) {
                spans.add(TextSpan(text: text.substring(lastMatchEnd, start)));
              }

              // Add 'O' as plain text
              spans.add(TextSpan(text: 'O'));

              // Add '2' as subscript
              spans.add(TextSpan(
                text: '2',
                style: TextStyle(fontFeatures: [FontFeature.subscripts()]),
              ));

              lastMatchEnd = end;
            }

            // Add remaining text as plain text
            if (lastMatchEnd < text.length) {
              spans.add(TextSpan(text: text.substring(lastMatchEnd)));
            }

            // dealing with :

            for (int i = spans.length - 1; i > -1; i--) {
              if (spans[i] is TextSpan) {
                if ((spans[i] as TextSpan).text!.contains(":") &&
                    !(spans[i] as TextSpan).text!.contains("http")) {
                  final currentText = (spans[i] as TextSpan).text!;
                  spans[i] = TextSpan(
                      text: currentText.substring(0, currentText.indexOf(":")),
                      style: TextStyle(fontStyle: FontStyle.italic));
                  spans.insert(
                      i + 1,
                      TextSpan(
                          text:
                              currentText.substring(currentText.indexOf(":"))));
                } else if ((spans[i] as TextSpan).text!.contains("<bold>")) {
                  final currentText = (spans[i] as TextSpan).text!;
                  spans[i] = TextSpan(
                    text:
                        currentText.substring(0, currentText.indexOf("<bold>")),
                  );
                  spans.insert(
                      i + 1,
                      TextSpan(
                          text: currentText
                              .substring(currentText.indexOf("<bold>") + 6),
                          style: TextStyle(fontWeight: FontWeight.bold)));
                }
              }
            }

            for (int i = spans.length - 1; i > -1; i--) {
              if (spans[i] is TextSpan) {
                if ((spans[i] as TextSpan).text!.contains("K+")) {
                  final charsOfInterest = "K+";
                  final currentText = (spans[i] as TextSpan).text!;
                  final pre =
                      currentText.substring(0, currentText.indexOf("K+") + 1);
                  final post =
                      currentText.substring(currentText.indexOf("K+") + 2);
                  spans[i] = TextSpan(
                    text: pre,
                  );
                  spans.insert(i + 1, TextSpan(text: post));
                  spans.insert(
                      i + 1,
                      TextSpan(
                        text: '+',
                        style: TextStyle(
                            fontFeatures: [FontFeature.superscripts()]),
                      ));
                }
              }
            }

            for (int i = spans.length - 1; i > -1; i--) {
              if (spans[i] is TextSpan) {
                if ((spans[i] as TextSpan).text!.contains("HCO3-")) {
                  final currentText = (spans[i] as TextSpan).text!;
                  final pre =
                      currentText.substring(0, currentText.indexOf("HCO") + 3);
                  final post =
                      currentText.substring(currentText.indexOf("HCO") + 5);
                  spans[i] = TextSpan(
                    text: pre,
                  );
                  spans.insert(i + 1, TextSpan(text: post));
                  spans.insert(
                      i + 1,
                      TextSpan(
                        text: '3-',
                        style:
                            TextStyle(fontFeatures: [FontFeature.subscripts()]),
                      ));
                }
              }
            }
            for (int i = spans.length - 1; i > -1; i--) {
              if (spans[i] is TextSpan) {
                if ((spans[i] as TextSpan).text!.contains("[")) {
                  final currentText = (spans[i] as TextSpan).text!;

                  spans[i] = TextSpan(
                      text: currentText.substring(0, currentText.indexOf('[')));

                  List<int> indices = RegExp(r'\[')
                      .allMatches(currentText)
                      .map((m) => m.start)
                      .toList();

                  List<String> parts = [];
                  for (int j = 0; j < indices.length - 1; j++) {
                    parts
                        .add(currentText.substring(indices[j], indices[j + 1]));
                  }

                  parts.add(currentText.substring(indices.last));

                  for (final part in parts.reversed) {
                    spans.insert(i + 1,
                        TextSpan(text: part.substring(part.indexOf(']') + 1)));
                    spans.insert(i + 1, createLinks(part));
                  }
                }
              }
            }

            return spans;
          }

          Widget getTable(line) {
            return IntrinsicHeight(
              child: Row(
                children: [
                  ...line.split("||").map((tablestring) {
                    String title = tablestring.split("|")[0].trim();
                    int clickAnimateIndex = 1;
                    if (title.trim() == "Shockable Arrest Rhythms") {
                      clickAnimateIndex = 2;
                    } else if (title.trim() == "Blood loss >20%") {
                      clickAnimateIndex = 3;
                    }

                    if (title.trim() == "or") {
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("or",
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(
                                    fontSize: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .fontSize! *
                                        1.2)),
                      );
                    }

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          if (tutorialcontroller.index == 0) {
                            tutorialcontroller.animateTo(clickAnimateIndex);
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: selectedColor)),
                          child: Column(
                            children: [
                              title.length > 0
                                  ? Container(
                                      padding: const EdgeInsets.all(8.0),
                                      color: selectedColor.withAlpha(100),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(title,
                                                maxLines: 2,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .copyWith(
                                                        fontSize:
                                                            Theme.of(context)
                                                                    .textTheme
                                                                    .bodyLarge!
                                                                    .fontSize! *
                                                                1.2)),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                              ...tablestring.split("|").sublist(1).map((e) {
                                e = e.trim();
                                if (e.length == 0) {
                                  return Container();
                                }
                                return Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(8.0),
                                    child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                            children: [...formatSubItalics(e)],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .copyWith(
                                                    fontSize: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge!
                                                            .fontSize! *
                                                        1.2))));
                              })
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                ],
              ),
            );
          }

          sections.forEach((element) {
            element = tallMan(element);

            List<Widget> chil = [];
            String firstline = element.split("\n")[0];

            if (element.length > 3) {
              if (firstline.contains('Tx') ||
                  firstline.contains('Shock') ||
                  firstline.contains('shock')) {
                bool first = false;

                element
                    .split("\n")
                    .where((element) => element != "")
                    .toList()
                    .sublist(1)
                    .forEach((line) {
                  if (startsWithNumber(line)) {
                    first = true;
                  }

                  if (!first) {
                    first = true;
                    chil.add(Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(line,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge),
                        ],
                      ),
                    ));
                  } else {
                    if (startsWithNumber(line)) {
                      chil.add(Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: Text(
                              line.substring(0, line.indexOf(" ")),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(fontWeight: FontWeight.bold),
                              softWrap: true,
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: createLinks(
                                  line.substring(line.indexOf(" ")),
                                  isTitle: true),
                              maxLines: null,

                              // style: Theme.of(context)
                              //     .textTheme
                              //     .bodyLarge!
                              //     .copyWith(fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ));
                    } else {
                      chil.add(Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: line.startsWith("  ") ? 20 : 0),
                            Container(
                                width: 60,
                                alignment: Alignment.topRight,
                                child: Icon(
                                  FlutterIcons.dot_single_ent,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color,
                                )),
                            Expanded(
                                child: Text.rich(
                              TextSpan(
                                children: [
                                  ...formatSubItalics(line),
                                  // TextSpan(
                                  //   text: line.trim(),
                                  //   style: TextStyle(
                                  //       color: Theme.of(context)
                                  //           .textTheme
                                  //           .bodyLarge!
                                  //           .color),
                                  // ),
                                ],
                              ),
                            ))
                          ]));
                      // }
                    }
                  }
                });
              } else if (element
                  .split("\n")
                  .where((element) => element != "")
                  .first
                  .contains("Drug doses:")) {
                chil.add(drugSlider(element, selectedColor, context,
                    scrollController: drugtabcontroller));
              } else if (element.split("\n").first == "Calc") {
                chil.add(drugSlider("hemorrhage", selectedColor, context));
              } else {
                bool first = true;
                element
                    .split("\n")
                    .where((element) => element != "")
                    .toList()
                    .sublist(1)
                    .forEach((line) {
                  {
                    if (line.contains("|")) {
                      chil.add(getTable(line));
                    } else {
                      chil.add(
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                  child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                        children: [...formatSubItalics(line)],
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge)),
                              ))
                            ]),
                      );
                    }
                  }
                });
              }

              chil.add(SizedBox(height: MediaQuery.of(context).padding.bottom));

              if (element
                  .split("\n")
                  .where((element) => element != "")
                  .first
                  .contains("Drug doses:")) {
                sectionWidgets.add(chil.first);
              } else if (element.split("\n").first == "Calc") {
                sectionWidgets.add(chil.first);
              } else {
                sectionWidgets.add(SingleChildScrollView(
                    child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [...chil]),
                )));
              }
            }
          });

          return Theme(
              data: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: selectedColor),
              ),
              child: StatefulBuilder(builder: (context, rebuildtop) {
                rebuildTopArrows = rebuildtop;
                return Column(
                  children: [
                    Container(
                      height: 40,
                      color: selectedColor,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            child: subsub.index > 0
                                ? IconButton(
                                    key: backKey,
                                    onPressed: () {
                                      subsub.animateTo(subsub.index - 1);
                                      rebuildtop(() {});
                                    },
                                    icon: Icon(FlutterIcons.left_ant,
                                        color:
                                            selectedColor.computeLuminance() >
                                                    0.5
                                                ? Colors.black
                                                : Colors.white))
                                : Container(),
                          ),
                          Expanded(
                            child: Center(
                                child: FittedBox(
                              child: Text(
                                selectedEvent,
                                style: TextStyle(
                                    fontSize: 40,
                                    color:
                                        selectedColor.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white),
                              ),
                            )),
                          ),
                          Container(
                            width: 50,
                            child: (subsub.index < subsub.length - 1)
                                ? IconButton(
                                    onPressed: () {
                                      subsub.animateTo(subsub.index + 1);
                                      rebuildtop(() {});
                                    },
                                    icon: Icon(FlutterIcons.right_ant,
                                        color:
                                            selectedColor.computeLuminance() >
                                                    0.5
                                                ? Colors.black
                                                : Colors.white))
                                : Container(),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          TabBar(
                            key: subtabKey,
                            controller: subsub,
                            tabs: tabLabels,
                            onTap: (value) {
                              subsub.animateTo(value);
                              rebuildtop(() {});
                            },
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: subsub,
                              children: sectionWidgets,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }));
        } else {
          return CircularProgressIndicator(); // Or any other loading indicator
        }
      },
    );
  });
}

final concformkey = GlobalKey<FormState>();
final weightformkey = GlobalKey<FormState>();
double _transformValue(double value) {
  if (value < 10) {
    return value / 10 * 0.6; // 0-10 occupies 50% of the slider
  } else {
    return 0.6 + (value - 10) / 140 * 0.4; // 10-100 occupies the remaining 50%
  }
}

double _inverseTransformValue(double value) {
  if (value < 0.6) {
    return double.parse((value / 0.6 * 10).toStringAsFixed(1));
  } else {
    return double.parse((10 + (value - 0.6) / 0.4 * 140).toStringAsFixed(0));
  }
}

formatWeightString(double input) {
  if (input < 10) {
    return input.toStringAsFixed(1);
  } else {
    return input.toStringAsFixed(0);
  }
}

Map<String, dynamic> customConcentrations = {};
saveCustomConcentrations() {
  SharedPreferences.getInstance().then((prefs) {
    prefs.setString('customconcentrations', json.encode(customConcentrations));
    print("setprefs" + json.encode(customConcentrations));
  });
}

Map<List<Color>, List<String>> colorMap = {
  [Color(0xffA5B772)]: ["atropine"],
  [Color(0xff410098)]: ["ephedrine", "epinephrine", "dopamine", "dobutamine"],
  [Color(0xffB4AEA7)]: ["lidocaine"],
  [Color(0xffB08770)]: ["esmolol"],
  [Color(0xff71c5e8), Colors.white]: ["naloxone"],
  [Color(0xff32CD32), Colors.white]: ["atipamezole"],
  [Color(0xffE76A27), Colors.white]: ["flumazenil"],
};
Map<String, List<Color>> flippedColorMap = {
  "atropine": [Color(0xffA5B772)],
  "ephedrine": [Color(0xff410098)],
  "epinephrine": [Color(0xff410098)],
  "dopamine": [Color(0xff410098)],
  "dobutamine": [Color(0xff410098)],
  "lidocaine": [Color(0xffB4AEA7)],
  "esmolol": [Color(0xffB08770)],
  "naloxone": [Color(0xff71c5e8), Colors.white],
  "atipamezole": [Color(0xff32CD32), Colors.white],
  "flumazenil": [Color(0xffE76A27), Colors.white],
};

Widget getDrugDotDecoration(String drug) {
  drug = drug.toLowerCase().replaceAll(" inf", "").trim();
  if (flippedColorMap.containsKey(drug)) {
    if (flippedColorMap[drug]!.length > 1) {
      return Container(
        width: 20,
        height: 20,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Container(
            height: 2,
            color: flippedColorMap[drug]![0],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![1],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![0],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![1],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![0],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![1],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![0],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![1],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![0],
          ),
          Container(
            height: 2,
            color: flippedColorMap[drug]![1],
          ),
        ]),
      );
    }
    return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: flippedColorMap[drug]![0],
        ));
  } else {
    return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.lightBlue,
        ));
  }
}

Widget otherTableMaker(line, context) {
  List<InlineSpan> formatSubItalics(String text) {
    final List<InlineSpan> spans = [];
    final RegExp regExp = RegExp(r'O2');
    text = text.replaceAll("  ", "");
    final Iterable<RegExpMatch> matches = regExp.allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      final start = match.start;
      final end = match.end;

      // Add text before match as plain text
      if (start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, start)));
      }

      // Add 'O' as plain text
      spans.add(TextSpan(text: 'O'));

      // Add '2' as subscript
      spans.add(TextSpan(
        text: '2',
        style: TextStyle(fontFeatures: [FontFeature.subscripts()]),
      ));

      lastMatchEnd = end;
    }

    // Add remaining text as plain text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    // dealing with :

    for (int i = spans.length - 1; i > -1; i--) {
      if (spans[i] is TextSpan) {
        if ((spans[i] as TextSpan).text!.contains(":") &&
            !(spans[i] as TextSpan).text!.contains("http")) {
          final currentText = (spans[i] as TextSpan).text!;
          spans[i] = TextSpan(
              text: currentText.substring(0, currentText.indexOf(":")),
              style: TextStyle(fontStyle: FontStyle.italic));
          spans.insert(i + 1,
              TextSpan(text: currentText.substring(currentText.indexOf(":"))));
        } else if ((spans[i] as TextSpan).text!.contains("<bold>")) {
          final currentText = (spans[i] as TextSpan).text!;
          spans[i] = TextSpan(
            text: currentText.substring(0, currentText.indexOf("<bold>")),
          );
          spans.insert(
              i + 1,
              TextSpan(
                  text:
                      currentText.substring(currentText.indexOf("<bold>") + 6),
                  style: TextStyle(fontWeight: FontWeight.bold)));
        }
      }
    }

    for (int i = spans.length - 1; i > -1; i--) {
      if (spans[i] is TextSpan) {
        if ((spans[i] as TextSpan).text!.contains("K+")) {
          final charsOfInterest = "K+";
          final currentText = (spans[i] as TextSpan).text!;
          final pre = currentText.substring(0, currentText.indexOf("K+") + 1);
          final post = currentText.substring(currentText.indexOf("K+") + 2);
          spans[i] = TextSpan(
            text: pre,
          );
          spans.insert(i + 1, TextSpan(text: post));
          spans.insert(
              i + 1,
              TextSpan(
                text: '+',
                style: TextStyle(fontFeatures: [FontFeature.superscripts()]),
              ));
        }
      }
    }

    for (int i = spans.length - 1; i > -1; i--) {
      if (spans[i] is TextSpan) {
        if ((spans[i] as TextSpan).text!.contains("HCO3-")) {
          final currentText = (spans[i] as TextSpan).text!;
          final pre = currentText.substring(0, currentText.indexOf("HCO") + 3);
          final post = currentText.substring(currentText.indexOf("HCO") + 5);
          spans[i] = TextSpan(
            text: pre,
          );
          spans.insert(i + 1, TextSpan(text: post));
          spans.insert(
              i + 1,
              TextSpan(
                text: '3-',
                style: TextStyle(fontFeatures: [FontFeature.subscripts()]),
              ));
        }
      }
    }

    return spans;
  }

  return IntrinsicHeight(
    child: Row(
      children: [
        ...line.split("||").map((tablestring) {
          String title = tablestring.split("|")[0].trim();
          int clickAnimateIndex = 1;
          if (title.trim() == "Shockable Arrest Rhythms") {
            clickAnimateIndex = 2;
          } else if (title.trim() == "Blood loss >20%") {
            clickAnimateIndex = 3;
          }

          if (title.trim() == "or") {
            return Container(
              padding: const EdgeInsets.all(8.0),
              child: Text("or",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize:
                          Theme.of(context).textTheme.bodyLarge!.fontSize! *
                              1.2)),
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () {
                if (tutorialcontroller.index == 0) {
                  tutorialcontroller.animateTo(clickAnimateIndex);
                }
              },
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selectedColor)),
                child: Column(
                  children: [
                    title.length > 0
                        ? Container(
                            padding: const EdgeInsets.all(8.0),
                            color: selectedColor.withAlpha(100),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(title,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                              fontSize: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .fontSize! *
                                                  1.2)),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    ...tablestring.split("|").sublist(1).map((e) {
                      e = e.trim();
                      if (e.length == 0) {
                        return Container();
                      }
                      return Container(
                          padding: const EdgeInsets.all(8.0),
                          child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                  children: [...formatSubItalics(e)],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                          fontSize: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .fontSize! *
                                              1.2))));
                    })
                  ],
                ),
              ),
            ),
          );
        })
      ],
    ),
  );
}

double volume_in_canister = 0;
TextEditingController canisterController = TextEditingController();
double PCV_canister_fluid = 0;
TextEditingController PCVcanisterfluidController = TextEditingController();
double PCV_preop_fluid = 0;
TextEditingController PCVpreopfluidController = TextEditingController();
double PCV_recipient = 0;
TextEditingController PCVrecipientController = TextEditingController();
double PCV_donor = 0;
TextEditingController PCVdonorController = TextEditingController();

double desiredPCV = 0;
TextEditingController desiredPCVController = TextEditingController();
double recipientPCV = 0;
TextEditingController recipientPCVController = TextEditingController();
double donorPCV = 0;
TextEditingController donorPCVController = TextEditingController();
double recipientBloodVolume = 0;
TextEditingController recipientBloodVolumeController = TextEditingController();

double pcv_blood_unit = 0;
TextEditingController pcvbloodunitController = TextEditingController();

double initialhct = 0;
TextEditingController initialhctController = TextEditingController();
double lowesthct = 0;
TextEditingController lowesthctController = TextEditingController();
double averagehct = 0;
TextEditingController averagehctController = TextEditingController();

List<Widget> HemorrhageCalculator(passedStateSetter, context) {
  return [
    otherTableMaker(
        "Estimated Blood Volumes | Dog 90 mL/kg = " +
            (90 * weight).toStringAsFixed(0) +
            " mL | Cat 60 mL/kg = " +
            (60 * weight).toStringAsFixed(0) +
            " mL",
        context),
    otherTableMaker(
        "Estimating Blood Loss | Check floor and table | Weigh sponges (1 mL blood = 1 gram) | Assess volume of blood in suction canister",
        context),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
            onPressed: () {
              passedStateSetter(() {
                volume_in_canister = 0;
                PCV_canister_fluid = 0;
                PCV_preop_fluid = 0;
                PCV_recipient = 0;
                PCV_donor = 0;
                desiredPCV = 0;
                recipientPCV = 0;
                donorPCV = 0;
                recipientBloodVolume = 0;
                pcv_blood_unit = 0;
                initialhct = 0;
                lowesthct = 0;
                averagehct = 0;
                canisterController.text = "";
                PCVcanisterfluidController.text = "";
                PCVpreopfluidController.text = "";
                PCVrecipientController.text = "";
                PCVdonorController.text = "";
                desiredPCVController.text = "";
                recipientPCVController.text = "";
                donorPCVController.text = "";
                recipientBloodVolumeController.text = "";
                pcvbloodunitController.text = "";
                initialhctController.text = "";
                lowesthctController.text = "";
                averagehctController.text = "";
              });
            },
            child: Text("Reset Variables"))
      ],
    ),
    Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: selectedColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: selectedColor.withAlpha(100),
                ),
                child: Text("Canister Volume",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .fontSize!)),
              ),
            ),
          ]),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      onChanged: (value) {
                        passedStateSetter(() {
                          volume_in_canister = double.tryParse(value) ?? 0;
                        });
                      },
                      controller: canisterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Volume in canister',
                      )),
                ),
              ),
              Text(" X "),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          onChanged: (value) {
                            passedStateSetter(() {
                              PCV_canister_fluid = double.tryParse(value) ?? 0;
                            });
                          },
                          controller: PCVcanisterfluidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'PCV canister fluid',
                          )),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                          onChanged: (value) {
                            passedStateSetter(() {
                              PCV_preop_fluid = double.tryParse(value) ?? 0;
                            });
                          },
                          controller: PCVpreopfluidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'PCV preop patient',
                          )),
                    ),
                  ],
                ),
              )
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: EdgeInsets.all(8),
                    child: Text("=",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .copyWith())),
                Text(
                    (volume_in_canister > 0 &&
                            PCV_canister_fluid > 0 &&
                            PCV_preop_fluid > 0)
                        ? "Estimated blood loss: " +
                            (volume_in_canister *
                                    PCV_canister_fluid /
                                    PCV_preop_fluid)
                                .toStringAsFixed(0) +
                            " mL"
                        : "Enter values to calculate",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize:
                            Theme.of(context).textTheme.bodyLarge!.fontSize!))
              ],
            ),
          ),
        ],
      ),
    ),
    Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: selectedColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: selectedColor.withAlpha(100),
                ),
                child: Text("Whole Blood Transfusion",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .fontSize!)),
              ),
            ),
          ]),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: Container(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                                onTapOutside: (event) {
                                  FocusScope.of(context).unfocus();
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Desired PCV',
                                  labelStyle: TextStyle(fontSize: 10),
                                ),
                                controller: desiredPCVController,
                                onChanged: (value) {
                                  passedStateSetter(() {
                                    desiredPCV = double.tryParse(value) ?? 0;
                                  });
                                })),
                      ),
                      Text(" - "),
                      Expanded(
                        child: Container(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                                onTapOutside: (event) {
                                  FocusScope.of(context).unfocus();
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Recipient PCV',
                                  labelStyle: TextStyle(fontSize: 10),
                                ),
                                controller: recipientPCVController,
                                onChanged: (value) {
                                  passedStateSetter(() {
                                    recipientPCV = double.tryParse(value) ?? 0;
                                  });
                                })),
                      )
                    ]),
                    Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                              padding: EdgeInsets.all(8),
                              child: TextField(
                                  onTapOutside: (event) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Donor PCV',
                                  ),
                                  controller: donorPCVController,
                                  onChanged: (value) {
                                    passedStateSetter(() {
                                      donorPCV = double.tryParse(value) ?? 0;
                                    });
                                  })),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Text(" X "),
              Expanded(
                child: Container(
                    padding: EdgeInsets.all(8),
                    child: TextField(
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Recipient Volume',
                          labelStyle: TextStyle(fontSize: 10),
                        ),
                        controller: recipientBloodVolumeController,
                        onChanged: (value) {
                          passedStateSetter(() {
                            recipientBloodVolume = double.tryParse(value) ?? 0;
                          });
                        })),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: EdgeInsets.all(8),
                    child: Text("=",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .copyWith())),
                (desiredPCV > 0 &&
                        recipientPCV > 0 &&
                        donorPCV > 0 &&
                        recipientBloodVolume > 0)
                    ? Text(
                        "Transfusion volume: " +
                            ((desiredPCV - recipientPCV) *
                                    recipientBloodVolume /
                                    donorPCV)
                                .toStringAsFixed(0) +
                            " mL",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .fontSize!))
                    : Text("Enter values to calculate",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .fontSize!))
              ],
            ),
          ),
        ],
      ),
    ),
    Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: selectedColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: selectedColor.withAlpha(100),
                ),
                child: Text("Packed Red Blood Cells",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .fontSize!)),
              ),
            ),
          ]),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: Container(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                                onTapOutside: (event) {
                                  FocusScope.of(context).unfocus();
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Desired PCV',
                                  labelStyle: TextStyle(fontSize: 10),
                                ),
                                controller: desiredPCVController,
                                onChanged: (value) {
                                  passedStateSetter(() {
                                    desiredPCV = double.tryParse(value) ?? 0;
                                  });
                                })),
                      ),
                      Text(" - "),
                      Expanded(
                        child: Container(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                                onTapOutside: (event) {
                                  FocusScope.of(context).unfocus();
                                },
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Recipient PCV',
                                  labelStyle: TextStyle(fontSize: 10),
                                ),
                                controller: recipientPCVController,
                                onChanged: (value) {
                                  passedStateSetter(() {
                                    recipientPCV = double.tryParse(value) ?? 0;
                                  });
                                })),
                      )
                    ]),
                    Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                              padding: EdgeInsets.all(8),
                              child: TextField(
                                  onTapOutside: (event) {
                                    FocusScope.of(context).unfocus();
                                  },
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'PCV of Blood Unit',
                                  ),
                                  controller: pcvbloodunitController,
                                  onChanged: (value) {
                                    passedStateSetter(() {
                                      pcv_blood_unit =
                                          double.tryParse(value) ?? 0;
                                    });
                                  })),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Text(" X "),
              Expanded(
                child: Container(
                    padding: EdgeInsets.all(8),
                    child: TextField(
                        onTapOutside: (event) {
                          FocusScope.of(context).unfocus();
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Recipient Volume',
                          labelStyle: TextStyle(fontSize: 10),
                        ),
                        controller: recipientBloodVolumeController,
                        onChanged: (value) {
                          passedStateSetter(() {
                            recipientBloodVolume = double.tryParse(value) ?? 0;
                          });
                        })),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: EdgeInsets.all(8),
                    child: Text("=",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .copyWith())),
                (desiredPCV > 0 &&
                        recipientPCV > 0 &&
                        pcv_blood_unit > 0 &&
                        recipientBloodVolume > 0)
                    ? Text(
                        "Transfusion volume: " +
                            ((desiredPCV - recipientPCV) *
                                    recipientBloodVolume /
                                    pcv_blood_unit)
                                .toStringAsFixed(0) +
                            " mL",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .fontSize!))
                    : Text("Enter values to calculate",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .fontSize!))
              ],
            ),
          ),
        ],
      ),
    ),
    Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: selectedColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: selectedColor.withAlpha(100),
                ),
                child: Text("Plasma",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .fontSize!)),
              ),
            ),
          ]),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: EdgeInsets.all(8),
                    child: Text("=",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .copyWith())),
                Text("10 mL/kg = " + (weight * 10).toStringAsFixed(0) + " mL",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize:
                            Theme.of(context).textTheme.bodyLarge!.fontSize!))
              ],
            ),
          ),
        ],
      ),
    ),
    Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: selectedColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: selectedColor.withAlpha(100),
                ),
                child: Text("Allowable Blood Loss",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: Theme.of(context)
                            .textTheme
                            .headlineLarge!
                            .fontSize!)),
              ),
            ),
          ]),
          ExpansionTile(
              controller: dogexpandcontroller,
              onExpansionChanged: (value) {
                if (value) {
                  catexpandcontroller.collapse();
                }
              },
              title: Text(
                "Dog",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                              "Dog\n(90 mL/kg)\n" +
                                  (90 * weight).toStringAsFixed(0) +
                                  " mL",
                              textAlign: TextAlign.center),
                          Text("Blood Volume")
                        ],
                      ),
                    ),
                    Text(" X "),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: TextField(
                                        onTapOutside: (event) {
                                          FocusScope.of(context).unfocus();
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Initial PCV',
                                          labelStyle: TextStyle(fontSize: 10),
                                        ),
                                        controller: initialhctController,
                                        onChanged: (value) {
                                          passedStateSetter(() {
                                            initialhct =
                                                double.tryParse(value) ?? 0;
                                          });
                                        })),
                              ),
                              Text(" - "),
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: TextField(
                                        onTapOutside: (event) {
                                          FocusScope.of(context).unfocus();
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Lowest PCV',
                                          labelStyle: TextStyle(fontSize: 10),
                                        ),
                                        controller: lowesthctController,
                                        onChanged: (value) {
                                          passedStateSetter(() {
                                            lowesthct =
                                                double.tryParse(value) ?? 0;
                                          });
                                        })),
                              ),
                            ],
                          ),
                          Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: Expanded(
                                  child: Container(
                                      padding: EdgeInsets.all(8),
                                      child: (lowesthct > 0 && initialhct > 0)
                                          ? Text(
                                              ((initialhct + lowesthct) / 2)
                                                  .toStringAsFixed(0),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                      fontSize: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge!
                                                          .fontSize!))
                                          : Text("PCVavg",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                      fontSize: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge!
                                                          .fontSize!))),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          padding: EdgeInsets.all(8),
                          child: Text("=",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .copyWith())),
                      Text(
                          (initialhct > 0 && lowesthct > 0)
                              ? "Dog 🐕 = " +
                                  ((90 * weight) *
                                          ((initialhct - lowesthct) /
                                              ((initialhct + lowesthct) / 2)))
                                      .toStringAsFixed(0)
                              : "Enter Values to Calculate",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  fontSize: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .fontSize!))
                    ],
                  ),
                ),
              ]),
          ExpansionTile(
              controller: catexpandcontroller,
              onExpansionChanged: (value) {
                if (value) {
                  dogexpandcontroller.collapse();
                }
              },
              title: Text("Cat",
                  style: Theme.of(context).textTheme.headlineMedium),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Cat\n(60 mL/kg)\n" +
                                (60 * weight).toStringAsFixed(0) +
                                " mL",
                            textAlign: TextAlign.center,
                          ),
                          Text("Blood Volume")
                        ],
                      ),
                    ),
                    Text(" X "),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: TextField(
                                        onTapOutside: (event) {
                                          FocusScope.of(context).unfocus();
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Initial PCV',
                                          labelStyle: TextStyle(fontSize: 10),
                                        ),
                                        controller: initialhctController,
                                        onChanged: (value) {
                                          passedStateSetter(() {
                                            initialhct =
                                                double.tryParse(value) ?? 0;
                                          });
                                        })),
                              ),
                              Text(" - "),
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: TextField(
                                        onTapOutside: (event) {
                                          FocusScope.of(context).unfocus();
                                        },
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Lowest PCV',
                                          labelStyle: TextStyle(fontSize: 10),
                                        ),
                                        controller: lowesthctController,
                                        onChanged: (value) {
                                          passedStateSetter(() {
                                            lowesthct =
                                                double.tryParse(value) ?? 0;
                                          });
                                        })),
                              ),
                            ],
                          ),
                          Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: Expanded(
                                  child: Container(
                                      padding: EdgeInsets.all(8),
                                      child: (lowesthct > 0 && initialhct > 0)
                                          ? Text(
                                              ((initialhct + lowesthct) / 2)
                                                  .toStringAsFixed(0),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                      fontSize: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge!
                                                          .fontSize!))
                                          : Text("PCVavg",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                      fontSize: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge!
                                                          .fontSize!))),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          padding: EdgeInsets.all(8),
                          child: Text("=",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .copyWith())),
                      Text(
                          (initialhct > 0 && lowesthct > 0)
                              ? "Cat 🐈 = " +
                                  ((60 * weight) *
                                          ((initialhct - lowesthct) /
                                              ((initialhct + lowesthct) / 2)))
                                      .toStringAsFixed(0)
                              : "Enter Values to Calculate",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  fontSize: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .fontSize!))
                    ],
                  ),
                ),
              ]),
        ],
      ),
    ),
    Container(
      height: 70,
    )
  ];
}

ExpansibleController catexpandcontroller = ExpansibleController();
ExpansibleController dogexpandcontroller = ExpansibleController();

Widget drugSlider(String paragraph, Color color, BuildContext context,
    {ScrollController? scrollController}) {
  ScrollController controller;

  if (scrollController != null) {
    controller = scrollController;
  } else {
    controller = ScrollController();
  }
  return StatefulBuilder(builder: (buildercontext, refreshDrug) {
    List<Widget> calcs = [];
    if (paragraph.length > 0 && paragraph != "hemorrhage") {
      calcs.add(TextButton(
        child: Text("reset concentrations"),
        onPressed: () => refreshDrug(() {
          customConcentrations = {};
          saveCustomConcentrations();
        }),
      ));
    }

    if (paragraph == "hemorrhage") {
      calcs = HemorrhageCalculator(refreshDrug, context);
    } else {
      for (String line in paragraph.split('\n')) {
        if (line.length > 0 && !line.contains("Drug doses:")) {
          int kgindex = line.indexOf('/kg');
          String secondLine = "";
          bool weightIndependent = false;

          if (line.contains("(")) {
            secondLine =
                line.substring(line.indexOf("(") + 1, line.indexOf(")"));
            line = line.substring(0, line.indexOf("(")) +
                line.substring(line.indexOf(")") + 1);
          }

          if (line.indexOf("/puff") > 0) {
            weightIndependent = true;
            kgindex = line.indexOf("/puff");
          }
          if (line.indexOf("/application") > 0) {
            weightIndependent = true;
            kgindex = line.indexOf("/application");
          }
          if (line.indexOf(" gm ") > 0) {
            weightIndependent = true;
            kgindex = line.indexOf(" gm ");
          }

          if (kgindex > 0) {
            final words = line.split(" ");

            var kgword = words.where((test) => test.contains("/kg"));
            var kgwordindex = 0;
            var units = "";
            var doseunits = "";
            var numbertoparse = "";
            var preceeding = "";
            var dosedescripton = "";
            var route = "";
            if (line.contains("kg")) {
              kgword = words.where((test) => test.contains("/kg"));
              kgwordindex = words.indexOf(kgword.first);
              units = words.sublist(kgwordindex, kgwordindex + 1).join(" ");
              doseunits = units.replaceAll("/kg", "");
              numbertoparse = words[kgwordindex - 1];
              preceeding = words.sublist(0, kgwordindex - 1).join(" ");
            } else {
              preceeding = line.substring(0, line.indexOf("|"));
              dosedescripton =
                  line.substring(line.indexOf(" ") + 1, line.indexOf("|"));
            }

            //find route
            if (preceeding.contains("IM")) {
              route = "IM";
              preceeding = preceeding.replaceAll(" IM", "");
            } else if (preceeding.contains("IV")) {
              route = "IV";
              preceeding = preceeding.replaceAll(" IV", "");
            } else if (preceeding.contains("SQ")) {
              route = "SQ";
              preceeding = preceeding.replaceAll(" SQ", "");
            }

            double concentration = 1;
            String concentrationUnits = "";
            String volumeUnits = "mL";
            if (units.contains("/min")) {
              volumeUnits = volumeUnits + " / HOUR";
            }
            if (line.contains("defibrillation")) {
              volumeUnits = "joules";
            }

            bool selfdilutewarning = false;
            if (words.contains("|")) {
              var concentrationwords = words
                  .sublist(words.indexOf("|") + 1)
                  .where((test) => test.length > 0)
                  .join(" ")
                  .split(" ");

              if (customConcentrations[preceeding] != null) {
                concentrationwords =
                    customConcentrations[preceeding].split(" ");
              }

              if (concentrationwords.join(" ") == "self dilute" &&
                  !customConcentrations.containsKey(preceeding)) {
                selfdilutewarning = true;
              } else {
                concentration = double.tryParse(concentrationwords[0]) ?? 1;
                concentrationUnits = concentrationwords[1];

                if (customConcentrations.containsKey(preceeding)) {
                  final customwords =
                      customConcentrations[preceeding].split(" ");
                  concentration = double.tryParse(customwords[0]) ?? 1;
                  concentrationUnits = customwords[1];
                }
              }
            }

            double dose =
                double.tryParse(numbertoparse.split("-")[0].trim()) ?? 0;
            double upperdose = 0;
            double upperdoseperweight = 0;
            double uppervolumeperweight = 0;
            double? doseperweight = (dose) * weight;
            double? volumeperweight = (doseunits.contains("mcg")
                    ? doseperweight / 1000
                    : doseperweight) /
                concentration;
            if (concentrationUnits.contains("mcg")) {
              volumeperweight = volumeperweight * 1000;
            }

            if (numbertoparse.contains("-")) {
              final split = numbertoparse.split("-");
              dose = double.tryParse(split[0].trim()) ?? 0;
              upperdose = double.tryParse(split[1].trim()) ?? 0;
              upperdoseperweight = (upperdose) * weight;
              uppervolumeperweight = (doseunits.contains("mcg")
                      ? upperdoseperweight / 1000
                      : upperdoseperweight) /
                  concentration;
            }

            if (weightIndependent && line.contains("|")) {
              doseunits = line.substring(0, line.indexOf("|"));
              doseunits = doseunits.replaceAll(preceeding, "").trim();
            }

            calcs.add(Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              margin: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
              child: Container(
                padding: EdgeInsets.all(5),
                margin: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
                child: Column(
                  children: [
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: color.withAlpha(50),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                          ),
                          getDrugDotDecoration(preceeding),
                          Container(
                            width: 10,
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              preceeding
                                  .trim()
                                  .replaceAll("Dogs", "")
                                  .replaceAll("Cats", ""),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          preceeding.contains("Dogs")
                              ? Chip(
                                  label: Text(
                                  "Dogs 🐕",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ))
                              : preceeding.contains("Cats")
                                  ? Chip(
                                      label: Text(
                                        "Cats 🐈",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      ),
                                    )
                                  : Container(),
                          paragraph.contains("**Intr")
                              ? Text(convert(toExact(doseperweight)) +
                                  " " +
                                  doseunits)
                              : Container(),
                          (dose > 0 && !selfdilutewarning)
                              ? Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      convert(toExact(volumeperweight *
                                              (volumeUnits.contains("HOUR")
                                                  ? 60
                                                  : 1))) +
                                          " " +
                                          volumeUnits,
                                      textAlign: TextAlign.end,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                )
                              : Container(),
                          (weightIndependent && doseunits.length > 0)
                              ? Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      doseunits,
                                      textAlign: TextAlign.end,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                )
                              : Container(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              route,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          )
                        ],
                      ),
                    ),
                    secondLine.length > 0
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              secondLine.trim(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          )
                        : Container(),
                    dose > 0
                        ? FittedBox(
                            child: Row(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8.0, left: 8),
                                  child: Text(
                                    convert(toExact(dose)) +
                                        " " +
                                        units +
                                        " = " +
                                        convert(toExact(doseperweight)) +
                                        " " +
                                        doseunits,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    line.contains("mL/kg") || line.contains("defibrillation")
                        ? Container()
                        : FittedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                customConcentrations[preceeding] != null
                                    ? Icon(Icons.star, color: color)
                                    : Container(),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Container(
                                    child: selfdilutewarning
                                        ? ElevatedButton(
                                            onPressed: () {
                                              var mcormg = [true, false];
                                              if (customConcentrations[
                                                      preceeding] !=
                                                  null) {
                                                if (customConcentrations[
                                                        preceeding]
                                                    .contains("mcg"))
                                                  mcormg = [false, true];
                                              }
                                              var isWeirdConc = units
                                                          .contains("mcg") ||
                                                      units.contains("mg") ||
                                                      units == ""
                                                  ? false
                                                  : true;

                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext contextet) {
                                                  return AlertDialog(
                                                    title:
                                                        Text("Concentration"),
                                                    content: Form(
                                                      key: concformkey,
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    Container(
                                                                  constraints:
                                                                      BoxConstraints(
                                                                          maxWidth:
                                                                              200),
                                                                  child:
                                                                      TextFormField(
                                                                    initialValue: customConcentrations[preceeding] !=
                                                                            null
                                                                        ? customConcentrations[preceeding]
                                                                            .split(' ')[0]
                                                                        : "",
                                                                    autofocus:
                                                                        true,
                                                                    keyboardType:
                                                                        TextInputType.numberWithOptions(
                                                                            decimal:
                                                                                true),
                                                                    decoration:
                                                                        InputDecoration(
                                                                      border:
                                                                          OutlineInputBorder(),
                                                                    ),
                                                                    validator:
                                                                        (value) {
                                                                      if (value!
                                                                          .isEmpty) {
                                                                        return 'Please enter a concentration';
                                                                      } else if (!value
                                                                          .contains(
                                                                              RegExp(r'^[0-9.,]+$'))) {
                                                                        return 'Please enter a valid number';
                                                                      } else {
                                                                        final numberFormat =
                                                                            NumberFormat.decimalPattern('en_US');
                                                                        final parsedValue = numberFormat.parse(value.replaceAll(
                                                                            ',',
                                                                            ''));
                                                                        if (parsedValue <
                                                                                0 ||
                                                                            parsedValue >
                                                                                10000) {
                                                                          return 'Concentration must be >0 and <1000';
                                                                        }
                                                                      }
                                                                      return null;
                                                                    },
                                                                    onSaved:
                                                                        (value) {
                                                                      if (isWeirdConc) {
                                                                        customConcentrations[preceeding] = value! +
                                                                            " " +
                                                                            units.replaceAll("kg", "mL").replaceAll("/min",
                                                                                "");
                                                                      } else {
                                                                        customConcentrations[preceeding] = value! +
                                                                            (mcormg.first
                                                                                ? " mg/mL"
                                                                                : " mcg/mL");
                                                                      }

                                                                      saveCustomConcentrations();
                                                                      refreshDrug(
                                                                          () {});
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              isWeirdConc
                                                                  ? Text(units
                                                                      .replaceAll(
                                                                          "kg",
                                                                          "mL")
                                                                      .replaceAll(
                                                                          "/min",
                                                                          ""))
                                                                  : StatefulBuilder(
                                                                      builder:
                                                                          (context,
                                                                              reload) {
                                                                      return ToggleButtons(
                                                                          children: [
                                                                            Padding(
                                                                              padding: const EdgeInsets.all(8.0),
                                                                              child: Text("MG/mL"),
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.all(8.0),
                                                                              child: Text("MCG/mL"),
                                                                            )
                                                                          ],
                                                                          onPressed:
                                                                              (index) {
                                                                            reload(() {
                                                                              for (int i = 0; i < mcormg.length; i++) {
                                                                                mcormg[i] = i == index;
                                                                              }
                                                                            });
                                                                          },
                                                                          isSelected:
                                                                              mcormg);
                                                                    }),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      ElevatedButton(
                                                        child: Text("Save"),
                                                        onPressed: () {
                                                          if (concformkey
                                                              .currentState!
                                                              .validate()) {
                                                            concformkey
                                                                .currentState!
                                                                .save();
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons
                                                    .warning_amber_rounded),
                                                Text("self dilute"),
                                              ],
                                            ))
                                        : Text(
                                            "Concentration: " +
                                                ((concentration > 0)
                                                    ? convert(
                                                        toExact(concentration))
                                                    : "") +
                                                " " +
                                                concentrationUnits,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium,
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: TextButton(
                                      onPressed: () {
                                        var mcormg = [true, false];
                                        if (customConcentrations[preceeding] !=
                                            null) {
                                          if (customConcentrations[preceeding]
                                              .contains("mcg"))
                                            mcormg = [false, true];
                                        }
                                        var isWeirdConc =
                                            units.contains("mcg") ||
                                                    units.contains("mg") ||
                                                    units == ""
                                                ? false
                                                : true;

                                        showDialog(
                                          context: context,
                                          builder: (BuildContext contextet) {
                                            return AlertDialog(
                                              title: Text("Concentration"),
                                              content: Form(
                                                key: concformkey,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                            constraints:
                                                                BoxConstraints(
                                                                    maxWidth:
                                                                        200),
                                                            child:
                                                                TextFormField(
                                                              initialValue: customConcentrations[
                                                                          preceeding] !=
                                                                      null
                                                                  ? customConcentrations[
                                                                          preceeding]
                                                                      .split(
                                                                          ' ')[0]
                                                                  : "",
                                                              autofocus: true,
                                                              keyboardType: TextInputType
                                                                  .numberWithOptions(
                                                                      decimal:
                                                                          true),
                                                              decoration:
                                                                  InputDecoration(
                                                                border:
                                                                    OutlineInputBorder(),
                                                              ),
                                                              validator:
                                                                  (value) {
                                                                if (value!
                                                                    .isEmpty) {
                                                                  return 'Please enter a concentration';
                                                                } else if (!value
                                                                    .contains(
                                                                        RegExp(
                                                                            r'^[0-9.,]+$'))) {
                                                                  return 'Please enter a valid number';
                                                                } else {
                                                                  final numberFormat =
                                                                      NumberFormat
                                                                          .decimalPattern(
                                                                              'en_US');
                                                                  final parsedValue =
                                                                      numberFormat.parse(
                                                                          value.replaceAll(
                                                                              ',',
                                                                              ''));
                                                                  if (parsedValue <
                                                                          0 ||
                                                                      parsedValue >
                                                                          10000) {
                                                                    return 'Concentration must be >0 and <1000';
                                                                  }
                                                                }
                                                                return null;
                                                              },
                                                              onSaved: (value) {
                                                                if (isWeirdConc) {
                                                                  customConcentrations[preceeding] = value! +
                                                                      " " +
                                                                      units
                                                                          .replaceAll(
                                                                              "kg",
                                                                              "mL")
                                                                          .replaceAll(
                                                                              "/min",
                                                                              "");
                                                                } else {
                                                                  customConcentrations[
                                                                          preceeding] =
                                                                      value! +
                                                                          (mcormg.first
                                                                              ? " mg/mL"
                                                                              : " mcg/mL");
                                                                }

                                                                saveCustomConcentrations();
                                                                refreshDrug(
                                                                    () {});
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        isWeirdConc
                                                            ? Text(units
                                                                .replaceAll(
                                                                    "kg", "mL")
                                                                .replaceAll(
                                                                    "/min", ""))
                                                            : StatefulBuilder(
                                                                builder:
                                                                    (context,
                                                                        reload) {
                                                                return ToggleButtons(
                                                                    children: [
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child: Text(
                                                                            "MG/mL"),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child: Text(
                                                                            "MCG/mL"),
                                                                      )
                                                                    ],
                                                                    onPressed:
                                                                        (index) {
                                                                      reload(
                                                                          () {
                                                                        for (int i =
                                                                                0;
                                                                            i < mcormg.length;
                                                                            i++) {
                                                                          mcormg[i] =
                                                                              i == index;
                                                                        }
                                                                      });
                                                                    },
                                                                    isSelected:
                                                                        mcormg);
                                                              }),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                ElevatedButton(
                                                  child: Text("Save"),
                                                  onPressed: () {
                                                    if (concformkey
                                                        .currentState!
                                                        .validate()) {
                                                      concformkey.currentState!
                                                          .save();
                                                      Navigator.of(context)
                                                          .pop();
                                                    }
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Icon(Icons.edit)),
                                ),
                              ],
                            ),
                          ),
                    Divider(),
                  ],
                ),
              ),
            ));
          } else if (line.length > 0) {
            if (!line.startsWith("**")) {
              calcs.add(Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 4,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  )
                ],
              ));
              calcs.add(
                  Text(line, style: Theme.of(context).textTheme.headlineLarge));
            }
          }
        }
      }
    }
    var needconvert = false;
    final kgweightcontroller = TextEditingController();
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(width: 1.0, color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Patient Weight",
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Enter Patient Weight (kg)"),
                            content: Form(
                                key: weightformkey,
                                child:
                                    StatefulBuilder(builder: (context, reload) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        autofocus: true,
                                        controller: kgweightcontroller,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                decimal: true),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: '0-150 kg',
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Please enter a weight';
                                          } else if (!value.contains(
                                              RegExp(r'^[0-9.,]+$'))) {
                                            return 'Please enter a valid number';
                                          } else {
                                            final numberFormat =
                                                NumberFormat.decimalPattern(
                                                    'en_US');
                                            final parsedValue =
                                                numberFormat.parse(
                                                    value.replaceAll(',', ''));
                                            if (parsedValue < 0 ||
                                                parsedValue > 150) {
                                              return 'Weight must be >0 and <150 kg';
                                            }
                                          }
                                          return null;
                                        },
                                        onSaved: (value) {
                                          final numberFormat =
                                              NumberFormat.decimalPattern(
                                                  'en_US');
                                          weight = numberFormat
                                              .parse(value!.replaceAll(',', ''))
                                              .toDouble();
                                          refreshDrug(() {});
                                          bannerSetter(() {});
                                        },
                                      ),
                                      TextButton(
                                          onPressed: () {
                                            reload(() {
                                              needconvert = true;
                                            });
                                          },
                                          child: Text("convert from pounds?")),
                                      needconvert
                                          ? TextFormField(
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                labelText: '0-330 lbs',
                                              ),
                                              onChanged: (value) {
                                                kgweightcontroller
                                                    .text = (value.length > 0
                                                        ? (double.tryParse(value
                                                                    .replaceAll(
                                                                        ',',
                                                                        '')) ??
                                                                0) /
                                                            2.20462
                                                        : 0)
                                                    .toStringAsFixed(0);
                                              },
                                            )
                                          : Container(),
                                    ],
                                  );
                                })),
                            actions: [
                              ElevatedButton(
                                child: Text("OK"),
                                onPressed: () {
                                  if (weightformkey.currentState!.validate()) {
                                    weightformkey.currentState!.save();
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      child: Row(
                        children: [
                          Text(formatWeightString(weight) + " kg",
                              style:
                                  Theme.of(globalcontext).textTheme.titleLarge),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                          ),
                          Icon(FlutterIcons.edit_mdi)
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Theme(
                        data: ThemeData(
                            colorScheme:
                                ColorScheme.fromSeed(seedColor: color)),
                        child: Slider(
                          value: _transformValue(weight),
                          min: 0.0,
                          max: 1.0,
                          label: formatWeightString(weight),
                          onChanged: (value) {
                            weight = _inverseTransformValue(value);
                            refreshDrug(() {});
                            bannerSetter(() {});
                          },
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
            child: NotificationListener<ScrollUpdateNotification>(
                // onNotification: (notification) {
                //   if (notification is ScrollUpdateNotification) {
                //     final metrics = notification.metrics;
                //     final position = metrics.pixels;
                //     print('Current position: $position');
                //   }
                //   return false;
                // },
                child: SingleChildScrollView(
                    controller: controller,
                    child: Column(children: [...calcs]))))
      ],
    );
  });
}

class TopItem extends StatelessWidget {
  TopItem(
      {super.key,
      required this.e,
      required this.color,
      this.isExpanded = false});
  final String e;
  final Color color;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final collapsedItems = [
      Container(
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              (toplevelEvents.indexOf(e) + 1).toString(),
              style: TextStyle(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white),
            ),
          )),
      Container(
        width: 5,
      ),
      Expanded(
        child: Text(
          key: toplevelEvents.indexOf(e) == 0 ? clickKey : null,
          e,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.left,
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
          decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15)),
          child: Container(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [...collapsedItems]))),
    );
  }
}

String convert(String number) {
  String result = '';

  int maxNonZeroDigit = 2;

  if (number.contains(".")) {
    var pre = number.substring(0, number.indexOf("."));
    var post = number.substring(number.indexOf(".") + 1);
    if ((double.tryParse(pre) ?? 0) > 10) {
      return pre;
    }
    if ((double.tryParse(pre) ?? 0) > 0) {
      if ((double.tryParse(post) ?? 0) > 0) {
        final deci = (post.length > 2) ? post.substring(0, 2) : post;
        return pre + "." + deci;
      }

      return pre;
    }

    int numzeroes = 0;
    for (int i = 0; maxNonZeroDigit > 0 && i < number.length; i++) {
      result += (number[i]);

      if (number[i] != '0' && number[i] != '.') {
        maxNonZeroDigit -= 1;
      }
    }
    if (number.length > 5) {
      if (result[result.length - 2] == '0') {
        result = result.substring(0, result.length - 2);
        while (result[result.length - 1] == '0') {
          result = result.substring(0, result.length - 1);
        }
      }
    }

    return result;
  }

  return number;
}

String toExact(double value) {
  var sign = "";
  if (value < 0) {
    value = -value;
    sign = "-";
  }
  var string = value.toString();
  var e = string.lastIndexOf('e');
  if (e < 0) return "$sign$string";
  assert(string.indexOf('.') == 1);
  var offset =
      int.parse(string.substring(e + (string.startsWith('-', e + 1) ? 1 : 2)));
  final digits = string.substring(0, e).replaceAll('.', '');
  if (offset < 0) {
    return "${sign}0.${"0" * ~offset}$digits";
  }
  if (offset > 0) {
    if (offset >= digits.length) return sign + digits.padRight(offset + 1, "0");
    return "$sign${digits.substring(0, offset + 1)}"
        ".${digits.substring(offset + 1)}";
  }
  return digits;
}

class HolePainter extends CustomPainter {
  final Rect _rect;
  final double animationValue;

  HolePainter(this._rect, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    Size larger =
        Size(10 * (100 - animationValue), 10 * (100 - animationValue));

    final path = Path()..addRect(Offset.zero & size);

    if (_rect != Rect.zero) {
      path.addRRect(
        RRect.fromLTRBR(
          _rect.left - larger.width, // left
          _rect.top - larger.height, // top
          (_rect.width + _rect.left) + larger.width, // right
          (_rect.height + _rect.top) + larger.height, // bottom
          Radius.circular(10), // radius
        ),
      );
      path.fillType = PathFillType.evenOdd;
    }
    // Draw the path
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
