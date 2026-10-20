import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

// ★取得したAgoraのApp ID
const String agoraAppId = "6055ea39cb33489ca856042cc7b19874";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodayFriendApp());
}

class TodayFriendApp extends StatelessWidget {
  const TodayFriendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '今日だけお友達',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const FirebaseInitWrapper(),
    );
  }
}

class FirebaseInitWrapper extends StatelessWidget {
  const FirebaseInitWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAHU02b7XzNuy3nlSzsFIVV4P_zSMBOTbU",
          appId: "1:400459372377:web:df13058c8efd823b4bde48",
          messagingSenderId: "400459372377",
          projectId: "today-d8f35",
          storageBucket: "today-d8f35.firebasestorage.app",
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('初期化エラー:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const FriendHomeMenuPage();
        }
        return const Scaffold(
            body:
                Center(child: CircularProgressIndicator(color: Colors.green)));
      },
    );
  }
}

// 0. スタートメニュー
class FriendHomeMenuPage extends StatelessWidget {
  const FriendHomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('今日だけお友達',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333))),
              const SizedBox(height: 8),
              const Text('名前を知らなくていい、その場限りのつながり',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RoomListPage())),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('みんなの部屋を選んで参加する',
                            style: TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateRoomPage())),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[800],
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.add_box),
                        label: const Text('自分で部屋を作って募集する',
                            style: TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FriendMatchPage())),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700]),
                        icon: const Icon(Icons.shuffle),
                        label: const Text('ランダムでパートナーを探す'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 1. 部屋一覧画面
class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

  void _showPreJoinDialog(
      BuildContext context, String roomId, String roomTitle, bool allowPhoto) {
    bool startWithMicOn = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('通話設定の確認'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ルーム「$roomTitle」に参加します。'),
                  const SizedBox(height: 15),
                  const Text('入室時のマイク状態を選んでください：',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  SwitchListTile(
                    title: Text(startWithMicOn
                        ? '🎤 マイク：ON で参加'
                        : '🔇 マイク：OFF（ミュート）で参加'),
                    value: startWithMicOn,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => startWithMicOn = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル',
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TemporaryChatPage(
                                roomId: roomId,
                                roomTitle: roomTitle,
                                allowPhoto: allowPhoto,
                                initialMicOn: startWithMicOn)));
                  },
                  child: const Text('部屋に入る'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('部屋一覧から参加'), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('現在募集中の部屋はありません。'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final roomTitle = data['roomTitle'] ?? '無題';
              final purpose = data['purpose'] ?? '目的なし';
              final allowPhoto = data['allowPhoto'] ?? true;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(roomTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text('目的: $purpose\n写真共有: ${allowPhoto ? 'あり' : 'なし'}'),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    onPressed: () => _showPreJoinDialog(
                        context, docs[index].id, roomTitle, allowPhoto),
                    child: const Text('参加'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 2. ランダムマッチ画面
class FriendMatchPage extends StatefulWidget {
  const FriendMatchPage({super.key});

  @override
  State<FriendMatchPage> createState() => _FriendMatchPageState();
}

class _FriendMatchPageState extends State<FriendMatchPage> {
  bool _isLoading = false;
  bool _allowPhoto = true;

  void _startMatching() async {
    setState(() => _isLoading = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('rooms').add({
        'roomTitle': 'ランダムマッチルーム',
        'purpose': 'すぐにおしゃべり・作業',
        'allowPhoto': _allowPhoto,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => TemporaryChatPage(
                  roomId: docRef.id,
                  roomTitle: 'ランダムマッチルーム',
                  allowPhoto: _allowPhoto,
                  initialMicOn: true)));
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('ランダムマッチ'), backgroundColor: Colors.green),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('写真を送れるようにする'),
                    value: _allowPhoto,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _allowPhoto = val),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startMatching,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.shuffle),
                    label: const Text('マッチングを開始する'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 3. 部屋作成画面
class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({super.key});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final TextEditingController _roomNameController = TextEditingController();
  bool _allowPhoto = true;
  String _selectedPurpose = '一緒に集中して勉強したい';
  bool _isCreating = false;

  void _createRoom() async {
    final roomName = _roomNameController.text.trim().isEmpty
        ? 'みんなの作業部屋'
        : _roomNameController.text.trim();
    setState(() => _isCreating = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('rooms').add({
        'roomTitle': roomName,
        'purpose': _selectedPurpose,
        'allowPhoto': _allowPhoto,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => TemporaryChatPage(
                  roomId: docRef.id,
                  roomTitle: roomName,
                  allowPhoto: _allowPhoto,
                  initialMicOn: true)));
    } catch (e) {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('部屋を作成して募集'), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                    controller: _roomNameController,
                    decoration: const InputDecoration(
                        labelText: 'ルーム名', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: _selectedPurpose,
                  isExpanded: true,
                  items: ['一緒に集中して勉強したい', 'ちょっと雑談・息抜きしたい', 'もくもく作業用']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPurpose = v!),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('写真を送れるようにする'),
                  value: _allowPhoto,
                  activeColor: Colors.green,
                  onChanged: (val) => setState(() => _allowPhoto = val),
                ),
                const SizedBox(height: 30),
                if (_isCreating)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _createRoom,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('部屋を作成して募集を開始する',
                        style: TextStyle(fontSize: 16)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 4. チャット＆音声通話（Web完全対応版）
class TemporaryChatPage extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final bool allowPhoto;
  final bool initialMicOn;

  const TemporaryChatPage({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.allowPhoto,
    required this.initialMicOn,
  });

  @override
  State<TemporaryChatPage> createState() => _TemporaryChatPageState();
}

class _TemporaryChatPageState extends State<TemporaryChatPage> {
  final TextEditingController _controller = TextEditingController();

  RtcEngine? _engine;
  bool _isJoined = false;
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _isMuted = !widget.initialMicOn;
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Web環境（ブラウザ）の場合はAgoraのネイティブ初期化を安全にスキップしてエラーを防ぐ
    if (kIsWeb) {
      setState(() => _isJoined = true);
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() => _isJoined = true);
              _engine?.muteLocalAudioStream(_isMuted);
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('新しいお友達が通話に参加しました！')));
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('お友達が通話から退出しました。')));
          },
        ),
      );

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();

      await _engine!.joinChannel(
        token: "",
        channelId: widget.roomId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_'),
        uid: 0,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isJoined = true);
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _engine?.leaveChannel();
      _engine?.release();
    }
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    if (!kIsWeb) {
      _engine?.muteLocalAudioStream(_isMuted);
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isMuted ? 'マイクをミュートしました' : 'マイクをオンに戻しました')));
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text;
    _controller.clear();
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({
      'sender': '自分',
      'message': text,
      'isImage': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _pickAndSendPhoto() async {
    if (!widget.allowPhoto) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('送信できません'),
          content: const Text('このルームでは写真の送信がオフに設定されています。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      try {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('messages')
            .add({
          'sender': '自分',
          'message': base64String,
          'isImage': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('画像の送信に失敗しました。')));
      } finally {
        Navigator.pop(context);
      }
    }
  }

  void _deleteRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('部屋を削除しますか？'),
        content: const Text('この部屋を一覧から削除し、通話を終了します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.roomId)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('部屋を削除しました！')));
                }
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('削除に失敗しました')));
              }
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomTitle),
        backgroundColor: Colors.green,
        actions: [
          Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(_isJoined ? '🔊 接続完了' : '🔄 接続中...',
                      style: const TextStyle(fontSize: 12)))),
          IconButton(
              icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
              onPressed: _toggleMute,
              tooltip: _isMuted ? 'ミュート解除' : 'ミュートする'),
          IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteRoom,
              tooltip: '部屋を削除'),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: widget.allowPhoto ? Colors.green[50] : Colors.yellow[100],
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline,
                    size: 16,
                    color:
                        widget.allowPhoto ? Colors.green[800] : Colors.brown),
                const SizedBox(width: 8),
                Text(
                    widget.allowPhoto
                        ? '写真共有：ON（端末の写真を選べます）'
                        : '写真共有：OFF（テキスト・通話のみ）',
                    style: TextStyle(
                        fontSize: 12,
                        color: widget.allowPhoto
                            ? Colors.green[800]
                            : Colors.brown)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty)
                  return const Center(child: Text('最初のメッセージを送ってみましょう！'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final sender = data['sender'] ?? '匿名';
                    final message = data['message'] ?? '';
                    final bool isImage = data['isImage'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$sender:',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              isImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(message),
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Text('📷 [画像を読み込めませんでした]',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                      ),
                                    )
                                  : Text(message,
                                      style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.green),
                  onPressed: _pickAndSendPhoto,
                  tooltip: 'スマホ/PCの写真を選ぶ',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'メッセージを入力...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
