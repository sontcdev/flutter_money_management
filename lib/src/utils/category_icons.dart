// path: lib/src/utils/category_icons.dart

import 'package:flutter/material.dart';

import '../features/categories/models/category_icon_registry.dart';

/// Danh sách icon cho danh mục - sử dụng Material Icons
class CategoryIcons {
  /// Map từ icon name sang IconData
  static const Map<String, IconData> icons = {
    // Mua sắm & Ăn uống
    'shopping_cart': Icons.shopping_cart_outlined,
    'restaurant': Icons.restaurant_outlined,
    'fastfood': Icons.fastfood_outlined,
    'local_cafe': Icons.local_cafe_outlined,
    'cake': Icons.cake_outlined,
    'local_bar': Icons.local_bar_outlined,
    'local_pizza': Icons.local_pizza_outlined,
    'ramen_dining': Icons.ramen_dining_outlined,
    'bakery_dining': Icons.bakery_dining_outlined,
    'icecream': Icons.icecream_outlined,

    // Di chuyển
    'directions_car': Icons.directions_car_outlined,
    'flight': Icons.flight_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'pedal_bike': Icons.pedal_bike_outlined,
    'train': Icons.train_outlined,
    'motorcycle': Icons.two_wheeler_outlined,
    'local_taxi': Icons.local_taxi_outlined,

    // Nhà cửa
    'home': Icons.home_outlined,
    'lightbulb': Icons.lightbulb_outlined,
    'build': Icons.build_outlined,
    'tv': Icons.tv_outlined,
    'bed': Icons.bed_outlined,
    'kitchen': Icons.kitchen_outlined,
    'water_drop': Icons.water_drop_outlined,
    'cleaning_services': Icons.cleaning_services_outlined,

    // Công việc & Giáo dục
    'work': Icons.work_outlined,
    'laptop': Icons.laptop_outlined,
    'menu_book': Icons.menu_book_outlined,
    'school': Icons.school_outlined,
    'edit_note': Icons.edit_note_outlined,
    'business_center': Icons.business_center_outlined,
    'computer': Icons.computer_outlined,

    // Sức khỏe
    'medication': Icons.medication_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'self_improvement': Icons.self_improvement_outlined,
    'spa': Icons.spa_outlined,
    'medical_services': Icons.medical_services_outlined,

    // Giải trí
    'sports_esports': Icons.sports_esports_outlined,
    'movie': Icons.movie_outlined,
    'music_note': Icons.music_note_outlined,
    'photo_camera': Icons.photo_camera_outlined,
    'palette': Icons.palette_outlined,
    'theater_comedy': Icons.theater_comedy_outlined,
    'headphones': Icons.headphones_outlined,

    // Tài chính & Tiết kiệm
    'wallet': Icons.wallet_outlined,
    'payments': Icons.payments_outlined,
    'credit_card': Icons.credit_card_outlined,
    'account_balance': Icons.account_balance_outlined,
    'savings': Icons.savings_outlined,
    'receipt_long': Icons.receipt_long_outlined,
    'trending_up': Icons.trending_up_outlined,
    'attach_money': Icons.attach_money_outlined,
    'currency_exchange': Icons.currency_exchange_outlined,

    // Tiện ích & Hóa đơn
    'bolt': Icons.bolt_outlined,
    'wifi': Icons.wifi_outlined,
    'phone': Icons.phone_outlined,
    'mail': Icons.mail_outlined,
    'receipt': Icons.receipt_outlined,

    // Mua sắm cá nhân
    'checkroom': Icons.checkroom_outlined,
    'diamond': Icons.diamond_outlined,
    'watch': Icons.watch_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'storefront': Icons.storefront_outlined,

    // Gia đình & Trẻ em
    'child_care': Icons.child_care_outlined,
    'toys': Icons.toys_outlined,
    'family_restroom': Icons.family_restroom_outlined,
    'stroller': Icons.stroller_outlined,
    'celebration': Icons.celebration_outlined,

    // Thú cưng
    'pets': Icons.pets_outlined,

    // Du lịch
    'luggage': Icons.luggage_outlined,
    'beach_access': Icons.beach_access_outlined,
    'hotel': Icons.hotel_outlined,
    'landscape': Icons.landscape_outlined,

    // Khác
    'card_giftcard': Icons.card_giftcard_outlined,
    'favorite': Icons.favorite_outlined,
    'star': Icons.star_outlined,
    'label': Icons.label_outlined,
    'inventory_2': Icons.inventory_2_outlined,
    'local_offer': Icons.local_offer_outlined,
    'more_horiz': Icons.more_horiz_outlined,
  };

  /// Danh sách icon cơ bản (hiển thị mặc định)
  static const List<String> basicIconKeys = [
    'shopping_cart',
    'restaurant',
    'directions_car',
    'home',
    'work',
    'laptop',
    'medication',
    'sports_esports',
    'payments',
    'savings',
    'bolt',
    'checkroom',
    'card_giftcard',
    'pets',
    'favorite',
  ];

  /// Lấy IconData từ tên icon - kiểm tra cả icons mặc định và SearchableIcons
  static IconData getIcon(String iconName) {
    // Nếu là emoji (ký tự unicode ngắn), trả về icon mặc định
    if (iconName.length <= 2) {
      return Icons.category_outlined;
    }

    // Kiểm tra trong icons mặc định
    if (icons.containsKey(iconName)) {
      return icons[iconName]!;
    }

    // Kiểm tra trong SearchableIcons (custom icons)
    if (SearchableIcons.allIcons.containsKey(iconName)) {
      return SearchableIcons.allIcons[iconName]!;
    }

    return Icons.category_outlined;
  }

  /// Kiểm tra xem có phải là icon name hợp lệ không
  static bool isValidIconName(String iconName) {
    return icons.containsKey(iconName) ||
        SearchableIcons.allIcons.containsKey(iconName);
  }

  /// Lấy tất cả icon keys
  static List<String> get allIconKeys => icons.keys.toList();
}
