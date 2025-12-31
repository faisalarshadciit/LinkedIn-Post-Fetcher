import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../services/linkedin_post_extractor.dart';

class LinkedInPostScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const LinkedInPostScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<LinkedInPostScreen> createState() => _LinkedInPostScreenState();
}

class _LinkedInPostScreenState extends State<LinkedInPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();

  String _rawText = '';
  List<String> _imageUrls = [];

  bool _isLoading = false;
  bool _cleanFormatting = false;
  bool _markdownPreview = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  String get _displayText => _cleanFormatting ? cleanFormatting(_rawText) : _rawText;
  int get _charCount => _displayText.length;

  Future<void> _fetchPostText() async {
    try {
      setState(() => _isLoading = true);

      final result = await LinkedInPostExtractor.instance.extractPost(_linkController.text.trim());

      setState(() {
        _rawText = result.text;
        _imageUrls = result.imageUrls;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _displayText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _share() {
    SharePlus.instance.share(ShareParams(text: _displayText));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn Post Fetcher'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// INPUT
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('LinkedIn Post URL', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _linkController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.link),
                          hintText:
                          'https://www.linkedin.com/posts/...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Enter LinkedIn post URL'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            FocusScope.of(context).unfocus();
                            _fetchPostText();
                          }
                        },
                        icon: _isLoading
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.download),
                        label: Text(
                            _isLoading ? 'Fetching...' : 'Fetch'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            /// RESULT
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Extracted Text', style: theme.textTheme.titleMedium),
                          if (_rawText.isNotEmpty)
                            Row(
                              children: [
                                Text(
                                  '$_charCount chars',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Copy',
                                  icon: const Icon(Icons.copy),
                                  onPressed: _copy,
                                ),
                                IconButton(
                                  tooltip: 'Share',
                                  icon: const Icon(Icons.share),
                                  onPressed: _share,
                                ),
                              ],
                            ),
                        ],
                      ),
                      /// TOGGLES
                      if (_rawText.isNotEmpty)
                        Wrap(
                          spacing: 12,
                          children: [
                            FilterChip(
                              label: const Text('Clean formatting'),
                              selected: _cleanFormatting,
                              onSelected: (v) => setState(() => _cleanFormatting = v),
                            ),
                            FilterChip(
                              label: const Text('Markdown preview'),
                              selected: _markdownPreview,
                              onSelected: (v) =>
                                  setState(() => _markdownPreview = v),
                            ),
                          ],
                        ),

                      const Divider(),

                      /// CONTENT
                      Expanded(
                        child: _rawText.isEmpty
                            ? Center(
                          child: Text(
                            'No text yet',
                            style: TextStyle(
                                color:
                                theme.colorScheme.outline),
                          ),
                        )
                            : _markdownPreview
                            ? Markdown(
                          data: _displayText,
                        )
                            : SelectableText(
                          _displayText,
                          style: const TextStyle(
                              fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatting helper
String cleanFormatting(String text) {
  return text
      .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}