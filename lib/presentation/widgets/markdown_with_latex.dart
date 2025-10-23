import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownWithLatex extends StatelessWidget {
  final String data;
  final TextStyle? textStyle;
  final bool selectable;

  const MarkdownWithLatex({
    super.key,
    required this.data,
    this.textStyle,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    // Process the content to handle LaTeX formatting
    final processedData = _processLatex(data);

    return MarkdownBody(
      data: processedData,
      styleSheet: MarkdownStyleSheet(
        p: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        code: TextStyle(
          backgroundColor: Colors.grey[200],
          fontFamily: 'monospace',
          fontSize: (textStyle?.fontSize ?? 14) - 2,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(
          color: Colors.grey[700],
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: Colors.blue.withValues(alpha: 0.3),
              width: 4,
            ),
          ),
        ),
      ),
    );
  }

  /// Process LaTeX delimiters and convert them to readable format
  /// Displays LaTeX formulas inline for better readability
  String _processLatex(String text) {
    String processed = text;

    // Handle display math $$...$$ - show on new line with emphasis
    processed = processed.replaceAllMapped(
      RegExp(r'\$\$(.+?)\$\$', dotAll: true),
      (match) => '\n\n${_cleanLatex(match.group(1)!)}\n\n',
    );

    // Handle inline math $...$ - keep inline with emphasis
    processed = processed.replaceAllMapped(
      RegExp(r'\$([^\$]+?)\$'),
      (match) => _cleanLatex(match.group(1)!),
    );

    // Handle \[...\] display math - show on new line with emphasis
    processed = processed.replaceAllMapped(
      RegExp(r'\\\[(.+?)\\\]', dotAll: true),
      (match) => '\n\n${_cleanLatex(match.group(1)!)}\n\n',
    );

    // Handle \(...\) inline math - keep inline with emphasis
    processed = processed.replaceAllMapped(
      RegExp(r'\\\((.+?)\\\)'),
      (match) => _cleanLatex(match.group(1)!),
    );

    return processed;
  }

  /// Clean up LaTeX to make it more readable
  String _cleanLatex(String latex) {
    String cleaned = latex;

    // Replace common LaTeX commands with readable equivalents
    cleaned = cleaned.replaceAll(r'\cdot', '·');
    cleaned = cleaned.replaceAll(r'\times', '×');
    cleaned = cleaned.replaceAll(r'\div', '÷');
    cleaned = cleaned.replaceAll(r'\pm', '±');
    cleaned = cleaned.replaceAll(r'\mp', '∓');
    cleaned = cleaned.replaceAll(r'\leq', '≤');
    cleaned = cleaned.replaceAll(r'\geq', '≥');
    cleaned = cleaned.replaceAll(r'\neq', '≠');
    cleaned = cleaned.replaceAll(r'\approx', '≈');
    cleaned = cleaned.replaceAll(r'\equiv', '≡');
    cleaned = cleaned.replaceAll(r'\sim', '~');
    cleaned = cleaned.replaceAll(r'\propto', '∝');
    cleaned = cleaned.replaceAll(r'\infty', '∞');
    cleaned = cleaned.replaceAll(r'\alpha', 'α');
    cleaned = cleaned.replaceAll(r'\beta', 'β');
    cleaned = cleaned.replaceAll(r'\gamma', 'γ');
    cleaned = cleaned.replaceAll(r'\delta', 'δ');
    cleaned = cleaned.replaceAll(r'\epsilon', 'ε');
    cleaned = cleaned.replaceAll(r'\theta', 'θ');
    cleaned = cleaned.replaceAll(r'\lambda', 'λ');
    cleaned = cleaned.replaceAll(r'\mu', 'μ');
    cleaned = cleaned.replaceAll(r'\pi', 'π');
    cleaned = cleaned.replaceAll(r'\sigma', 'σ');
    cleaned = cleaned.replaceAll(r'\tau', 'τ');
    cleaned = cleaned.replaceAll(r'\phi', 'φ');
    cleaned = cleaned.replaceAll(r'\omega', 'ω');
    cleaned = cleaned.replaceAll(r'\Delta', 'Δ');
    cleaned = cleaned.replaceAll(r'\Sigma', 'Σ');
    cleaned = cleaned.replaceAll(r'\Omega', 'Ω');

    // Handle fractions: \frac{a}{b} -> (a)/(b)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'),
      (match) => '(${match.group(1)})/(${match.group(2)})',
    );

    // Handle square roots: \sqrt{x} -> √(x)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\sqrt\{([^}]+)\}'),
      (match) => '√(${match.group(1)})',
    );

    // Handle superscripts: x^{2} -> x²
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\^(\{[^}]+\}|\w)'),
      (match) {
        final exp = match.group(1)!.replaceAll(RegExp(r'[{}]'), '');
        return '^($exp)';
      },
    );

    // Handle subscripts: x_{i} -> xᵢ
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'_(\{[^}]+\}|\w)'),
      (match) {
        final sub = match.group(1)!.replaceAll(RegExp(r'[{}]'), '');
        return '_($sub)';
      },
    );

    // Handle matrices: \begin{pmatrix}...\end{pmatrix} -> [matrix]
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\begin\{pmatrix\}(.+?)\\end\{pmatrix\}', dotAll: true),
      (match) {
        final content = match.group(1)!;
        // Split by rows (\\)
        final rows = content.split(r'\\').map((row) {
          // Split by columns (&)
          return row.trim().split('&').map((cell) => cell.trim()).join(' ');
        }).where((row) => row.isNotEmpty).join('\n');
        return '\n**Matrix:**\n$rows\n';
      },
    );

    // Handle other matrix types
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\begin\{(bmatrix|vmatrix|Vmatrix|matrix)\}(.+?)\\end\{\1\}', dotAll: true),
      (match) {
        final content = match.group(2)!;
        final rows = content.split(r'\\').map((row) {
          return row.trim().split('&').map((cell) => cell.trim()).join(' ');
        }).where((row) => row.isNotEmpty).join('\n');
        return '\n**Matrix:**\n$rows\n';
      },
    );

    // Remove remaining LaTeX commands that we don't handle
    cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');

    // Clean up extra whitespace and braces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[{}]'), '');
    cleaned = cleaned.trim();

    // Make it bold for emphasis
    return '**$cleaned**';
  }
}
