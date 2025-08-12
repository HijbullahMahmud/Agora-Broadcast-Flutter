import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_signaling/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class BroadcastPage extends StatefulWidget {
  final bool isBroadcaster;
  const BroadcastPage({super.key, this.isBroadcaster = false});

  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  final _users = <int>[];
  late final RtcEngine _engine;
  bool muted = false;
  int? streamId;
  late final RtcEngineEventHandler _rtcEngineEventHandler;

  bool hasInitialized = false;

  @override
  void dispose() {
    disposeEngine();
    super.dispose();
  }

  disposeEngine() {
    _engine.unregisterEventHandler(_rtcEngineEventHandler);
    // clear users
    _users.clear();
    // destroy sdk and leave channel
    _cleanup();
  }

  Future<void> _cleanup() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionIfNeed()
        .then((_) async {
          await initializeAgora();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              hasInitialized = true;
            });
          });
        })
        .catchError((error) {
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

  Future<void> initializeAgora() async {
    await _initAgoraRtcEngine();

    if (widget.isBroadcaster) {
      streamId = await _engine.createDataStream(
        DataStreamConfig(syncWithAudio: true, ordered: true),
      );
    }

    _rtcEngineEventHandler = RtcEngineEventHandler(
      onError: (err, msg) {
        print('onError: $err, msg: $msg');
        setState(() {});
      },
      onJoinChannelSuccess: (connection, elapsed) {
        print(
          'onJoinChannelSuccess: ${connection.channelId}, uid: ${connection.localUid}, elapsed: $elapsed',
        );
        setState(() {});
      },
      onLeaveChannel: (connection, stats) {
        print('onLeaveChannel: ${connection.channelId}, stats: $stats');
        setState(() {
          _users.clear();
        });
      },
      onUserJoined: (connection, rUID, elapsed) {
        print(
          'onUserJoined: ${connection.channelId}, uid: $rUID, elapsed: $elapsed',
        );
        setState(() {
          _users.add(rUID);
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        print(
          'onUserOffline: ${connection.channelId}, uid: $remoteUid, reason: $reason',
        );
        if (mounted && widget.isBroadcaster) {
          setState(() {
            _users.remove(remoteUid);
          });
        }
        if (!widget.isBroadcaster) {
           _engine.unregisterEventHandler(_rtcEngineEventHandler);
          // clear users
          _users.clear();
          // destroy sdk and leave channel
          _cleanup();
          Navigator.pop(context);
        }
      },

      onStreamMessage: (connection, remoteUid, streamId, data, length, sentTs) {
        final String info = "here is the message ${connection.toString()}";
        print(info);
      },

      onStreamMessageError:
          (connection, remoteUid, streamId, code, missed, cached) {
            final String info = "here is the error $streamId";
            print(info);
          },
    );
    _engine.registerEventHandler(_rtcEngineEventHandler);

    await _engine.joinChannel(
      token: Config.token,
      channelId: Config.channelName,
      uid: 0,
      options: ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: widget.isBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      ),
    );
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: Config.appId));

    await _engine.enableVideo();

    await _engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    if (widget.isBroadcaster) {
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !hasInitialized
            ? CircularProgressIndicator()
            : Stack(children: <Widget>[_broadcastView(), _toolbar()]),
      ),
    );
  }

  Widget _toolbar() {
    return widget.isBroadcaster
        ? Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RawMaterialButton(
                  onPressed: _onToggleMute,
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
                RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  child: Icon(Icons.call_end, color: Colors.white, size: 35.0),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.redAccent,
                  padding: const EdgeInsets.all(15.0),
                ),
                RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  child: Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                ),
              ],
            ),
          )
        : Container();
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.isBroadcaster) {
      list.add(
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: VideoCanvas(
              uid: 0,
              renderMode: RenderModeType.renderModeHidden,
            ),
          ),
        ),
      );
    }
    _users.forEach(
      (int uid) => list.add(
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: Config.channelName),
          ),
        ),
      ),
    );
    return list;
  }

  /// Video view row wrapper
  Widget _expandedVideoView(List<Widget> views) {
    final wrappedViews = views
        .map<Widget>((view) => Expanded(child: Container(child: view)))
        .toList();
    return Expanded(child: Row(children: wrappedViews));
  }

  /// Video layout wrapper
  Widget _broadcastView() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView([views[0]]),
            ],
          ),
        );
      case 2:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView([views[0]]),
              _expandedVideoView([views[1]]),
            ],
          ),
        );
      case 3:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView(views.sublist(0, 2)),
              _expandedVideoView(views.sublist(2, 3)),
            ],
          ),
        );
      case 4:
        return Container(
          child: Column(
            children: <Widget>[
              _expandedVideoView(views.sublist(0, 2)),
              _expandedVideoView(views.sublist(2, 4)),
            ],
          ),
        );
      default:
    }
    return Container();
  }

  void _onCallEnd(BuildContext context) {
    disposeEngine();
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    if (streamId != null) {
      // _engine.sendStreamMessage(streamId: streamId!, data: data, length: length)
      _engine.switchCamera();
    }
    // _engine?.sendStreamMessage(streamId, "mute user blet");
    //_engine.switchCamera();
  }
}
