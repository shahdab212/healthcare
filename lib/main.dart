import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission();
  await initNotifications();
  runApp(MyHealthApp());
}

// Request notification permission for Android 13+
Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

// Initialize Notifications
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  tz.initializeTimeZones();
}

// Schedule Daily Health Tips at 8 AM
Future<void> scheduleDailyHealthTips() async {
  final tips = [
    'গরমে বেশি পানি পান করুন।',
    'মশা থেকে বাঁচুন, মশারি ব্যবহার করুন।',
    'নিয়মিত হাত ধুয়ে জীবাণু থেকে বাঁচুন।',
  ];
  final randomTip = tips[DateTime.now().millisecondsSinceEpoch % tips.length];
  final now = DateTime.now();
  var scheduledTime = DateTime(now.year, now.month, now.day, 8, 0); // 8 AM
  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(Duration(days: 1));
  }

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'দৈনিক স্বাস্থ্য টিপস',
    randomTip,
    tz.TZDateTime.from(scheduledTime, tz.local),
    NotificationDetails(
      android: AndroidNotificationDetails(
        'health_tips_channel',
        'Daily Health Tips',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // Recur daily
  );
}

class MyHealthApp extends StatefulWidget {
  @override
  _MyHealthAppState createState() => _MyHealthAppState();
}

class _MyHealthAppState extends State<MyHealthApp> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), scheduleDailyHealthTips);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'স্বাস্থ্য সেবা অ্যাপ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue[50],
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontSize: 20),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            minimumSize: Size(double.infinity, 60),
          ),
        ),
      ),
      home: HomeScreen(),
      routes: {
        '/symptom_checker': (context) => SymptomCheckerScreen(),
        '/first_aid': (context) => FirstAidScreen(),
        '/nearby_hospitals': (context) => NearbyHospitalsScreen(),
        '/medicine_reminder': (context) => MedicineReminderScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('স্বাস্থ্য সেবা', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'স্বাস্থ্য সেবায় আপনাদের পাশে',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              semanticsLabel: 'স্বাস্থ্য সেবায় আপনাদের পাশে',
            ),
            SizedBox(height: 20),
            Expanded(
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.pushNamed(context, '/symptom_checker');
                    },
                    child: Text('রোগ চিহ্নিত করুন', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      Navigator.pushNamed(context, '/first_aid');
                    },
                    child: Text('প্রাথমিক চিকিৎসা', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () {
                      Navigator.pushNamed(context, '/nearby_hospitals');
                    },
                    child: Text('নিকটস্থ হাসপাতাল খুঁজুন', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    onPressed: () {
                      Navigator.pushNamed(context, '/medicine_reminder');
                    },
                    child: Text('ঔষধ মনে করানো', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      try {
                        const phoneNumber = 'tel:+880123456789';
                        if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                          await launchUrl(Uri.parse(phoneNumber));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('কল করা যায়নি')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ত্রুটি: $e')),
                        );
                      }
                      setState(() => isLoading = false);
                    },
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('জরুরি সাহায্য প্রয়োজন?', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class SymptomCheckerScreen extends StatefulWidget {
  @override
  _SymptomCheckerScreenState createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  List<String> selectedSymptoms = [];
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  final List<Map<String, String>> symptoms = [
    {'name': 'জ্বর', 'icon': '🌡️'},
    {'name': 'কাশি', 'icon': '😷'},
    {'name': 'পেট ব্যথা', 'icon': '🤢'},
    {'name': 'সর্দি', 'icon': '🤧'},
    {'name': 'ব্যথা', 'icon': '🤕'},
    {'name': 'কাটা-পোড়া', 'icon': '🩹'},
    {'name': 'মাথা ঘোরা', 'icon': '😵'},
    {'name': 'বমি', 'icon': '🤮'},
    {'name': 'শ্বাসকষ্ট', 'icon': '😤'},
    {'name': 'চোখ লাল', 'icon': '👁️'},
    {'name': 'ডায়রিয়া', 'icon': '🚽'},
  ];

  Future<void> speak(String text) async {
    setState(() => isSpeaking = true);
    try {
      await flutterTts.setLanguage('bn-BD');
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ভয়েস প্লে ত্রুটি: $e')),
      );
    }
    setState(() => isSpeaking = false);
  }

  void diagnose() {
    String diagnosis = 'দুঃখিত, এই উপসর্গের জন্য নির্দিষ্ট রোগ নির্ণয় করা যায়নি।\nকী করবেন: ডাক্তারের পরামর্শ নিন।';
    
    if (selectedSymptoms.contains('জ্বর')) {
      diagnosis = 'সম্ভাব্য রোগ: ফ্লু বা ভাইরাল সংক্রমণ\nকী করবেন: বিশ্রাম নিন, পানি পান করুন, ডাক্তারের পরামর্শ নিন\nজরুরি: জ্বর ১০২°F ছাড়ালে হাসপাতালে যান';
    } else if (selectedSymptoms.contains('কাশি')) {
      diagnosis = 'সম্ভাব্য রোগ: সাধারণ সর্দি বা অ্যালার্জি\nকী করবেন: গরম পানি পান করুন, ডাক্তারের পরামর্শ নিন\nজরুরি: শ্বাসকষ্ট হলে হাসপাতালে যান';
    } else if (selectedSymptoms.contains('পেট ব্যথা')) {
      diagnosis = 'সম্ভাব্য রোগ: গ্যাস বা হজমের সমস্যা\nকী করবেন: হালকা খাবার খান, ডাক্তারের পরামর্শ নিন\nজরুরি: তীব্র ব্যথা হলে হাসপাতালে যান';
    } else if (selectedSymptoms.contains('ডায়রিয়া')) {
      diagnosis = 'সম্ভাব্য রোগ: গ্যাস্ট্রোএন্টেরাইটিস\nকী করবেন: ওআরএস পান করুন, হালকা খাবার খান\nজরুরি: পানিশূন্যতার লক্ষণ দেখা দিলে হাসপাতালে যান';
    } else if (selectedSymptoms.contains('মাথা ঘোরা')) {
      diagnosis = 'সম্ভাব্য রোগ: মাইগ্রেন বা নিম্ন রক্তচাপ\nকী করবেন: শান্ত জায়গায় বিশ্রাম নিন, ডাক্তারের পরামর্শ নিন\nজরুরি: অজ্ঞান হলে হাসপাতালে যান';
    } else if (selectedSymptoms.contains('শ্বাসকষ্ট')) {
      diagnosis = 'সম্ভাব্য রোগ: অ্যাজমা বা নিউমোনিয়া\nকী করবেন: ডাক্তারের পরামর্শ নিন, ইনহেলার ব্যবহার করুন (যদি থাকে)\nজরুরি: শ্বাসকষ্ট বাড়লে তৎক্ষণাৎ হাসপাতালে যান';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('রোগ নির্ণয়', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        content: Text(diagnosis, style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedSymptoms.clear();
              });
            },
            child: Text('ঠিক আছে', style: TextStyle(fontSize: 18)),
          ),
          IconButton(
            icon: isSpeaking ? CircularProgressIndicator() : Icon(Icons.play_arrow, size: 30),
            onPressed: isSpeaking ? null : () => speak(diagnosis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('রোগ চিহ্নিত করুন', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'আপনার উপসর্গ বেছে নিন',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              semanticsLabel: 'আপনার উপসর্গ বেছে নিন',
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.0,
                ),
                itemCount: symptoms.length,
                itemBuilder: (context, index) {
                  final symptom = symptoms[index];
                  final isSelected = selectedSymptoms.contains(symptom['name']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSymptoms.clear();
                        selectedSymptoms.add(symptom['name']!);
                        diagnose();
                      });
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: isSelected ? Colors.green[100] : Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            symptom['icon']!,
                            style: TextStyle(fontSize: 50),
                            semanticsLabel: symptom['name'],
                          ),
                          SizedBox(height: 10),
                          Text(
                            symptom['name']!,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FirstAidScreen extends StatefulWidget {
  @override
  _FirstAidScreenState createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  final List<Map<String, String>> firstAidCategories = [
    {
      'name': 'কাটা-পোড়া',
      'instruction': '১. জায়গাটি ঠান্ডা পানি দিয়ে ১০ মিনিট ধুন\n২. পরিষ্কার ব্যান্ডেজ লাগান\n৩. সংক্রমণের লক্ষণ দেখলে ডাক্তারের পরামর্শ নিন'
    },
    {
      'name': 'বিষক্রিয়া',
      'instruction': '১. বিষাক্ত পদার্থ অপসারণ করুন\n২. তৎক্ষণাৎ ডাক্তারের সাথে যোগাযোগ করুন\n৩. রোগীকে বমি করতে বাধ্য করবেন না'
    },
    {
      'name': 'মাথা ব্যথা',
      'instruction': '১. শান্ত পরিবেশে বিশ্রাম নিন\n২. পর্যাপ্ত পানি পান করুন\n৩. প্রয়োজনে প্যারাসিটামল খান, তবে ডাক্তারের পরামর্শ নিন'
    },
    {
      'name': 'পোকামাকড় কামড়',
      'instruction': '১. কামড়ের জায়গা সাবান দিয়ে ধুন\n২. অ্যান্টিসেপটিক ক্রিম লাগান\n৩. ফোলা বা শ্বাসকষ্ট হলে হাসপাতালে যান'
    },
    {
      'name': 'রক্তপাত',
      'instruction': '১. ক্ষতস্থানে পরিষ্কার কাপড় দিয়ে চাপ দিন\n২. হাত উঁচু করে রাখুন\n৩. রক্তপাত না থামলে তৎক্ষণাৎ হাসপাতালে যান'
    },
    {
      'name': 'হৃদরোগের আক্রমণ',
      'instruction': '১. রোগীকে বসান বা শোয়ান\n২. জরুরি নম্বরে কল করুন\n৩. অ্যাসপিরিন (যদি থাকে) দিন, তবে ডাক্তারের পরামর্শ অনুযায়ী'
    },
    {
      'name': 'অজ্ঞান হওয়া',
      'instruction': '১. রোগীকে সমতল জায়গায় শোয়ান\n২. পা একটু উঁচু করুন\n৩. জ্ঞান না ফিরলে তৎক্ষণাৎ হাসপাতালে নিন'
    },
    {
      'name': 'হিট স্ট্রোক',
      'instruction': '১. রোগীকে ছায়ায় নিন\n২. শরীরে ঠান্ডা পানি ছিটিয়ে দিন\n৩. পানি বা ওআরএস পান করান, জ্ঞান না ফিরলে হাসপাতালে যান'
    },
  ];

  Future<void> speak(String text) async {
    setState(() => isSpeaking = true);
    try {
      await flutterTts.setLanguage('bn-BD');
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ভয়েস প্লে ত্রুটি: $e')),
      );
    }
    setState(() => isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('প্রাথমিক চিকিৎসা', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: firstAidCategories.length,
          itemBuilder: (context, index) {
            final category = firstAidCategories[index];
            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListTile(
                  leading: Icon(Icons.medical_services, size: 50, color: Colors.blue),
                  title: Text(
                    category['name']!,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      category['instruction']!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  trailing: IconButton(
                    icon: isSpeaking ? CircularProgressIndicator() : Icon(Icons.play_arrow, size: 30),
                    onPressed: isSpeaking ? null : () => speak(category['instruction']!),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NearbyHospitalsScreen extends StatefulWidget {
  @override
  _NearbyHospitalsScreenState createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  bool isLoading = false;

  final List<Map<String, String>> hospitals = [
    {'name': 'ঢাকা মেডিকেল', 'address': 'ঢাকা', 'phone': '+880123456789'},
    {'name': 'ইবনে সিনা', 'address': 'ধানমন্ডি, ঢাকা', 'phone': '+880987654321'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('নিকটস্থ হাসপাতাল', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: hospitals.length,
          itemBuilder: (context, index) {
            final hospital = hospitals[index];
            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.local_hospital, size: 50, color: Colors.red),
                title: Text(
                  hospital['name']!,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${hospital['address']}\n${hospital['phone']}',
                  style: TextStyle(fontSize: 16),
                ),
                trailing: IconButton(
                  icon: isLoading ? CircularProgressIndicator() : Icon(Icons.phone, size: 30),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            final phoneNumber = 'tel:${hospital['phone']}';
                            if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                              await launchUrl(Uri.parse(phoneNumber));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('কল করা যায়নি')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('ত্রুটি: $e')),
                            );
                          }
                          setState(() => isLoading = false);
                        },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MedicineReminderScreen extends StatefulWidget {
  @override
  _MedicineReminderScreenState createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends State<MedicineReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  String? medicineName;
  int? doseFrequency;
  List<TimeOfDay> doseTimes = [];
  int? totalDoses;
  int remainingDoses = 0;
  bool isScheduling = false;

  void scheduleNotification(String medicine, TimeOfDay time, int doseIndex) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      doseIndex,
      'ঔষধ খাওয়ার সময়',
      'আপনার ঔষধ \'$medicine\' খাওয়ার সময় হয়েছে।',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_channel',
          'Medicine Reminders',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction('taken', 'খাওয়া হয়েছে'),
            AndroidNotificationAction('snooze', 'পরে মনে করানো'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void snoozeNotification(String medicine, TimeOfDay time, int doseIndex) {
    final snoozeTime = TimeOfDay(
      hour: time.hour,
      minute: time.minute + 15,
    );
    scheduleNotification(medicine, snoozeTime, doseIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ঔষধ মনে করানো', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ঔষধের তথ্য দিন',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  semanticsLabel: 'ঔষধের তথ্য দিন',
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'ঔষধের নাম',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ঔষধের নাম লিখুন';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    medicineName = value;
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'দিনে কয়বার',
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3].map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text('$freq বার'),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'ডোজ ফ্রিকোয়েন্সি বেছে নিন';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      doseFrequency = value;
                      doseTimes = List.generate(value!, (index) => TimeOfDay.now());
                    });
                  },
                ),
                SizedBox(height: 20),
                if (doseFrequency != null)
                  Column(
                    children: List.generate(doseFrequency!, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ডোজ ${index + 1} সময়: ${doseTimes[index].format(context)}',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                downloaded from Grok, created by xAI
                                final selectedTime = await showTimePicker(
                                  context: context,
                                  initialTime: doseTimes[index],
                                );
                                if (selectedTime != null) {
                                  setState(() {
                                    doseTimes[index] = selectedTime;
                                  });
                                }
                              },
                              child: Text('সময় নির্বাচন করুন'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'মোট ডোজ সংখ্যা',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'মোট ডোজ সংখ্যা লিখুন';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    totalDoses = int.parse(value!);
                    remainingDoses = totalDoses!;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isScheduling
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isScheduling = true);
                            _formKey.currentState!.save();
                            try {
                              for (int i = 0; i < doseTimes.length; i++) {
                                scheduleNotification(medicineName!, doseTimes[i], i);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('রিমাইন্ডার সেট করা হয়েছে')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ত্রুটি: $e')),
                              );
                            }
                            setState(() => isScheduling = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: isScheduling
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('রিমাইন্ডার সেট করুন'),
                ),
                SizedBox(height: 20),
                Text(
                  'বাকি ডোজ: $remainingDoses',
                  style: TextStyle(fontSize: 18, color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
