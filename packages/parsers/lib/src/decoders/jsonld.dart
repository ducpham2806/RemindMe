import 'dart:convert';

import '../extract/candidate.dart';

/// schema.org Reservation nhúng trong HTML email (JSON-LD), E1.2. Không phụ thuộc ngôn ngữ của email: nhiều hãng bay, OTA,
/// nhà ga nhúng sẵn (on-device-extraction.md §2). Hỗ trợ Flight, Lodging, Train, Bus, Event, FoodEstablishment, RentalCar.
class JsonLdDecoder {
  const JsonLdDecoder();

  static final _script = RegExp(r'''<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>([\s\S]*?)</script>''', caseSensitive: false);

  List<Candidate> decodeHtml(String html) => [
        for (final m in _script.allMatches(html)) ...decodeJson(_unescapeHtml(m[1]!)),
      ];

  List<Candidate> decodeJson(String json) {
    Object? data;
    try {
      data = jsonDecode(json);
    } on FormatException {
      return const [];
    }
    final out = <Candidate>[];
    for (final node in _nodes(data)) {
      final c = _reservation(node);
      if (c != null) out.add(c);
    }
    return out;
  }

  /// Phẳng hóa: mảng, `@graph`.
  static Iterable<Map<String, Object?>> _nodes(Object? data) sync* {
    if (data is List) {
      for (final x in data) {
        yield* _nodes(x);
      }
    } else if (data is Map) {
      final m = data.cast<String, Object?>();
      if (m['@graph'] case final g?) yield* _nodes(g);
      yield m;
    }
  }

  static String _type(Map<String, Object?>? m) {
    final t = m?['@type'];
    final s = t is List ? (t.isEmpty ? '' : '${t.first}') : '${t ?? ''}';
    return s.replaceFirst(RegExp(r'^(https?://)?schema\.org/'), '');
  }

  static Map<String, Object?>? _map(Object? v) => v is Map ? v.cast<String, Object?>() : (v is List && v.isNotEmpty ? _map(v.first) : null);
  static String? _str(Object? v) {
    if (v == null) return null;
    if (v is Map) return _str(v['name'] ?? v['@id']);
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static Candidate? _reservation(Map<String, Object?> r) {
    final type = _type(r);
    if (!type.endsWith('Reservation')) return null;
    final status = _str(r['reservationStatus'])?.toLowerCase() ?? '';
    if (status.contains('cancel')) return null;
    final f = _map(r['reservationFor']);
    final code = _str(r['reservationNumber']) ?? _str(r['reservationId']);
    final provider = _str(_map(r['provider'])?['name']) ?? _str(_map(r['broker'])?['name']);
    final price = _price(r);
    final party = int.tryParse(_str(r['partySize']) ?? '') ?? _countPeople(r['underName']);
    switch (type) {
      case 'FlightReservation':
        final dep = _map(f?['departureAirport']), arr = _map(f?['arrivalAirport']);
        final airline = _map(f?['airline']);
        final ticket = _map(r['reservedTicket']);
        return Candidate(
          kind: CandidateKind.booking,
          bookingType: BookingType.flight,
          source: 'jsonld',
          fields: CandidateFields(
            confirmationCode: code,
            provider: provider ?? _str(airline?['name']),
            carrierCode: _str(airline?['iataCode']),
            number: _str(f?['flightNumber']),
            origin: Place(code: _str(dep?['iataCode']), name: _str(dep?['name']), terminal: _str(f?['departureTerminal']), gate: _str(f?['departureGate'])),
            destination: Place(code: _str(arr?['iataCode']), name: _str(arr?['name']), terminal: _str(f?['arrivalTerminal'])),
            startsAt: LocalTime.fromIso(_str(f?['departureTime'])),
            endsAt: LocalTime.fromIso(_str(f?['arrivalTime'])),
            seat: _str(_map(ticket?['ticketedSeat'])?['seatNumber']) ?? _str(r['airplaneSeat']),
            travelClass: _str(r['airplaneSeatClass']) ?? _str(_map(ticket?['ticketedSeat'])?['seatingType']),
            passengerCount: party,
            price: price,
          ),
        );
      case 'LodgingReservation':
        return Candidate(
          kind: CandidateKind.booking,
          bookingType: BookingType.hotel,
          source: 'jsonld',
          fields: CandidateFields(
            title: _str(f?['name']),
            confirmationCode: code,
            provider: provider,
            checkIn: LocalTime.fromIso(_str(r['checkinTime']) ?? _str(r['checkinDate'])),
            checkOut: LocalTime.fromIso(_str(r['checkoutTime']) ?? _str(r['checkoutDate'])),
            locationText: _address(f?['address']),
            passengerCount: party,
            price: price,
          ),
        );
      case 'TrainReservation' || 'BusReservation':
        final train = type == 'TrainReservation';
        final dep = _map(f?[train ? 'departureStation' : 'departureBusStop']), arr = _map(f?[train ? 'arrivalStation' : 'arrivalBusStop']);
        final ticket = _map(r['reservedTicket']);
        final seat = _map(ticket?['ticketedSeat']);
        return Candidate(
          kind: CandidateKind.booking,
          bookingType: train ? BookingType.train : BookingType.bus,
          source: 'jsonld',
          fields: CandidateFields(
            confirmationCode: code,
            provider: provider ?? _str(f?['provider']),
            number: _str(f?[train ? 'trainNumber' : 'busNumber']),
            origin: Place(name: _str(dep?['name'])),
            destination: Place(name: _str(arr?['name'])),
            startsAt: LocalTime.fromIso(_str(f?['departureTime'])),
            endsAt: LocalTime.fromIso(_str(f?['arrivalTime'])),
            seat: _str(seat?['seatNumber']),
            carriage: _str(seat?['seatSection']),
            passengerCount: party,
            price: price,
          ),
        );
      case 'EventReservation':
        return Candidate(
          kind: CandidateKind.booking,
          bookingType: BookingType.eventTicket,
          source: 'jsonld',
          fields: CandidateFields(
            title: _str(f?['name']),
            confirmationCode: code,
            provider: provider,
            startsAt: LocalTime.fromIso(_str(f?['startDate'])),
            endsAt: LocalTime.fromIso(_str(f?['endDate'])),
            locationText: _str(_map(f?['location'])?['name']) ?? _address(_map(f?['location'])?['address']),
            seat: _str(_map(_map(r['reservedTicket'])?['ticketedSeat'])?['seatNumber']),
            passengerCount: party,
            price: price,
          ),
        );
      case 'FoodEstablishmentReservation':
        return Candidate(
          kind: CandidateKind.booking,
          bookingType: BookingType.restaurant,
          source: 'jsonld',
          fields: CandidateFields(
            title: _str(f?['name']),
            confirmationCode: code,
            provider: provider,
            startsAt: LocalTime.fromIso(_str(r['startTime'])),
            locationText: _address(f?['address']),
            passengerCount: party,
          ),
        );
      case 'RentalCarReservation':
        return Candidate(
          kind: CandidateKind.booking,
          bookingType: BookingType.carRental,
          source: 'jsonld',
          fields: CandidateFields(
            title: _str(f?['name']),
            confirmationCode: code,
            provider: provider ?? _str(_map(f?['rentalCompany'])?['name']),
            startsAt: LocalTime.fromIso(_str(r['pickupTime'])),
            endsAt: LocalTime.fromIso(_str(r['dropoffTime'])),
            origin: Place(name: _str(_map(r['pickupLocation'])?['name'])),
            destination: Place(name: _str(_map(r['dropoffLocation'])?['name'])),
            price: price,
          ),
        );
      default:
        return null;
    }
  }

  static Price? _price(Map<String, Object?> r) {
    final amount = _str(r['totalPrice']) ?? _str(_map(r['priceSpecification'])?['price']);
    final cur = _str(r['priceCurrency']) ?? _str(_map(r['priceSpecification'])?['priceCurrency']);
    if (amount == null || cur == null || !RegExp(r'^[A-Z]{3}$').hasMatch(cur)) return null;
    final norm = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return RegExp(r'^\d+(\.\d+)?$').hasMatch(norm) ? Price(norm, cur) : null;
  }

  static int? _countPeople(Object? underName) => underName is List ? underName.length : null;

  static String? _address(Object? a) {
    if (a is String) return a.trim().isEmpty ? null : a.trim();
    final m = _map(a);
    if (m == null) return null;
    final parts = [m['streetAddress'], m['addressLocality'], m['addressRegion'], m['addressCountry'] is Map ? _str(m['addressCountry']) : m['addressCountry']]
        .map(_str)
        .whereType<String>()
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String _unescapeHtml(String s) =>
      s.replaceAll('&quot;', '"').replaceAll('&#34;', '"').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&amp;', '&');
}
