import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/test_session_model.dart';
import '../../../core/models/question_model.dart';
import '../../../core/services/test_session_service.dart';
import '../../widgets/markdown_with_latex.dart';

class TestSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const TestSessionScreen({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<TestSessionScreen> createState() => _TestSessionScreenState();
}

class _TestSessionScreenState extends ConsumerState<TestSessionScreen> {
  TestSessionModel? _testSession;
  bool _isLoading = true;
  String? _error;
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadTestSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTestSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the test session
      final session = await TestSessionService.resumeTestSession(widget.sessionId);

      setState(() {
        _testSession = session;
        _isLoading = false;

        // Start timer if timed mode
        if (session.timeDuration != null && !session.finished) {
          _startTimer(session);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTimer(TestSessionModel session) {
    final totalSeconds = session.timeDuration! * 60;
    final elapsedSeconds = DateTime.now().difference(session.startedTime).inSeconds;
    _remainingSeconds = totalSeconds - elapsedSeconds;

    if (_remainingSeconds <= 0) {
      _autoSubmitTest();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _autoSubmitTest();
        }
      });
    });
  }

  Future<void> _autoSubmitTest() async {
    if (_testSession == null || _testSession!.finished) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time is up! Auto-submitting test...')),
    );

    await _submitTest();
  }

  void _saveSelection(int questionId, List<int> selectedOptions) {
    if (_testSession == null) return;

    // Update UI immediately - save selection but don't mark as answered
    setState(() {
      final updatedQuestions = _testSession!.questions.map((q) {
        if (q.id == questionId) {
          return QuestionModel(
            id: q.id,
            question: q.question,
            questionType: q.questionType,
            options: q.options,
            correctOptions: q.correctOptions,
            explanation: q.explanation,
            selectedAnswerList: selectedOptions,
            questionsTotalMark: q.questionsTotalMark,
            questionsScoredMark: q.questionsScoredMark,
            answered: q.answered, // Keep current answered status
            isCorrect: q.isCorrect, // Keep current correctness status
          );
        }
        return q;
      }).toList();

      _testSession = _testSession!.copyWith(questions: updatedQuestions);
    });
  }

  void _saveAnswer(int questionId, List<int> selectedOptions) {
    if (_testSession == null) return;

    // Update UI immediately (optimistic update)
    setState(() {
      final updatedQuestions = _testSession!.questions.map((q) {
        if (q.id == questionId) {
          // Calculate if answer is correct
          final isCorrect = _checkAnswerCorrect(selectedOptions, q.correctOptions);
          final scoredMark = isCorrect ? q.questionsTotalMark : 0.0;

          return QuestionModel(
            id: q.id,
            question: q.question,
            questionType: q.questionType,
            options: q.options,
            correctOptions: q.correctOptions,
            explanation: q.explanation,
            selectedAnswerList: selectedOptions,
            questionsTotalMark: q.questionsTotalMark,
            questionsScoredMark: scoredMark,
            answered: true, // Always mark as answered when saving
            isCorrect: isCorrect,
          );
        }
        return q;
      }).toList();

      _testSession = _testSession!.copyWith(questions: updatedQuestions);
    });

    // Fire and forget - send to backend without waiting
    TestSessionService.saveAnswer(
      sessionId: _testSession!.sessionId,
      questionId: questionId,
      selectedOptions: selectedOptions,
      currentQuestionIndex: _currentQuestionIndex,
      remainingTime: _remainingSeconds > 0 ? _remainingSeconds : null,
    ).catchError((e) {
      // Silently handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync answer'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  bool _checkAnswerCorrect(List<int> selectedOptions, List<int> correctOptions) {
    if (selectedOptions.length != correctOptions.length) return false;

    final selectedSet = Set<int>.from(selectedOptions);
    final correctSet = Set<int>.from(correctOptions);

    return selectedSet.difference(correctSet).isEmpty &&
           correctSet.difference(selectedSet).isEmpty;
  }

  void _toggleReviewMark(int questionId) {
    if (_testSession == null) return;

    setState(() {
      final updatedBookmarks = List<int>.from(_testSession!.bookmarkedQuestionIds);
      if (updatedBookmarks.contains(questionId)) {
        updatedBookmarks.remove(questionId);
      } else {
        updatedBookmarks.add(questionId);
      }
      _testSession = _testSession!.copyWith(bookmarkedQuestionIds: updatedBookmarks);
    });
  }

  Future<void> _submitTest() async {
    if (_testSession == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Answered: ${_testSession!.answeredCount}/${_testSession!.totalQuestions}'),
            Text('Unanswered: ${_testSession!.unansweredCount}'),
            if (_testSession!.markedForReviewCount > 0)
              Text('Marked for review: ${_testSession!.markedForReviewCount}'),
            const SizedBox(height: 16),
            const Text('Are you sure you want to submit?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final results = await TestSessionService.submitTestSession(_testSession!.sessionId);

      _timer?.cancel();

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/test-results',
          arguments: {
            'sessionId': _testSession!.sessionId,
            'results': results,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit test: ${e.toString()}')),
        );
      }
    }
  }

  void _showQuestionNavigator() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuestionNavigatorSheet(
        testSession: _testSession!,
        currentIndex: _currentQuestionIndex,
        onQuestionSelected: (index) {
          setState(() {
            _currentQuestionIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Test?'),
            content: const Text(
              'Your progress has been saved. You can resume this test later from your test history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_testSession?.questionSetName ?? 'Test Session'),
          actions: [
            if (_testSession?.timeDuration != null && !_testSession!.finished)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _remainingSeconds < 300
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _remainingSeconds < 300 ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: _showQuestionNavigator,
              tooltip: 'Question Navigator',
            ),
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              onPressed: _submitTest,
              tooltip: 'Finish Test',
            ),
          ],
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
                          'Failed to load test',
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
                          onPressed: _loadTestSession,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _testSession == null
                    ? const Center(child: Text('Test session not found'))
                    : Column(
                        children: [
                          // Progress indicator
                          LinearProgressIndicator(
                            value: (_currentQuestionIndex + 1) / _testSession!.totalQuestions,
                            backgroundColor: Colors.grey[200],
                          ),

                          // Question content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Statistics panel
                                  _buildStatisticsPanel(),
                                  const SizedBox(height: 16),

                                  // Question view
                                  _QuestionView(
                                question: _testSession!.questions[_currentQuestionIndex],
                                questionNumber: _currentQuestionIndex + 1,
                                totalQuestions: _testSession!.totalQuestions,
                                selectedOptions: _testSession!.getSelectedOptions(
                                  _testSession!.questions[_currentQuestionIndex].id,
                                ),
                                isMarkedForReview: _testSession!.isQuestionMarkedForReview(
                                  _testSession!.questions[_currentQuestionIndex].id,
                                ),
                                testFinished: _testSession!.finished,
                                onSelectionChanged: (selectedOptions) {
                                  _saveSelection(
                                    _testSession!.questions[_currentQuestionIndex].id,
                                    selectedOptions,
                                  );
                                },
                                onAnswerSelected: (selectedOptions) {
                                  _saveAnswer(
                                    _testSession!.questions[_currentQuestionIndex].id,
                                    selectedOptions,
                                  );
                                },
                                onToggleReviewMark: () {
                                  _toggleReviewMark(
                                    _testSession!.questions[_currentQuestionIndex].id,
                                  );
                                },
                              ),
                                ],
                              ),
                            ),
                          ),

                          // Navigation buttons
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                if (_currentQuestionIndex > 0)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentQuestionIndex--;
                                        });
                                      },
                                      child: const Text('Previous'),
                                    ),
                                  ),
                                if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                                Expanded(
                                  child: _currentQuestionIndex < _testSession!.totalQuestions - 1
                                      ? ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _currentQuestionIndex++;
                                            });
                                          },
                                          child: const Text('Next'),
                                        )
                                      : ElevatedButton(
                                          onPressed: _submitTest,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Submit Test'),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildStatisticsPanel() {
    if (_testSession == null) return const SizedBox.shrink();

    final answered = _testSession!.answeredCount;
    final total = _testSession!.totalQuestions;
    final scoredMarks = _testSession!.questions
        .where((q) => q.answered)
        .fold(0.0, (sum, q) => sum + q.questionsScoredMark);
    final accuracy = answered > 0
        ? (scoredMarks / _testSession!.questions
                .where((q) => q.answered)
                .fold(0.0, (sum, q) => sum + q.questionsTotalMark)) * 100
        : 0.0;

    // Calculate current streak (consecutive correct answers from current position backwards)
    int currentStreak = 0;
    for (int i = _currentQuestionIndex - 1; i >= 0; i--) {
      final q = _testSession!.questions[i];
      if (q.answered && q.isCorrect) {
        currentStreak++;
      } else if (q.answered) {
        break; // Break on first incorrect answer
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.check_circle_outline,
            label: 'Answered',
            value: '$answered/$total',
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            icon: Icons.bar_chart,
            label: 'Accuracy',
            value: '${accuracy.toStringAsFixed(0)}%',
            color: accuracy >= 70
                ? Colors.green
                : accuracy >= 50
                    ? Colors.orange
                    : Colors.red,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _buildStatItem(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '$currentStreak',
            color: currentStreak >= 5
                ? Colors.orange
                : currentStreak >= 3
                    ? Colors.deepOrange
                    : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}

class _QuestionView extends StatefulWidget {
  final QuestionModel question;
  final int questionNumber;
  final int totalQuestions;
  final List<int> selectedOptions;
  final bool isMarkedForReview;
  final Function(List<int>) onSelectionChanged;
  final Function(List<int>) onAnswerSelected;
  final VoidCallback onToggleReviewMark;
  final bool testFinished;

  const _QuestionView({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedOptions,
    required this.isMarkedForReview,
    required this.onSelectionChanged,
    required this.onAnswerSelected,
    required this.onToggleReviewMark,
    required this.testFinished,
  });

  @override
  State<_QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<_QuestionView> {
  late List<int> _localSelectedOptions;

  @override
  void initState() {
    super.initState();
    _localSelectedOptions = List.from(widget.selectedOptions);
  }

  @override
  void didUpdateWidget(_QuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _localSelectedOptions = List.from(widget.selectedOptions);
    }
  }

  void _handleOptionSelection(int optionIndex) {
    // Only allow selection if not answered yet
    if (widget.question.answered && !widget.testFinished) return;

    setState(() {
      if (widget.question.isMultiSelect) {
        if (_localSelectedOptions.contains(optionIndex)) {
          _localSelectedOptions.remove(optionIndex);
        } else {
          _localSelectedOptions.add(optionIndex);
        }
      } else {
        _localSelectedOptions = [optionIndex];
      }
    });

    // Save the selection immediately (but don't mark as answered)
    widget.onSelectionChanged(_localSelectedOptions);
  }

  void _submitAnswer() {
    if (_localSelectedOptions.isEmpty) return;

    // Call the callback to save answer (fire and forget)
    widget.onAnswerSelected(_localSelectedOptions);
  }

  bool get _showFeedback => widget.question.answered || widget.testFinished;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${widget.questionNumber} of ${widget.totalQuestions}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                if (widget.question.marks != 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${widget.question.marks}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    widget.isMarkedForReview ? Icons.flag : Icons.flag_outlined,
                    color: widget.isMarkedForReview ? Colors.orange : null,
                  ),
                  onPressed: widget.onToggleReviewMark,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Question type badge
        if (widget.question.isMultiSelect)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_box_outlined, size: 16, color: Colors.purple),
                SizedBox(width: 6),
                Text(
                  'Multiple Select',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Question statement
        MarkdownWithLatex(
          data: widget.question.statement,
          textStyle: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),

        // Question image - removed as not in backend response

        // Options
        ...List.generate(widget.question.options.length, (index) {
          final isSelected = _localSelectedOptions.contains(index);
          final isCorrectOption = widget.question.correctOptions.contains(index);

          // Determine colors based on feedback state
          Color borderColor;
          Color backgroundColor;
          Color indicatorColor;

          if (_showFeedback) {
            // After answering, show correct/incorrect feedback
            if (isCorrectOption) {
              borderColor = Colors.green;
              backgroundColor = Colors.green.withValues(alpha: 0.1);
              indicatorColor = Colors.green;
            } else if (isSelected && !isCorrectOption) {
              borderColor = Colors.red;
              backgroundColor = Colors.red.withValues(alpha: 0.1);
              indicatorColor = Colors.red;
            } else {
              borderColor = Colors.grey[300]!;
              backgroundColor = Colors.transparent;
              indicatorColor = Colors.grey[400]!;
            }
          } else {
            // Before answering, use default selection colors
            borderColor = isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!;
            backgroundColor = isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent;
            indicatorColor = isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[400]!;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _handleOptionSelection(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Selection indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: widget.question.isMultiSelect
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        border: Border.all(
                          color: indicatorColor,
                          width: 2,
                        ),
                        color: (isSelected || (_showFeedback && isCorrectOption))
                            ? indicatorColor
                            : Colors.transparent,
                        borderRadius: widget.question.isMultiSelect
                            ? BorderRadius.circular(4)
                            : null,
                      ),
                      child: (isSelected || (_showFeedback && isCorrectOption))
                          ? Icon(
                              _showFeedback && isCorrectOption
                                  ? Icons.check
                                  : Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Option text
                    Expanded(
                      child: MarkdownWithLatex(
                        data: widget.question.options[index],
                        textStyle: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),

                    // Show feedback icon
                    if (_showFeedback && isCorrectOption)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    if (_showFeedback && isSelected && !isCorrectOption)
                      const Icon(Icons.cancel, color: Colors.red, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Answer button - only show if not yet answered
        if (!_showFeedback)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _localSelectedOptions.isEmpty ? null : _submitAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Answer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),


        // Explanation section - show after answering
        if (_showFeedback && widget.question.explanation != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explanation',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    // Save explanation button could go here
                  ],
                ),
                const SizedBox(height: 12),
                MarkdownWithLatex(
                  data: widget.question.explanation!,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionNavigatorSheet extends StatelessWidget {
  final TestSessionModel testSession;
  final int currentIndex;
  final Function(int) onQuestionSelected;

  const _QuestionNavigatorSheet({
    required this.testSession,
    required this.currentIndex,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Question Navigator',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                'Answered',
                testSession.answeredCount.toString(),
                Colors.green,
              ),
              _buildSummaryItem(
                context,
                'Unanswered',
                testSession.unansweredCount.toString(),
                Colors.grey,
              ),
              _buildSummaryItem(
                context,
                'Marked',
                testSession.markedForReviewCount.toString(),
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Question grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: testSession.totalQuestions,
              itemBuilder: (context, index) {
                final question = testSession.questions[index];
                final isAnswered = testSession.isQuestionAnswered(question.id);
                final isMarked = testSession.isQuestionMarkedForReview(question.id);
                final isCurrent = index == currentIndex;

                return InkWell(
                  onTap: () => onQuestionSelected(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : isAnswered
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: isMarked
                          ? Border.all(color: Colors.orange, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
