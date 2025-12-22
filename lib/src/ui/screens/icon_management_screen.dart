// path: lib/src/ui/screens/icon_management_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';

/// Provider for custom icons stored in SharedPreferences
final customIconsProvider = StateNotifierProvider<CustomIconsNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomIconsNotifier(prefs);
});

class CustomIconsNotifier extends StateNotifier<List<String>> {
  static const String _customIconsKey = 'custom_icons';
  final SharedPreferences _prefs;

  CustomIconsNotifier(this._prefs) : super([]) {
    _loadCustomIcons();
  }

  void _loadCustomIcons() {
    final icons = _prefs.getStringList(_customIconsKey) ?? [];
    state = icons;
  }

  Future<bool> addIcon(String iconKey) async {
    if (state.contains(iconKey)) {
      return false; // Already exists
    }
    final newList = [...state, iconKey];
    await _prefs.setStringList(_customIconsKey, newList);
    state = newList;
    return true;
  }

  Future<void> removeIcon(String iconKey) async {
    final newList = state.where((i) => i != iconKey).toList();
    await _prefs.setStringList(_customIconsKey, newList);
    state = newList;
  }
}

/// Full list of searchable Material Icons
class SearchableIcons {
  static const Map<String, IconData> allIcons = {
    // Food & Drinks
    'restaurant': Icons.restaurant_outlined,
    'fastfood': Icons.fastfood_outlined,
    'local_cafe': Icons.local_cafe_outlined,
    'cake': Icons.cake_outlined,
    'local_bar': Icons.local_bar_outlined,
    'local_pizza': Icons.local_pizza_outlined,
    'ramen_dining': Icons.ramen_dining_outlined,
    'bakery_dining': Icons.bakery_dining_outlined,
    'icecream': Icons.icecream_outlined,
    'local_dining': Icons.local_dining_outlined,
    'lunch_dining': Icons.lunch_dining_outlined,
    'dinner_dining': Icons.dinner_dining_outlined,
    'breakfast_dining': Icons.breakfast_dining_outlined,
    'brunch_dining': Icons.brunch_dining_outlined,
    'liquor': Icons.liquor_outlined,
    'wine_bar': Icons.wine_bar_outlined,
    'coffee': Icons.coffee_outlined,
    'emoji_food_beverage': Icons.emoji_food_beverage_outlined,
    
    // Transport
    'directions_car': Icons.directions_car_outlined,
    'car_rental': Icons.car_rental_outlined,
    'car_repair': Icons.car_repair_outlined,
    'flight': Icons.flight_outlined,
    'directions_bus': Icons.directions_bus_outlined,
    'local_gas_station': Icons.local_gas_station_outlined,
    'pedal_bike': Icons.pedal_bike_outlined,
    'train': Icons.train_outlined,
    'motorcycle': Icons.two_wheeler_outlined,
    'local_taxi': Icons.local_taxi_outlined,
    'subway': Icons.subway_outlined,
    'tram': Icons.tram_outlined,
    'airport_shuttle': Icons.airport_shuttle_outlined,
    'electric_car': Icons.electric_car_outlined,
    'ev_station': Icons.ev_station_outlined,
    'sailing': Icons.sailing_outlined,
    'directions_boat': Icons.directions_boat_outlined,
    
    // Home & Utilities
    'home': Icons.home_outlined,
    'house': Icons.house_outlined,
    'apartment': Icons.apartment_outlined,
    'lightbulb': Icons.lightbulb_outlined,
    'build': Icons.build_outlined,
    'construction': Icons.construction_outlined,
    'tv': Icons.tv_outlined,
    'bed': Icons.bed_outlined,
    'kitchen': Icons.kitchen_outlined,
    'water_drop': Icons.water_drop_outlined,
    'cleaning_services': Icons.cleaning_services_outlined,
    'bathtub': Icons.bathtub_outlined,
    'shower': Icons.shower_outlined,
    'chair': Icons.chair_outlined,
    'table_restaurant': Icons.table_restaurant_outlined,
    'weekend': Icons.weekend_outlined,
    'microwave': Icons.microwave_outlined,
    'blender': Icons.blender_outlined,
    'iron': Icons.iron_outlined,
    'air': Icons.air_outlined,
    'ac_unit': Icons.ac_unit_outlined,
    'fireplace': Icons.fireplace_outlined,
    'door_front': Icons.door_front_door_outlined,
    'window': Icons.window_outlined,
    'roofing': Icons.roofing_outlined,
    'grass': Icons.grass_outlined,
    'yard': Icons.yard_outlined,
    
    // Work & Business
    'work': Icons.work_outlined,
    'work_history': Icons.work_history_outlined,
    'laptop': Icons.laptop_outlined,
    'computer': Icons.computer_outlined,
    'desktop_windows': Icons.desktop_windows_outlined,
    'phone_android': Icons.phone_android_outlined,
    'phone_iphone': Icons.phone_iphone_outlined,
    'tablet': Icons.tablet_outlined,
    'keyboard': Icons.keyboard_outlined,
    'mouse': Icons.mouse_outlined,
    'print': Icons.print_outlined,
    'scanner': Icons.scanner_outlined,
    'business_center': Icons.business_center_outlined,
    'corporate_fare': Icons.corporate_fare_outlined,
    'meeting_room': Icons.meeting_room_outlined,
    'folder': Icons.folder_outlined,
    'folder_open': Icons.folder_open_outlined,
    'description': Icons.description_outlined,
    'article': Icons.article_outlined,
    'assignment': Icons.assignment_outlined,
    'task': Icons.task_outlined,
    'checklist': Icons.checklist_outlined,
    'note': Icons.note_outlined,
    'sticky_note': Icons.sticky_note_2_outlined,
    'edit': Icons.edit_outlined,
    'edit_note': Icons.edit_note_outlined,
    
    // Education
    'school': Icons.school_outlined,
    'menu_book': Icons.menu_book_outlined,
    'auto_stories': Icons.auto_stories_outlined,
    'library_books': Icons.library_books_outlined,
    'class': Icons.class_outlined,
    'science': Icons.science_outlined,
    'biotech': Icons.biotech_outlined,
    'calculate': Icons.calculate_outlined,
    'functions': Icons.functions_outlined,
    'history_edu': Icons.history_edu_outlined,
    'backpack': Icons.backpack_outlined,
    'book': Icons.book_outlined,
    'bookmark': Icons.bookmark_outlined,
    'draw': Icons.draw_outlined,
    'brush': Icons.brush_outlined,
    'architecture': Icons.architecture_outlined,
    
    // Health & Fitness
    'medication': Icons.medication_outlined,
    'medical_services': Icons.medical_services_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'healing': Icons.healing_outlined,
    'health_and_safety': Icons.health_and_safety_outlined,
    'fitness_center': Icons.fitness_center_outlined,
    'self_improvement': Icons.self_improvement_outlined,
    'spa': Icons.spa_outlined,
    'hot_tub': Icons.hot_tub_outlined,
    'sports': Icons.sports_outlined,
    'sports_basketball': Icons.sports_basketball_outlined,
    'sports_soccer': Icons.sports_soccer_outlined,
    'sports_tennis': Icons.sports_tennis_outlined,
    'sports_golf': Icons.sports_golf_outlined,
    'pool': Icons.pool_outlined,
    'surfing': Icons.surfing_outlined,
    'downhill_skiing': Icons.downhill_skiing_outlined,
    'snowboarding': Icons.snowboarding_outlined,
    'hiking': Icons.hiking_outlined,
    'directions_run': Icons.directions_run_outlined,
    'directions_walk': Icons.directions_walk_outlined,
    'monitor_heart': Icons.monitor_heart_outlined,
    'bloodtype': Icons.bloodtype_outlined,
    'vaccines': Icons.vaccines_outlined,
    'personal_injury': Icons.personal_injury_outlined,
    'psychology': Icons.psychology_outlined,
    'elderly': Icons.elderly_outlined,
    'wheelchair_pickup': Icons.wheelchair_pickup_outlined,
    
    // Entertainment
    'sports_esports': Icons.sports_esports_outlined,
    'videogame_asset': Icons.videogame_asset_outlined,
    'movie': Icons.movie_outlined,
    'theaters': Icons.theaters_outlined,
    'live_tv': Icons.live_tv_outlined,
    'music_note': Icons.music_note_outlined,
    'headphones': Icons.headphones_outlined,
    'headset': Icons.headset_outlined,
    'speaker': Icons.speaker_outlined,
    'radio': Icons.radio_outlined,
    'mic': Icons.mic_outlined,
    'photo_camera': Icons.photo_camera_outlined,
    'camera': Icons.camera_outlined,
    'videocam': Icons.videocam_outlined,
    'palette': Icons.palette_outlined,
    'theater_comedy': Icons.theater_comedy_outlined,
    'celebration': Icons.celebration_outlined,
    'party_mode': Icons.party_mode_outlined,
    'nightlife': Icons.nightlife_outlined,
    'casino': Icons.casino_outlined,
    'sports_bar': Icons.sports_bar_outlined,
    'stadium': Icons.stadium_outlined,
    'attractions': Icons.attractions_outlined,
    'amusement_park': Icons.local_activity_outlined,
    
    // Finance & Shopping
    'payments': Icons.payments_outlined,
    'credit_card': Icons.credit_card_outlined,
    'account_balance': Icons.account_balance_outlined,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'savings': Icons.savings_outlined,
    'receipt': Icons.receipt_outlined,
    'receipt_long': Icons.receipt_long_outlined,
    'trending_up': Icons.trending_up_outlined,
    'trending_down': Icons.trending_down_outlined,
    'attach_money': Icons.attach_money_outlined,
    'money': Icons.money_outlined,
    'currency_exchange': Icons.currency_exchange_outlined,
    'price_check': Icons.price_check_outlined,
    'shopping_cart': Icons.shopping_cart_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'shopping_basket': Icons.shopping_basket_outlined,
    'storefront': Icons.storefront_outlined,
    'store': Icons.store_outlined,
    'local_mall': Icons.local_mall_outlined,
    'redeem': Icons.redeem_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'sell': Icons.sell_outlined,
    'discount': Icons.discount_outlined,
    'local_offer': Icons.local_offer_outlined,
    
    // Clothing & Fashion
    'checkroom': Icons.checkroom_outlined,
    'dry_cleaning': Icons.dry_cleaning_outlined,
    'diamond': Icons.diamond_outlined,
    'watch': Icons.watch_outlined,
    
    // Family & Kids  
    'child_care': Icons.child_care_outlined,
    'child_friendly': Icons.child_friendly_outlined,
    'toys': Icons.toys_outlined,
    'stroller': Icons.stroller_outlined,
    'family_restroom': Icons.family_restroom_outlined,
    'baby_changing_station': Icons.baby_changing_station,
    'escalator_warning': Icons.escalator_warning_outlined,
    'crib': Icons.crib_outlined,
    
    // Pets
    'pets': Icons.pets_outlined,
    'cruelty_free': Icons.cruelty_free_outlined,
    
    // Travel & Vacation
    'luggage': Icons.luggage_outlined,
    'beach_access': Icons.beach_access_outlined,
    'hotel': Icons.hotel_outlined,
    'pool_vacation': Icons.pool_outlined,
    'landscape': Icons.landscape_outlined,
    'terrain': Icons.terrain_outlined,
    'park': Icons.park_outlined,
    'forest': Icons.forest_outlined,
    'nature': Icons.nature_outlined,
    'nature_people': Icons.nature_people_outlined,
    'public': Icons.public_outlined,
    'map': Icons.map_outlined,
    'tour': Icons.tour_outlined,
    'photo_library': Icons.photo_library_outlined,
    'camera_alt': Icons.camera_alt_outlined,
    
    // Communication
    'phone': Icons.phone_outlined,
    'call': Icons.call_outlined,
    'sms': Icons.sms_outlined,
    'chat': Icons.chat_outlined,
    'email': Icons.email_outlined,
    'mail': Icons.mail_outlined,
    'send': Icons.send_outlined,
    'wifi': Icons.wifi_outlined,
    'signal_cellular': Icons.signal_cellular_alt_outlined,
    
    // Security & Safety
    'lock': Icons.lock_outlined,
    'security': Icons.security_outlined,
    'shield': Icons.shield_outlined,
    'vpn_key': Icons.vpn_key_outlined,
    'key': Icons.key_outlined,
    'password': Icons.password_outlined,
    'verified_user': Icons.verified_user_outlined,
    'admin_panel_settings': Icons.admin_panel_settings_outlined,
    
    // Utilities & Misc
    'bolt': Icons.bolt_outlined,
    'electric_bolt': Icons.electric_bolt_outlined,
    'power': Icons.power_outlined,
    'settings': Icons.settings_outlined,
    'tune': Icons.tune_outlined,
    'handyman': Icons.handyman_outlined,
    'plumbing': Icons.plumbing_outlined,
    'carpenter': Icons.carpenter_outlined,
    'pest_control': Icons.pest_control_outlined,
    'recycling': Icons.recycling_outlined,
    'delete': Icons.delete_outlined,
    'inventory': Icons.inventory_2_outlined,
    'archive': Icons.archive_outlined,
    'category': Icons.category_outlined,
    'label': Icons.label_outlined,
    'bookmark_border': Icons.bookmark_border_outlined,
    'star_border': Icons.star_border_outlined,
    'favorite_border': Icons.favorite_border_outlined,
    'thumb_up': Icons.thumb_up_outlined,
    'emoji_events': Icons.emoji_events_outlined,
    'military_tech': Icons.military_tech_outlined,
    'workspace_premium': Icons.workspace_premium_outlined,
    'verified': Icons.verified_outlined,
    'new_releases': Icons.new_releases_outlined,
    'schedule': Icons.schedule_outlined,
    'timer': Icons.timer_outlined,
    'alarm': Icons.alarm_outlined,
    'event': Icons.event_outlined,
    'today': Icons.today_outlined,
    'calendar_month': Icons.calendar_month_outlined,
    'date_range': Icons.date_range_outlined,
    'notifications': Icons.notifications_outlined,
    'info': Icons.info_outlined,
    'help': Icons.help_outlined,
    'question_mark': Icons.question_mark_outlined,
    'priority_high': Icons.priority_high_outlined,
    'warning': Icons.warning_outlined,
    'error': Icons.error_outlined,
    'check_circle': Icons.check_circle_outlined,
    'cancel': Icons.cancel_outlined,
    'add_circle': Icons.add_circle_outlined,
    'remove_circle': Icons.remove_circle_outlined,
    'highlight': Icons.highlight_outlined,
    'lightbulb_circle': Icons.lightbulb_circle_outlined,
    'auto_awesome': Icons.auto_awesome_outlined,
    'grade': Icons.grade_outlined,
  };

  static List<MapEntry<String, IconData>> search(String query) {
    if (query.isEmpty) {
      return allIcons.entries.take(30).toList();
    }
    final lowerQuery = query.toLowerCase();
    return allIcons.entries
        .where((e) => e.key.toLowerCase().contains(lowerQuery))
        .take(50)
        .toList();
  }
}

class IconManagementScreen extends HookConsumerWidget {
  const IconManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final customIcons = ref.watch(customIconsProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final searchResults = SearchableIcons.search(searchQuery.value);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.iconManagement),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: l10n.searchIconHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),
          
          // My Icons section
          if (customIcons.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.myIcons,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: customIcons.length,
                itemBuilder: (context, index) {
                  final iconKey = customIcons[index];
                  final iconData = SearchableIcons.allIcons[iconKey] ?? Icons.category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _IconTile(
                      iconKey: iconKey,
                      iconData: iconData,
                      isAdded: true,
                      onTap: () async {
                        await ref.read(customIconsProvider.notifier).removeIcon(iconKey);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.iconRemoved)),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
          ],
          
          // Available icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.apps, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.availableIcons,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${searchResults.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Search results grid
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(l10n.noIconsFound),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final entry = searchResults[index];
                      final isAdded = customIcons.contains(entry.key);
                      return _IconTile(
                        iconKey: entry.key,
                        iconData: entry.value,
                        isAdded: isAdded,
                        onTap: () async {
                          if (isAdded) {
                            await ref.read(customIconsProvider.notifier).removeIcon(entry.key);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.iconRemoved)),
                              );
                            }
                          } else {
                            final added = await ref.read(customIconsProvider.notifier).addIcon(entry.key);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(added ? l10n.iconAdded : l10n.iconAlreadyAdded),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final String iconKey;
  final IconData iconData;
  final bool isAdded;
  final VoidCallback onTap;

  const _IconTile({
    required this.iconKey,
    required this.iconData,
    required this.isAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: iconKey,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isAdded 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAdded 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
              width: isAdded ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  iconData,
                  size: 28,
                  color: isAdded 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                ),
              ),
              if (isAdded)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
