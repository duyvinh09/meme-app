import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/nearby_place_service.dart';
import '../../../data/models/nearby_place_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

/// Maximum radius scanned via API (to cache 0-5km data in one single network request).
const double _kApiScanRadiusKm = 5.0;

/// Shows the Smart Nearby Place bottom sheet.
///
/// [spendingCategory] is the category of the recently added group expense.
/// Scans up to 5km+ via API, caches results, and filters by tabs [1km, 3km, 5km].
Future<void> showNearbyPlaceBottomSheet(
  BuildContext context, {
  required String spendingCategory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => NearbyPlaceBottomSheet(
      spendingCategory: spendingCategory,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class NearbyPlaceBottomSheet extends StatefulWidget {
  final String spendingCategory;

  const NearbyPlaceBottomSheet({
    super.key,
    required this.spendingCategory,
  });

  @override
  State<NearbyPlaceBottomSheet> createState() => _NearbyPlaceBottomSheetState();
}

class _NearbyPlaceBottomSheetState extends State<NearbyPlaceBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  // Shimmer animation controller for skeleton loading
  late AnimationController _shimmerController;

  late List<String> _suggestedCategories;
  late String _selectedCategory;

  // Selected distance filter tab:
  // 1.0 -> 0 to 2.9 km (Default)
  // 3.0 -> 3.0 to 4.9 km
  // 5.0 -> 5.0 km+
  double _selectedRadiusTab = 1.0;

  _SheetState _state = _SheetState.loading;
  List<NearbyPlace> _allPlaces = [];
  String? _errorMessage;

  String? _lastFetchedCategory;
  AppLocationResult? _lastFetchedLocation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _suggestedCategories =
        NearbyPlaceConfig.getSuggestedCategories(widget.spendingCategory);
    _selectedCategory = _suggestedCategories.first;

    // Immediately trigger 5km+ scan on open; tab 1km is shown by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchPlaces(_selectedCategory);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool _isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }

  /// Filter places based on active tab:
  /// - Tab 1 km: 0 - 2.9 km (< 3000 m)
  /// - Tab 3 km: 3.0 - 4.9 km (3000 m <= d < 5000 m)
  /// - Tab 5 km: 5.0 km+ (d >= 5000 m)
  List<NearbyPlace> get _currentFilteredPlaces {
    if (_selectedRadiusTab == 1.0) {
      return _allPlaces.where((p) => p.distanceMeters < 3000).toList();
    } else if (_selectedRadiusTab == 3.0) {
      return _allPlaces
          .where((p) => p.distanceMeters >= 3000 && p.distanceMeters < 5000)
          .toList();
    } else {
      return _allPlaces.where((p) => p.distanceMeters >= 5000).toList();
    }
  }

  // ── Place Fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchPlaces(
    String category, {
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _state = _SheetState.loading;
      _errorMessage = null;
    });

    // 1. Location permission check
    final hasPermission = await LocationService.hasLocationPermission();
    if (!hasPermission) {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _state = _SheetState.permissionDenied;
          });
        }
        return;
      }
    }

    // 2. Location GPS service check
    final gpsEnabled = await LocationService.isLocationServiceEnabled();
    if (!gpsEnabled) {
      if (mounted) {
        setState(() {
          _state = _SheetState.gpsOff;
        });
      }
      return;
    }

    // 3. Obtain location
    AppLocationResult? location;
    try {
      location = await LocationService.getCurrentLocation(
        requestPermissionIfNeeded: false,
      );
    } catch (_) {
      location = null;
    }

    if (location == null) {
      if (mounted) {
        setState(() {
          _state = _SheetState.locationError;
        });
      }
      return;
    }

    // 4. Fetch places from Overpass API (scan full 5km+ range and cache)
    try {
      final service = OverpassNearbyPlaceService.instance;

      if (_lastFetchedLocation != null) {
        service.invalidateCacheIfMoved(
          oldLat: _lastFetchedLocation!.latitude,
          oldLon: _lastFetchedLocation!.longitude,
          newLat: location.latitude,
          newLon: location.longitude,
        );
      }

      final places = await service.searchNearby(
        latitude: location.latitude,
        longitude: location.longitude,
        category: category,
        radiusKm: _kApiScanRadiusKm,
      );

      _lastFetchedCategory = category;
      _lastFetchedLocation = location;

      if (mounted) {
        setState(() {
          _allPlaces = places;
          _state = places.isEmpty ? _SheetState.empty : _SheetState.loaded;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isNetwork = msg.contains('SocketException') ||
            msg.contains('TimeoutException') ||
            msg.contains('Connection');
        setState(() {
          _state = isNetwork ? _SheetState.noInternet : _SheetState.apiError;
          _errorMessage = isNetwork ? null : msg;
        });
      }
    }
  }

  void _onCategorySelected(String category) {
    if (category == _selectedCategory &&
        _lastFetchedCategory == category &&
        (_state == _SheetState.loaded || _state == _SheetState.empty)) {
      return;
    }
    setState(() {
      _selectedCategory = category;
    });
    _fetchPlaces(category);
  }

  /// Instant client-side filter switch (zero network delay)
  void _onRadiusTabSelected(double radiusKm) {
    if (_selectedRadiusTab == radiusKm) return;
    setState(() {
      _selectedRadiusTab = radiusKm;
    });
  }

  Future<void> _openDirections(NearbyPlace place) async {
    final uri = Uri.parse(place.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallbackGeo = Uri(
        scheme: 'geo',
        path: '${place.latitude},${place.longitude}',
        queryParameters: {'q': place.name},
      );
      if (await canLaunchUrl(fallbackGeo)) {
        await launchUrl(fallbackGeo, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _sharePlace(NearbyPlace place, bool isEn) {
    final text = place.getShareText(isEn: isEn);
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _copyAddress(String address, bool isEn) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(isEn ? 'Address copied to clipboard!' : 'Đã sao chép địa chỉ!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.darkCard,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isEn = _isEnglish(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    final sheetBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(isDark),
            _buildHeader(isDark, isEn),
            _buildRadiusAndStatusRow(isDark, isEn),
            _buildCategoryCarousel(isDark, isEn),
            const SizedBox(height: 6),
            Flexible(child: _buildBody(isDark, isEn)),
            SizedBox(height: mediaQuery.viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 42,
          height: 4.5,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isEn) {
    final origCatLabel = NearbyPlaceConfig.getCategoryLabel(
      widget.spendingCategory,
      isEn: isEn,
    );
    final icon = NearbyPlaceConfig.iconForCategory(widget.spendingCategory);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        children: [
          // MeMe Brand Icon Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueDark,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlueDark.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.explore_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Where to next?' : 'Bạn muốn đi đâu tiếp?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.income,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isEn
                            ? 'After spending on $icon $origCatLabel'
                            : 'Gợi ý sau khoản chi $icon $origCatLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusAndStatusRow(bool isDark, bool isEn) {
    final filtered = _currentFilteredPlaces;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 3, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Places count or status tag
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 15,
                  color: AppColors.primaryBlueDark,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _state == _SheetState.loaded
                        ? (isEn
                            ? '${filtered.length} places'
                            : 'Tìm thấy ${filtered.length} địa điểm')
                        : (isEn ? 'Filter by distance' : 'Khoảng cách lọc'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tab filters: [1km] [3km] [5km] (1km is default)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(context), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [1.0, 3.0, 5.0].map((r) {
                final isSelected = _selectedRadiusTab == r;
                return GestureDetector(
                  onTap: () => _onRadiusTabSelected(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlueDark
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlueDark
                                    .withValues(alpha: 0.28),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '${r.toInt()} km',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCarousel(bool isDark, bool isEn) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _suggestedCategories.length,
        itemBuilder: (context, index) {
          final cat = _suggestedCategories[index];
          final isSelected = cat == _selectedCategory;
          final icon = NearbyPlaceConfig.iconForCategory(cat);
          final label = NearbyPlaceConfig.getCategoryLabel(cat, isEn: isEn);
          final isOriginal = cat == widget.spendingCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onCategorySelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isOriginal
                          ? AppColors.warning
                          : AppColors.primaryBlueDark)
                      : (isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.border(context),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isOriginal
                                    ? AppColors.warning
                                    : AppColors.primaryBlueDark)
                                .withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isOriginal ? Colors.black87 : Colors.white)
                            : AppColors.textPrimary(context),
                      ),
                    ),
                    if (isOriginal && !isSelected) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(bool isDark, bool isEn) {
    switch (_state) {
      case _SheetState.loading:
        return _buildShimmerLoading(isDark);
      case _SheetState.loaded:
        final filtered = _currentFilteredPlaces;
        if (filtered.isEmpty) {
          return _buildBracketEmptyState(isDark, isEn);
        }
        return _buildPlaceList(filtered, isDark, isEn);
      case _SheetState.empty:
        return _buildEmptyState(isDark, isEn);
      case _SheetState.permissionDenied:
        return _buildPermissionDeniedState(isDark, isEn);
      case _SheetState.gpsOff:
        return _buildGpsOffState(isDark, isEn);
      case _SheetState.noInternet:
        return _buildNoInternetState(isDark, isEn);
      case _SheetState.locationError:
        return _buildLocationErrorState(isDark, isEn);
      case _SheetState.apiError:
        return _buildApiErrorState(isDark, isEn);
    }
  }

  // ── Place List ──────────────────────────────────────────────────────────────

  Widget _buildPlaceList(List<NearbyPlace> places, bool isDark, bool isEn) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final place = places[index];
        return _PlaceCard(
          place: place,
          isDark: isDark,
          isEn: isEn,
          onNavigate: () => _openDirections(place),
          onShare: () => _sharePlace(place, isEn),
          onCopyAddress: (addr) => _copyAddress(addr, isEn),
        );
      },
    );
  }

  // ── Skeleton Shimmer Loading ────────────────────────────────────────────────

  Widget _buildShimmerLoading(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildSkeletonCard(isDark, _shimmerController.value);
          },
        );
      },
    );
  }

  Widget _buildSkeletonCard(bool isDark, double shimmerValue) {
    final baseColor = isDark ? const Color(0xFF1B202E) : const Color(0xFFEDEFF5);
    final highlightColor =
        isDark ? const Color(0xFF262D42) : const Color(0xFFF9FAFD);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left avatar skeleton
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Color.lerp(baseColor, highlightColor, (shimmerValue * 2 - 1).abs()),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 14),
          // Right content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color.lerp(baseColor, highlightColor, shimmerValue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Color.lerp(baseColor, highlightColor, (shimmerValue + 0.2) % 1.0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 90,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Color.lerp(baseColor, highlightColor, (shimmerValue + 0.4) % 1.0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bracket Empty State (When no places match the selected distance bracket) ─

  Widget _buildBracketEmptyState(bool isDark, bool isEn) {
    final String bracketLabel = '${_selectedRadiusTab.toInt()} km';
    final double alternateTab = _selectedRadiusTab == 1.0 ? 3.0 : 1.0;

    return _buildStateContainer(
      isDark: isDark,
      emoji: '📍',
      title: isEn
          ? 'No spots within $bracketLabel'
          : 'Không có địa điểm trong phạm vi $bracketLabel',
      subtitle: isEn
          ? 'We found ${_allPlaces.length} places in other distances. Try tab ${alternateTab.toInt()} km!'
          : 'Có ${_allPlaces.length} địa điểm ở khoảng cách khác. Thử xem tab ${alternateTab.toInt()} km nhé!',
      primaryButtonLabel: isEn ? 'Switch to ${alternateTab.toInt()} km' : 'Chuyển sang ${alternateTab.toInt()} km',
      onPrimaryButton: () => _onRadiusTabSelected(alternateTab),
    );
  }

  // ── Global Empty & Error States ─────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark, bool isEn) {
    return _buildStateContainer(
      isDark: isDark,
      emoji: '🔍',
      title: isEn
          ? 'No places found within 5 km'
          : 'Không tìm thấy địa điểm trong 5 km',
      subtitle: isEn
          ? 'Try picking another category from the list above.'
          : 'Thử chọn một danh mục khác ở danh sách bên trên nhé!',
      primaryButtonLabel: isEn ? 'Refresh' : 'Thử lại',
      onPrimaryButton: () => _fetchPlaces(_selectedCategory, forceRefresh: true),
    );
  }

  Widget _buildPermissionDeniedState(bool isDark, bool isEn) {
    return _buildStateContainer(
      isDark: isDark,
      emoji: '📍',
      title: isEn
          ? 'Location permission needed'
          : 'MeMe cần quyền vị trí',
      subtitle: isEn
          ? 'To discover amazing places around you, please grant location access.'
          : 'Để khám phá địa điểm thú vị gần bạn, vui lòng cấp quyền vị trí cho ứng dụng.',
      primaryButtonLabel: isEn ? 'Grant Permission' : 'Cấp quyền vị trí',
      onPrimaryButton: () async {
        await LocationService.openAppSettings();
      },
    );
  }

  Widget _buildGpsOffState(bool isDark, bool isEn) {
    return _buildStateContainer(
      isDark: isDark,
      emoji: '📡',
      title: isEn ? 'GPS is turned off' : 'GPS đang tắt',
      subtitle: isEn
          ? 'Please enable device location to search places around you.'
          : 'Vui lòng bật dịch vụ định vị trên thiết bị để tìm địa điểm gần bạn.',
      primaryButtonLabel: isEn ? 'Turn on GPS' : 'Bật GPS',
      onPrimaryButton: () async {
        await LocationService.openLocationSettings();
      },
    );
  }

  Widget _buildNoInternetState(bool isDark, bool isEn) {
    return _buildStateContainer(
      isDark: isDark,
      emoji: '📶',
      title: isEn ? 'No Internet connection' : 'Không có kết nối mạng',
      subtitle: isEn
          ? 'Please check your connection and tap retry.'
          : 'Kiểm tra đường truyền internet và thử lại nhé.',
      primaryButtonLabel: isEn ? 'Retry' : 'Thử lại',
      onPrimaryButton: () => _fetchPlaces(
        _selectedCategory,
        forceRefresh: true,
      ),
    );
  }

  Widget _buildLocationErrorState(bool isDark, bool isEn) {
    return _buildStateContainer(
      isDark: isDark,
      emoji: '🧭',
      title: isEn ? 'Could not get location' : 'Không thể lấy vị trí',
      subtitle: isEn
          ? 'Please verify GPS settings and try again.'
          : 'Hãy kiểm tra lại tín hiệu GPS và thử lại.',
      primaryButtonLabel: isEn ? 'Retry' : 'Thử lại',
      onPrimaryButton: () => _fetchPlaces(
        _selectedCategory,
        forceRefresh: true,
      ),
    );
  }

  Widget _buildApiErrorState(bool isDark, bool isEn) {
    return _buildStateContainer(
      isDark: isDark,
      emoji: '⚠️',
      title: isEn ? 'Could not load places' : 'Không thể tải địa điểm',
      subtitle: _errorMessage ??
          (isEn
              ? 'An error occurred. Please try again.'
              : 'Đã xảy ra lỗi khi tải dữ liệu. Vui lòng thử lại.'),
      primaryButtonLabel: isEn ? 'Retry' : 'Thử lại',
      onPrimaryButton: () => _fetchPlaces(
        _selectedCategory,
        forceRefresh: true,
      ),
    );
  }

  Widget _buildStateContainer({
    required bool isDark,
    required String emoji,
    required String title,
    required String subtitle,
    required String primaryButtonLabel,
    required VoidCallback onPrimaryButton,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryBlueDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlueDark.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onPrimaryButton,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                primaryButtonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlueDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACE CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  final NearbyPlace place;
  final bool isDark;
  final bool isEn;
  final VoidCallback onNavigate;
  final VoidCallback onShare;
  final ValueChanged<String> onCopyAddress;

  const _PlaceCard({
    required this.place,
    required this.isDark,
    required this.isEn,
    required this.onNavigate,
    required this.onShare,
    required this.onCopyAddress,
  });

  @override
  Widget build(BuildContext context) {
    final icon = NearbyPlaceConfig.iconForCategory(place.category);
    final categoryLabel =
        NearbyPlaceConfig.getCategoryLabel(place.category, isEn: isEn);
    final travelTime = place.travelTimeEstimate(isEn: isEn);

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightCard;
    final borderColor = AppColors.border(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Thumbnail Badge
                  _buildThumbnail(context, icon),
                  const SizedBox(width: 13),
                  // Title, Category, Travel Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            height: 1.25,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Badges Row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Category Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkInnerBorder
                                    : AppColors.lightInnerBorder,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '$icon $categoryLabel',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                            // Travel Time Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlueDark
                                    .withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                travelTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.primaryBlue
                                      : AppColors.primaryBlueDark,
                                ),
                              ),
                            ),
                            // Rating Tag (if available)
                            if (place.rating != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      place.rating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Address Row (if available)
              if (place.address != null && place.address!.trim().isNotEmpty) ...[
                const SizedBox(height: 9),
                GestureDetector(
                  onTap: () => onCopyAddress(place.address!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5.5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary(context),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            place.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: AppColors.textSecondary(context).withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 11),
              // Action Buttons Row: "Chỉ đường" (Directions) + "Chia sẻ" (Share)
              Row(
                children: [
                  // Directions Button (Primary)
                  Expanded(
                    child: GestureDetector(
                      onTap: onNavigate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueDark,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlueDark
                                  .withValues(alpha: 0.28),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isEn ? 'Directions' : 'Chỉ đường',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share Button (Secondary)
                  GestureDetector(
                    onTap: onShare,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkInnerBorder
                            : AppColors.lightInnerBorder,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColors.border(context),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            size: 15,
                            color: AppColors.textPrimary(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isEn ? 'Share' : 'Chia sẻ',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, String icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkInnerBorder
                : AppColors.lightInnerBorder,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 5),
        // Distance badge under avatar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryBlueDark.withValues(alpha: isDark ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 10,
                color: isDark ? AppColors.primaryBlue : AppColors.primaryBlueDark,
              ),
              const SizedBox(width: 2),
              Text(
                place.distanceLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.primaryBlue : AppColors.primaryBlueDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum _SheetState {
  loading,
  loaded,
  empty,
  permissionDenied,
  gpsOff,
  noInternet,
  locationError,
  apiError,
}
