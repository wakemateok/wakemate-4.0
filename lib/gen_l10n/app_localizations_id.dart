// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get languageSettingsTitle => 'Pengaturan Bahasa';

  @override
  String get selectYourLanguage => 'Pilih bahasa pilihan Anda';

  @override
  String get caffeineIntake => 'Asupan Kafein';

  @override
  String get sleepDuration => 'Durasi Tidur';

  @override
  String get addRecord => 'Tambah Catatan';

  @override
  String get caffeineIntakeToday => 'Asupan Kafein Hari Ini';

  @override
  String get sleepDurationToday => 'Durasi Tidur Hari Ini';

  @override
  String get unitMg => ' mg';

  @override
  String get unitHours => ' jam';

  @override
  String get wakeTime => 'Waktu Terjaga';

  @override
  String get sleepTime => 'Waktu Tidur';

  @override
  String get caffeineLog => 'Catatan Kafein';

  @override
  String get inputHistory => 'Riwayat Input';

  @override
  String get calculateRecommendation => 'Hitung Rekomendasi';

  @override
  String get recommendationHistory => 'Riwayat Rekomendasi';

  @override
  String get dailyQuestionnaire => 'Kuesioner Harian';

  @override
  String get personalSettings => 'Pengaturan Pribadi';

  @override
  String get alertnessTest => 'Tes Kewaspadaan';

  @override
  String get logout => 'Keluar';

  @override
  String get userFallback => 'Pengguna';

  @override
  String get addData => 'Tambah Data';

  @override
  String get targetWakePeriod => 'Target Waktu Terjaga';

  @override
  String get actualSleepPeriod => 'Periode Tidur Aktual';

  @override
  String get addCaffeineRecord => 'Tambah Catatan Kafein';

  @override
  String get dailyQuestionnaireReminder => 'Pengingat Kuesioner Harian';

  @override
  String get dailyQuestionnaireMessage =>
      'Silakan isi kuesioner harian sesuai kondisi hari ini. Jika sudah mengisi atau ingin nanti, Anda dapat melewatinya dulu.';

  @override
  String get remindLater => 'Ingatkan Nanti';

  @override
  String get skipToday => 'Lewati Hari Ini';

  @override
  String get questionnaireLoading =>
      'Tautan kuesioner sedang dimuat. Coba lagi nanti.';

  @override
  String get questionnaireNotConfigured => 'Tautan kuesioner belum diatur.';

  @override
  String get openFailed => 'Tidak dapat membuka tautan.';

  @override
  String get allInputHistory => 'Semua Riwayat Input';

  @override
  String get allInputHistorySubtitle =>
      'Menampilkan semua catatan aktif. Anda dapat mengedit atau menghapus catatan lama di sini.';

  @override
  String get historyLoading => 'Memuat riwayat input...';

  @override
  String get noInputRecords => 'Belum ada catatan input.';

  @override
  String get noSleepRecords => 'Belum ada catatan tidur';

  @override
  String get noWakeRecords => 'Belum ada target waktu terjaga';

  @override
  String get noCaffeineRecords => 'Belum ada catatan kafein';

  @override
  String get startTime => 'Waktu Mulai';

  @override
  String get endTime => 'Waktu Selesai';

  @override
  String get drinkingTime => 'Waktu Minum';

  @override
  String get drinkName => 'Nama Minuman';

  @override
  String get caffeineAmountMg => 'Jumlah Kafein (mg)';

  @override
  String get duration => 'Durasi';

  @override
  String get hours => 'jam';

  @override
  String get minutes => 'menit';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Hapus';

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get confirmDelete => 'Konfirmasi Hapus';

  @override
  String get deleteConfirmMessage =>
      'Hapus catatan ini? Server akan menghitung ulang setelah penghapusan.';

  @override
  String get chooseDateTime => 'Pilih tanggal dan waktu';

  @override
  String get dateTimeHelper => 'Bisa diketik manual, contoh 2026-06-23 19:30';

  @override
  String get invalidDateTimeFormat => 'Gunakan format yyyy-MM-dd HH:mm.';

  @override
  String get endAfterStart =>
      'Waktu selesai harus lebih lambat dari waktu mulai.';

  @override
  String get updated => 'Data diperbarui.';

  @override
  String get deleted => 'Data dihapus.';

  @override
  String get updateFailed => 'Gagal memperbarui';

  @override
  String get deleteFailed => 'Gagal menghapus';

  @override
  String get networkError => 'Kesalahan jaringan';

  @override
  String get wakePageTitle => 'Atur Target Waktu Terjaga';

  @override
  String get wakeInstruction =>
      'Masukkan waktu saat Anda perlu tetap terjaga atau fokus. Untuk menguji rekomendasi, gunakan waktu di masa depan.';

  @override
  String get wakeSlot => 'Waktu Terjaga';

  @override
  String get addWakeSlot => 'Tambah Waktu';

  @override
  String get saveWakeSlots => 'Simpan Target Waktu Terjaga';

  @override
  String get wakeSaveSuccess => 'Target waktu terjaga disimpan.';

  @override
  String get wakeSavePartial => 'Sebagian target waktu terjaga gagal disimpan.';

  @override
  String get wakeSaveFailed => 'Gagal menyimpan target waktu terjaga.';

  @override
  String get deleteOldRecordsWarning =>
      'Catatan lama gagal dibersihkan, tetapi catatan baru tetap dikirim. Hapus duplikat dari riwayat input jika perlu.';

  @override
  String get sleepPageTitle => 'Tambah Periode Tidur Aktual';

  @override
  String get sleepInstruction =>
      'Masukkan waktu saat Anda benar-benar tidur dan waktu bangun terakhir.';

  @override
  String get sleepStart => 'Mulai Tidur';

  @override
  String get sleepEnd => 'Bangun';

  @override
  String get saveSleep => 'Simpan Periode Tidur';

  @override
  String get sleepTooLong => 'Periode tidur tidak boleh lebih dari 48 jam.';

  @override
  String get sleepSaveSuccess => 'Periode tidur disimpan.';

  @override
  String get sleepSaveFailed => 'Gagal menyimpan periode tidur.';

  @override
  String get recommendationTitle => 'Rekomendasi Kafein';

  @override
  String get calculatingRecommendation => 'Menghitung rekomendasi kafein...';

  @override
  String get recommendationNote =>
      'Jika layanan Render sedang aktif kembali, ini mungkin perlu waktu.';

  @override
  String get recommendationFetched => 'Rekomendasi diperbarui.';

  @override
  String get recommendationFailed => 'Gagal menghitung rekomendasi';

  @override
  String get noRecommendationTitle => 'Belum ada rekomendasi';

  @override
  String get noRecommendationBody =>
      'Pastikan target waktu terjaga di masa depan dan periode tidur aktual sudah disimpan. Jika kewaspadaan diprediksi cukup, model mungkin tidak memberi rekomendasi kafein.';

  @override
  String get retry => 'Coba Lagi';

  @override
  String get back => 'Kembali';

  @override
  String get recommendationItem => 'Rekomendasi Kafein';

  @override
  String get recommendedTiming => 'Waktu Rekomendasi';

  @override
  String get recommendedAmount => 'Jumlah Rekomendasi';

  @override
  String get calculateAgain => 'Hitung Ulang';

  @override
  String get noRecommendationsForDate =>
      'Tidak ada rekomendasi untuk tanggal ini.';

  @override
  String get productCatalog => 'Katalog Produk';

  @override
  String get manualEstimate => 'Estimasi Manual';

  @override
  String get chooseStore => 'Pilih Toko';

  @override
  String get chooseProduct => 'Pilih Produk';

  @override
  String get source => 'Sumber';

  @override
  String get estimateCaffeine => 'Estimasi Kafein';

  @override
  String get chooseDrinkType => 'Pilih Jenis Minuman';

  @override
  String get chooseAmount => 'Pilih Jumlah';

  @override
  String get strength => 'Kepekatan';

  @override
  String get light => 'Ringan';

  @override
  String get normal => 'Normal';

  @override
  String get strong => 'Pekat';

  @override
  String get uncertainAmount => 'Jumlah tidak pasti';

  @override
  String get uncertainAmountHelp =>
      'Aktifkan jika ukuran atau kepekatan hanya perkiraan.';

  @override
  String get otherDrink => 'Minuman Lain';

  @override
  String get manualInput => 'Input Manual';

  @override
  String get saveCaffeine => 'Simpan Catatan Kafein';

  @override
  String get caffeineSaveSuccess => 'Catatan kafein disimpan.';

  @override
  String get caffeineSaveFailed => 'Gagal menyimpan catatan kafein.';

  @override
  String get enterDrinkingTime => 'Masukkan waktu minum.';

  @override
  String get enterPositiveCaffeine => 'Masukkan jumlah kafein lebih dari 0.';

  @override
  String get caffeineIntro =>
      'Pilih produk di sekitar RS NTU atau estimasikan kafein secara manual. Nama produk dibiarkan sesuai label sumber.';
}
