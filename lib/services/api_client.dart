import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Defaults to 127.0.0.1:3000 (works with `adb reverse tcp:3000 tcp:3000` on USB phone and desktop);
  // auto-falls back to 10.0.2.2:3000 on Android Emulator if 127.0.0.1 is unreachable.
  static String _baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );
  static const _fallbackEmulatorUrl = 'http://10.0.2.2:3000';

  static final _refreshController = StreamController<void>.broadcast();

  static void notifyRefresh() {
    if (!_refreshController.isClosed) {
      _refreshController.add(null);
    }
  }

  static Future<http.Response> _send(
    Future<http.Response> Function(String base) requestFn,
  ) async {
    try {
      return await requestFn(_baseUrl).timeout(const Duration(seconds: 6));
    } catch (_) {
      if (_baseUrl != _fallbackEmulatorUrl) {
        _baseUrl = _fallbackEmulatorUrl;
        return await requestFn(_baseUrl).timeout(const Duration(seconds: 6));
      }
      rethrow;
    }
  }

  static Future<dynamic> get(String path) async {
    final res = await _send((base) => http.get(Uri.parse('$base$path')));
    return _decode(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _send(
      (base) => http.post(
        Uri.parse('$base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await _send(
      (base) => http.put(
        Uri.parse('$base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  static dynamic _decode(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final msg = decoded is Map && decoded['error'] != null
        ? decoded['error']
        : 'HTTP ${res.statusCode}';
    throw Exception(msg);
  }

  // Emits immediately, on every interval, and whenever ApiClient.notifyRefresh() is called
  static Stream<T> pollStream<T>(
    Future<T> Function() fetcher, {
    Duration interval = const Duration(seconds: 3),
  }) {
    late StreamController<T> controller;
    Timer? timer;
    StreamSubscription<void>? refreshSub;
    bool fetching = false;

    Future<void> poll() async {
      if (fetching || controller.isClosed) return;
      fetching = true;
      try {
        final data = await fetcher();
        if (!controller.isClosed) controller.add(data);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        fetching = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        poll();
        timer = Timer.periodic(interval, (_) => poll());
        refreshSub = _refreshController.stream.listen((_) => poll());
      },
      onCancel: () {
        timer?.cancel();
        refreshSub?.cancel();
      },
    );

    return controller.stream;
  }
}
