import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
    // Parse ALL content (text, inline math, display math)
    final segments = _parseContent(data);

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build one flowing text with inline and display elements
    final List<InlineSpan> spans = [];

    for (var segment in segments) {
      final type = segment['type'] as String;
      final content = segment['content'] as String;

      if (type == 'display_math') {
        // Display math inline - no line breaks
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _buildMath(content, context, isDisplay: true),
        ));
      } else if (type == 'inline_math') {
        // Inline math - no breaks
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _buildMath(content, context, isDisplay: false),
        ));
      } else {
        // Text - parse markdown and preserve newlines
        spans.addAll(_parseMarkdown(content, context));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _buildMath(String latex, BuildContext context, {required bool isDisplay}) {
    try {
      final mathWidget = Math.tex(
        latex,
        textStyle: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
      );

      // Wrap in LayoutBuilder to get available width and prevent overflow
      return LayoutBuilder(
        builder: (context, constraints) {
          // Get the max width from parent, defaulting to screen width if unconstrained
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width - 32; // 32 for padding

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: mathWidget,
            ),
          );
        },
      );
    } catch (e) {
      return Text(
        latex,
        style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  List<InlineSpan> _parseMarkdown(String text, BuildContext context) {
    final List<InlineSpan> spans = [];
    final baseStyle = textStyle ?? Theme.of(context).textTheme.bodyMedium;

    // Split by newlines first to preserve them
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.isEmpty) {
        // Add newline for empty lines
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
        continue;
      }

      // Parse markdown formatting in the line
      int lastIndex = 0;

      // Match **bold** and *italic* (bold must be checked first)
      final markdownPattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');

      for (final match in markdownPattern.allMatches(line)) {
        // Add text before markdown
        if (match.start > lastIndex) {
          final textBefore = line.substring(lastIndex, match.start);
          if (textBefore.isNotEmpty) {
            spans.add(TextSpan(text: textBefore, style: baseStyle));
          }
        }

        // Add markdown formatted text
        if (match.group(1) != null) {
          // Bold **text**
          spans.add(TextSpan(
            text: match.group(1),
            style: baseStyle?.copyWith(fontWeight: FontWeight.bold) ??
                   const TextStyle(fontWeight: FontWeight.bold),
          ));
        } else if (match.group(2) != null) {
          // Italic *text*
          spans.add(TextSpan(
            text: match.group(2),
            style: baseStyle?.copyWith(fontStyle: FontStyle.italic) ??
                   const TextStyle(fontStyle: FontStyle.italic),
          ));
        }

        lastIndex = match.end;
      }

      // Add remaining text in the line
      if (lastIndex < line.length) {
        final remaining = line.substring(lastIndex);
        if (remaining.isNotEmpty) {
          spans.add(TextSpan(text: remaining, style: baseStyle));
        }
      }

      // Add newline after each line except the last
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  List<Map<String, String>> _parseContent(String text) {
    final List<Map<String, String>> segments = [];
    int lastIndex = 0;

    // Match both display math $$...$$ and inline math $...$
    // Process in order they appear
    final mathPattern = RegExp(r'\$\$(.+?)\$\$|\$([^\$\n]+?)\$', dotAll: true);

    for (final match in mathPattern.allMatches(text)) {
      // Add text before math
      if (match.start > lastIndex) {
        final textBefore = text.substring(lastIndex, match.start);
        if (textBefore.isNotEmpty) {
          segments.add({'type': 'text', 'content': textBefore});
        }
      }

      // Add math (display or inline)
      if (match.group(1) != null) {
        // Display math $$...$$
        segments.add({'type': 'display_math', 'content': match.group(1)!});
      } else if (match.group(2) != null) {
        // Inline math $...$
        segments.add({'type': 'inline_math', 'content': match.group(2)!});
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex);
      if (remaining.isNotEmpty) {
        segments.add({'type': 'text', 'content': remaining});
      }
    }

    return segments;
  }
}
