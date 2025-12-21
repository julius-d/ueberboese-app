import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/speaker.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Überböse App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: const HomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  List<Speaker> speakers = [
    const Speaker(
      id: '1',
      name: 'Living Room Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.101',
    ),
    const Speaker(
      id: '2',
      name: 'Bedroom Speaker',
      emoji: '🎵',
      ipAddress: '192.168.1.102',
    ),
    const Speaker(
      id: '3',
      name: 'Kitchen Speaker',
      emoji: '🎶',
      ipAddress: '192.168.1.103',
    ),
    const Speaker(
      id: '4',
      name: 'Office Speaker',
      emoji: '🎧',
      ipAddress: '192.168.1.104',
    ),
    const Speaker(
      id: '5',
      name: 'Garage Speaker',
      emoji: '📻',
      ipAddress: '192.168.1.105',
    ),
  ];

  void addSpeaker(Speaker speaker) {
    speakers.add(speaker);
    notifyListeners();
  }
}
