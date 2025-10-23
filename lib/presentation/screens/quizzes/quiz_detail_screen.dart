import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/services/test_session_service.dart';
import '../../widgets/markdown_with_latex.dart';
import 'package:intl/intl.dart';

class QuizDetailScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
  });

  @override
  ConsumerState<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends ConsumerState<QuizDetailScreen> {
  QuizModel? _quiz;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuizDetails();
  }

  Future<void> _loadQuizDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final quiz = await QuizService.getQuizById(widget.quizId);
      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startQuiz() {
    if (_quiz == null) return;

    // Show mode selection dialog with options
    showDialog(
      context: context,
      builder: (context) => _TestModeDialog(quiz: _quiz!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load quiz',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadQuizDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _quiz == null
                  ? const Center(child: Text('Quiz not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cover Image
                          if (_quiz!.coverImage != null && _quiz!.coverImage!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _quiz!.coverImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.quiz, size: 64, color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            _quiz!.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(
                                Icons.book_outlined,
                                _quiz!.subject,
                                Colors.blue,
                              ),
                              _buildInfoChip(
                                Icons.language,
                                _quiz!.language,
                                Colors.green,
                              ),
                              _buildInfoChip(
                                Icons.quiz_outlined,
                                '${_quiz!.totalQuestions} Questions',
                                Colors.purple,
                              ),
                              if (_quiz!.exam != null && _quiz!.exam!.isNotEmpty)
                                _buildInfoChip(
                                  Icons.school_outlined,
                                  _quiz!.exam!,
                                  Colors.orange,
                                ),
                              if (_quiz!.accessLevel == 'premium')
                                _buildInfoChip(
                                  Icons.star,
                                  'Premium',
                                  Colors.amber,
                                ),
                              if (_quiz!.verified)
                                _buildInfoChip(
                                  Icons.verified,
                                  'Verified',
                                  Colors.teal,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Description
                          if (_quiz!.description != null && _quiz!.description!.isNotEmpty) ...[
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            MarkdownWithLatex(
                              data: _quiz!.description!,
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Quiz Info
                          Text(
                            'Quiz Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          _buildInfoRow(
                            Icons.psychology,
                            'Mode',
                            _quiz!.mode == 'exam' ? 'Exam Mode' : 'Practice Mode',
                          ),
                          if (_quiz!.timeDuration != null)
                            _buildInfoRow(
                              Icons.timer,
                              'Duration',
                              '${_quiz!.timeDuration} minutes',
                            ),
                          _buildInfoRow(
                            Icons.person_outline,
                            'Creator',
                            _quiz!.createdByName.isNotEmpty
                                ? _quiz!.createdByName
                                : _quiz!.createdByEmail,
                          ),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Created',
                            DateFormat('MMM dd, yyyy').format(_quiz!.createdAt),
                          ),
                          _buildInfoRow(
                            Icons.play_circle_outline,
                            'Attempts',
                            '${_quiz!.testSessionsTaken}',
                          ),

                          // Tags
                          if (_quiz!.tags.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Tags',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _quiz!.tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
      bottomNavigationBar: _quiz != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _startQuiz,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Start Quiz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Test Mode Dialog with options - matches frontend exactly
class _TestModeDialog extends StatefulWidget {
  final QuizModel quiz;

  const _TestModeDialog({required this.quiz});

  @override
  State<_TestModeDialog> createState() => _TestModeDialogState();
}

class _TestModeDialogState extends State<_TestModeDialog> {
  bool _timingEnabled = false;
  String _timingMode = 'per-question'; // 'per-question' or 'total'
  int _secondsPerQuestion = 10;
  int _totalTimeMinutes = 60;
  bool _shareWithCreator = false;
  bool _randomizeQuestions = true;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Quiz'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timing Options Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timed/Untimed checkbox
                  CheckboxListTile(
                    value: _timingEnabled,
                    onChanged: (value) => setState(() => _timingEnabled = value ?? false),
                    title: const Text('Enable Timer'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  if (_timingEnabled) ...[
                    const SizedBox(height: 8),

                    // Timing mode selection
                    RadioListTile<String>(
                      value: 'per-question',
                      groupValue: _timingMode,
                      onChanged: (value) => setState(() => _timingMode = value!),
                      title: const Text('Per-question timing'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_timingMode == 'per-question')
                      Padding(
                        padding: const EdgeInsets.only(left: 32, bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Seconds per question',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(text: _secondsPerQuestion.toString())
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(offset: _secondsPerQuestion.toString().length),
                                  ),
                                onChanged: (value) {
                                  setState(() {
                                    _secondsPerQuestion = int.tryParse(value) ?? 10;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    RadioListTile<String>(
                      value: 'total',
                      groupValue: _timingMode,
                      onChanged: (value) => setState(() => _timingMode = value!),
                      title: const Text('Total test time'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_timingMode == 'total')
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Total minutes',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(text: _totalTimeMinutes.toString())
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(offset: _totalTimeMinutes.toString().length),
                                  ),
                                onChanged: (value) {
                                  setState(() {
                                    _totalTimeMinutes = int.tryParse(value) ?? 60;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share with Creator Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: CheckboxListTile(
                value: _shareWithCreator,
                onChanged: (value) => setState(() => _shareWithCreator = value ?? false),
                title: const Text('Share results with creator'),
                subtitle: const Text(
                  'Creator will receive detailed analytics about your performance',
                  style: TextStyle(fontSize: 11),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 16),

            // Randomize Questions Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: CheckboxListTile(
                value: _randomizeQuestions,
                onChanged: (value) => setState(() => _randomizeQuestions = value ?? false),
                title: const Text('Randomize answer options'),
                subtitle: const Text(
                  'Shuffle the order of answer choices',
                  style: TextStyle(fontSize: 11),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _startTest,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start Quiz'),
        ),
      ],
    );
  }

  Future<void> _startTest() async {
    setState(() {
      _isCreating = true;
    });

    try {
      // Calculate mode and timing parameters
      String mode = 'untimed';
      int secondsPerQuestion = 0;
      int timeCapSeconds = 0;

      if (_timingEnabled) {
        if (_timingMode == 'per-question') {
          mode = 'q_timed';
          secondsPerQuestion = _secondsPerQuestion;
        } else {
          mode = 't_timed';
          timeCapSeconds = _totalTimeMinutes * 60;
        }
      }

      // Start the test session
      final sessionId = await TestSessionService.startTestSession(
        questionSetId: widget.quiz.id,
        randomizeQuestions: _randomizeQuestions,
        mode: mode,
        secondsPerQuestion: secondsPerQuestion,
        timeCapSeconds: timeCapSeconds,
        shareWithCreator: _shareWithCreator,
      );

      if (!context.mounted) return;

      Navigator.pop(context);
      Navigator.pushNamed(
        context,
        '/test-session',
        arguments: {
          'sessionId': sessionId,
        },
      );
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start quiz: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
