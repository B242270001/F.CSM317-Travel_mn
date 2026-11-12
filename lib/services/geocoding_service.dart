// lib/services/geocoding_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/picked_location.dart';

/// Хаяг хайхад гарсан алдаа — хэрэглэгчид ойлгомжтой мессежтэй.
class GeocodingException implements Exception {
  const GeocodingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Хаягаар байршил хайх ба координатаас хаяг тодорхойлох.
/// OpenStreetMap-ийн Nominatim үйлчилгээ — үнэгүй, API түлхүүр шаардахгүй,
/// Android, iOS, вэб, Windows бүгд дээр ажиллана. Ашиглах нөхцөл:
/// • секундэд 1-ээс олон хүсэлт илгээхгүй (доорх дараалал хангана);
/// • апп-аа User-Agent-аар танилцуулна (вэбд хөтөч Referer илгээнэ);
/// • үр дүнг кэшлэнэ; бичих бүрт автоматаар хайхгүй (зөвхөн «Хайх» дарахад).
class Geocoding {
  const Geocoding._();

  static const _host = 'nominatim.openstreetmap.org';

  static final _searchCache = <String, List<PickedLocation>>{};
  static final _reverseCache = <String, PickedLocation?>{};

  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<void> _queue = Future.value();

  /// «Хөвсгөл нуур», «Цэцэрлэг» гэх мэт текстээр Монгол дотроос хайна.
  static Future<List<PickedLocation>> search(String query) async {
    final key = query.trim().toLowerCase();
    final cached = _searchCache[key];
    if (cached != null) return cached;

    final data = await _get('/search', {
      'q': query.trim(),
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
      'countrycodes': 'mn', // зөвхөн Монгол
      'accept-language': 'mn',
    });
    if (data is! List) return const [];
    final results = [
      for (final r in data.whereType<Map<String, dynamic>>()) _parse(r),
    ];
    _searchCache[key] = results;
    return results;
  }

  /// Газрын зураг дээр дарсан цэгийн хаягийг тодорхойлно.
  static Future<PickedLocation?> reverse(double lat, double lng) async {
    // ~10 м-ийн нарийвчлалаар кэшлэнэ
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(key)) {
      return _at(_reverseCache[key], lat, lng);
    }

    final data = await _get('/reverse', {
      'lat': '$lat',
      'lon': '$lng',
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '14', // тосгон/сумын түвшин
      'accept-language': 'mn',
    });
    // Далай, хил гадна гэх мэт хаяггүй цэгт {"error": "..."} буцаана
    final result = data is Map<String, dynamic> && !data.containsKey('error')
        ? _parse(data)
        : null;
    _reverseCache[key] = result;
    return _at(result, lat, lng);
  }

  /// Хэрэглэгчийн дарсан яг цэгийн координатыг хадгална.
  static PickedLocation? _at(PickedLocation? r, double lat, double lng) =>
      r == null
          ? null
          : PickedLocation(
              latitude: lat,
              longitude: lng,
              address: r.address,
              name: r.name,
              region: r.region,
            );

  /// Хүсэлтүүдийг дараалалд оруулж, хооронд нь 1 секундээс их зай гаргана.
  static Future<Object?> _get(String path, Map<String, String> params) {
    final result = _queue.then<Object?>((_) => _send(path, params));
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static Future<Object?> _send(String path, Map<String, String> params) async {
    final wait = _lastRequest
        .add(const Duration(milliseconds: 1100))
        .difference(DateTime.now());
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _lastRequest = DateTime.now();

    final http.Response res;
    try {
      res = await http
          .get(
            Uri.https(_host, path, params),
            // Хөтөч User-Agent солихыг зөвшөөрдөггүй тул вэбд илгээхгүй
            headers: kIsWeb ? null : {'User-Agent': nominatimUserAgent},
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const GeocodingException(
        'Сервер хариу өгсөнгүй. Интернэтээ шалгаад дахин оролдоно уу.',
      );
    } on http.ClientException catch (e) {
      throw GeocodingException('Сүлжээний алдаа: ${e.message}');
    } on Exception {
      // SocketException гэх мэт (интернэтгүй үед, вэбээс бусад платформд)
      throw const GeocodingException(
        'Сүлжээнд холбогдож чадсангүй. Интернэтээ шалгана уу.',
      );
    }

    switch (res.statusCode) {
      case 200:
        try {
          return jsonDecode(utf8.decode(res.bodyBytes));
        } on FormatException {
          throw const GeocodingException('Серверийн хариуг уншиж чадсангүй.');
        }
      case 429:
        throw const GeocodingException(
          'Хэт олон хүсэлт илгээлээ. Түр хүлээгээд дахин оролдоно уу.',
        );
      case 403:
        throw const GeocodingException(
          'Nominatim хүсэлтийг хаалаа (403). Түр хүлээгээд дахин оролдоно уу.',
        );
      default:
        throw GeocodingException('Серверийн алдаа (HTTP ${res.statusCode}).');
    }
  }

  /// Газрын нэр гэж үзэх address түлхүүрүүд — эхнийх нь илүү тохиромжтой.
  static const _nameKeys = [
    'tourism',
    'natural',
    'water',
    'leisure',
    'historic',
    'village',
    'town',
    'hamlet',
    'city',
    'county',
  ];

  /// Бүс нутаг: аймаг (state), Улаанбаатар бол city.
  static const _regionKeys = ['state', 'city', 'province', 'region', 'county'];

  static PickedLocation _parse(Map<String, dynamic> r) {
    final address = r['address'] is Map
        ? (r['address'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = address[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final rawName = r['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : pick(_nameKeys);

    return PickedLocation(
      latitude: double.parse('${r['lat']}'), // jsonv2: тоог текстээр өгдөг
      longitude: double.parse('${r['lon']}'),
      address: r['display_name'] as String?,
      name: name,
      region: pick(_regionKeys),
    );
  }
}
