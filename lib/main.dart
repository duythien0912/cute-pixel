import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widget_helper.dart';
import 'ai_service.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cute Pixel',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF2D2D44),
        fontFamily: 'monospace',
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int gridSize = 16;

  List<List<Color>> pixels = List.generate(
    gridSize,
    (_) => List.generate(gridSize, (_) => Colors.white),
  );
  final _controller = TextEditingController();
  bool _isLoading = false;
  final List<String> _logs = [];
  AIModel _selectedModel = AIModel.groq;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _isEmpty = _controller.text.trim().isEmpty);
    });
  }

  Future<void> _generatePixelArt(String prompt) async {
    setState(() => _isLoading = true);
    final startTime = DateTime.now();

    try {
      final result = await AIService.generate(_selectedModel, prompt, gridSize);
      final duration = DateTime.now().difference(startTime);

      setState(() {
        pixels = result;
        _logs.insert(
          0,
          '[${DateTime.now().toString().substring(11, 19)}] '
          '${_selectedModel.name.toUpperCase()} | "$prompt" | ${duration.inMilliseconds}ms',
        );
      });

      WidgetHelper.updateWidget(pixels);
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      await Clipboard.setData(ClipboardData(text: errorMsg));
      setState(() {
        _logs.insert(
          0,
          '[${DateTime.now().toString().substring(11, 19)}] ERROR: $errorMsg',
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          backgroundColor: const Color(0xFF2D2D44),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      body: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24).copyWith(),
        margin: EdgeInsets.only(top: 48),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF5B5B7E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3D3D5C), width: 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9BBC0F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0F380F),
                      width: 0,
                    ),
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                        ),
                        itemCount: gridSize * gridSize,
                        itemBuilder: (context, index) {
                          int row = index ~/ gridSize;
                          int col = index % gridSize;
                          return Container(
                            decoration: BoxDecoration(
                              color: pixels[row][col],
                              border: Border.all(
                                color: Colors.black.withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D5C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<AIModel>(
                              segments: const [
                                ButtonSegment(
                                  value: AIModel.groq,
                                  label: Text('Groq'),
                                ),
                                ButtonSegment(
                                  value: AIModel.gemini,
                                  label: Text('Gemini'),
                                ),
                              ],
                              selected: {_selectedModel},
                              onSelectionChanged: (Set<AIModel> selected) {
                                setState(() => _selectedModel = selected.first);
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? const Color(0xFF9BBC0F)
                                      : const Color(0xFF2D2D44),
                                ),
                                foregroundColor: WidgetStateProperty.resolveWith(
                                  (states) => states.contains(WidgetState.selected)
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        onSubmitted: _isLoading || _isEmpty
                            ? null
                            : (v) => _generatePixelArt(v),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'cat, heart, tree...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2D2D44),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _isLoading || _isEmpty
                            ? null
                            : () => _generatePixelArt(_controller.text),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isLoading || _isEmpty
                                ? const Color(0xFF666666)
                                : const Color(0xFFD84654),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _isLoading || _isEmpty
                                  ? const Color(0xFF444444)
                                  : const Color(0xFF8B2E39),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'GENERATE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
