import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// In-memory GotrueAsyncStorage — avoids SharedPreferences plugin in tests.
class _MemStorage extends GotrueAsyncStorage {
  final _store = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _store[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _store[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _store.remove(key);
}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Load .env from disk (bypasses rootBundle — works in unit tests)
    final envContent = File('.env').readAsStringSync();
    dotenv.testLoad(fileInput: envContent);

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemStorage(),
      ),
    );
  });

  test('SUPABASE_URL is loaded correctly', () {
    final url = dotenv.env['SUPABASE_URL'];
    expect(url, isNotNull);
    expect(url, startsWith('https://'));
    expect(url, contains('supabase.co'));
  });

  test('SUPABASE_ANON_KEY is loaded correctly', () {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    expect(key, isNotNull);
    expect(key!.isNotEmpty, true);
  });

  test('Supabase client is initialized', () {
    final client = Supabase.instance.client;
    expect(client, isNotNull);
  });

  test('Supabase can query the database (live connectivity)', () async {
    final client = Supabase.instance.client;
    final response = await client.from('users').select().limit(1);
    expect(response, isA<List>());
  });
}
