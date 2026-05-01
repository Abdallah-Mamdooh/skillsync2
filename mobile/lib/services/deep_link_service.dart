import 'dart:async';

import 'package:app_links/app_links.dart';

typedef ResetPasswordHandler = void Function(String token);

class DeepLinkService {
  DeepLinkService._(this._appLinks);

  static DeepLinkService? _instance;

  final AppLinks _appLinks;
  StreamSubscription? _linkSub;

  static DeepLinkService get instance {
    _instance ??= DeepLinkService._(AppLinks());
    return _instance!;
  }

  /// Call once from the top-level widget to start listening for reset links.
  Future<void> init({
    required ResetPasswordHandler onResetLink,
  }) async {
    // Initial link (cold start)
    try {
      final initialLink = await _appLinks.getInitialLinkString();
      if (initialLink != null && initialLink.isNotEmpty) {
        _handleUri(Uri.parse(initialLink), onResetLink);
      }
    } catch (_) {
      // Ignore invalid or missing initial links
    }

    // Stream (app already running)
    await _linkSub?.cancel();
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri, onResetLink),
      onError: (_) {},
    );
  }

  void _handleUri(Uri uri, ResetPasswordHandler onResetLink) {
    String? token;

    // Try to extract token from path: /reset-password/:token
    final segments = uri.pathSegments;
    final resetIndex = segments.indexOf('reset-password');
    if (resetIndex != -1 && resetIndex + 1 < segments.length) {
      token = segments[resetIndex + 1];
    }

    // Fallback to query parameter: ?token=xyz
    if (token == null || token.isEmpty) {
      token = uri.queryParameters['token'];
    }

    if (token == null || token.isEmpty) return;
    onResetLink(token);
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _linkSub = null;
  }
}

