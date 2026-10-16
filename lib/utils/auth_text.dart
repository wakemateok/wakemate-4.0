String authText(String key, String language) {
  final texts = <String, List<String>>{
    'passwordPolicy': [
      '密碼至少 12 個字元，UTF-8 長度不可超過 72 bytes。',
      'Use at least 12 characters and no more than 72 UTF-8 bytes.',
      'Gunakan minimal 12 karakter dan maksimal 72 byte UTF-8.',
    ],
    'passwordChangeRequired': [
      '為保護帳號，請先更新原本較短的密碼。',
      'Update your short password before continuing.',
      'Perbarui kata sandi pendek Anda sebelum melanjutkan.',
    ],
    'currentPassword': ['目前密碼', 'Current password', 'Kata sandi saat ini'],
    'newPassword': ['新密碼', 'New password', 'Kata sandi baru'],
    'confirmPassword': [
      '確認新密碼',
      'Confirm new password',
      'Konfirmasi kata sandi baru',
    ],
    'passwordMismatch': [
      '兩次輸入的密碼不一致。',
      'The passwords do not match.',
      'Kata sandi tidak cocok.',
    ],
    'changePassword': ['變更密碼', 'Change password', 'Ubah kata sandi'],
    'invalid_credentials': [
      '電子郵件或密碼不正確。',
      'Incorrect email or password.',
      'Email atau kata sandi salah.',
    ],
    'too_many_attempts': [
      '嘗試次數過多，請 15 分鐘後再試。',
      'Too many attempts. Try again in 15 minutes.',
      'Terlalu banyak percobaan. Coba lagi dalam 15 menit.',
    ],
    'email_already_registered': [
      '此電子郵件已註冊。',
      'This email is already registered.',
      'Email ini sudah terdaftar.',
    ],
    'invalid_current_password': [
      '目前密碼不正確。',
      'The current password is incorrect.',
      'Kata sandi saat ini salah.',
    ],
    'choose_a_different_password': [
      '新密碼不可與目前密碼相同。',
      'Choose a different password.',
      'Pilih kata sandi yang berbeda.',
    ],
    'server_unavailable': [
      '暫時無法連線，請確認網路後再試。',
      'Unable to connect. Check your connection and try again.',
      'Tidak dapat terhubung. Periksa koneksi dan coba lagi.',
    ],
    'session_expired': [
      '登入已失效，請重新登入。',
      'Your session has expired. Sign in again.',
      'Sesi telah berakhir. Silakan masuk kembali.',
    ],
    'invalid_session': [
      '登入資料無效，請重新登入。',
      'Invalid session. Sign in again.',
      'Sesi tidak valid. Silakan masuk kembali.',
    ],
    'showPassword': [
      '顯示或隱藏密碼',
      'Show or hide password',
      'Tampilkan atau sembunyikan kata sandi',
    ],
  };
  final normalized =
      key == 'password_requires_12_characters_max_72_bytes'
          ? 'passwordPolicy'
          : key;
  final text = texts[normalized] ?? texts['server_unavailable']!;
  return text[language.startsWith('id')
      ? 2
      : language.startsWith('en')
      ? 1
      : 0];
}
