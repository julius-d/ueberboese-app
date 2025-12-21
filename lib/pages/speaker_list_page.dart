import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/speaker.dart';
import '../main.dart';
import 'speaker_detail_page.dart';
import 'add_speaker_page.dart';

class SpeakerListPage extends StatelessWidget {
  const SpeakerListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    Widget content;
    if (appState.speakers.isEmpty) {
      content = const Center(
        child: Text('No speakers available'),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: appState.speakers.length,
        itemBuilder: (context, index) {
          final speaker = appState.speakers[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            child: ListTile(
              leading: Text(
                speaker.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              title: Text(
                speaker.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                speaker.type,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpeakerDetailPage(speaker: speaker),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddSpeakerPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
