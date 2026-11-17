import '../main.dart';
import '../models/notifikasi_model.dart';

class NotifikasiService {
  /// Stream Realtime notifikasi untuk user yang sedang login
  static Stream<List<NotifikasiInboxModel>> streamInboxUser(String userId) {
    return supabase
        .from('notifikasi_inbox')
        .stream(primaryKey: ['id_notifikasi'])
        .eq('id_penerima', userId)
        .order('waktu_dibuat', ascending: false)
        .map((rows) => rows.map((e) => NotifikasiInboxModel.fromMap(e)).toList());
  }

  /// Tandai 1 pesan sudah dibaca
  static Future<void> tandaiDibaca(String idNotifikasi) async {
    await supabase.from('notifikasi_inbox').update({'dibaca': true}).eq('id_notifikasi', idNotifikasi);
  }

  /// Tandai semua pesan milik user sudah dibaca
  static Future<void> tandaiSemuaDibaca(String userId) async {
    await supabase.from('notifikasi_inbox').update({'dibaca': true}).eq('id_penerima', userId).eq('dibaca', false);
  }
}
