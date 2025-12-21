import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/speaker.dart';
import 'pages/home_page.dart';
import 'services/speaker_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = MyAppState();
  await appState.initializeSpeakers();

  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  final MyAppState appState;

  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
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
  final SpeakerStorageService _storageService = SpeakerStorageService();
  List<Speaker> speakers = [];

  Future<void> initializeSpeakers() async {
    speakers = await _storageService.loadSpeakers();
    notifyListeners();
  }

  void addSpeaker(Speaker speaker) {
    speakers.add(speaker);
    _storageService.saveSpeakers(speakers);
    notifyListeners();
  }

  void removeSpeaker(Speaker speaker) {
    speakers.remove(speaker);
    _storageService.saveSpeakers(speakers);
    notifyListeners();
  }
}
