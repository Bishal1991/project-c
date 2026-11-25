import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://efnzdlqrshucqjqsdcpm.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmbnpkbHFyc2h1Y3FqcXNkY3BtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU0OTEwNDEsImV4cCI6MjExMTA2NzA0MX0.8hFOv-sDYXmXWw5sY5Yd4tVN3N2TPu1GygUAjM3R3Qg',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static final _refreshController = StreamController<void>.broadcast();

  static void notifyRefresh() {
    if (!_refreshController.isClosed) {
      _refreshController.add(null);
    }
  }

  /// Creates a reactive stream that fetches immediately from Supabase,
  /// listens to Supabase Realtime Postgres changes on [tables], and
  /// re-fetches whenever [notifyRefresh] is triggered.
  static Stream<T> watchQuery<T>(
    Future<T> Function() fetcher, {
    required List<String> tables,
    String? channelPrefix,
  }) {
    late StreamController<T> controller;
    RealtimeChannel? channel;
    StreamSubscription<void>? refreshSub;
    Timer? fallbackTimer;
    bool fetching = false;
    bool pendingFetch = false;

    Future<void> runFetch() async {
      if (controller.isClosed) return;
      if (fetching) {
        pendingFetch = true;
        return;
      }
      fetching = true;
      try {
        final data = await fetcher();
        if (!controller.isClosed) controller.add(data);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        fetching = false;
        if (pendingFetch && !controller.isClosed) {
          pendingFetch = false;
          runFetch();
        }
      }
    }

    controller = StreamController<T>(
      onListen: () {
        runFetch();
        refreshSub = _refreshController.stream.listen((_) => runFetch());

        final chName =
            '${channelPrefix ?? tables.join('_')}_${DateTime.now().microsecondsSinceEpoch}';
        var ch = client.channel(chName);
        for (final table in tables) {
          ch = ch.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (_) => runFetch(),
          );
        }
        channel = ch..subscribe();

        // Periodic fallback sync in case network reconnects
        fallbackTimer = Timer.periodic(
          const Duration(seconds: 15),
          (_) => runFetch(),
        );
      },
      onCancel: () {
        refreshSub?.cancel();
        fallbackTimer?.cancel();
        if (channel != null) {
          client.removeChannel(channel!);
        }
      },
    );

    return controller.stream;
  }
}
