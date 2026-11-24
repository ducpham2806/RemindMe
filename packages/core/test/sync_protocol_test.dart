import 'package:remindme_core/remindme_core.dart';
import 'package:test/test.dart';

void main() {
  test('Mutation.edit gắn cùng clock cho mọi trường, JSON đúng tên server', () {
    final m = Mutation.edit(SyncTable.bookingDetails, 'id-1', {'seat': '14C', 'class': 'Economy'}, Hlc(1, 2, 'd'));
    final j = m.toJson();
    expect(j['table'], 'booking_details');
    expect(j['op'], 'upsert');
    expect(j['field_clock'], {'seat': '0000000000001:0002:d', 'class': '0000000000001:0002:d'});
    expect(Mutation.fromJson(j).payload, m.payload);
  });

  test('delete không gửi payload', () {
    final j = Mutation(table: SyncTable.items, id: 'x', op: MutationOp.delete).toJson();
    expect(j.containsKey('payload'), isFalse);
  });

  test('parse kết quả sync_push (dạng thật từ pgTAP)', () {
    final r = MutationResult.fromJson({
      'table': 'items', 'id': 'a', 'key': {'id': 'a'}, 'status': 'quota_exceeded',
      'error': 'quota_exceeded', 'details': {'key': 'max_active_appointments', 'limit': 10, 'used': 10},
    });
    expect(r.status, MutationStatus.quotaExceeded);
    expect(r.details!['key'], 'max_active_appointments');
    expect(MutationResult.fromJson({'table': 'items', 'id': 'a', 'status': 'conflict', 'error': 'notes_conflict'}).isNotesConflict, isTrue);
  });

  test('parse trang sync_pull', () {
    final p = PullPage.fromJson({
      'rows': {'items': [{'id': 'a', 'version': 3}], 'occurrence_log': <Object?>[]},
      'next_since': 3, 'has_more': false,
    });
    expect(p.rows[SyncTable.items]!.single['id'], 'a');
    expect(p.rows.containsKey(SyncTable.occurrenceLog), isTrue);
  });

  test('mã lỗi phiên', () {
    expect(SyncErrorCode.fromMessage('session_revoked'), SyncErrorCode.sessionRevoked);
    expect(SyncErrorCode.fromMessage('profile_missing: call profile_init first'), SyncErrorCode.profileMissing);
    expect(SyncErrorCode.fromMessage('???'), SyncErrorCode.unknown);
    expect(SyncErrorCode.sessionRevoked.endsSession, isTrue);
  });
}
