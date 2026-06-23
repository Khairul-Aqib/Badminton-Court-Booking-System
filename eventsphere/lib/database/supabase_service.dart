import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../models/booking.dart';
import '../models/court.dart';
import '../models/addon.dart';
import '../models/admin.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _db = Supabase.instance.client;

  // ── Users ───────────────────────────────────────────────────────────────────

  Future<User?> getUser(String username, String password) async {
    final result = await _db
        .from('users')
        .select()
        .eq('username', username)
        .eq('password', password)
        .eq('role', 'user')
        .maybeSingle();
    return result == null ? null : User.fromMap(result);
  }

  Future<Admin?> getAdmin(String username, String password) async {
    final result = await _db
        .from('users')
        .select()
        .eq('username', username)
        .eq('password', password)
        .eq('role', 'admin')
        .maybeSingle();
    return result == null ? null : Admin.fromMap(result);
  }

  Future<void> insertUser(User user) async {
    await _db.from('users').insert(user.toInsertMap());
  }

  Future<void> updateUser(User user) async {
    await _db.from('users').update(user.toUpdateMap()).eq('id', user.id!);
  }

  Future<void> deleteUser(int id) async {
    await _db.from('users').delete().eq('id', id);
  }

  Future<User?> getUserById(int id) async {
    final result =
        await _db.from('users').select().eq('id', id).maybeSingle();
    return result == null ? null : User.fromMap(result);
  }

  Future<List<Map<String, dynamic>>> getUsersWithBookings() async {
    final users = await _db
        .from('users')
        .select('id, full_name, email, phone, username, role')
        .eq('role', 'user')
        .order('full_name');

    final bookings = await _db
        .from('bookings')
        .select('id, user_id, booking_date, start_time, end_time, total_amount, status, courts(court_name)')
        .order('booked_at', ascending: false);

    final result = <Map<String, dynamic>>[];
    for (final user in users) {
      final userBookings =
          bookings.where((b) => b['user_id'] == user['id']).toList();
      if (userBookings.isEmpty) {
        result.add({...user, 'bookings': []});
      } else {
        result.add({...user, 'bookings': userBookings});
      }
    }
    return result;
  }

  // ── Courts ──────────────────────────────────────────────────────────────────

  Future<List<Court>> getCourts() async {
    final result = await _db.from('courts').select().order('id');
    return result.map((c) => Court.fromMap(c)).toList();
  }

  // ── Addons ──────────────────────────────────────────────────────────────────

  Future<List<Addon>> getAddons() async {
    final result = await _db.from('addons').select().order('id');
    return result.map((a) => Addon.fromMap(a)).toList();
  }

  // ── Bookings ─────────────────────────────────────────────────────────────────

  Future<List<Booking>> getUserBookings(int userId) async {
    final result = await _db
        .from('bookings')
        .select('*, courts(court_name, court_type), booking_addons(*, addons(addon_name))')
        .eq('user_id', userId)
        .order('booked_at', ascending: false);
    return result.map((b) => Booking.fromMap(b)).toList();
  }

  Future<void> insertBooking(
      Booking booking, List<Map<String, dynamic>> addonRows) async {
    final result = await _db
        .from('bookings')
        .insert(booking.toInsertMap())
        .select('id')
        .single();
    final bookingId = result['id'] as int;
    if (addonRows.isNotEmpty) {
      final rows =
          addonRows.map((a) => {...a, 'booking_id': bookingId}).toList();
      await _db.from('booking_addons').insert(rows);
    }
  }

  Future<void> updateBooking(int bookingId, String bookingDate,
      String startTime, String endTime, double durationHours) async {
    await _db.from('bookings').update({
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
    }).eq('id', bookingId);
  }

  Future<void> cancelBooking(int id) async {
    await _db
        .from('bookings')
        .update({'status': 'cancelled'}).eq('id', id);
  }
}