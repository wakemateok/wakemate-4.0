String reviewText(String key, String language) {
  const texts = <String, List<String>>{
    'date': ['日期', 'Date', 'Tanggal'],
    'timeTab': ['時間', 'Time', 'Waktu'],
    'caffeine': ['咖啡因攝取', 'Caffeine intake', 'Asupan kafein'],
    'time': ['時間（24 小時制）', 'Time (24-hour)', 'Waktu (24 jam)'],
    'recommendations': [
      '當日咖啡因推薦',
      'Daily caffeine recommendations',
      'Rekomendasi kafein harian',
    ],
    'refreshFailed': [
      '無法更新資料，請檢查網路後重試。下方可能仍是上次資料。',
      'Unable to refresh. Check your connection and retry. Previous data may still be shown.',
      'Data tidak dapat diperbarui. Periksa koneksi dan coba lagi. Data sebelumnya mungkin masih ditampilkan.',
    ],
    'missingSleep': [
      '尚未填寫睡眠紀錄',
      'Sleep record missing',
      'Catatan tidur belum diisi',
    ],
    'missingWake': [
      '尚未填寫目標清醒時段',
      'Target wake period missing',
      'Target waktu terjaga belum diisi',
    ],
    'noDose': [
      '這一天目前沒有推薦攝取時段；不代表需要額外喝咖啡。',
      'No intake times are currently recommended for this day. This does not mean you need extra caffeine.',
      'Belum ada waktu konsumsi yang direkomendasikan untuk tanggal ini. Ini tidak berarti Anda perlu menambah kafein.',
    ],
    'updating': ['更新中', 'Updating', 'Memperbarui'],
    'firstSteps': ['待完成事項', 'Getting started', 'Langkah awal'],
    'profile': ['基本資料', 'Personal details', 'Data pribadi'],
    'sleep': ['睡眠紀錄', 'Sleep record', 'Catatan tidur'],
    'wake': ['清醒時段', 'Wake period', 'Waktu terjaga'],
    'test': ['清醒度測試', 'Alertness test', 'Tes kewaspadaan'],
    'guide': ['開始事項', 'Getting started', 'Langkah awal'],
    'done': ['完成', 'Done', 'Selesai'],
    'sleepByWakeDate': [
      '睡眠時數依起床日期統計',
      'Sleep hours are grouped by wake-up date',
      'Jam tidur dikelompokkan berdasarkan tanggal bangun',
    ],
    'drinkOptions': ['對應飲品', 'Drink options', 'Pilihan minuman'],
    'doseReference': [
      '標示含量與實際含量可能有差異。以下僅換算飲品份量，不是額外攝取建議；不必喝完整杯。',
      'Actual caffeine may differ from labels. These are portion conversions, not advice to consume extra caffeine. A full cup is not required.',
      'Kafein aktual dapat berbeda dari label. Ini hanya konversi porsi, bukan anjuran menambah kafein. Tidak perlu menghabiskan satu gelas.',
    ],
    'noDrinkMatch': [
      '現有商品中沒有合適的份量，請勿為了湊劑量增加攝取。',
      'No suitable portion was found in the current catalog. Do not increase intake just to match a dose.',
      'Tidak ada porsi yang sesuai di katalog saat ini. Jangan menambah konsumsi hanya untuk mencocokkan dosis.',
    ],
    'allBrands': ['所有品牌', 'All brands', 'Semua merek'],
    'whole': ['整杯', 'Full cup', 'Satu gelas'],
    'half': ['半杯', 'Half cup', 'Setengah gelas'],
    'quarter': ['1/4 杯', 'Quarter cup', 'Seperempat gelas'],
    'threeQuarters': ['3/4 杯', 'Three-quarter cup', 'Tiga perempat gelas'],
    'portion': ['實際飲用份量', 'Consumed portion', 'Porsi yang diminum'],
    'recordActual': ['登記實際攝取', 'Log actual intake', 'Catat konsumsi aktual'],
    'perCup': ['整杯標示', 'Full-cup label', 'Label satu gelas'],
    'feedback': ['本次測驗回饋', 'Your test summary', 'Ringkasan tes Anda'],
    'testMeaning': [
      '平均反應時間越小，代表本次有效反應較快。單次結果不能判斷疾病，也不能直接比較短版與長版。',
      'A lower mean time indicates faster valid responses in this test. One result is not a diagnosis; short and long versions are not directly comparable.',
      'Rata-rata waktu yang lebih kecil menunjukkan respons valid yang lebih cepat pada tes ini. Satu hasil bukan diagnosis; versi pendek dan panjang tidak dapat dibandingkan langsung.',
    ],
    'earlyAdvice': [
      '本次有提前按壓。下次請等提示出現後才按下，避免搶按影響結果。',
      'Early responses were recorded. Wait for the signal before pressing next time to avoid affecting the result.',
      'Ada respons terlalu awal. Tunggu tanda muncul sebelum menekan agar hasil tidak terpengaruh.',
    ],
    'lapseAdvice': [
      '本次出現較慢或未回應的紀錄；疲倦、分心或操作環境都可能影響結果，可在休息後再測。',
      'Slow or missed responses were recorded. Fatigue, distraction or testing conditions may affect the result. You can test again after resting.',
      'Ada respons lambat atau terlewat. Kelelahan, gangguan perhatian, atau kondisi tes dapat memengaruhi hasil. Anda dapat mengulang setelah beristirahat.',
    ],
    'sleepyAdvice': [
      '你填寫的睡意分數顯示目前感到睏倦。請先休息，避免駕駛或其他需要高度注意力的活動。',
      'Your sleepiness rating indicates that you feel sleepy. Rest first and avoid driving or other activities requiring close attention.',
      'Nilai kantuk Anda menunjukkan bahwa Anda mengantuk. Beristirahatlah dan hindari mengemudi atau aktivitas yang memerlukan perhatian tinggi.',
    ],
    'generalAdvice': [
      '若持續感到睏倦或睡眠受到困擾，請與研究團隊或醫師討論；不要只靠咖啡因取代休息。',
      'Discuss persistent sleepiness or sleep problems with the research team or a clinician. Caffeine should not replace rest.',
      'Diskusikan kantuk atau masalah tidur yang menetap dengan tim penelitian atau dokter. Kafein tidak menggantikan istirahat.',
    ],
    'testRecorded': ['有效反應', 'Valid responses', 'Respons valid'],
    'calculating': [
      '正在更新推薦',
      'Updating recommendations',
      'Memperbarui rekomendasi',
    ],
    'calculationFailed': [
      '紀錄已儲存，但推薦尚未更新完成。請稍後重新整理。',
      'Your records are saved, but recommendations could not be updated. Refresh again later.',
      'Catatan tersimpan, tetapi rekomendasi belum dapat diperbarui. Muat ulang nanti.',
    ],
    'savedRecommendationPending': [
      '紀錄已儲存，但推薦尚未更新；不必重複新增。',
      'Your records are saved, but recommendations are not updated. Do not add the same records again.',
      'Catatan sudah tersimpan, tetapi rekomendasi belum diperbarui. Jangan menambah catatan yang sama lagi.',
    ],
  };
  final index =
      language.startsWith('id')
          ? 2
          : language.startsWith('en')
          ? 1
          : 0;
  return (texts[key] ?? [key, key, key])[index];
}

String portionText(double fraction, String language) => reviewText(
  fraction == 1
      ? 'whole'
      : fraction == .75
      ? 'threeQuarters'
      : fraction == .5
      ? 'half'
      : 'quarter',
  language,
);
