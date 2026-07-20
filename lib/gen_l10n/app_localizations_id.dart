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
      'Pilih produk di sekitar RS NTU atau estimasikan kafein secara manual. Detail produk ditampilkan sesuai bahasa aplikasi jika tersedia.';

  @override
  String get loginWelcome => 'Selamat Datang Kembali';

  @override
  String get loginTitle => 'Masuk';

  @override
  String get loginSubtitle => 'Masukkan Email dan kata sandi Anda';

  @override
  String get passwordLabel => 'Kata Sandi';

  @override
  String get loginButton => 'Masuk';

  @override
  String get loginMissingCredentials => 'Masukkan Email dan kata sandi.';

  @override
  String get loginSuccessPrefix => 'Berhasil masuk';

  @override
  String get loginMissingUserId =>
      'Berhasil masuk, tetapi ID pengguna tidak diterima.';

  @override
  String get loginInvalidCredentials =>
      'Gagal masuk: Email atau kata sandi salah.';

  @override
  String get loginFailedPrefix => 'Gagal masuk';

  @override
  String get serverUnknownError => 'Kesalahan server tidak diketahui.';

  @override
  String get serverInvalidResponse =>
      'Server mengembalikan respons yang tidak valid.';

  @override
  String get serverConnectionError => 'Tidak dapat terhubung ke server.';

  @override
  String get noAccountPrompt => 'Belum punya akun?';

  @override
  String get registerLink => 'Daftar di sini';

  @override
  String get registerPageTitle => 'Buat Akun';

  @override
  String get registerTitle => 'Buat Akun Baru';

  @override
  String get nameLabel => 'Nama';

  @override
  String get registerButton => 'Daftar';

  @override
  String get registerMissingFields => 'Harap isi semua kolom.';

  @override
  String get invalidEmailFormat => 'Format Email tidak valid.';

  @override
  String get registerSuccessLogin => 'Pendaftaran berhasil. Silakan masuk.';

  @override
  String get registerEmailAlreadyRegistered =>
      'Pendaftaran gagal: Email ini sudah terdaftar.';

  @override
  String get registerFailedPrefix => 'Pendaftaran gagal';

  @override
  String get bodySettingsTitle => 'Informasi Tubuh';

  @override
  String get genderLabel => 'Jenis Kelamin';

  @override
  String get maleLabel => 'Laki-laki';

  @override
  String get femaleLabel => 'Perempuan';

  @override
  String get ageLabel => 'Usia';

  @override
  String get ageHint => 'Masukkan usia Anda';

  @override
  String get ageRequired => 'Usia wajib diisi.';

  @override
  String get invalidAge => 'Masukkan usia yang valid.';

  @override
  String get heightLabel => 'Tinggi Badan (cm)';

  @override
  String get heightHint => 'Masukkan tinggi badan Anda';

  @override
  String get heightRequired => 'Tinggi badan wajib diisi.';

  @override
  String get invalidHeight => 'Masukkan tinggi badan yang valid.';

  @override
  String get weightLabel => 'Berat Badan (kg)';

  @override
  String get weightHint => 'Masukkan berat badan Anda';

  @override
  String get weightRequired => 'Berat badan wajib diisi.';

  @override
  String get invalidWeight => 'Masukkan berat badan yang valid.';

  @override
  String get bmiHint => 'BMI akan dihitung otomatis.';

  @override
  String get saving => 'Menyimpan...';

  @override
  String get saveSettings => 'Simpan Pengaturan';

  @override
  String get settingsSaved => 'Pengaturan disimpan.';

  @override
  String get settingsSaveFailed => 'Gagal menyimpan pengaturan';

  @override
  String get settingsLoadFailed => 'Gagal memuat data';

  @override
  String get settingsLoadError => 'Kesalahan saat memuat data';

  @override
  String get completeRequiredFieldsAndGender =>
      'Harap isi semua kolom wajib dan pilih jenis kelamin.';

  @override
  String get baselineQuestionnaireTitle => 'Kuesioner Awal Penelitian';

  @override
  String get baselineQuestionnaireBody =>
      'Kuesioner ini hanya perlu diisi satu kali pada awal penelitian. Jika sudah mengisi atau belum bisa mengisi sekarang, Anda dapat melewatinya dan masuk ke WakeMate.';

  @override
  String get questionnaireReturnInstruction =>
      'Setelah selesai mengisi kuesioner, tutup jendela browser dan kembali ke aplikasi WakeMate.';

  @override
  String get baselineQuestionnaireNotConfigured =>
      'Tautan kuesioner awal belum diatur. Anda dapat melewati dan masuk ke aplikasi terlebih dahulu, atau memperbarui tautan nanti.';

  @override
  String get skipEnterApp => 'Lewati dan Masuk ke App';

  @override
  String get linkNotConfiguredSuffix => 'tautan belum diatur.';

  @override
  String get unableToOpenPrefix => 'Tidak dapat membuka';

  @override
  String get chineseBaselineQuestionnaire => 'Kuesioner Awal Bahasa Mandarin';

  @override
  String get indonesianBaselineQuestionnaire =>
      'Kuesioner Awal Bahasa Indonesia';

  @override
  String get chineseDailyQuestionnaire => 'Kuesioner Harian Bahasa Mandarin';

  @override
  String get indonesianDailyQuestionnaire =>
      'Kuesioner Harian Bahasa Indonesia';

  @override
  String get notificationCenterTitle => 'Notifikasi';

  @override
  String get alertnessTapToStart => 'Ketuk Mulai';

  @override
  String get alertnessWait => 'Harap tunggu...';

  @override
  String get alertnessTapNow => 'Ketuk sekarang!';

  @override
  String get alertnessTooEarly => 'Terlalu cepat. Coba lagi.';

  @override
  String get alertnessTrialPrefix => 'Percobaan';

  @override
  String get alertnessTrialSuffix => '';

  @override
  String get millisecondsUnit => 'md';

  @override
  String get alertnessResultTitle => 'Hasil Tes';

  @override
  String get alertnessEachReactionTime => 'Waktu reaksi setiap percobaan:';

  @override
  String get alertnessAverageReactionTime => 'Rata-rata waktu reaksi';

  @override
  String get alertnessChooseKss =>
      'Pilih tingkat kewaspadaan Anda saat ini (KSS):';

  @override
  String get alertnessChooseKssHint => 'Pilih skor KSS';

  @override
  String get alertnessRetest => 'Tes Lagi';

  @override
  String get alertnessDoneClose => 'Selesai dan Tutup';

  @override
  String get alertnessDataSent => 'Data berhasil dikirim.';

  @override
  String get alertnessSubmitFailedStatus => 'Gagal mengirim. Kode status:';

  @override
  String get alertnessNetworkSubmitFailed =>
      'Kesalahan jaringan. Tidak dapat mengirim data.';

  @override
  String get tapHere => 'Ketuk Di Sini';

  @override
  String get startTest => 'Mulai Tes';

  @override
  String get kss1 => 'Sangat waspada';

  @override
  String get kss2 => 'Sangat segar';

  @override
  String get kss3 => 'Waspada';

  @override
  String get kss4 => 'Cukup waspada';

  @override
  String get kss5 => 'Tidak waspada dan tidak mengantuk';

  @override
  String get kss6 => 'Mulai ada tanda mengantuk';

  @override
  String get kss7 => 'Mengantuk, tetapi tidak perlu usaha untuk tetap terjaga';

  @override
  String get kss8 => 'Mengantuk, perlu usaha untuk tetap terjaga';

  @override
  String get kss9 => 'Sangat mengantuk, perlu usaha besar untuk tetap terjaga';

  @override
  String get notificationChannelName => 'Pengingat WakeMate';

  @override
  String get notificationChannelDescription =>
      'Notifikasi rekomendasi dan pengingat kafein WakeMate';
}
