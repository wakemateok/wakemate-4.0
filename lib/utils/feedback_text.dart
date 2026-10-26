String feedbackText(String key, String language) {
  const texts = <String, List<String>>{
    'title': ['問題回報與建議', 'Report a problem', 'Laporkan masalah'],
    'recipient': ['收件信箱', 'Recipient', 'Penerima'],
    'category': ['問題類型', 'Category', 'Kategori'],
    'general': ['操作問題', 'App issue', 'Masalah aplikasi'],
    'recommendation': ['推薦結果', 'Recommendations', 'Rekomendasi'],
    'notification': ['通知提醒', 'Notifications', 'Notifikasi'],
    'account': ['帳號與資料', 'Account and data', 'Akun dan data'],
    'suggestion': ['功能建議', 'Suggestion', 'Saran'],
    'subject': ['主旨（選填）', 'Subject (optional)', 'Subjek (opsional)'],
    'description': [
      '問題描述或建議',
      'Description or suggestion',
      'Deskripsi atau saran',
    ],
    'required': [
      '請填寫問題描述或建議',
      'Enter a description or suggestion',
      'Masukkan deskripsi atau saran',
    ],
    'privacy': [
      '請勿填入密碼、病歷或可辨識病患的個人資料。',
      'Do not include passwords, medical records or identifiable patient information.',
      'Jangan sertakan kata sandi, rekam medis, atau informasi yang dapat mengidentifikasi pasien.',
    ],
    'includeVersion': [
      '附上 App 版本與測試版本',
      'Include app version and test mode',
      'Sertakan versi aplikasi dan mode tes',
    ],
    'openMail': ['開啟郵件', 'Open email', 'Buka email'],
    'copy': ['複製回報內容', 'Copy report', 'Salin laporan'],
    'copied': ['回報內容已複製', 'Report copied', 'Laporan disalin'],
    'copyFailed': [
      '無法複製，請手動選取內容。',
      'Unable to copy. Select the text manually.',
      'Tidak dapat menyalin. Pilih teks secara manual.',
    ],
    'mailOpened': [
      '已開啟郵件程式，請確認內容後按下寄出。',
      'Email composer opened. Review the message and press Send.',
      'Aplikasi email dibuka. Periksa pesan lalu tekan Kirim.',
    ],
    'mailUnavailable': [
      '無法開啟郵件程式。可先複製內容，再寄到上方信箱。',
      'Unable to open an email app. Copy the report and send it to the address above.',
      'Tidak dapat membuka aplikasi email. Salin laporan dan kirim ke alamat di atas.',
    ],
    'discardTitle': [
      '離開問題回報？',
      'Leave this report?',
      'Tinggalkan laporan ini?',
    ],
    'discardBody': [
      '尚未寄出的內容不會保存在 App。',
      'Unsent text will not be saved in the app.',
      'Teks yang belum dikirim tidak disimpan di aplikasi.',
    ],
    'stay': ['繼續填寫', 'Keep editing', 'Lanjutkan mengedit'],
    'leave': ['離開', 'Leave', 'Keluar'],
    'version': ['App 版本', 'App version', 'Versi aplikasi'],
  };
  final index =
      language.startsWith('id')
          ? 2
          : language.startsWith('en')
          ? 1
          : 0;
  return (texts[key] ?? [key, key, key])[index];
}
