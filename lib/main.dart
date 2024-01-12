import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkedIn Post Fetcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();
  String _postText = "";
  bool _isLoading = false;

  Future<String?> _fetchPostText(String link) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(Uri.parse(link));

      if (response.statusCode == 200)
      {
        final document = html_parser.parse(response.body);
        final postElement = document.querySelector('.break-words');

        if (postElement != null)
        {
          setState(() {
            _postText = postElement.text;
            _isLoading = false;
          });
        }
        else
        {
          setState(() {
            _postText = "Failed to fetch post text.";
            _isLoading = false;
          });
        }

        return null;
      }
      else
      {
        setState(() {
          _postText = "";
          _isLoading = false;
        });

        return "Failed to fetch LinkedIn post. Status code: ${response.statusCode}";
      }
    } catch (exception) {
      setState(() {
        _isLoading = false;
        _postText = "";
      });

      return "Invalid URL format. Please enter a valid LinkedIn post link. ($exception)";
    }
  }

  void _showErrorSnackbar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700]!, // Customize the background color
        duration: const Duration(seconds: 3), // Set the duration to 3 seconds
        behavior: SnackBarBehavior.floating, // Make it look like a floating card
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Add rounded corners
        ),
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _postText));
  }

  void _sharePost() {
    Share.share(_postText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LinkedIn Post Fetcher',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _postText.isNotEmpty ? _copyToClipboard : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _postText.isNotEmpty ? _sharePost : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _linkController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Paste LinkedIn Post Link',
                  hintText: 'https://www.linkedin.com/posts/example',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(color: Colors.teal, width: 2.0), // Set the border color
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16.0),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(color: Colors.teal, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                  {
                    return 'Please enter a LinkedIn post link.';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate())
                {
                  FocusScope.of(context).unfocus();
                  String link = _linkController.text.trim();

                  String? error = await _fetchPostText(link);
                  if (error != null)
                  {
                    _showErrorSnackbar(error);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Fetch Post Text'),
            ),
            const SizedBox(height: 16),
            const Text('Post Text:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Text(
                    _postText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
