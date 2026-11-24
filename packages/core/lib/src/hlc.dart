/// Hybrid Logical Clock cho Last-Writer-Wins theo trường (data-model.md §3).
///
/// Dạng chuỗi khớp với server: `<epoch_ms 13 chữ số>:<counter 4 chữ số>:<node>`.
/// So sánh chuỗi theo byte (Postgres `collate "C"`) cho cùng kết quả với [compareTo]
/// vì mọi phần đều độ dài cố định trừ node, và node chỉ gồm ASCII không có ':'.
library;

final _nodePattern = RegExp(r'^[A-Za-z0-9._-]{1,64}$');

class Hlc implements Comparable<Hlc> {
  Hlc(this.millis, this.counter, this.node) {
    if (millis < 0 || millis > 9999999999999) {
      throw ArgumentError.value(millis, 'millis', 'phải vừa 13 chữ số');
    }
    if (counter < 0 || counter > maxCounter) {
      throw ArgumentError.value(counter, 'counter', 'phải trong 0..$maxCounter');
    }
    if (!_nodePattern.hasMatch(node)) {
      throw ArgumentError.value(node, 'node', 'chỉ gồm [A-Za-z0-9._-], tối đa 64 ký tự');
    }
  }

  static const maxCounter = 9999;

  final int millis;
  final int counter;
  final String node;

  factory Hlc.parse(String packed) {
    final parts = packed.split(':');
    if (parts.length != 3 || parts[0].length != 13 || parts[1].length != 4) {
      throw FormatException('HLC không hợp lệ', packed);
    }
    return Hlc(int.parse(parts[0]), int.parse(parts[1]), parts[2]);
  }

  String pack() =>
      '${millis.toString().padLeft(13, '0')}:${counter.toString().padLeft(4, '0')}:$node';

  @override
  int compareTo(Hlc other) {
    if (millis != other.millis) return millis.compareTo(other.millis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return node.compareTo(other.node);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) => other is Hlc && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(millis, counter, node);

  @override
  String toString() => pack();
}

/// Đồng hồ HLC của một thiết bị. Không thread-safe: dùng 1 instance trong 1 isolate.
class HlcClock {
  HlcClock(this.node, {int Function()? now, Hlc? last, this.maxDriftMs = 24 * 3600 * 1000})
      : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
        _last = last ?? Hlc(0, 0, node);

  final String node;
  final int Function() _now;
  /// Clock từ xa vượt giờ máy quá ngưỡng này thì [receive] trả về true (để báo telemetry);
  /// vẫn nhận để không chặn sync.
  final int maxDriftMs;
  Hlc _last;

  Hlc get last => _last;

  /// Clock cho một lần sửa local.
  Hlc send() {
    final wall = _now();
    if (wall > _last.millis) {
      _last = Hlc(wall, 0, node);
    } else if (_last.counter < Hlc.maxCounter) {
      _last = Hlc(_last.millis, _last.counter + 1, node);
    } else {
      _last = Hlc(_last.millis + 1, 0, node);
    }
    return _last;
  }

  /// Gộp clock nhận từ server/thiết bị khác. Trả true nếu clock đó lệch quá [maxDriftMs] so với giờ máy.
  bool receive(Hlc remote) {
    final wall = _now();
    final drifted = remote.millis - wall > maxDriftMs;
    final maxMillis = [wall, _last.millis, remote.millis].reduce((a, b) => a > b ? a : b);
    int counter;
    if (maxMillis == _last.millis && maxMillis == remote.millis) {
      counter = (_last.counter > remote.counter ? _last.counter : remote.counter) + 1;
    } else if (maxMillis == _last.millis) {
      counter = _last.counter + 1;
    } else if (maxMillis == remote.millis) {
      counter = remote.counter + 1;
    } else {
      counter = 0;
    }
    _last = counter > Hlc.maxCounter ? Hlc(maxMillis + 1, 0, node) : Hlc(maxMillis, counter, node);
    return drifted;
  }
}
