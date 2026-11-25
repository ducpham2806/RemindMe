import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Dưới ngưỡng này trường đọc tự động được tô `warning` (design-system.md `ImportReviewCard`): chỉ pattern 0,6, suy luận 0,4.
const lowConfidence = 0.7;

/// Còn trường độ tin cậy thấp người dùng chưa sửa, trong các trường form cho sửa (trường không được lưu vào item, như số khách,
/// không làm thẻ báo mãi không tắt được).
bool needsCheck(Candidate c) => reviewKeys(c).any((k) => (c.fieldConfidence[k] ?? 1) < lowConfidence);

/// Khóa `fieldConfidence` mà form sửa được cho [c].
Set<String> reviewKeys(Candidate c) {
  final isTask = c.kind == CandidateKind.task, isHotel = c.bookingType == BookingType.hotel;
  return {
    'title',
    isTask ? 'due' : (isHotel ? 'check_in' : 'starts_at'),
    if (!isTask) isHotel ? 'check_out' : 'ends_at',
    if (c.bookingType != BookingType.flight) 'location_text',
    if (!isTask) 'confirmation_code',
    if (_hasNumber(c)) ...{'number', 'carrier_code'},
    if (_hasSeat(c)) 'seat',
    if (c.bookingType == BookingType.train) 'carriage',
    if (c.kind == CandidateKind.appointment) ...{'department', 'queue_number', 'preparation'},
  };
}

bool _hasNumber(Candidate c) => c.bookingType == BookingType.flight || c.bookingType == BookingType.train;
bool _hasSeat(Candidate c) => const {BookingType.flight, BookingType.train, BookingType.bus, BookingType.eventTicket}.contains(c.bookingType);

/// Mở form sửa 1 đề xuất (E5.1). Trả bản đã sửa, null nếu hủy. Trường đã sửa có độ tin cậy 1 (người dùng xác nhận).
/// [title]: tên đang hiện ở màn Xem lại (có thể là tên mặc định ghép từ số chuyến).
Future<Candidate?> editCandidate(BuildContext context, Candidate c, {required CivilDate today, String? title}) =>
    Navigator.of(context).push<Candidate>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => CandidateEditorScreen(candidate: c, today: today, title: title)),
    );

enum _TimeSlot { start, end }

class CandidateEditorScreen extends StatefulWidget {
  const CandidateEditorScreen({super.key, required this.candidate, required this.today, this.title});
  final Candidate candidate;
  final CivilDate today;
  final String? title;

  @override
  State<CandidateEditorScreen> createState() => _CandidateEditorScreenState();
}

class _CandidateEditorScreenState extends State<CandidateEditorScreen> {
  Candidate get c => widget.candidate;
  CandidateFields get f => c.fields;
  bool get _isTask => c.kind == CandidateKind.task;
  bool get _isHotel => c.bookingType == BookingType.hotel;
  bool get _hasEnd => !_isTask && (c.kind == CandidateKind.booking || f.endsAt != null || f.checkOut != null);

  /// Khóa trường theo schema (như `fieldConfidence`) của ô bắt đầu/kết thúc.
  String get _startKey => _isTask ? 'due' : (_isHotel ? 'check_in' : 'starts_at');
  String get _endKey => _isHotel ? 'check_out' : 'ends_at';

  late LocalTime? _start = _isTask ? (f.due ?? f.startsAt) : (_isHotel ? f.checkIn : f.startsAt);
  late LocalTime? _end = _isHotel ? f.checkOut : f.endsAt;
  final _edited = <String>{};
  late final Map<String, TextEditingController> _text = {
    'title': TextEditingController(text: widget.title ?? f.title),
    if (c.bookingType != BookingType.flight) 'location_text': TextEditingController(text: f.locationText),
    if (!_isTask) 'confirmation_code': TextEditingController(text: f.confirmationCode),
    if (_hasNumber(c)) 'number': TextEditingController(text: _numberText),
    if (_hasSeat(c)) 'seat': TextEditingController(text: f.seat),
    if (c.bookingType == BookingType.train) 'carriage': TextEditingController(text: f.carriage),
    if (c.kind == CandidateKind.appointment) ...{
      'department': TextEditingController(text: f.department),
      'queue_number': TextEditingController(text: f.queueNumber),
      'preparation': TextEditingController(text: f.preparation),
    },
  };

  @override
  void dispose() {
    for (final t in _text.values) {
      t.dispose();
    }
    super.dispose();
  }

  /// Số chuyến bay hiện 1 ô "ZZ 245" (mã hãng + số), số hiệu tàu "SE3".
  String? get _numberText => [?f.carrierCode, ?f.number].join(' ').trim().isEmpty ? null : [?f.carrierCode, ?f.number].join(' ');

  bool _warn(String key) {
    final keys = key == 'number' ? const ['number', 'carrier_code'] : [key];
    return !_edited.contains(key) && keys.any((k) => (c.fieldConfidence[k] ?? 1) < lowConfidence);
  }

  void _save() {
    String? text(String k) {
      final v = _text[k]?.text.trim();
      return v == null || v.isEmpty ? null : v;
    }

    var fields = f.copyWith(
      title: text('title'),
      locationText: _text.containsKey('location_text') ? text('location_text') : f.locationText,
      confirmationCode: _text.containsKey('confirmation_code') ? text('confirmation_code') : f.confirmationCode,
      seat: _text.containsKey('seat') ? text('seat') : f.seat,
      carriage: _text.containsKey('carriage') ? text('carriage') : f.carriage,
      department: _text.containsKey('department') ? text('department') : f.department,
      queueNumber: _text.containsKey('queue_number') ? text('queue_number') : f.queueNumber,
      preparation: _text.containsKey('preparation') ? text('preparation') : f.preparation,
    );
    if (_text.containsKey('number')) {
      final v = text('number');
      final m = v == null || c.bookingType != BookingType.flight ? null : RegExp(r'^([A-Z0-9]{2})\s?(\d{1,4}[A-Z]?)$').firstMatch(v.toUpperCase());
      fields = m == null ? fields.copyWith(number: v, carrierCode: c.bookingType == BookingType.flight ? null : f.carrierCode) : fields.copyWith(carrierCode: m[1], number: m[2]);
    }
    if (_edited.contains(_startKey)) {
      fields = switch (_startKey) {
        'due' => fields.copyWith(due: _start, startsAt: f.due == null ? _start : f.startsAt),
        'check_in' => fields.copyWith(checkIn: _start),
        _ => fields.copyWith(startsAt: _start),
      };
    }
    if (_edited.contains(_endKey)) fields = _isHotel ? fields.copyWith(checkOut: _end) : fields.copyWith(endsAt: _end);

    for (final e in _text.entries) {
      if ((e.value.text.trim()) != (_initialText(e.key) ?? '')) _edited.add(e.key);
    }
    final issues = [...c.issues];
    if (_edited.contains(_startKey)) {
      issues.removeWhere((i) => i == 'past_date' || i == 'date_order_ambiguous');
      if (_start != null && _start!.local.substring(0, 10).compareTo(widget.today.toIso()) < 0) issues.add('past_date');
    }
    if (_edited.contains(_endKey)) issues.removeWhere((i) => i == 'arrival_next_day' || i == 'check_out_before_check_in');
    if (_edited.contains('number')) _edited.add('carrier_code');
    Navigator.of(context).pop(c.copyWith(
      fields: fields,
      fieldConfidence: {...c.fieldConfidence, for (final k in _edited) k: 1.0},
      issues: issues,
    ));
  }

  String? _initialText(String key) => switch (key) {
        'title' => widget.title ?? f.title,
        'location_text' => f.locationText,
        'confirmation_code' => f.confirmationCode,
        'number' => _numberText,
        'seat' => f.seat,
        'carriage' => f.carriage,
        'department' => f.department,
        'queue_number' => f.queueNumber,
        'preparation' => f.preparation,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = {
      'title': l.itemTitleLabel,
      'location_text': l.importFieldLocation,
      'confirmation_code': l.importFieldCode,
      'number': c.bookingType == BookingType.flight ? l.importFieldFlightNumber : l.importFieldTrainNumber,
      'seat': l.importFieldSeat,
      'carriage': l.importFieldCarriage,
      'department': l.importFieldDepartment,
      'queue_number': l.importFieldQueue,
      'preparation': l.importFieldPreparation,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l.importEditTitle),
        actions: [TextButton(key: const Key('importEditSave'), onPressed: _save, child: Text(l.quickAddSave))],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(Tokens.screenMargin),
        children: [
          _field(context, 'title', labels['title']!, fieldKey: const Key('importName')),
          _timeRow(context, _TimeSlot.start, _isTask ? l.importFieldDue : l.importFieldStart),
          if (_hasEnd) _timeRow(context, _TimeSlot.end, l.importFieldEnd),
          for (final k in _text.keys.where((k) => k != 'title')) _field(context, k, labels[k]!),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String key, String label, {Key? fieldKey}) {
    final warn = _warn(key);
    final color = RemindColors.of(context).warning;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: Tokens.space4),
      child: TextField(
        key: fieldKey ?? Key('importField-$key'),
        controller: _text[key],
        minLines: 1,
        maxLines: key == 'preparation' || key == 'location_text' ? 3 : 1,
        onChanged: (_) => setState(() => _edited.add(key)),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: warn ? OutlineInputBorder(borderSide: BorderSide(color: color, width: 2)) : null,
          suffixIcon: warn ? _checkIcon(context) : null,
        ),
      ),
    );
  }

  Widget _checkIcon(BuildContext context) => Tooltip(
        message: AppLocalizations.of(context).importFieldCheck,
        child: Icon(Icons.info_outline, color: RemindColors.of(context).warning, semanticLabel: AppLocalizations.of(context).importFieldCheck),
      );

  Widget _timeRow(BuildContext context, _TimeSlot slot, String label) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final key = slot == _TimeSlot.start ? _startKey : _endKey;
    final value = slot == _TimeSlot.start ? _start : _end;
    final wall = _wallOf(value);
    final warn = _warn(key);
    final fmt = Fmt.of(context);

    void set(LocalTime? v) => setState(() {
          if (slot == _TimeSlot.start) {
            _start = v;
          } else {
            _end = v;
          }
          _edited.add(key);
        });

    Future<void> pickDate() async {
      final initial = wall?.date ?? _wallOf(_start)?.date ?? widget.today;
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(initial.year, initial.month, initial.day),
        firstDate: DateTime(widget.today.year - 5),
        lastDate: DateTime(widget.today.year + 20),
      );
      if (picked == null) return;
      set(_withWall(value, CivilDate.of(picked), wall?.time));
    }

    Future<void> pickTime() async {
      final t = wall?.time;
      final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: t?.hour ?? 9, minute: t?.minute ?? 0));
      if (picked == null) return;
      set(_withWall(value, wall?.date ?? widget.today, CivilTime(picked.hour, picked.minute)));
    }

    final date = wall == null ? null : DateTime(wall.date.year, wall.date.month, wall.date.day);
    final time = wall?.time == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: wall!.time!.hour, minute: wall.time!.minute),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: Tokens.space4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: warn ? OutlineInputBorder(borderSide: BorderSide(color: RemindColors.of(context).warning, width: 2)) : null,
          suffixIcon: warn ? _checkIcon(context) : null,
        ),
        child: Wrap(
          spacing: Tokens.space2,
          runSpacing: Tokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              key: Key('importEdit-$key-date'),
              avatar: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(date == null ? l.itemAddDate : fmt.date(date, now: DateTime(widget.today.year))),
              onPressed: pickDate,
            ),
            if (wall != null)
              ActionChip(
                key: Key('importEdit-$key-time'),
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(time ?? l.itemAddTime),
                onPressed: pickTime,
              ),
            if (wall?.time != null)
              IconButton(
                tooltip: l.itemRemoveTime,
                icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurfaceVariant),
                onPressed: () => set(_withWall(value, wall!.date, null)),
              ),
          ],
        ),
      ),
    );
  }

  /// Giờ in trên tài liệu ('YYYY-MM-DD[THH:MM]'), đọc như giờ tường của nơi đó (không đổi múi giờ).
  static CivilDateTime? _wallOf(LocalTime? t) {
    if (t == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2}))?').firstMatch(t.local);
    if (m == null || !CivilDate.isValid(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!))) return null;
    final d = CivilDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    return CivilDateTime(d, m[4] == null ? null : CivilTime(int.parse(m[4]!), int.parse(m[5]!)));
  }

  /// Giữ múi giờ của nguồn (giờ bay theo sân bay); nguồn chỉ có offset thì giữ offset (giờ tường vẫn theo offset đó).
  static LocalTime _withWall(LocalTime? old, CivilDate d, CivilTime? t) {
    final iso = d.toIso();
    final local = t == null ? iso : '${iso}T${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final keepOffset = old?.tz == null && old?.utcOffsetMinutes != null;
    return LocalTime(local, tz: old?.tz, utcOffsetMinutes: keepOffset ? old!.utcOffsetMinutes : null);
  }
}
