import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'api.dart';

void main() => runApp(const MeetingApp());

class MeetingApp extends StatelessWidget {
  const MeetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPAScribe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B5BDB),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Meeting {
  Meeting({
    required this.title,
    required this.date,
    required this.duration,
    required this.audioPath,
  });

  final String title;
  final DateTime date;
  final Duration duration;
  final String audioPath;
  String? transcript;
}

String formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
}

// ---------------------------------------------------------------- Home

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Meeting> _meetings = [];

  Future<void> _newMeeting() async {
    final result = await Navigator.of(context).push<Meeting>(
      MaterialPageRoute(builder: (_) => const RecordingScreen()),
    );
    if (result != null) {
      setState(() => _meetings.insert(0, result));
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SummaryScreen(meeting: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon.png', width: 32, height: 32),
            ),
            const SizedBox(width: 10),
            const Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: 'RPA',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(
                    text: 'Scribe',
                    style: TextStyle(color: Color(0xFF185FA5))),
              ]),
            ),
          ],
        ),
      ),
      body: _meetings.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Start your first meeting. Tap the button below to record.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _meetings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = _meetings[i];
                return Card(
                  child: ListTile(
                    title: Text(m.title),
                    subtitle:
                        Text('${formatDate(m.date)} · ${formatDuration(m.duration)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => SummaryScreen(meeting: m)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newMeeting,
        icon: const Icon(Icons.add),
        label: const Text('New meeting'),
      ),
    );
  }
}

// ----------------------------------------------------------- Recording

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final DateTime _startedAt = DateTime.now();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _paused = false;
  bool _ready = false;
  String? _path;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _error = 'Microphone access is needed to record.');
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      _path =
          '${dir.path}/meeting_${_startedAt.millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 32000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _path!,
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_paused) setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() => _ready = true);
    } catch (e) {
      setState(() => _error = 'Couldn\'t start recording. Try again.');
    }
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await _recorder.resume();
    } else {
      await _recorder.pause();
    }
    setState(() => _paused = !_paused);
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _recorder.stop() ?? _path;
    if (!mounted) return;
    if (path == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(
      Meeting(
        title: 'Meeting ${formatDate(_startedAt)}',
        date: _startedAt,
        duration: _elapsed,
        audioPath: path,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recording')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _error != null
            ? Center(child: Text(_error!, textAlign: TextAlign.center))
            : Column(
                children: [
                  const Text(
                    'Place the phone in the middle of the table.',
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _paused
                          ? scheme.surfaceContainerHighest
                          : scheme.errorContainer,
                    ),
                    child: Icon(
                      _paused ? Icons.pause : Icons.mic,
                      size: 56,
                      color: _paused ? scheme.outline : scheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    formatDuration(_elapsed),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _ready ? _togglePause : null,
                          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                          label: Text(_paused ? 'Resume' : 'Pause'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _ready ? _stop : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ------------------------------------------------------------- Summary

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.meeting});

  final Meeting meeting;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _loading = false;
  String? _error;

  // Placeholder content. In step 3 this comes from the Claude API.
  static const Map<String, String> _sample = {
    'Main topics': 'Summary will appear here after AI is connected.',
    'Projects and scenarios': '—',
    'RPA tasks': '—',
    'Innovation ideas': '—',
    'Decisions': '—',
    'Action items': '—',
  };

  @override
  void initState() {
    super.initState();
    if (widget.meeting.transcript == null) _transcribe();
  }

  Future<void> _transcribe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final text = await transcribeAudio(widget.meeting.audioPath);
      widget.meeting.transcript = text;
    } catch (e) {
      _error = 'Couldn\'t transcribe this recording. Check your connection and try again.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: () {
              // Step 4: build a PDF and open the share sheet.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing comes in step 4')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(meeting.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${formatDate(meeting.date)} · ${formatDuration(meeting.duration)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final entry in _sample.entries) ...[
            Text(
              entry.key,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(entry.value),
            const SizedBox(height: 16),
          ],
          const Divider(),
          const SizedBox(height: 8),
          Text('Transcript', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loading)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Transcribing…'),
              ],
            )
          else if (_error != null) ...[
            Text(_error!),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _transcribe, child: const Text('Try again')),
          ] else
            SelectableText(
              (meeting.transcript ?? '').isEmpty
                  ? 'No speech detected.'
                  : meeting.transcript!,
            ),
        ],
      ),
    );
  }
}
