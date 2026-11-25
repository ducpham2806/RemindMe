class Airport {
  const Airport(this.code, this.country, this.tz, this.city);
  final String code;
  /// ISO 3166-1 alpha-2.
  final String country;
  /// Múi giờ IANA của sân bay: giờ in trên vé là giờ địa phương nơi đó.
  final String tz;
  final String city;
}

/// Từ điển mã IATA sân bay (`packages/parsers/data/airports.tsv`, nguồn ở `data/README.md`).
class AirportIndex {
  AirportIndex(Iterable<Airport> airports) : _byCode = {for (final a in airports) a.code: a};

  /// Dòng `iata\tcountry\ttz\tcity`; dòng bắt đầu bằng `#` là chú thích.
  factory AirportIndex.parse(String tsv) {
    final out = <Airport>[];
    for (final line in tsv.split('\n')) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final f = line.split('\t');
      if (f.length < 3) continue;
      out.add(Airport(f[0], f[1], f[2], f.length > 3 ? f[3].trimRight() : ''));
    }
    return AirportIndex(out);
  }

  final Map<String, Airport> _byCode;

  Airport? operator [](String code) => _byCode[code];
  bool contains(String code) => _byCode.containsKey(code);
  int get length => _byCode.length;
}
