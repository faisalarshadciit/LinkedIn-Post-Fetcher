import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

import '../models/linkedin_post_content.dart';

class LinkedInPostExtractor {
  LinkedInPostExtractor._();
  static final LinkedInPostExtractor instance = LinkedInPostExtractor._();

  Future<LinkedInPostContent> extractPost(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: const {
        'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load post (${response.statusCode})');
    }

    final document = parse(response.body);

    // ─────────────────────────────────────────────
    // TEXT (Open Graph – most reliable)
    // ─────────────────────────────────────────────
    final text = document
        .querySelector('meta[property="og:description"]')
        ?.attributes['content']
        ?.trim() ??
        '';

    if (text.isEmpty) {
      throw Exception('Unable to extract post text');
    }

    // ─────────────────────────────────────────────
    // IMAGES (heuristic ranking)
    // ─────────────────────────────────────────────
    final Set<String> candidates = {};

    final imgTags = document.querySelectorAll('img');

    for (final img in imgTags) {
      final src = img.attributes['src'];
      if (_isCandidateImage(src)) {
        candidates.add(_normalizeImageUrl(src!));
      }
    }

    // Fallback to og:image if nothing else found
    if (candidates.isEmpty) {
      final ogImage = document
          .querySelector('meta[property="og:image"]')
          ?.attributes['content'];

      if (_isCandidateImage(ogImage)) {
        candidates.add(_normalizeImageUrl(ogImage!));
      }
    }

    // Rank & select
    final images = _rankImages(candidates);

    return LinkedInPostContent(
      text: text,
      imageUrls: images.toList(),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  bool _isCandidateImage(String? url) {
    if (url == null) return false;

    return url.startsWith('https://media.licdn.com') &&
        !url.contains('sprite') &&
        !url.contains('ghost');
  }

  /// Remove size & cache params
  String _normalizeImageUrl(String url) {
    return url.split('?').first;
  }

  /// Pick the most likely "real" image
  List<String> _rankImages(Set<String> images) {
    final list = images.toList();

    list.sort((a, b) {
      int score(String u) {
        int s = 0;
        if (u.contains('dms/image')) s += 3;
        if (u.contains('image')) s += 2;
        if (!u.contains('logo')) s += 1;
        if (!u.contains('profile')) s += 1;
        return s;
      }

      return score(b).compareTo(score(a));
    });

    // Return best image only (what user expects)
    return list.isNotEmpty ? [list.first] : [];
  }

}