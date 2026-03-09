import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class PrayerTimeService {
  static const String _cacheKey = 'cached_prayer_data';
  static const String _cacheMonthKey = 'cached_month';
  static const String _cacheTzKey = 'cached_timezone';

  final String apiUrl;

  PrayerTimeService({required this.apiUrl});

  Future<Map<String, dynamic>?> getPrayerSchedule(double lat, double lng) async {
    final today = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final cachedMonth = prefs.getInt(_cacheMonthKey);

    // Try to fetch from API first
    try {
      final data = await _fetchFromApi(lat, lng);
      await prefs.setString(_cacheKey, jsonEncode(data));
      await prefs.setInt(_cacheMonthKey, today.month);

      if (data['iana_timezone'] != null) {
        await prefs.setString(_cacheTzKey, data['iana_timezone']);
      }

      return data;
    } catch (e) {
      //print('API Error: $e');
      // Fallback to cache if API fails
      return _getCachedData(prefs);
    }
  }

  Map<String, dynamic>? _getCachedData(SharedPreferences prefs) {
    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null) {
      return jsonDecode(cachedJson);
    }
    return null;
  }

  Future<Map<String, dynamic>> _fetchFromApi(double lat, double lng) async {
    final uri = Uri.parse('$apiUrl?lat=$lat&lng=$lng');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true) {
        return json;
      }
    }
    throw Exception('Failed to fetch API data');
  }

  bool _hasValidCache(DateTime today, int? cachedMonth, SharedPreferences prefs) {
    final hasCache = prefs.containsKey(_cacheKey);
    return hasCache && cachedMonth == today.month;
  }

  Future<String?> getCachedIanaTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheTzKey);
  }

  tz.Location resolveLocation({String? ianaTimezone, int? offset}) {
    if (ianaTimezone != null) {
      return tz.getLocation(ianaTimezone);
    } else if (offset != null) {
      const tzMap = {
        7: 'Asia/Jakarta',
        8: 'Asia/Makassar',
        9: 'Asia/Jayapura',
      };
      return tz.getLocation(tzMap[offset] ?? 'Asia/Jakarta');
    } else {
      return tz.getLocation('Asia/Jakarta');
    }
  }

  Future<tz.TZDateTime> nowWithResolvedLocation({String? ianaTimezone, int? offset}) async {
    final location = resolveLocation(ianaTimezone: ianaTimezone, offset: offset);
    return tz.TZDateTime.now(location);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheMonthKey);
    await prefs.remove(_cacheTzKey);
  }

  Future<Map<String, dynamic>?> loadCachedLocationOrDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('cached_lat') ?? -7.7325213;
    final lng = prefs.getDouble('cached_lng') ?? 110.402376;
    final tzOffset = prefs.getInt('cached_tz');

    return await getPrayerSchedule(lat, lng);
  }

  Future<void> saveLocation(double lat, double lng, int? tzOffset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cached_lat', lat);
    await prefs.setDouble('cached_lng', lng);
    if (tzOffset != null) {
      await prefs.setInt('cached_tz', tzOffset);
    }
  }

  Future<void> loadPrayerSchedule({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('cached_lat') ?? -7.7325213;
    final lng = prefs.getDouble('cached_lng') ?? 110.402376;

    if (forceRefresh) {
      await clearCache();
    }
    await getPrayerSchedule(lat, lng);
  }

  Future<Map<String, dynamic>?> getTodayPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);
    final ianaTimezone = await getCachedIanaTimezone();
    final tzOffset = prefs.getInt('cached_tz');
    final location = resolveLocation(ianaTimezone: ianaTimezone, offset: tzOffset);

    if (cachedJson != null) {
      final data = jsonDecode(cachedJson);
      final today = DateTime.now();
      final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final daily = (data['data'] as List?)?.firstWhere(
        (e) => e['tanggal'] == dateStr,
        orElse: () => null,
      );

      if (daily != null && daily['jadwal'] != null) {
        return convertTimesToLocal(daily['jadwal'] as Map<String, dynamic>, location);
      }
    }
    return null;
  }

  Map<String, dynamic> convertTimesToLocal(
    Map<String, dynamic> times, 
    tz.Location location
  ) {
    final now = tz.TZDateTime.now(location);
    return times.map((key, value) {
      final time = DateFormat.Hm().parse(value);
      final dt = tz.TZDateTime(location, now.year, now.month, now.day, time.hour, time.minute);
      return MapEntry(key, DateFormat.Hms().format(dt));
    });
  }

  Future<String> getNextPrayerName() async {
    final times = await getTodayPrayerTimes();
    if (times == null) return "shubuh";

    final now = DateTime.now();
    final prayers = {
      'shubuh': times["shubuh"],
      'dhuhur': times["dhuhur"],
      'ashar': times["ashar"],
      'magrib': times["magrib"],
      'isya': times["isya"],
    };

    for (var entry in prayers.entries) {
      if (entry.value != null) {
        final prayerTime = DateFormat.Hms().parse(entry.value!);
        if (prayerTime.isAfter(now)) {
          return entry.key;
        }
      }
    }
    return "shubuh";
  }

  Future<DateTime> getNextPrayerTime() async {
    final name = await getNextPrayerName();
    final times = await getTodayPrayerTimes();
    
    if (times == null || times[name] == null) {
      return DateTime.now().add(Duration(hours: 1));
    }

    return DateFormat.Hms().parse(times[name]!);
  }
}