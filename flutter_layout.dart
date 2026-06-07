import 'package:flutter/material.dart';

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
          titleLarge: TextStyle(color: Color(0xFFE8D5B0), fontWeight: FontWeight.bold),
        ),
      ),
      home: const RoboMunchHomePage(),
    );
  }
}

class RoboMunchHomePage extends StatelessWidget {
  const RoboMunchHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildArtStudioPanel(context)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildChatStudioPanel(context)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1A08),
              borderRadius: BorderRadius.circular(16),
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
              Text('ROBO',
                  style: TextStyle(
                    color: Color(0xFFE8D5B0),
                    fontSize: 34,
                    letterSpacing: 3,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                  )),
              Text('MUNCH',
                  style: TextStyle(
                    color: Color(0xFFC8651A),
                    fontSize: 34,
                    letterSpacing: 3,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtStudioPanel(BuildContext context) {
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
          _buildSectionTitle('ART STUDIO'),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF110A02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8651A), width: 2),
              ),
              child: const Center(
                child: Text(
                  'Image Output',
                  style: TextStyle(color: Color(0xFFE8D5B0), fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField('Type your prompt here.'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8651A),
                foregroundColor: const Color(0xFFFFF8F0),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {},
              child: const Text('🎨 Paint', style: TextStyle(letterSpacing: 0.08)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatStudioPanel(BuildContext context) {
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
          _buildSectionTitle('CHAT STUDIO'),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF110A02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8651A), width: 2),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _ChatBubble(text: 'Welcome to RoboMunch!', isSender: false),
                  SizedBox(height: 12),
                  _ChatBubble(text: 'Ask me for an image or transcribe audio.', isSender: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFC8651A),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white, size: 22),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField('Type your message here.')),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8651A),
                  foregroundColor: const Color(0xFFFFF8F0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: const Text('✉️ Send', style: TextStyle(letterSpacing: 0.08)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE8D5B0),
            fontSize: 18,
            letterSpacing: 0.15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: const Color(0xFFC8651A),
        ),
      ],
    );
  }

  Widget _buildInputField(String placeholder) {
    return TextField(
      style: const TextStyle(color: Color(0xFFF0DFC0)),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Color(0xFF8A6040)),
        filled: true,
        fillColor: const Color(0xFF2E1C08),
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
      minLines: 1,
      maxLines: 3,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;

  const _ChatBubble({required this.text, required this.isSender});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: isSender ? const Color(0xFFC8651A) : const Color(0xFF221508),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC8651A)),
        ),
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFFF0DFC0)),
        ),
      ),
    );
  }
}
