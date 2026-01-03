import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/volume.dart';
import 'package:ueberboese_app/models/now_playing.dart';

class SpeakerWebsocketService {
  final String ipAddress;
  WebSocketChannel? _channel;
  final _volumeController = StreamController<Volume>.broadcast();
  final _nowPlayingController = StreamController<NowPlaying>.broadcast();
  StreamSubscription<dynamic>? _messageSubscription;
  bool _isConnected = false;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;

  SpeakerWebsocketService(this.ipAddress);

  Stream<Volume> get volumeStream => _volumeController.stream;
  Stream<NowPlaying> get nowPlayingStream => _nowPlayingController.stream;

  bool get isConnected => _isConnected;

  void connect() {
    if (_isDisposed) return;
    if (_isConnected) return;

    try {
      final uri = Uri.parse('ws://$ipAddress:8080');
      debugPrint('[WebSocket] Connecting to $uri');

      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;

      _messageSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      debugPrint('[WebSocket] Connected successfully to $ipAddress:8080');
    } catch (e) {
      debugPrint('[WebSocket] Connection error: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    if (_isDisposed) return;

    try {
      final messageStr = message.toString();
      debugPrint('[WebSocket] Received message: $messageStr');

      final document = XmlDocument.parse(messageStr);
      final updatesElements = document.findAllElements('updates');

      if (updatesElements.isEmpty) {
        debugPrint('[WebSocket] No <updates> element found in message');
        return;
      }

      final updatesElement = updatesElements.first;

      // Check for volume updates
      final volumeUpdatedElements = updatesElement.findElements('volumeUpdated');
      if (volumeUpdatedElements.isNotEmpty) {
        _handleVolumeUpdate(volumeUpdatedElements.first);
      }

      // Check for now playing updates
      final nowPlayingUpdatedElements = updatesElement.findElements('nowPlayingUpdated');
      if (nowPlayingUpdatedElements.isNotEmpty) {
        _handleNowPlayingUpdate(nowPlayingUpdatedElements.first);
      }

      // Check for other update types and log them
      final knownTypes = {'volumeUpdated', 'nowPlayingUpdated'};
      final childElements = updatesElement.childElements;
      for (final child in childElements) {
        if (!knownTypes.contains(child.name.local)) {
          debugPrint('[WebSocket] Unhandled update type: ${child.name.local}');
        }
      }
    } catch (e) {
      debugPrint('[WebSocket] Error parsing message: $e');
    }
  }

  void _handleVolumeUpdate(XmlElement volumeUpdatedElement) {
    try {
      final volumeElements = volumeUpdatedElement.findElements('volume');
      if (volumeElements.isEmpty) {
        debugPrint('[WebSocket] No <volume> element in volumeUpdated');
        return;
      }

      final volumeElement = volumeElements.first;

      final targetVolumeElements = volumeElement.findElements('targetvolume');
      final actualVolumeElements = volumeElement.findElements('actualvolume');
      final muteEnabledElements = volumeElement.findElements('muteenabled');

      if (targetVolumeElements.isEmpty || actualVolumeElements.isEmpty || muteEnabledElements.isEmpty) {
        debugPrint('[WebSocket] Incomplete volume data');
        return;
      }

      final targetVolume = int.parse(targetVolumeElements.first.innerText);
      final actualVolume = int.parse(actualVolumeElements.first.innerText);
      final muteEnabled = muteEnabledElements.first.innerText.toLowerCase() == 'true';

      final volume = Volume(
        targetVolume: targetVolume,
        actualVolume: actualVolume,
        muteEnabled: muteEnabled,
      );

      debugPrint('[WebSocket] Volume update: ${volume.actualVolume}%');

      if (!_volumeController.isClosed) {
        _volumeController.add(volume);
      }
    } catch (e) {
      debugPrint('[WebSocket] Error parsing volume update: $e');
    }
  }

  void _handleNowPlayingUpdate(XmlElement nowPlayingUpdatedElement) {
    try {
      final nowPlayingElements = nowPlayingUpdatedElement.findElements('nowPlaying');
      if (nowPlayingElements.isEmpty) {
        debugPrint('[WebSocket] No <nowPlaying> element in nowPlayingUpdated');
        return;
      }

      final nowPlayingElement = nowPlayingElements.first;

      // Extract optional fields
      String? track;
      final trackElements = nowPlayingElement.findElements('track');
      if (trackElements.isNotEmpty) {
        track = trackElements.first.innerText;
      }

      String? artist;
      final artistElements = nowPlayingElement.findElements('artist');
      if (artistElements.isNotEmpty) {
        artist = artistElements.first.innerText;
      }

      String? album;
      final albumElements = nowPlayingElement.findElements('album');
      if (albumElements.isNotEmpty) {
        album = albumElements.first.innerText;
      }

      String? art;
      final artElements = nowPlayingElement.findElements('art');
      if (artElements.isNotEmpty) {
        art = artElements.first.innerText;
      }

      String? artImageStatus;
      if (artElements.isNotEmpty) {
        artImageStatus = artElements.first.getAttribute('artImageStatus');
      }

      String? shuffleSetting;
      final shuffleElements = nowPlayingElement.findElements('shuffleSetting');
      if (shuffleElements.isNotEmpty) {
        shuffleSetting = shuffleElements.first.innerText;
      }

      String? repeatSetting;
      final repeatElements = nowPlayingElement.findElements('repeatSetting');
      if (repeatElements.isNotEmpty) {
        repeatSetting = repeatElements.first.innerText;
      }

      String? playStatus;
      final playStatusElements = nowPlayingElement.findElements('playStatus');
      if (playStatusElements.isNotEmpty) {
        playStatus = playStatusElements.first.innerText;
      }

      // Extract location and source from ContentItem or nowPlaying attributes
      String? location;
      String? source;

      final contentItemElements = nowPlayingElement.findElements('ContentItem');
      if (contentItemElements.isNotEmpty) {
        final contentItem = contentItemElements.first;
        location = contentItem.getAttribute('location');
        source = contentItem.getAttribute('source');
      } else {
        // Try to get from nowPlaying attributes
        source = nowPlayingElement.getAttribute('source');
      }

      final nowPlaying = NowPlaying(
        track: track,
        artist: artist,
        album: album,
        art: art,
        artImageStatus: artImageStatus,
        shuffleSetting: shuffleSetting,
        repeatSetting: repeatSetting,
        playStatus: playStatus,
        location: location,
        source: source,
      );

      debugPrint('[WebSocket] Now playing update: ${track ?? "Unknown"} - ${artist ?? "Unknown"}');

      if (!_nowPlayingController.isClosed) {
        _nowPlayingController.add(nowPlaying);
      }
    } catch (e) {
      debugPrint('[WebSocket] Error parsing now playing update: $e');
    }
  }

  void _handleError(Object error) {
    debugPrint('[WebSocket] Stream error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDone() {
    debugPrint('[WebSocket] Connection closed');
    _isConnected = false;
    if (!_isDisposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WebSocket] Max reconnect attempts reached, giving up');
      return;
    }

    _reconnectAttempts++;
    final delay = _baseReconnectDelay * _reconnectAttempts;

    debugPrint('[WebSocket] Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        debugPrint('[WebSocket] Attempting to reconnect...');
        connect();
      }
    });
  }

  void disconnect() {
    debugPrint('[WebSocket] Disconnecting...');
    _isDisposed = true;
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _volumeController.close();
    _nowPlayingController.close();
  }
}
