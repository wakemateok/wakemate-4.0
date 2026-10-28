String authText(String key, String language) {
  final texts = <String, List<String>>{
    'googleRetry': [
      '重新載入 Google 登入',
      'Retry Google sign-in',
      'Coba lagi login Google',
    ],
    'googleSignIn': [
      '使用 Google 帳號登入',
      'Sign in with Google',
      'Masuk dengan Google',
    ],
    'googleContinue': [
      '使用 Google 帳號繼續',
      'Continue with Google',
      'Lanjutkan dengan Google',
    ],
    'googleAccount': ['Google 帳號綁定', 'Google account', 'Akun Google'],
    'googleLinked': [
      '已綁定 Google 帳號',
      'Google account linked',
      'Akun Google terhubung',
    ],
    'googleLinkHint': [
      '請輸入目前的 WakeMate 密碼，再選擇相同信箱的 Google 帳號。原有紀錄會保留。',
      'Enter your current WakeMate password, then select the Google account with the same email. Your records will be kept.',
      'Masukkan kata sandi WakeMate saat ini, lalu pilih akun Google dengan email yang sama. Catatan Anda tetap tersimpan.',
    ],
    'google_existing_account_sign_in_first': [
      '這個信箱已有 WakeMate 帳號。請先用原密碼登入，再從選單「Google 帳號綁定」完成綁定。',
      'This email already has a WakeMate account. Sign in with your password, then open Google account in the menu to link it.',
      'Email ini sudah memiliki akun WakeMate. Masuk dengan kata sandi, lalu buka Akun Google di menu untuk menghubungkannya.',
    ],
    'google_email_mismatch': [
      '請選擇與目前 WakeMate 帳號相同信箱的 Google 帳號。',
      'Choose the Google account with the same email as your WakeMate account.',
      'Pilih akun Google dengan email yang sama dengan akun WakeMate Anda.',
    ],
    'google_account_already_linked': [
      '這個 Google 帳號或 WakeMate 帳號已有其他綁定，請聯絡研究團隊。',
      'This Google or WakeMate account is already linked. Contact the research team.',
      'Akun Google atau WakeMate ini sudah terhubung. Hubungi tim peneliti.',
    ],
    'google_not_configured': [
      'Google 登入尚未開通，請先使用原本的帳密登入。',
      'Google sign-in is not configured yet. Use your email and password for now.',
      'Login Google belum disiapkan. Gunakan email dan kata sandi untuk sementara.',
    ],
    'google_temporarily_unavailable': [
      '暫時無法使用 Google 登入，請稍後重試或使用帳密登入。',
      'Google sign-in is temporarily unavailable. Try again later or use your password.',
      'Login Google sementara tidak tersedia. Coba lagi nanti atau gunakan kata sandi.',
    ],
    'invalid_google_token': [
      '無法驗證 Google 登入，請重新選擇帳號。',
      'Google sign-in could not be verified. Select your account again.',
      'Login Google tidak dapat diverifikasi. Pilih kembali akun Anda.',
    ],
    'google_configuration_changed': [
      'Google 登入設定已更新，請關閉並重新開啟 WakeMate。',
      'Google sign-in settings changed. Close and reopen WakeMate.',
      'Pengaturan login Google berubah. Tutup dan buka kembali WakeMate.',
    ],
    'google_platform_unavailable': [
      '目前僅 Android App 支援 Google 登入。',
      'Google sign-in is currently available in the Android app only.',
      'Login Google saat ini hanya tersedia di aplikasi Android.',
    ],
    'google_services_unavailable': [
      '手機的 Google 登入服務無法使用，請確認 Google Play 服務已安裝並更新，或使用帳密登入。',
      'Google sign-in services are unavailable. Check that Google Play services are installed and updated, or use your password.',
      'Layanan login Google tidak tersedia. Pastikan layanan Google Play terpasang dan diperbarui, atau gunakan kata sandi.',
    ],
    'auth_flow_in_progress': [
      '登入處理中，請稍候。',
      'Sign-in is in progress. Please wait.',
      'Proses masuk sedang berlangsung. Harap tunggu.',
    ],
    'password_login_not_available': [
      '此帳號使用 Google 登入，尚未設定 WakeMate 密碼。',
      'This account uses Google sign-in and has no WakeMate password.',
      'Akun ini menggunakan login Google dan belum memiliki kata sandi WakeMate.',
    ],
    'retry': ['重試', 'Retry', 'Coba lagi'],
    'passwordHint': [
      '密碼不可空白，建議使用較長且不重複的密碼。',
      'Password cannot be blank. A longer, unique password is recommended.',
      'Kata sandi tidak boleh kosong. Sebaiknya gunakan kata sandi panjang dan unik.',
    ],
    'passwordPolicy': [
      '密碼不可空白，不限制最少字數或字元組合；建議使用較長且不重複的密碼。長度上限為 72 UTF-8 bytes。',
      'Password cannot be blank. No minimum length or character mix is required. A longer, unique password is recommended. Maximum: 72 UTF-8 bytes.',
      'Kata sandi tidak boleh kosong. Tidak ada batas minimum atau kombinasi karakter wajib. Sebaiknya gunakan kata sandi panjang dan unik. Maksimal 72 byte UTF-8.',
    ],
    'passwordChangeRequired': [
      '請更新密碼後再繼續，或登出後重新登入以確認最新帳號狀態。',
      'Update your password, or sign out and sign in again to check your current account status.',
      'Perbarui kata sandi, atau keluar dan masuk kembali untuk memeriksa status akun terbaru.',
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
      key == 'password_requires_12_characters_max_72_bytes' ||
              key == 'password_must_not_be_blank_max_72_bytes'
          ? 'passwordPolicy'
          : key;
  final text = texts[normalized] ?? texts['server_unavailable']!;
  return text[language.startsWith('id')
      ? 2
      : language.startsWith('en')
      ? 1
      : 0];
}
