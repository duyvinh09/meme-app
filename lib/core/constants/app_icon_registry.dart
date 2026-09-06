import 'package:flutter/material.dart';

class AppIconRegistry {
  const AppIconRegistry._();

  static const IconData defaultIcon = Icons.account_balance_wallet_outlined;

  static const List<IconData> registeredIcons = [
    Icons.account_balance_wallet_rounded,
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
    Icons.shopping_cart_rounded,
    Icons.shopping_cart_outlined,
    Icons.shopping_cart,
    Icons.shopping_bag_rounded,
    Icons.shopping_bag_outlined,
    Icons.shopping_bag,
    Icons.home_rounded,
    Icons.home_outlined,
    Icons.home,
    Icons.directions_car_rounded,
    Icons.directions_car_outlined,
    Icons.directions_car,
    Icons.restaurant_rounded,
    Icons.restaurant_outlined,
    Icons.restaurant,
    Icons.theater_comedy_rounded,
    Icons.theater_comedy_outlined,
    Icons.favorite_rounded,
    Icons.favorite_outline_rounded,
    Icons.favorite,
    Icons.school_rounded,
    Icons.school_outlined,
    Icons.school,
    Icons.work_rounded,
    Icons.work_outlined,
    Icons.work,
    Icons.flight_rounded,
    Icons.flight_outlined,
    Icons.flight,
    Icons.card_giftcard_rounded,
    Icons.card_giftcard_outlined,
    Icons.card_giftcard,
    Icons.sports_esports_rounded,
    Icons.sports_esports_outlined,
    Icons.checkroom_rounded,
    Icons.checkroom_outlined,
    Icons.medication_rounded,
    Icons.medication_outlined,
    Icons.pending_actions_rounded,
    Icons.pending_actions_outlined,
    Icons.volunteer_activism_rounded,
    Icons.volunteer_activism_outlined,
    Icons.celebration_rounded,
    Icons.celebration_outlined,
    Icons.directions_bus_outlined,
    Icons.directions_bus_rounded,
    Icons.directions_bus,
    Icons.movie_outlined,
    Icons.movie_rounded,
    Icons.movie,
    Icons.menu_book_outlined,
    Icons.menu_book_rounded,
    Icons.menu_book,
    Icons.payments_outlined,
    Icons.payments_rounded,
    Icons.payments,
    Icons.more_horiz_rounded,
    Icons.more_horiz_outlined,
    Icons.more_horiz,
    Icons.attach_money_rounded,
    Icons.monetization_on_rounded,
    Icons.currency_exchange_rounded,
    Icons.savings_rounded,
    Icons.savings_outlined,
    Icons.local_gas_station_rounded,
    Icons.local_cafe_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.phone_iphone_rounded,
    Icons.wifi_rounded,
    Icons.electric_bolt_rounded,
    Icons.water_drop_rounded,
    Icons.fastfood_rounded,
    Icons.local_grocery_store_rounded,
    Icons.receipt_long_rounded,
    Icons.paid_rounded,
    Icons.category_rounded,
    Icons.category_outlined,
    Icons.play_arrow_rounded,
    Icons.lock_outline_rounded,
    Icons.people_outline_rounded,
    Icons.public_rounded,
  ];

  static final Map<int, IconData> _codePointMap = {
    for (final icon in registeredIcons) icon.codePoint: icon,
  };

  /// Rebuild an icon from persisted Material icon code point.
  /// Uses a constant lookup map so Flutter font tree shaking succeeds.
  static IconData fromCodePoint(int codePoint) {
    if (codePoint <= 0) {
      return defaultIcon;
    }

    return _codePointMap[codePoint] ?? defaultIcon;
  }
}
