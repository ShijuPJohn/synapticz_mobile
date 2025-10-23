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
  bool _isSavingAnswer = false;

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
        if (session.timeDuration != null && !session.completed) {
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
    final elapsedSeconds = DateTime.now().difference(session.startedAt).inSeconds;
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
    if (_testSession == null || _testSession!.completed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time is up! Auto-submitting test...')),
    );

    await _submitTest();
  }

  Future<void> _saveAnswer(int questionId, List<int> selectedOptions) async {
    if (_testSession == null || _isSavingAnswer) return;

    setState(() {
      _isSavingAnswer = true;
    });

    try {
      await TestSessionService.saveAnswer(
        sessionId: _testSession!.sessionId,
        questionId: questionId,
        selectedOptions: selectedOptions,
        currentQuestionIndex: _currentQuestionIndex,
        remainingTime: _remainingSeconds > 0 ? _remainingSeconds : null,
      );

      setState(() {
        final updatedAnswers = Map<int, List<int>>.from(_testSession!.selectedAnswers);
        updatedAnswers[questionId] = selectedOptions;
        _testSession = _testSession!.copyWith(selectedAnswers: updatedAnswers);
        _isSavingAnswer = false;
      });
    } catch (e) {
      setState(() {
        _isSavingAnswer = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save answer: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleReviewMark(int questionId) {
    if (_testSession == null) return;

    setState(() {
      final updatedReviewMarked = Map<int, bool>.from(_testSession!.reviewMarked);
      updatedReviewMarked[questionId] = !(_testSession!.isQuestionMarkedForReview(questionId));
      _testSession = _testSession!.copyWith(reviewMarked: updatedReviewMarked);
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
            if (_testSession?.timeDuration != null && !_testSession!.completed)
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
                              child: _QuestionView(
                                question: _testSession!.questions[_currentQuestionIndex],
                                questionNumber: _currentQuestionIndex + 1,
                                totalQuestions: _testSession!.totalQuestions,
                                selectedOptions: _testSession!.getSelectedOptions(
                                  _testSession!.questions[_currentQuestionIndex].id,
                                ),
                                isMarkedForReview: _testSession!.isQuestionMarkedForReview(
                                  _testSession!.questions[_currentQuestionIndex].id,
                                ),
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
  final Function(List<int>) onAnswerSelected;
  final VoidCallback onToggleReviewMark;

  const _QuestionView({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selectedOptions,
    required this.isMarkedForReview,
    required this.onAnswerSelected,
    required this.onToggleReviewMark,
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
    widget.onAnswerSelected(_localSelectedOptions);
  }

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

        // Question image
        if (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.question.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.image_not_supported, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Image failed to load'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

        // Options
        ...List.generate(widget.question.options.length, (index) {
          final isSelected = _localSelectedOptions.contains(index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _handleOptionSelection(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300]!,
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
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: widget.question.isMultiSelect
                            ? BorderRadius.circular(4)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
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
                  ],
                ),
              ),
            ),
          );
        }),

        // Hint
        if (widget.question.hint != null && widget.question.hint!.isNotEmpty) ...[
          const SizedBox(height: 24),
          ExpansionTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: const Text('Hint'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: MarkdownWithLatex(
                  data: widget.question.hint!,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
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
