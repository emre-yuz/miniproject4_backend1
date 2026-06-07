import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// For local testing with an Android emulator use 10.0.2.2.
// For iOS simulators or desktop use 127.0.0.1.
// For a physical phone on the same Wi-Fi set this to your PC's local IP (for example 192.168.x.x).
const String backendBaseUrl = 'http://127.0.0.1:7860';

// Replace with the deployed cloud VM address when the cloud backend is published.
const String cloudBackendBaseUrl = 'http://127.0.0.1:8000';

void main() {
  runApp(const RoboMunchApp());
}

class RoboMunchApp extends StatelessWidget {
  const RoboMunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoboMunch',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1008),
        fontFamily: 'Georgia',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF0DFC0)),
          bodyMedium: TextStyle(color: Color(0xFFF0DFC0)),
          titleLarge: TextStyle(
            color: Color(0xFFE8D5B0),
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2E1C08),
          hintStyle: const TextStyle(color: Color(0xFF8A6040)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7A4820)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7A4820)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC8651A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const RoboMunchHomePage(),
    );
  }
}

class RoboMunchHomePage extends StatefulWidget {
  const RoboMunchHomePage({super.key});

  @override
  State<RoboMunchHomePage> createState() => _RoboMunchHomePageState();
}

class _RoboMunchHomePageState extends State<RoboMunchHomePage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Welcome to RoboMunch! Ask for an image or send a chat prompt.',
      isUser: false,
    ),
  ];
  Uint8List? _imageBytes;
  bool _isPainting = false;
  bool _isChatting = false;
  bool _isConverting = false;
  bool _speechEnabled = false;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(onStatus: (_) {}, onError: (_) {});
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      _showMessage('Speech recognition unavailable on this device.');
      return;
    }

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _chatController.text = result.recognizedWords;
          });
        }
        if (result.finalResult) {
          _speech.stop();
          _showMessage('Voice text has been captured.');
        }
      },
      listenMode: stt.ListenMode.confirmation,
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _promptController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showMessage('Enter an art prompt first.');
      return;
    }

    setState(() => _isPainting = true);
    try {
      final uri = Uri.parse('$backendBaseUrl/paint');
      final response = await http.post(uri, body: {'prompt': prompt});

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() => _imageBytes = response.bodyBytes);
      } else {
        _showMessage('Failed to generate image.');
      }
    } catch (error) {
      _showMessage('Error generating image: $error');
    } finally {
      setState(() => _isPainting = false);
    }
  }

  Future<void> _sendChatMessage() async {
    final prompt = _chatController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: prompt, isUser: true));
      _isChatting = true;
      _chatController.clear();
    });

    try {
      final uri = Uri.parse('$backendBaseUrl/chat');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt, 'history': []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = data['reply']?.toString() ?? 'No reply.';
        setState(() => _messages.add(_ChatMessage(text: reply, isUser: false)));
      } else {
        setState(() => _messages.add(const _ChatMessage(text: 'Chat request failed.', isUser: false)));
      }
    } catch (error) {
      setState(() => _messages.add(_ChatMessage(text: 'Error: $error', isUser: false)));
    } finally {
      setState(() => _isChatting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFC8651A),
    ));
  }

  Future<void> _convertImageToGrayscale() async {
    if (_imageBytes == null) {
      _showMessage('Generate an image before colorizing.');
      return;
    }
    setState(() => _isConverting = true);
    try {
      final uri = Uri.parse('$cloudBackendBaseUrl/convert/grayscale');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: 'art.png', contentType: MediaType('image', 'png')));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() => _imageBytes = response.bodyBytes);
        _showMessage('Image converted to grayscale by cloud backend.');
      } else {
        _showMessage('Cloud colorize request failed.');
      }
    } catch (error) {
      _showMessage('Error converting image: $error');
    } finally {
      setState(() => _isConverting = false);
    }
  }

  Future<void> _requestImageInfo() async {
    if (_imageBytes == null) {
      _showMessage('Generate an image to inspect resolution.');
      return;
    }

    try {
      final uri = Uri.parse('$cloudBackendBaseUrl/get/resolution');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: 'art.png', contentType: MediaType('image', 'png')));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final width = data['width'];
        final height = data['height'];
        _showMessage('Image resolution: ${width}x$height');
      } else {
        _showMessage('Failed to fetch image info.');
      }
    } catch (error) {
      _showMessage('Error fetching image info: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildArtStudio()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildChatStudio()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildArtStudio(),
                          const SizedBox(height: 16),
                          _buildChatStudio(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1A08), Color(0xFF1A1008)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFC8651A), width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1A08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC8651A), width: 3),
              image: const DecorationImage(
                image: AssetImage('assets/robomunch_logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'ROBO',
                style: TextStyle(
                  color: Color(0xFFE8D5B0),
                  fontSize: 34,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'MUNCH',
                style: TextStyle(
                  color: Color(0xFFC8651A),
                  fontSize: 34,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtStudio() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF221508),
        border: Border.all(color: const Color(0xFF5A3510)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'ART STUDIO'),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF110A02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8651A), width: 2),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Image Output',
                        style: TextStyle(color: Color(0xFFE8D5B0), fontSize: 16),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promptController,
            style: const TextStyle(color: Color(0xFFF0DFC0)),
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Type your prompt here.',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Image.asset('assets/paint_button.png', width: 22, height: 22),
                  label: const Text('Paint', style: TextStyle(letterSpacing: 0.08)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8651A),
                    foregroundColor: const Color(0xFFFFF8F0),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isPainting ? null : _generateImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isConverting ? null : _convertImageToGrayscale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C5A1A),
                    foregroundColor: const Color(0xFFFFF8F0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Colorize', style: TextStyle(letterSpacing: 0.08)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _requestImageInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A5A5A),
              foregroundColor: const Color(0xFFFFF8F0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Image Info', style: TextStyle(letterSpacing: 0.08)),
          ),
          if (_isPainting || _isConverting) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: Color(0xFFC8651A), backgroundColor: Color(0xFF3C220F)),
          ],
        ],
      ),
    );
  }

  Widget _buildChatStudio() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF221508),
        border: Border.all(color: const Color(0xFF5A3510)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'CHAT STUDIO'),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF110A02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8651A), width: 2),
              ),
              padding: const EdgeInsets.all(14),
              child: ListView.separated(
                itemCount: _messages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _ChatBubble(message: message);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8651A),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Image.asset('assets/mic_button.png', width: 20, height: 20),
                  onPressed: _startListening,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Color(0xFFF0DFC0)),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Type your message here.'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: Image.asset('assets/send_button.png', width: 20, height: 20),
                label: const Text('Send', style: TextStyle(letterSpacing: 0.08)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8651A),
                  foregroundColor: const Color(0xFFFFF8F0),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isChatting ? null : _sendChatMessage,
              ),
            ],
          ),
          if (_isChatting) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: Color(0xFFC8651A), backgroundColor: Color(0xFF3C220F)),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE8D5B0),
            fontSize: 18,
            letterSpacing: 0.15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: const Color(0xFFC8651A)),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isUser ? const Color(0xFFC8651A) : const Color(0xFF221508);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC8651A)),
        ),
        padding: const EdgeInsets.all(14),
        child: Text(
          message.text,
          style: const TextStyle(color: Color(0xFFF0DFC0)),
        ),
      ),
    );
  }
}
