import 'package:my_app/data/ntu_hospital_caffeine_catalog.dart';

String catalogProductName(CaffeineCatalogItem item, String language) {
  if (language.startsWith('zh')) return item.productName;

  final isId = language.startsWith('id');
  if (item.id.contains('espresso_30ml')) {
    return 'Espresso';
  }
  if (item.id.contains('strong_americano')) {
    if (item.brand == "Let’s Café") {
      return isId ? 'Americano Ekstra Pekat' : 'Extra Strong Americano';
    }
    return isId ? 'Americano Pekat' : 'Bold Americano';
  }
  if (item.id.contains('strong_latte')) {
    return isId ? 'Latte Pekat' : 'Bold Latte';
  }
  if (item.id.contains('americano')) {
    if (item.brand == "Let’s Café") {
      return isId ? 'Americano Klasik' : 'Classic Americano';
    }
    return 'Americano';
  }
  if (item.id.contains('latte')) {
    if (item.brand == "Let’s Café") {
      return isId ? 'Latte Klasik' : 'Classic Latte';
    }
    if (item.brand == 'Starbucks') {
      return isId ? 'Caffe Latte' : 'Caffe Latte';
    }
    return 'Latte';
  }

  return item.productName;
}

String catalogSizeLabel(CaffeineCatalogItem item, String language) {
  if (language.startsWith('zh')) return item.sizeLabel;

  final isId = language.startsWith('id');
  final hot = item.id.contains('_hot_');
  final iced = item.id.contains('_iced_');
  final temperature =
      hot
          ? (isId ? 'Panas' : 'Hot')
          : iced
          ? (isId ? 'Dingin' : 'Iced')
          : '';

  String size;
  if (item.id.endsWith('_30ml')) {
    size = '30 ml';
  } else if (item.id.endsWith('_short')) {
    size = 'Short';
  } else if (item.id.endsWith('_tall')) {
    size = 'Tall';
  } else if (item.id.endsWith('_grande')) {
    size = 'Grande';
  } else if (item.id.endsWith('_venti')) {
    size = 'Venti';
  } else if (item.id.endsWith('_s')) {
    size = isId ? 'Kecil' : 'Small';
  } else if (item.id.endsWith('_m')) {
    size = isId ? 'Sedang' : 'Medium';
  } else if (item.id.endsWith('_l')) {
    size = isId ? 'Besar' : 'Large';
  } else if (item.id.endsWith('_xl')) {
    size = isId ? 'Ekstra besar' : 'Extra large';
  } else {
    size = item.sizeLabel;
  }

  return temperature.isEmpty ? size : '$temperature $size';
}
