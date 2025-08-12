import 'package:agora_signaling/broadcast_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _requestPermissionIfNeed().then((_) {}).catchError((error) {
      debugPrint("Error requesting permissions: $error");
    });
  }

  Future<void> _requestPermissionIfNeed() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [
        Permission.audio,
        Permission.microphone,
        Permission.camera,
      ].request();
    }
  }

  Future<void> onJoin({bool isBroadcaster = false}) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BroadcastPage(isBroadcaster: isBroadcaster),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora Broadcasting Home Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                onJoin(isBroadcaster: true);
              },
              child: Text("Broadcast"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                onJoin(isBroadcaster: false);
              },
              child: Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
}
