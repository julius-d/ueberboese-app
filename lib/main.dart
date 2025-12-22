import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/speaker.dart';
import 'models/app_config.dart';
import 'pages/home_page.dart';
import 'services/speaker_storage_service.dart';
import 'services/config_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = MyAppState();
  await appState.initialize();

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
  final ConfigStorageService _configStorageService = ConfigStorageService();

  List<Speaker> speakers = [];
  AppConfig config = const AppConfig();

  Future<void> initialize() async {
    await Future.wait([
      initializeSpeakers(),
      initializeConfig(),
    ]);
    notifyListeners();
  }

  Future<void> initializeSpeakers() async {
    speakers = await _storageService.loadSpeakers();
  }

  Future<void> initializeConfig() async {
    config = await _configStorageService.loadConfig();
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

  void updateSpeaker(Speaker updatedSpeaker) {
    final index = speakers.indexWhere((s) => s.id == updatedSpeaker.id);
    if (index != -1) {
      speakers[index] = updatedSpeaker;
      _storageService.saveSpeakers(speakers);
      notifyListeners();
    }
  }

  void updateConfig(AppConfig newConfig) {
    config = newConfig;
    _configStorageService.saveConfig(config);
    notifyListeners();
  }
}
