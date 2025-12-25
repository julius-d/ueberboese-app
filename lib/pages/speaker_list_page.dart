import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'speaker_detail_page.dart';
import 'add_speaker_page.dart';

class SpeakerListPage extends StatelessWidget {
  const SpeakerListPage({super.key});

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
        padding: const EdgeInsets.all(16),
        itemCount: appState.speakers.length,
        itemBuilder: (context, index) {
          final speaker = appState.speakers[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: ListTile(
              leading: Text(
                speaker.emoji,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              title: Text(
                speaker.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                speaker.type,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
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
        tooltip: 'Add speaker',
        child: const Icon(Icons.add),
      ),
    );
  }
}
