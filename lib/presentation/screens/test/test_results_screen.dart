import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../core/models/question_model.dart';
import '../../../core/services/test_session_service.dart';
import '../../widgets/markdown_with_latex.dart';

class TestResultsScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? initialResults;

  const TestResultsScreen({
    super.key,
    required this.sessionId,
    this.initialResults,
  });

  @override
  ConsumerState<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends ConsumerState<TestResultsScreen> {
  Map<String, dynamic>? _results;
  bool _isLoading = true;
  String? _error;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadResults();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    if (widget.initialResults != null) {
      setState(() {
        _results = widget.initialResults;
        _isLoading = false;
      });
      _checkAndShowConfetti();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the test session to get results
      final session = await TestSessionService.resumeTestSession(widget.sessionId);
      // For now, just show a basic view - results will be passed from submit
      setState(() {
        _results = {
          'score': 0,
          'total_marks': 0,
          'percentage': 0,
          'correct_count': 0,
          'incorrect_count': 0,
          'unanswered_count': 0,
          'total_questions': session.totalQuestions,
          'question_results': [],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _checkAndShowConfetti() {
    if (_results == null) return;

    final percentage = (_results!['percentage'] as num?)?.toDouble() ?? 0.0;
    if (percentage >= 75.0) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        // Navigate to home when back button is pressed
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test Results'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load results',
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
                              onPressed: _loadResults,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _results == null
                        ? const Center(child: Text('No results found'))
                        : _buildResultsContent(),

            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent() {
    final score = (_results!['score'] as num?)?.toDouble() ?? 0.0;
    final totalMarks = (_results!['total_marks'] as num?)?.toDouble() ?? 0.0;
    final percentage = (_results!['percentage'] as num?)?.toDouble() ?? 0.0;
    final correctCount = (_results!['correct_count'] as int?) ?? 0;
    final incorrectCount = (_results!['incorrect_count'] as int?) ?? 0;
    final unansweredCount = (_results!['unanswered_count'] as int?) ?? 0;
    final totalQuestions = (_results!['total_questions'] as int?) ?? 0;
    final timeTaken = _results!['time_taken'] as String?;
    final questionResults = _results!['question_results'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(percentage),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${score.toStringAsFixed(1)} / ${totalMarks.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getPerformanceText(percentage),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Correct',
                  correctCount.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Incorrect',
                  incorrectCount.toString(),
                  Colors.red,
                  Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Skipped',
                  unansweredCount.toString(),
                  Colors.grey,
                  Icons.remove_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Additional Info
          _buildInfoRow(Icons.quiz, 'Total Questions', totalQuestions.toString()),
          if (timeTaken != null) _buildInfoRow(Icons.timer, 'Time Taken', timeTaken),
          const SizedBox(height: 32),

          // Question-wise Results Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question-wise Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$correctCount/$totalQuestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Results List
          ...questionResults.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value as Map<String, dynamic>;
            return _buildQuestionResultCard(index + 1, result);
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResultCard(int questionNumber, Map<String, dynamic> result) {
    final isCorrect = result['is_correct'] as bool? ?? false;
    final question = result['question'] as Map<String, dynamic>?;
    final selectedOptions = (result['selected_options'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        [];
    final correctOptions = (question?['correct_options'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        [];

    if (question == null) return const SizedBox.shrink();

    final questionModel = QuestionModel.fromJson(question);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withValues(alpha: 0.1)
                : selectedOptions.isEmpty
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isCorrect
                  ? Icons.check
                  : selectedOptions.isEmpty
                      ? Icons.remove
                      : Icons.close,
              color: isCorrect
                  ? Colors.green
                  : selectedOptions.isEmpty
                      ? Colors.grey
                      : Colors.red,
            ),
          ),
        ),
        title: Text(
          'Question $questionNumber',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isCorrect
              ? 'Correct (+${questionModel.marks})'
              : selectedOptions.isEmpty
                  ? 'Skipped (0)'
                  : 'Incorrect${questionModel.negativeMarks != null ? ' (${questionModel.negativeMarks})' : ' (0)'}',
          style: TextStyle(
            color: isCorrect
                ? Colors.green
                : selectedOptions.isEmpty
                    ? Colors.grey
                    : Colors.red,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Statement
                MarkdownWithLatex(
                  data: questionModel.statement,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Options
                ...List.generate(questionModel.options.length, (index) {
                  final isSelected = selectedOptions.contains(index);
                  final isCorrectOption = correctOptions.contains(index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrectOption
                          ? Colors.green.withValues(alpha: 0.1)
                          : isSelected
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.transparent,
                      border: Border.all(
                        color: isCorrectOption
                            ? Colors.green
                            : isSelected
                                ? Colors.red
                                : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (isCorrectOption)
                          const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        else if (isSelected)
                          const Icon(Icons.cancel, color: Colors.red, size: 20)
                        else
                          Icon(Icons.circle_outlined, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MarkdownWithLatex(
                            data: questionModel.options[index],
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Explanation
                if (questionModel.explanation != null &&
                    questionModel.explanation!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Explanation',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MarkdownWithLatex(
                          data: questionModel.explanation!,
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(double percentage) {
    if (percentage >= 75) {
      return [Colors.green, Colors.green[700]!];
    } else if (percentage >= 50) {
      return [Colors.orange, Colors.orange[700]!];
    } else {
      return [Colors.red, Colors.red[700]!];
    }
  }

  String _getPerformanceText(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding!';
    } else if (percentage >= 75) {
      return 'Excellent!';
    } else if (percentage >= 60) {
      return 'Good Job!';
    } else if (percentage >= 50) {
      return 'Keep Practicing!';
    } else {
      return 'Need More Practice';
    }
  }
}
