import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @vietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @english.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get english;

  /// No description provided for @appearance.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get appearance;

  /// No description provided for @light.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get system;

  /// No description provided for @currency.
  ///
  /// In vi, this message translates to:
  /// **'Tiền tệ'**
  String get currency;

  /// No description provided for @vnd.
  ///
  /// In vi, this message translates to:
  /// **'VNĐ'**
  String get vnd;

  /// No description provided for @usd.
  ///
  /// In vi, this message translates to:
  /// **'USD'**
  String get usd;

  /// No description provided for @exchangeRateUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật tỷ giá: {rate}'**
  String exchangeRateUpdated(String rate);

  /// No description provided for @updating.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật'**
  String get updating;

  /// No description provided for @update.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get update;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get profile;

  /// No description provided for @user.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get user;

  /// No description provided for @joined.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia: {date}'**
  String joined(String date);

  /// No description provided for @friends.
  ///
  /// In vi, this message translates to:
  /// **'{count} Bạn bè'**
  String friends(int count);

  /// No description provided for @groups.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get groups;

  /// No description provided for @changeEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email đăng nhập'**
  String get changeEmail;

  /// No description provided for @feedback.
  ///
  /// In vi, this message translates to:
  /// **'Góp ý'**
  String get feedback;

  /// No description provided for @deleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản'**
  String get deleteAccount;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này sẽ xoá tài khoản của bạn khỏi Meme. Bạn sẽ không thể đăng nhập lại bằng tài khoản này.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountNote.
  ///
  /// In vi, this message translates to:
  /// **'Nếu bạn chỉ muốn rời app tạm thời, hãy chọn Đăng xuất thay vì xoá tài khoản.'**
  String get deleteAccountNote;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu hiện tại'**
  String get enterCurrentPassword;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get cancel;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu hiện tại'**
  String get pleaseEnterPassword;

  /// No description provided for @accountNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tài khoản hiện tại'**
  String get accountNotFound;

  /// No description provided for @deleteAccountError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xoá tài khoản. Vui lòng kiểm tra mật khẩu hoặc đăng nhập lại.'**
  String get deleteAccountError;

  /// No description provided for @goodMorning.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi sáng'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi chiều'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In vi, this message translates to:
  /// **'Chào buổi tối'**
  String get goodEvening;

  /// No description provided for @noTransactionsToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn chưa thêm giao dịch nào.'**
  String get noTransactionsToday;

  /// No description provided for @receivedToday.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận {amount} hôm nay'**
  String receivedToday(String amount);

  /// No description provided for @spentToday.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi {amount} hôm nay'**
  String spentToday(String amount);

  /// No description provided for @you.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get you;

  /// No description provided for @recentTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch gần đây'**
  String get recentTransactions;

  /// No description provided for @transactionCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch'**
  String transactionCount(int count);

  /// No description provided for @noTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nào'**
  String get noTransactions;

  /// No description provided for @addFirstTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu'**
  String get addFirstTransaction;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @email.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? '**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? '**
  String get alreadyHaveAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại 👋'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để tiếp tục lưu ảnh, ghi chú và chi tiêu của bạn.'**
  String get loginSubtitle;

  /// No description provided for @appSlogan.
  ///
  /// In vi, this message translates to:
  /// **'Lưu khoảnh khắc chi tiêu theo cách vui hơn, thật hơn.'**
  String get appSlogan;

  /// No description provided for @pleaseEnterPasswordLogin.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get pleaseEnterPasswordLogin;

  /// No description provided for @pleaseEnterName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên hiển thị'**
  String get pleaseEnterName;

  /// No description provided for @createNewAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới ✨'**
  String get createNewAccount;

  /// No description provided for @registerSlogan.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu lưu khoảnh khắc chi tiêu theo cách vui hơn, thật hơn.'**
  String get registerSlogan;

  /// No description provided for @joinMeme.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia Meme'**
  String get joinMeme;

  /// No description provided for @registerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hồ sơ để quản lý chi tiêu, lưu ảnh và kết nối với bạn bè.'**
  String get registerSubtitle;

  /// No description provided for @displayName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get displayName;

  /// No description provided for @username.
  ///
  /// In vi, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In vi, this message translates to:
  /// **'Dùng 3-20 ký tự: chữ thường, số, dấu . hoặc _'**
  String get usernameHint;

  /// No description provided for @passwordHint.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu tối thiểu 6 ký tự'**
  String get passwordHint;

  /// No description provided for @currentBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư hiện tại'**
  String get currentBalance;

  /// No description provided for @totalIncome.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thu'**
  String get totalIncome;

  /// No description provided for @totalExpense.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi'**
  String get totalExpense;

  /// No description provided for @streak.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi duy trì'**
  String get streak;

  /// No description provided for @daysStreak.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày liên tiếp'**
  String daysStreak(int count);

  /// No description provided for @streakLevel1.
  ///
  /// In vi, this message translates to:
  /// **'Cực đỉnh'**
  String get streakLevel1;

  /// No description provided for @streakLevel2.
  ///
  /// In vi, this message translates to:
  /// **'Ổn áp'**
  String get streakLevel2;

  /// No description provided for @streakLevel3.
  ///
  /// In vi, this message translates to:
  /// **'Đều đặn'**
  String get streakLevel3;

  /// No description provided for @streakLevel4.
  ///
  /// In vi, this message translates to:
  /// **'Đang lên mood'**
  String get streakLevel4;

  /// No description provided for @streakLevel5.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu thôi'**
  String get streakLevel5;

  /// No description provided for @personalBudget.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách cá nhân'**
  String get personalBudget;

  /// No description provided for @budgetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách cá nhân'**
  String get budgetTitle;

  /// No description provided for @budgetSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo chủ đề và đặt mục tiêu tiền'**
  String get budgetSubtitle;

  /// No description provided for @budgetNote.
  ///
  /// In vi, this message translates to:
  /// **'Các danh mục mặc định như Ăn uống, Mua sắm, Đi lại sẽ không có giới hạn. Ngân sách ở đây là chủ đề cá nhân do bạn tự tạo.'**
  String get budgetNote;

  /// No description provided for @budgetOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan ngân sách'**
  String get budgetOverview;

  /// No description provided for @monthYear.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month} {year}'**
  String monthYear(int month, int year);

  /// No description provided for @overLimit.
  ///
  /// In vi, this message translates to:
  /// **'Đã vượt mục tiêu'**
  String get overLimit;

  /// No description provided for @remainingAmount.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại {amount}'**
  String remainingAmount(String amount);

  /// No description provided for @budgetGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get budgetGoal;

  /// No description provided for @usedAmount.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng'**
  String get usedAmount;

  /// No description provided for @deleteBudgetQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ngân sách?'**
  String get deleteBudgetQuestion;

  /// No description provided for @deleteBudgetWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xoá chủ đề \"{name}\" không? Các giao dịch đã tạo trước đó vẫn giữ nguyên, chỉ xoá mục tiêu ngân sách này.'**
  String deleteBudgetWarning(String name);

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get delete;

  /// No description provided for @budgetDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá \"{name}\"'**
  String budgetDeleted(String name);

  /// No description provided for @noBudgetThemes.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chủ đề ngân sách'**
  String get noBudgetThemes;

  /// No description provided for @noBudgetThemesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo một chủ đề như Picnic, Mua iPad hoặc Đi du lịch để đặt mục tiêu tiền riêng.'**
  String get noBudgetThemesSubtitle;

  /// No description provided for @personalThemes.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đề cá nhân'**
  String get personalThemes;

  /// No description provided for @trackSpentVsGoal.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi số tiền đã dùng so với mục tiêu'**
  String get trackSpentVsGoal;

  /// No description provided for @monthly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng tháng'**
  String get monthly;

  /// No description provided for @daily.
  ///
  /// In vi, this message translates to:
  /// **'Hằng ngày'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng tuần'**
  String get weekly;

  /// No description provided for @biweekly.
  ///
  /// In vi, this message translates to:
  /// **'2 tuần/lần'**
  String get biweekly;

  /// No description provided for @yearly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng năm'**
  String get yearly;

  /// No description provided for @custom.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chỉnh'**
  String get custom;

  /// No description provided for @total.
  ///
  /// In vi, this message translates to:
  /// **'Tổng'**
  String get total;

  /// No description provided for @category.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get category;

  /// No description provided for @allSpending.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả chi tiêu'**
  String get allSpending;

  /// No description provided for @syncFromCategory.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ từ danh mục'**
  String get syncFromCategory;

  /// No description provided for @budgetNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên ngân sách'**
  String get budgetNameLabel;

  /// No description provided for @budgetNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Chi tiêu hằng ngày'**
  String get budgetNameHint;

  /// No description provided for @budgetAmountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền ngân sách'**
  String get budgetAmountLabel;

  /// No description provided for @period.
  ///
  /// In vi, this message translates to:
  /// **'Chu kỳ'**
  String get period;

  /// No description provided for @budgetType.
  ///
  /// In vi, this message translates to:
  /// **'Loại ngân sách'**
  String get budgetType;

  /// No description provided for @color.
  ///
  /// In vi, this message translates to:
  /// **'Màu'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get icon;

  /// No description provided for @createBudget.
  ///
  /// In vi, this message translates to:
  /// **'Tạo ngân sách'**
  String get createBudget;

  /// No description provided for @addBudget.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ngân sách'**
  String get addBudget;

  /// No description provided for @editBudget.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa ngân sách'**
  String get editBudget;

  /// No description provided for @cancelLabel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get cancelLabel;

  /// No description provided for @pleaseEnterBudgetName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên ngân sách'**
  String get pleaseEnterBudgetName;

  /// No description provided for @pleaseEnterBudgetAmount.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền ngân sách'**
  String get pleaseEnterBudgetAmount;

  /// No description provided for @budgetAmountPositive.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền ngân sách phải lớn hơn 0'**
  String get budgetAmountPositive;

  /// No description provided for @cannotCreateBudget.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo ngân sách: {error}'**
  String cannotCreateBudget(String error);

  /// No description provided for @budgetUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ngân sách'**
  String get budgetUpdated;

  /// No description provided for @budgetUnchanged.
  ///
  /// In vi, this message translates to:
  /// **'Không có thay đổi để cập nhật'**
  String get budgetUnchanged;

  /// No description provided for @cannotUpdateBudget.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật ngân sách: {error}'**
  String cannotUpdateBudget(String error);

  /// No description provided for @cannotDeleteBudget.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xoá ngân sách: {error}'**
  String cannotDeleteBudget(String error);

  /// No description provided for @budgetAnalysis.
  ///
  /// In vi, this message translates to:
  /// **'Phân tích ngân sách'**
  String get budgetAnalysis;

  /// No description provided for @deleteBudget.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ngân sách'**
  String get deleteBudget;

  /// No description provided for @loadBudgetError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải ngân sách:\n{error}'**
  String loadBudgetError(String error);

  /// No description provided for @budgetHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử ngân sách'**
  String get budgetHistory;

  /// No description provided for @average.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình'**
  String get average;

  /// No description provided for @overBudget.
  ///
  /// In vi, this message translates to:
  /// **'Vượt ngân sách'**
  String get overBudget;

  /// No description provided for @bestPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ tốt nhất'**
  String get bestPeriod;

  /// No description provided for @worstPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ tệ nhất'**
  String get worstPeriod;

  /// No description provided for @periodCount.
  ///
  /// In vi, this message translates to:
  /// **'Số kỳ'**
  String get periodCount;

  /// No description provided for @compareOverPeriods.
  ///
  /// In vi, this message translates to:
  /// **'So sánh qua từng kỳ'**
  String get compareOverPeriods;

  /// No description provided for @budgetLimitLegend.
  ///
  /// In vi, this message translates to:
  /// **'Giới hạn ngân sách'**
  String get budgetLimitLegend;

  /// No description provided for @withinBudgetLegend.
  ///
  /// In vi, this message translates to:
  /// **'Trong ngân sách'**
  String get withinBudgetLegend;

  /// No description provided for @overBudgetLegend.
  ///
  /// In vi, this message translates to:
  /// **'Vượt ngân sách!'**
  String get overBudgetLegend;

  /// No description provided for @periodDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết từng kỳ'**
  String get periodDetail;

  /// No description provided for @currentPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại'**
  String get currentPeriod;

  /// No description provided for @remainingLabel.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại: {amount}'**
  String remainingLabel(String amount);

  /// No description provided for @budgetLimitLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách: {amount}'**
  String budgetLimitLabel(String amount);

  /// No description provided for @overBudgetWarning.
  ///
  /// In vi, this message translates to:
  /// **'Vượt ngân sách!'**
  String get overBudgetWarning;

  /// No description provided for @budgetNamePreview.
  ///
  /// In vi, this message translates to:
  /// **'Tên ngân sách'**
  String get budgetNamePreview;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email đã đăng ký để nhận liên kết đặt lại mật khẩu.'**
  String get forgotPasswordInstruction;

  /// No description provided for @recoveryPassword.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục mật khẩu'**
  String get recoveryPassword;

  /// No description provided for @recoveryPasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống sẽ gửi cho bạn một email để đặt lại mật khẩu.'**
  String get recoveryPasswordSubtitle;

  /// No description provided for @enterEmail.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email'**
  String get enterEmail;

  /// No description provided for @recoveryEmailSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi email khôi phục mật khẩu'**
  String get recoveryEmailSent;

  /// No description provided for @couldNotSendRecoveryEmail.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi email khôi phục'**
  String get couldNotSendRecoveryEmail;

  /// No description provided for @sendRecoveryEmail.
  ///
  /// In vi, this message translates to:
  /// **'Gửi email khôi phục'**
  String get sendRecoveryEmail;

  /// No description provided for @backToLogin.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại đăng nhập'**
  String get backToLogin;

  /// No description provided for @editProfile.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hồ sơ'**
  String get editProfile;

  /// No description provided for @name.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get name;

  /// No description provided for @saveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật hồ sơ thành công'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật hồ sơ thất bại'**
  String get profileUpdateFailed;

  /// No description provided for @changeEmailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email đăng nhập'**
  String get changeEmailTitle;

  /// No description provided for @changeEmailSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật email dùng để đăng nhập tài khoản của bạn'**
  String get changeEmailSubtitle;

  /// No description provided for @currentEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email hiện tại'**
  String get currentEmail;

  /// No description provided for @unknown.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ'**
  String get unknown;

  /// No description provided for @newEmailInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin email mới'**
  String get newEmailInfo;

  /// No description provided for @newEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email mới'**
  String get newEmail;

  /// No description provided for @enterNewEmail.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email mới của bạn'**
  String get enterNewEmail;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu để xác nhận'**
  String get enterPasswordToConfirm;

  /// No description provided for @changeEmailNotice.
  ///
  /// In vi, this message translates to:
  /// **'Để bảo vệ tài khoản, bạn cần nhập lại mật khẩu hiện tại trước khi đổi email đăng nhập.'**
  String get changeEmailNotice;

  /// No description provided for @updateEmail.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật email'**
  String get updateEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email mới không hợp lệ'**
  String get invalidEmail;

  /// No description provided for @emailSameAsCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Email mới đang trùng với email hiện tại'**
  String get emailSameAsCurrent;

  /// No description provided for @emailChangedSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi email đăng nhập thành công'**
  String get emailChangedSuccessfully;

  /// No description provided for @feedbackTitle.
  ///
  /// In vi, this message translates to:
  /// **'Góp ý'**
  String get feedbackTitle;

  /// No description provided for @sendFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Gửi phản hồi'**
  String get sendFeedback;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ý kiến, đề xuất hoặc báo lỗi để Meme ngày càng hoàn thiện hơn.'**
  String get feedbackSubtitle;

  /// No description provided for @yourEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email của bạn'**
  String get yourEmail;

  /// No description provided for @emailPrefilledNote.
  ///
  /// In vi, this message translates to:
  /// **'Email này được điền sẵn từ tài khoản của bạn.'**
  String get emailPrefilledNote;

  /// No description provided for @yourFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi của bạn *'**
  String get yourFeedback;

  /// No description provided for @feedbackHint.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ý kiến, báo lỗi hoặc đề xuất tính năng mới...'**
  String get feedbackHint;

  /// No description provided for @sending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi...'**
  String get sending;

  /// No description provided for @invalidEmailGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get invalidEmailGeneric;

  /// No description provided for @pleaseEnterFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập nội dung góp ý'**
  String get pleaseEnterFeedback;

  /// No description provided for @feedbackTooLong.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung góp ý không được quá {count} ký tự'**
  String feedbackTooLong(int count);

  /// No description provided for @feedbackEmailSubject.
  ///
  /// In vi, this message translates to:
  /// **'Góp ý từ ứng dụng Meme'**
  String get feedbackEmailSubject;

  /// No description provided for @feedbackEmailBody.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào Admin,\n\nBạn vừa nhận được một góp ý mới từ ứng dụng Meme.\n\nThông tin người gửi:\n- Tên: {name}\n- Username: {username}\n- Email: {email}\n\nNội dung góp ý:\n{message}\n\n---\nEmail này được tạo tự động từ màn Góp ý của app Meme.'**
  String feedbackEmailBody(
      String name, String username, String email, String message);

  /// No description provided for @feedbackSentEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở email để gửi góp ý cho admin'**
  String get feedbackSentEmail;

  /// No description provided for @feedbackSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu góp ý. Thiết bị chưa mở được ứng dụng email.'**
  String get feedbackSaved;

  /// No description provided for @feedbackError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi góp ý: {error}'**
  String feedbackError(String error);

  /// No description provided for @friendsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get friendsTitle;

  /// No description provided for @friendsSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm bạn bè...'**
  String get friendsSearchHint;

  /// No description provided for @noFriends.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bạn bè'**
  String get noFriends;

  /// No description provided for @noFriendsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn bè để chia sẻ chi tiêu và tham gia nhóm.'**
  String get noFriendsSubtitle;

  /// No description provided for @addFriend.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn bè'**
  String get addFriend;

  /// No description provided for @deleteFriendQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xoá bạn bè?'**
  String get deleteFriendQuestion;

  /// No description provided for @deleteFriendWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xoá {name} khỏi danh sách bạn bè?'**
  String deleteFriendWarning(String name);

  /// No description provided for @deleteFriendGroupsNote.
  ///
  /// In vi, this message translates to:
  /// **'Người này vẫn sẽ ở trong các nhóm chung. Nếu muốn xoá khỏi nhóm, bạn cần vào nhóm để chỉnh sửa thành viên hoặc rời nhóm.'**
  String get deleteFriendGroupsNote;

  /// No description provided for @friendDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {name} khỏi danh sách bạn bè'**
  String friendDeleted(String name);

  /// No description provided for @addFriendTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn bè'**
  String get addFriendTitle;

  /// No description provided for @addFriendSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập username hoặc email...'**
  String get addFriendSearchHint;

  /// No description provided for @noUsersFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng'**
  String get noUsersFound;

  /// No description provided for @sendFriendRequest.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get sendFriendRequest;

  /// No description provided for @requestSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu kết bạn tới {name}'**
  String requestSent(String name);

  /// No description provided for @alreadyFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn và {name} đã là bạn bè'**
  String alreadyFriends(String name);

  /// No description provided for @requestPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get requestPending;

  /// No description provided for @friendRequests.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời kết bạn'**
  String get friendRequests;

  /// No description provided for @friendRequestsReceivedTab.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận'**
  String get friendRequestsReceivedTab;

  /// No description provided for @friendRequestsSentTab.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get friendRequestsSentTab;

  /// No description provided for @noFriendRequests.
  ///
  /// In vi, this message translates to:
  /// **'Không có yêu cầu nào'**
  String get noFriendRequests;

  /// No description provided for @noSentFriendRequests.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi lời mời nào'**
  String get noSentFriendRequests;

  /// No description provided for @noFriendRequestsReceivedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khi người dùng Meme khác gửi yêu cầu kết bạn cho bạn, chúng sẽ xuất hiện ở đây'**
  String get noFriendRequestsReceivedSubtitle;

  /// No description provided for @noFriendRequestsSentSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Những lời mời kết bạn bạn đã gửi sẽ hiển thị ở đây'**
  String get noFriendRequestsSentSubtitle;

  /// No description provided for @sentRequestToUsername.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu gửi đến @{username}'**
  String sentRequestToUsername(String username);

  /// No description provided for @requestPendingStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get requestPendingStatus;

  /// No description provided for @friendBadgeInvitationSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời'**
  String get friendBadgeInvitationSent;

  /// No description provided for @friendBadgeAlreadyFriendsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get friendBadgeAlreadyFriendsLabel;

  /// No description provided for @friendRequestCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ lời mời'**
  String get friendRequestCancelled;

  /// No description provided for @accept.
  ///
  /// In vi, this message translates to:
  /// **'Chấp nhận'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get decline;

  /// No description provided for @requestAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã chấp nhận lời mời kết bạn từ {name}'**
  String requestAccepted(String name);

  /// No description provided for @requestDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối lời mời kết bạn từ {name}'**
  String requestDeclined(String name);

  /// No description provided for @groupsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get groupsTitle;

  /// No description provided for @noGroups.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhóm'**
  String get noGroups;

  /// No description provided for @noGroupsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm để quản lý chi tiêu chung với bạn bè.'**
  String get noGroupsSubtitle;

  /// No description provided for @createGroup.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm'**
  String get createGroup;

  /// No description provided for @createVerb.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get createVerb;

  /// No description provided for @membersCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên'**
  String membersCount(int count);

  /// No description provided for @deleteGroupQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Xoá nhóm?'**
  String get deleteGroupQuestion;

  /// No description provided for @deleteGroupWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xoá nhóm \"{name}\"?'**
  String deleteGroupWarning(String name);

  /// No description provided for @contribution.
  ///
  /// In vi, this message translates to:
  /// **'Đóng góp'**
  String get contribution;

  /// No description provided for @goal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get goal;

  /// No description provided for @noGroupTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nhóm'**
  String get noGroupTransactions;

  /// No description provided for @addGroupTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Thêm giao dịch nhóm'**
  String get addGroupTransaction;

  /// No description provided for @editGroup.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhóm'**
  String get editGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In vi, this message translates to:
  /// **'Rời'**
  String get leaveGroup;

  /// No description provided for @leaveGroupQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm?'**
  String get leaveGroupQuestion;

  /// No description provided for @leaveGroupWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn rời khỏi nhóm \"{name}\"?'**
  String leaveGroupWarning(String name);

  /// No description provided for @groupName.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhóm'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên nhóm'**
  String get groupNameHint;

  /// No description provided for @description.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mô tả nhóm (tuỳ chọn)'**
  String get descriptionHint;

  /// No description provided for @contributionGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu đóng góp'**
  String get contributionGoal;

  /// No description provided for @contributionGoalHint.
  ///
  /// In vi, this message translates to:
  /// **'Đặt số tiền mục tiêu (tuỳ chọn)'**
  String get contributionGoalHint;

  /// No description provided for @members.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get members;

  /// No description provided for @addMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thành viên'**
  String get addMembers;

  /// No description provided for @selectedCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} đã chọn'**
  String selectedCount(int count);

  /// No description provided for @groupSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thông tin nhóm'**
  String get groupSaved;

  /// No description provided for @groupCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo nhóm thành công'**
  String get groupCreated;

  /// No description provided for @currentUserNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng hiện tại'**
  String get currentUserNotFound;

  /// No description provided for @groupNoMembersToContribute.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm chưa có thành viên để đóng góp'**
  String get groupNoMembersToContribute;

  /// No description provided for @youAreNotMember.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn thuộc nhóm này'**
  String get youAreNotMember;

  /// No description provided for @addContribution.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tiền đóng góp'**
  String get addContribution;

  /// No description provided for @selectMember.
  ///
  /// In vi, this message translates to:
  /// **'Chọn thành viên'**
  String get selectMember;

  /// No description provided for @youAreContributingFor.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang đóng góp cho'**
  String get youAreContributingFor;

  /// No description provided for @amount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get amount;

  /// No description provided for @enterValidAmount.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tiền hợp lệ'**
  String get enterValidAmount;

  /// No description provided for @canOnlyAddForSelf.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chỉ có thể thêm tiền cho chính mình'**
  String get canOnlyAddForSelf;

  /// No description provided for @contributionAdded.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm tiền đóng góp'**
  String get contributionAdded;

  /// No description provided for @cannotAddContribution.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thêm đóng góp: {error}'**
  String cannotAddContribution(String error);

  /// No description provided for @saving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get saving;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @groupNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy nhóm'**
  String get groupNotFound;

  /// No description provided for @group.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get group;

  /// No description provided for @groupDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết nhóm'**
  String get groupDetails;

  /// No description provided for @groupOwner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhóm'**
  String get groupOwner;

  /// No description provided for @groupColor.
  ///
  /// In vi, this message translates to:
  /// **'Màu nhóm'**
  String get groupColor;

  /// No description provided for @ofAmount.
  ///
  /// In vi, this message translates to:
  /// **'trên {amount}'**
  String ofAmount(String amount);

  /// No description provided for @reachedPercentage.
  ///
  /// In vi, this message translates to:
  /// **'Đã đạt {percentage}%'**
  String reachedPercentage(int percentage);

  /// No description provided for @contributingMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên đóng góp'**
  String get contributingMembers;

  /// No description provided for @noMembersYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành viên nào'**
  String get noMembersYet;

  /// No description provided for @paidAmount.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng {amount}'**
  String paidAmount(String amount);

  /// No description provided for @groupOptions.
  ///
  /// In vi, this message translates to:
  /// **'Tuỳ chọn nhóm'**
  String get groupOptions;

  /// No description provided for @editGroupSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên, màu, mục tiêu hoặc thành viên'**
  String get editGroupSubtitle;

  /// No description provided for @deleteGroup.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get deleteGroup;

  /// No description provided for @deleteGroupSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá nhóm này cho tất cả thành viên'**
  String get deleteGroupSubtitle;

  /// No description provided for @leaveGroupSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi nhóm này'**
  String get leaveGroupSubtitle;

  /// No description provided for @deleteGroupConfirmation.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xoá nhóm này không? Hành động này sẽ xoá nhóm khỏi tất cả thành viên.'**
  String get deleteGroupConfirmation;

  /// No description provided for @leaveGroupConfirmation.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn rời khỏi nhóm này không?'**
  String get leaveGroupConfirmation;

  /// No description provided for @groupDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá nhóm'**
  String get groupDeleted;

  /// No description provided for @youLeftGroup.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã rời nhóm'**
  String get youLeftGroup;

  /// No description provided for @cannotDeleteGroup.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xoá nhóm: {error}'**
  String cannotDeleteGroup(String error);

  /// No description provided for @cannotLeaveGroup.
  ///
  /// In vi, this message translates to:
  /// **'Không thể rời nhóm: {error}'**
  String cannotLeaveGroup(String error);

  /// No description provided for @ownerMustBeInGroup.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhóm luôn phải ở trong nhóm'**
  String get ownerMustBeInGroup;

  /// No description provided for @onlyOwnerCanEditGroup.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ nhóm mới có thể chỉnh sửa nhóm'**
  String get onlyOwnerCanEditGroup;

  /// No description provided for @groupInfoNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin nhóm'**
  String get groupInfoNotFound;

  /// No description provided for @pleaseEnterGroupName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên nhóm'**
  String get pleaseEnterGroupName;

  /// No description provided for @groupNameTooLong.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhóm tối đa 50 ký tự'**
  String get groupNameTooLong;

  /// No description provided for @pleaseEnterGoalAmount.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số tiền mục tiêu'**
  String get pleaseEnterGoalAmount;

  /// No description provided for @groupUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật nhóm'**
  String get groupUpdated;

  /// No description provided for @groupUpdateFailedWithError.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật nhóm thất bại: {error}'**
  String groupUpdateFailedWithError(String error);

  /// No description provided for @noPermissionToEditGroup.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền chỉnh sửa nhóm này'**
  String get noPermissionToEditGroup;

  /// No description provided for @onlyOwnerCanEditNote.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ nhóm mới có thể đổi thông tin, mời thành viên hoặc xoá thành viên khỏi nhóm.'**
  String get onlyOwnerCanEditNote;

  /// No description provided for @goalAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền mục tiêu'**
  String get goalAmount;

  /// No description provided for @goalAmountHintExample.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền mục tiêu, ví dụ {example}'**
  String goalAmountHintExample(String example);

  /// No description provided for @groupMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên nhóm'**
  String get groupMembers;

  /// No description provided for @groupMembersNote.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bạn bè để mời vào nhóm. Thành viên cũ vẫn được giữ lại dù không còn là bạn bè.'**
  String get groupMembersNote;

  /// No description provided for @noMembersOrFriends.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành viên hoặc bạn bè để hiển thị'**
  String get noMembersOrFriends;

  /// No description provided for @currentMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên hiện tại'**
  String get currentMember;

  /// No description provided for @notFriendsAnymore.
  ///
  /// In vi, this message translates to:
  /// **'Không còn là bạn bè'**
  String get notFriendsAnymore;

  /// No description provided for @groupMemberManagementNote.
  ///
  /// In vi, this message translates to:
  /// **'Khi thêm thành viên mới, nhóm sẽ xuất hiện trong tài khoản của họ. Khi bỏ chọn thành viên, nhóm sẽ bị xoá khỏi danh sách nhóm của người đó.'**
  String get groupMemberManagementNote;

  /// No description provided for @gettingLocation.
  ///
  /// In vi, this message translates to:
  /// **'Đang lấy vị trí...'**
  String get gettingLocation;

  /// No description provided for @currentLocationSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vị trí hiện tại'**
  String get currentLocationSaved;

  /// No description provided for @noLocation.
  ///
  /// In vi, this message translates to:
  /// **'Không có vị trí'**
  String get noLocation;

  /// No description provided for @skipPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua ảnh'**
  String get skipPhoto;

  /// No description provided for @food.
  ///
  /// In vi, this message translates to:
  /// **'Ăn uống'**
  String get food;

  /// No description provided for @shopping.
  ///
  /// In vi, this message translates to:
  /// **'Mua sắm'**
  String get shopping;

  /// No description provided for @transport.
  ///
  /// In vi, this message translates to:
  /// **'Di chuyển'**
  String get transport;

  /// No description provided for @education.
  ///
  /// In vi, this message translates to:
  /// **'Giáo dục'**
  String get education;

  /// No description provided for @other.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get other;

  /// No description provided for @salary.
  ///
  /// In vi, this message translates to:
  /// **'Lương'**
  String get salary;

  /// No description provided for @gift.
  ///
  /// In vi, this message translates to:
  /// **'Quà tặng'**
  String get gift;

  /// No description provided for @entertainment.
  ///
  /// In vi, this message translates to:
  /// **'Giải trí'**
  String get entertainment;

  /// No description provided for @private.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get private;

  /// No description provided for @everyone.
  ///
  /// In vi, this message translates to:
  /// **'Mọi người'**
  String get everyone;

  /// No description provided for @maxAmountDigits.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 10 chữ số'**
  String get maxAmountDigits;

  /// No description provided for @addDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chi tiết'**
  String get addDetails;

  /// No description provided for @overBudgetLimitTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vượt mục tiêu ngân sách'**
  String get overBudgetLimitTitle;

  /// No description provided for @overBudgetLimitWarning.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch này sẽ khiến chủ đề \"{name}\" vượt mục tiêu {limit} khoảng {over}. Bạn vẫn muốn lưu chứ?'**
  String overBudgetLimitWarning(String name, String limit, String over);

  /// No description provided for @saveAnyway.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn lưu'**
  String get saveAnyway;

  /// No description provided for @shareType.
  ///
  /// In vi, this message translates to:
  /// **'Loại: {type}'**
  String shareType(String type);

  /// No description provided for @shareCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục: {category}'**
  String shareCategory(String category);

  /// No description provided for @shareAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền: {amount}'**
  String shareAmount(String amount);

  /// No description provided for @shareDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết: {details}'**
  String shareDetails(String details);

  /// No description provided for @sharePrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư: {privacy}'**
  String sharePrivacy(String privacy);

  /// No description provided for @cannotShareNow.
  ///
  /// In vi, this message translates to:
  /// **'Không thể chia sẻ lúc này'**
  String get cannotShareNow;

  /// No description provided for @amountLimitExceeded.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền vượt quá giới hạn 10 chữ số'**
  String get amountLimitExceeded;

  /// No description provided for @savedWithOverLimit.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu, nhưng chủ đề \"{category}\" đã vượt mục tiêu.'**
  String savedWithOverLimit(String category);

  /// No description provided for @transactionSavedSuccessfully.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giao dịch thành công'**
  String get transactionSavedSuccessfully;

  /// No description provided for @transactionSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Lưu giao dịch thất bại'**
  String get transactionSaveFailed;

  /// No description provided for @limitLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get limitLabel;

  /// No description provided for @retake.
  ///
  /// In vi, this message translates to:
  /// **'Chụp lại'**
  String get retake;

  /// No description provided for @share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// No description provided for @statsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get statsTitle;

  /// No description provided for @income.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get expense;

  /// No description provided for @month.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get month;

  /// No description provided for @year.
  ///
  /// In vi, this message translates to:
  /// **'Năm'**
  String get year;

  /// No description provided for @backToThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Về tháng này'**
  String get backToThisMonth;

  /// No description provided for @backToThisYear.
  ///
  /// In vi, this message translates to:
  /// **'Về năm này'**
  String get backToThisYear;

  /// No description provided for @selectMonthStats.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tháng thống kê'**
  String get selectMonthStats;

  /// No description provided for @current.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại'**
  String get current;

  /// No description provided for @monthLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}'**
  String monthLabel(int month);

  /// No description provided for @shortMonth.
  ///
  /// In vi, this message translates to:
  /// **'thg {month}'**
  String shortMonth(int month);

  /// No description provided for @selectYearStats.
  ///
  /// In vi, this message translates to:
  /// **'Chọn năm thống kê'**
  String get selectYearStats;

  /// No description provided for @olderYears.
  ///
  /// In vi, this message translates to:
  /// **'Năm cũ hơn'**
  String get olderYears;

  /// No description provided for @newerYears.
  ///
  /// In vi, this message translates to:
  /// **'Năm mới hơn'**
  String get newerYears;

  /// No description provided for @totalExpenseLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi tiêu'**
  String get totalExpenseLabel;

  /// No description provided for @totalIncomeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thu nhập'**
  String get totalIncomeLabel;

  /// No description provided for @compareToPreviousMonth.
  ///
  /// In vi, this message translates to:
  /// **'so với tháng trước'**
  String get compareToPreviousMonth;

  /// No description provided for @compareToPreviousYear.
  ///
  /// In vi, this message translates to:
  /// **'so với năm trước'**
  String get compareToPreviousYear;

  /// No description provided for @expenseByCategoryMonth.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu theo danh mục tháng này'**
  String get expenseByCategoryMonth;

  /// No description provided for @incomeByCategoryMonth.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập theo danh mục tháng này'**
  String get incomeByCategoryMonth;

  /// No description provided for @expenseByCategoryYear.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu theo danh mục năm này'**
  String get expenseByCategoryYear;

  /// No description provided for @incomeByCategoryYear.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập theo danh mục năm này'**
  String get incomeByCategoryYear;

  /// No description provided for @noExpenseDataMonth.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu chi tiêu tháng này'**
  String get noExpenseDataMonth;

  /// No description provided for @noIncomeDataMonth.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu thu nhập tháng này'**
  String get noIncomeDataMonth;

  /// No description provided for @noExpenseDataYear.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu chi tiêu năm này'**
  String get noExpenseDataYear;

  /// No description provided for @noIncomeDataYear.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu thu nhập năm này'**
  String get noIncomeDataYear;

  /// No description provided for @expenseNoChange.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu của bạn không thay đổi so với kỳ trước.'**
  String get expenseNoChange;

  /// No description provided for @incomeNoChange.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập của bạn không thay đổi so với kỳ trước.'**
  String get incomeNoChange;

  /// No description provided for @expenseMore.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã chi nhiều hơn {percent}% so với kỳ trước.'**
  String expenseMore(String percent);

  /// No description provided for @incomeMore.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã nhận nhiều hơn {percent}% so với kỳ trước.'**
  String incomeMore(String percent);

  /// No description provided for @expenseLess.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã chi ít hơn {percent}% so với kỳ trước.'**
  String expenseLess(String percent);

  /// No description provided for @incomeLess.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã nhận ít hơn {percent}% so với kỳ trước.'**
  String incomeLess(String percent);

  /// No description provided for @previousPeriodAmount.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ trước: {amount}'**
  String previousPeriodAmount(String amount);

  /// No description provided for @categories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get categories;

  /// No description provided for @map.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ'**
  String get map;

  /// No description provided for @transactionMap.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ giao dịch'**
  String get transactionMap;

  /// No description provided for @mapControl.
  ///
  /// In vi, this message translates to:
  /// **'Điều khiển bản đồ'**
  String get mapControl;

  /// No description provided for @controlling.
  ///
  /// In vi, this message translates to:
  /// **'Đang điều khiển'**
  String get controlling;

  /// No description provided for @tapToControlMap.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để điều khiển bản đồ'**
  String get tapToControlMap;

  /// No description provided for @tapControllingToDisable.
  ///
  /// In vi, this message translates to:
  /// **'Chạm \"Đang điều khiển\" để tắt tương tác bản đồ.'**
  String get tapControllingToDisable;

  /// No description provided for @recentTransactionsOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan các giao dịch gần đây.'**
  String get recentTransactionsOverview;

  /// No description provided for @mapEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu bản đồ'**
  String get mapEmptyTitle;

  /// No description provided for @mapEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các giao dịch mới sau khi bạn cấp quyền vị trí sẽ được hiển thị trên bản đồ.'**
  String get mapEmptySubtitle;

  /// No description provided for @mapSummary.
  ///
  /// In vi, this message translates to:
  /// **'{transactions} giao dịch tại {locations} vị trí'**
  String mapSummary(int transactions, int locations);

  /// No description provided for @mapTransactionsHere.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch ở đây'**
  String mapTransactionsHere(int count);

  /// No description provided for @expenseDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết chi tiêu'**
  String get expenseDetails;

  /// No description provided for @incomeDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết thu nhập'**
  String get incomeDetails;

  /// No description provided for @percentOfTotalExpense.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% tổng chi tiêu'**
  String percentOfTotalExpense(int percent);

  /// No description provided for @percentOfTotalIncome.
  ///
  /// In vi, this message translates to:
  /// **'{percent}% tổng thu nhập'**
  String percentOfTotalIncome(int percent);

  /// No description provided for @noUser.
  ///
  /// In vi, this message translates to:
  /// **'Không có người dùng'**
  String get noUser;

  /// No description provided for @loadFeedError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải feed:\n{error}'**
  String loadFeedError(String error);

  /// No description provided for @emptyFeedFriends.
  ///
  /// In vi, this message translates to:
  /// **'Feed bạn bè đang trống'**
  String get emptyFeedFriends;

  /// No description provided for @emptyFeedFriendsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khi bạn hoặc bạn bè chia sẻ giao dịch ở chế độ \"Bạn bè\", bài đăng sẽ xuất hiện ở đây.'**
  String get emptyFeedFriendsSubtitle;

  /// No description provided for @noPostsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bài đăng nào'**
  String get noPostsYet;

  /// No description provided for @youHaveNoPosts.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có bài đăng nào'**
  String get youHaveNoPosts;

  /// No description provided for @userHasNoPosts.
  ///
  /// In vi, this message translates to:
  /// **'{name} chưa có bài đăng nào'**
  String userHasNoPosts(String name);

  /// No description provided for @justNow.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count}ph'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count}g'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count}ngày'**
  String daysAgo(int count);

  /// No description provided for @dateAt.
  ///
  /// In vi, this message translates to:
  /// **'ngày {date}'**
  String dateAt(String date);

  /// No description provided for @noPhotosInFeed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh nào trong feed'**
  String get noPhotosInFeed;

  /// No description provided for @allPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả ảnh'**
  String get allPhotos;

  /// No description provided for @calendarTransactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch giao dịch'**
  String get calendarTransactionsTitle;

  /// No description provided for @selectMonth.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tháng'**
  String get selectMonth;

  /// No description provided for @todayLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get todayLabel;

  /// No description provided for @dayDetailEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có giao dịch trong ngày này'**
  String get dayDetailEmpty;

  /// No description provided for @momentViewerEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có giao dịch để hiển thị'**
  String get momentViewerEmpty;

  /// No description provided for @momentViewerSaveVideo.
  ///
  /// In vi, this message translates to:
  /// **'Lưu video vào máy'**
  String get momentViewerSaveVideo;

  /// No description provided for @momentViewerSaveImage.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ảnh vào máy'**
  String get momentViewerSaveImage;

  /// No description provided for @momentViewerDeleteTransaction.
  ///
  /// In vi, this message translates to:
  /// **'Xoá giao dịch'**
  String get momentViewerDeleteTransaction;

  /// No description provided for @momentViewerVideoNoLink.
  ///
  /// In vi, this message translates to:
  /// **'Video này chưa có link để lưu vào máy'**
  String get momentViewerVideoNoLink;

  /// No description provided for @momentViewerImageNoLink.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh dạng icon/category không thể lưu trực tiếp vào máy'**
  String get momentViewerImageNoLink;

  /// No description provided for @momentViewerSaveVideoSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu video vào máy'**
  String get momentViewerSaveVideoSuccess;

  /// No description provided for @momentViewerSaveImageSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ảnh vào máy'**
  String get momentViewerSaveImageSuccess;

  /// No description provided for @momentViewerSaveVideoFailed.
  ///
  /// In vi, this message translates to:
  /// **'Lưu video thất bại'**
  String get momentViewerSaveVideoFailed;

  /// No description provided for @momentViewerSaveImageFailed.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ảnh thất bại'**
  String get momentViewerSaveImageFailed;

  /// No description provided for @momentViewerCannotSaveVideo.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu video vào máy'**
  String get momentViewerCannotSaveVideo;

  /// No description provided for @momentViewerCannotSaveImage.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu ảnh vào máy'**
  String get momentViewerCannotSaveImage;

  /// No description provided for @momentViewerDeleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá giao dịch'**
  String get momentViewerDeleteConfirmTitle;

  /// No description provided for @momentViewerDeleteConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xoá giao dịch này không?'**
  String get momentViewerDeleteConfirmMessage;

  /// No description provided for @momentViewerDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá giao dịch'**
  String get momentViewerDeleted;

  /// No description provided for @momentViewerDeleteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Xoá giao dịch thất bại'**
  String get momentViewerDeleteFailed;

  /// No description provided for @momentViewerUploadTime.
  ///
  /// In vi, this message translates to:
  /// **'lúc {time} ngày {date}'**
  String momentViewerUploadTime(String time, String date);

  /// No description provided for @tabHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get tabHome;

  /// No description provided for @tabStats.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get tabStats;

  /// No description provided for @tabFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get tabFriends;

  /// No description provided for @tabBudget.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách'**
  String get tabBudget;

  /// No description provided for @tabLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải'**
  String get tabLoading;

  /// No description provided for @someone.
  ///
  /// In vi, this message translates to:
  /// **'Người này'**
  String get someone;

  /// No description provided for @manageCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get manageCategories;

  /// No description provided for @categoriesExpenseTab.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get categoriesExpenseTab;

  /// No description provided for @categoriesIncomeTab.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập'**
  String get categoriesIncomeTab;

  /// No description provided for @addCustomCategory.
  ///
  /// In vi, this message translates to:
  /// **'Thêm danh mục'**
  String get addCustomCategory;

  /// No description provided for @categoryNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục (tiếng Việt)'**
  String get categoryNameHint;

  /// No description provided for @categoryTypeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Loại'**
  String get categoryTypeLabel;

  /// No description provided for @categoryIconLabel.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get categoryIconLabel;

  /// No description provided for @categoryColorLabel.
  ///
  /// In vi, this message translates to:
  /// **'Màu'**
  String get categoryColorLabel;

  /// No description provided for @saveCategory.
  ///
  /// In vi, this message translates to:
  /// **'Lưu danh mục'**
  String get saveCategory;

  /// No description provided for @categorySaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu danh mục'**
  String get categorySaved;

  /// No description provided for @categoryNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên danh mục'**
  String get categoryNameRequired;

  /// No description provided for @categoryDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã có danh mục trùng tên'**
  String get categoryDuplicate;

  /// No description provided for @categoryReserved.
  ///
  /// In vi, this message translates to:
  /// **'Tên này dành cho danh mục mặc định của ứng dụng'**
  String get categoryReserved;

  /// No description provided for @categoryNameTooLong.
  ///
  /// In vi, this message translates to:
  /// **'Tên quá dài (tối đa 50 ký tự)'**
  String get categoryNameTooLong;

  /// No description provided for @categorySaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu danh mục'**
  String get categorySaveFailed;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá danh mục'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In vi, this message translates to:
  /// **'Xoá \"{name}\"? Các giao dịch đã lưu vẫn giữ nguyên.'**
  String deleteCategoryMessage(String name);

  /// No description provided for @deleteCategoryConfirmAction.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get deleteCategoryConfirmAction;

  /// No description provided for @categoryDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá danh mục'**
  String get categoryDeleted;

  /// No description provided for @categoryDeleteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xoá danh mục'**
  String get categoryDeleteFailed;

  /// No description provided for @categoriesExpenseEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục chi tiêu tùy chỉnh. Chạm + để thêm.'**
  String get categoriesExpenseEmpty;

  /// No description provided for @categoriesIncomeEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh mục thu nhập tùy chỉnh. Chạm + để thêm.'**
  String get categoriesIncomeEmpty;

  /// No description provided for @builtinCategoriesHeading.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục mặc định (không chỉnh sửa)'**
  String get builtinCategoriesHeading;

  /// No description provided for @yourCategoriesHeading.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục của bạn'**
  String get yourCategoriesHeading;

  /// No description provided for @editCustomCategory.
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get editCustomCategory;

  /// No description provided for @categoryUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật danh mục'**
  String get categoryUpdated;

  /// No description provided for @categoryUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật danh mục'**
  String get categoryUpdateFailed;

  /// No description provided for @categoryNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục không còn tồn tại'**
  String get categoryNotFound;

  /// No description provided for @closeFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thân'**
  String get closeFriends;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bật máy ảnh để sử dụng Meme'**
  String get cameraPermissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở cài đặt'**
  String get openSettings;

  /// No description provided for @noCameraAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy máy ảnh'**
  String get noCameraAvailable;

  /// No description provided for @dayTab.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get dayTab;

  /// No description provided for @monthTab.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get monthTab;

  /// No description provided for @expenseLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get expenseLabel;

  /// No description provided for @incomeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập'**
  String get incomeLabel;

  /// No description provided for @appIcon.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng ứng dụng'**
  String get appIcon;

  /// No description provided for @appIconSection.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng ứng dụng'**
  String get appIconSection;

  /// No description provided for @appIconSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh biểu tượng Meme trên màn hình chính'**
  String get appIconSubtitle;

  /// No description provided for @appIconPickerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn kiểu biểu tượng Meme để hiển thị trên màn hình chính của bạn.'**
  String get appIconPickerSubtitle;

  /// No description provided for @appIconClassic.
  ///
  /// In vi, this message translates to:
  /// **'Meme Cổ Điển'**
  String get appIconClassic;

  /// No description provided for @appIconClassicDesc.
  ///
  /// In vi, this message translates to:
  /// **'Phong cách biểu tượng gốc quen thuộc và vui nhộn'**
  String get appIconClassicDesc;

  /// No description provided for @appIconNeon.
  ///
  /// In vi, this message translates to:
  /// **'Meme Vàng Neon'**
  String get appIconNeon;

  /// No description provided for @appIconNeonDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tông vàng ấm áp, nổi bật và đậm cá tính'**
  String get appIconNeonDesc;

  /// No description provided for @appIconOcean.
  ///
  /// In vi, this message translates to:
  /// **'Meme Xanh Đại Dương'**
  String get appIconOcean;

  /// No description provided for @appIconOceanDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tông xanh dương hiện đại, tươi mát và năng động'**
  String get appIconOceanDesc;

  /// No description provided for @appIconInUse.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get appIconInUse;

  /// No description provided for @appIconChangedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi biểu tượng ứng dụng thành \"{name}\"'**
  String appIconChangedSuccess(String name);

  /// No description provided for @appIconChangeFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đổi biểu tượng trên thiết bị này'**
  String get appIconChangeFailed;

  /// No description provided for @cameraTheme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện máy ảnh'**
  String get cameraTheme;

  /// No description provided for @cameraThemeSection.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện máy ảnh'**
  String get cameraThemeSection;

  /// No description provided for @cameraThemeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy biến phong cách màu sắc và kính ngắm cho máy ảnh'**
  String get cameraThemeSubtitle;

  /// No description provided for @cameraThemePickerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh kính ngắm, màu nút chụp và giao diện máy ảnh theo phong cách của bạn.'**
  String get cameraThemePickerSubtitle;

  /// No description provided for @cameraThemeClassic.
  ///
  /// In vi, this message translates to:
  /// **'Meme Cổ Điển'**
  String get cameraThemeClassic;

  /// No description provided for @cameraThemeClassicDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện tối tinh tế với điểm nhấn xanh ngọc lục bảo neon'**
  String get cameraThemeClassicDesc;

  /// No description provided for @cameraThemeCyber.
  ///
  /// In vi, this message translates to:
  /// **'Cyber Neon'**
  String get cameraThemeCyber;

  /// No description provided for @cameraThemeCyberDesc.
  ///
  /// In vi, this message translates to:
  /// **'Phong cách cyberpunk với sắc tím rực rỡ và xanh điện tử'**
  String get cameraThemeCyberDesc;

  /// No description provided for @cameraThemeSunset.
  ///
  /// In vi, this message translates to:
  /// **'Hoàng Hôn Vàng'**
  String get cameraThemeSunset;

  /// No description provided for @cameraThemeSunsetDesc.
  ///
  /// In vi, this message translates to:
  /// **'Không gian hoàng hôn ấm áp với ánh hổ phách sang trọng'**
  String get cameraThemeSunsetDesc;

  /// No description provided for @cameraThemeOcean.
  ///
  /// In vi, this message translates to:
  /// **'Gió Biển'**
  String get cameraThemeOcean;

  /// No description provided for @cameraThemeOceanDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xanh sapphire sâu thẳm, tươi mát và tràn đầy năng lượng'**
  String get cameraThemeOceanDesc;

  /// No description provided for @cameraThemeMatcha.
  ///
  /// In vi, this message translates to:
  /// **'Matcha Thiền'**
  String get cameraThemeMatcha;

  /// No description provided for @cameraThemeMatchaDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sắc xanh matcha thanh tịnh cùng tông rừng tự nhiên'**
  String get cameraThemeMatchaDesc;

  /// No description provided for @cameraThemeAurora.
  ///
  /// In vi, this message translates to:
  /// **'Bắc Cực Quang'**
  String get cameraThemeAurora;

  /// No description provided for @cameraThemeAuroraDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ánh sáng phương bắc huyền ảo với làn sóng xanh mòng két và tím'**
  String get cameraThemeAuroraDesc;

  /// No description provided for @cameraThemeSakura.
  ///
  /// In vi, this message translates to:
  /// **'Hoa Anh Đào'**
  String get cameraThemeSakura;

  /// No description provided for @cameraThemeSakuraDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sắc hồng pastel ngọt ngào và trẻ trung như hoa anh đào nở'**
  String get cameraThemeSakuraDesc;

  /// No description provided for @cameraThemeGalaxy.
  ///
  /// In vi, this message translates to:
  /// **'Tinh Vân Thiên Hà'**
  String get cameraThemeGalaxy;

  /// No description provided for @cameraThemeGalaxyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Không gian vũ trụ huyền bí với tím cực tím, hồng magenta và xanh điện'**
  String get cameraThemeGalaxyDesc;

  /// No description provided for @cameraThemeLava.
  ///
  /// In vi, this message translates to:
  /// **'Dòng Nham Thạch'**
  String get cameraThemeLava;

  /// No description provided for @cameraThemeLavaDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dòng magma rực lửa với đỏ thẫm và ngọn lửa vàng bốc cháy'**
  String get cameraThemeLavaDesc;

  /// No description provided for @cameraThemeVaporwave.
  ///
  /// In vi, this message translates to:
  /// **'Retro Vaporwave'**
  String get cameraThemeVaporwave;

  /// No description provided for @cameraThemeVaporwaveDesc.
  ///
  /// In vi, this message translates to:
  /// **'Năng lượng synthwave thập niên 80 với xanh ngọc, hồng rực và ánh vàng'**
  String get cameraThemeVaporwaveDesc;

  /// No description provided for @cameraThemeChangedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã áp dụng chủ đề \"{name}\"'**
  String cameraThemeChangedSuccess(String name);

  /// No description provided for @chatBubbleThemeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện bong bóng chat'**
  String get chatBubbleThemeTitle;

  /// No description provided for @chatBubbleSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get chatBubbleSuggestions;

  /// No description provided for @chatBubbleAppliesToAll.
  ///
  /// In vi, this message translates to:
  /// **'Kiểu bong bóng này áp dụng cho tất cả cuộc trò chuyện.'**
  String get chatBubbleAppliesToAll;

  /// No description provided for @chatBubblePreviewMe.
  ///
  /// In vi, this message translates to:
  /// **'Bây giờ bạn có thể đổi kiểu bong bóng chat để cuộc trò chuyện trông mới mẻ hơn. Thật tuyệt!'**
  String get chatBubblePreviewMe;

  /// No description provided for @chatBubblePreviewFriend.
  ///
  /// In vi, this message translates to:
  /// **'Trông đẹp đấy! Mình cũng đổi kiểu ngay đây.'**
  String get chatBubblePreviewFriend;

  /// No description provided for @chatBubbleSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get chatBubbleSave;

  /// No description provided for @chatBubbleCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get chatBubbleCancel;

  /// No description provided for @friendsCountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè ({count})'**
  String friendsCountTitle(int count);

  /// No description provided for @findNewFriends.
  ///
  /// In vi, this message translates to:
  /// **'Tìm bạn bè'**
  String get findNewFriends;

  /// No description provided for @searchInFriends.
  ///
  /// In vi, this message translates to:
  /// **'Tìm trong bạn bè...'**
  String get searchInFriends;

  /// No description provided for @friendsTabAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get friendsTabAll;

  /// No description provided for @friendsTabClose.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thân'**
  String get friendsTabClose;

  /// No description provided for @friendsTabRequests.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời'**
  String get friendsTabRequests;

  /// No description provided for @sendMessageAction.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin'**
  String get sendMessageAction;

  /// No description provided for @addToCloseFriends.
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào bạn thân'**
  String get addToCloseFriends;

  /// No description provided for @removeFromCloseFriends.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khỏi bạn thân'**
  String get removeFromCloseFriends;

  /// No description provided for @addedToCloseFriends.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm {name} vào bạn thân ⭐'**
  String addedToCloseFriends(String name);

  /// No description provided for @removedFromCloseFriends.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa {name} khỏi bạn thân'**
  String removedFromCloseFriends(String name);

  /// No description provided for @noMatchingFriends.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bạn bè phù hợp'**
  String get noMatchingFriends;

  /// No description provided for @noCloseFriendsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bạn thân nào'**
  String get noCloseFriendsYet;

  /// No description provided for @noCloseFriendsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào biểu tượng ngôi sao bên cạnh bạn bè để thêm họ vào bạn thân'**
  String get noCloseFriendsSubtitle;

  /// No description provided for @typeMessageHint.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn...'**
  String get typeMessageHint;

  /// No description provided for @emptyConversationPrompt.
  ///
  /// In vi, this message translates to:
  /// **'✨ Gửi tin nhắn hoặc thả cảm xúc đầu tiên!'**
  String get emptyConversationPrompt;

  /// No description provided for @replyingToSelf.
  ///
  /// In vi, this message translates to:
  /// **'Đang trả lời chính bạn'**
  String get replyingToSelf;

  /// No description provided for @replyingToUser.
  ///
  /// In vi, this message translates to:
  /// **'Đang trả lời {name}'**
  String replyingToUser(String name);

  /// No description provided for @replyingToPost.
  ///
  /// In vi, this message translates to:
  /// **'Đang trả lời bài viết của {name}'**
  String replyingToPost(String name);

  /// No description provided for @youRepliedToYourself.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã trả lời chính mình'**
  String get youRepliedToYourself;

  /// No description provided for @youRepliedToUser.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã trả lời {name}'**
  String youRepliedToUser(String name);

  /// No description provided for @userRepliedToYou.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã trả lời bạn'**
  String userRepliedToYou(String name);

  /// No description provided for @userRepliedToThemself.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã trả lời chính họ'**
  String userRepliedToThemself(String name);

  /// No description provided for @activeNow.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get activeNow;

  /// No description provided for @activeAgo.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động {time} trước'**
  String activeAgo(String time);

  /// No description provided for @offlineStatus.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại tuyến'**
  String get offlineStatus;

  /// No description provided for @feedMessageHint.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn...'**
  String get feedMessageHint;

  /// No description provided for @sendReactionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thả cảm xúc'**
  String get sendReactionTitle;

  /// No description provided for @postActivityTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get postActivityTitle;

  /// No description provided for @noPostActivityYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hoạt động nào!'**
  String get noPostActivityYet;

  /// No description provided for @postViewedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã xem!'**
  String get postViewedStatus;

  /// No description provided for @oneNewPost.
  ///
  /// In vi, this message translates to:
  /// **'1 bài viết mới!'**
  String get oneNewPost;

  /// No description provided for @newPostsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} bài viết mới!'**
  String newPostsCount(int count);

  /// No description provided for @closeFriendBadge.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thân'**
  String get closeFriendBadge;

  /// No description provided for @viewSentRequests.
  ///
  /// In vi, this message translates to:
  /// **'Xem lời mời đã gửi'**
  String get viewSentRequests;

  /// No description provided for @sentRequestsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đã gửi'**
  String get sentRequestsTitle;

  /// No description provided for @sentRequestsCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi {count} lời mời'**
  String sentRequestsCount(int count);

  /// No description provided for @noSentRequestsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lời mời nào đã gửi!'**
  String get noSentRequestsYet;

  /// No description provided for @sortDefault.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định'**
  String get sortDefault;

  /// No description provided for @sortNewestFirst.
  ///
  /// In vi, this message translates to:
  /// **'Mới nhất trước'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In vi, this message translates to:
  /// **'Cũ nhất trước'**
  String get sortOldestFirst;

  /// No description provided for @sortBy.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp theo'**
  String get sortBy;

  /// No description provided for @cancelRequest.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancelRequest;

  /// No description provided for @requestCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy lời mời kết bạn'**
  String get requestCancelled;

  /// No description provided for @noFriendRequestsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lời mời kết bạn nào!'**
  String get noFriendRequestsYet;

  /// No description provided for @reply.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời'**
  String get reply;

  /// No description provided for @copy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get copy;

  /// No description provided for @copiedToClipboard.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép tin nhắn'**
  String get copiedToClipboard;

  /// No description provided for @unsend.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get unsend;

  /// No description provided for @unsendConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi tin nhắn?'**
  String get unsendConfirm;

  /// No description provided for @unsendConfirmDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn này sẽ được thu hồi đối với tất cả mọi người trong đoạn chat.'**
  String get unsendConfirmDesc;

  /// No description provided for @deleteForMe.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ở phía tôi'**
  String get deleteForMe;

  /// No description provided for @deleteForMeConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tin nhắn ở phía bạn?'**
  String get deleteForMeConfirm;

  /// No description provided for @deleteForMeConfirmDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn này chỉ bị xóa ở phía bạn. Những người khác vẫn sẽ nhìn thấy.'**
  String get deleteForMeConfirmDesc;

  /// No description provided for @report.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get report;

  /// No description provided for @reportMessage.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo tin nhắn'**
  String get reportMessage;

  /// No description provided for @reportMessageDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tại sao bạn muốn báo cáo tin nhắn này?'**
  String get reportMessageDesc;

  /// No description provided for @reportSpam.
  ///
  /// In vi, this message translates to:
  /// **'Spam hoặc làm phiền'**
  String get reportSpam;

  /// No description provided for @reportInappropriate.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung không phù hợp'**
  String get reportInappropriate;

  /// No description provided for @reportViolence.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn từ thù ghét hoặc bạo lực'**
  String get reportViolence;

  /// No description provided for @reportOther.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác'**
  String get reportOther;

  /// No description provided for @reportSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn. Báo cáo của bạn đã được gửi.'**
  String get reportSuccess;

  /// No description provided for @selectReaction.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cảm xúc'**
  String get selectReaction;

  /// No description provided for @streakMaintaining.
  ///
  /// In vi, this message translates to:
  /// **'Đang duy trì'**
  String get streakMaintaining;

  /// No description provided for @bestStreakLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ lục cá nhân'**
  String get bestStreakLabel;

  /// No description provided for @avatarCollection.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập'**
  String get avatarCollection;

  /// No description provided for @framesCount.
  ///
  /// In vi, this message translates to:
  /// **'{unlocked}/{total} Khung'**
  String framesCount(int unlocked, int total);

  /// No description provided for @dailyMemeStreak.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi Meme Hằng Ngày'**
  String get dailyMemeStreak;

  /// No description provided for @unlockedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở khóa'**
  String get unlockedStatus;

  /// No description provided for @unlockedBadgeCount.
  ///
  /// In vi, this message translates to:
  /// **'{unlocked}/{total} Đã mở'**
  String unlockedBadgeCount(int unlocked, int total);

  /// No description provided for @hasPostedStreakMotivation.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đăng bài hôm nay. Hãy tiếp tục duy trì phong độ tuyệt vời này!'**
  String get hasPostedStreakMotivation;

  /// No description provided for @notPostedStreakMotivation.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay bạn chưa đăng bài. Hãy chia sẻ một khoảnh khắc để giữ chuỗi nhé!'**
  String get notPostedStreakMotivation;

  /// No description provided for @avatarFrameCollectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập Khung đại diện'**
  String get avatarFrameCollectionTitle;

  /// No description provided for @currentEquipped.
  ///
  /// In vi, this message translates to:
  /// **'Đang sử dụng'**
  String get currentEquipped;

  /// No description provided for @nextMilestone.
  ///
  /// In vi, this message translates to:
  /// **'Cột mốc tiếp theo'**
  String get nextMilestone;

  /// No description provided for @daysLeftToUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} ngày để mở khóa {frameName}'**
  String daysLeftToUnlock(int count, String frameName);

  /// No description provided for @allFramesUnlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở khóa toàn bộ khung avatar'**
  String get allFramesUnlocked;

  /// No description provided for @allFramesUnlockedDesc.
  ///
  /// In vi, this message translates to:
  /// **'Hãy tiếp tục duy trì chuỗi khoảnh khắc tuyệt vời mỗi ngày!'**
  String get allFramesUnlockedDesc;

  /// No description provided for @needStreakToUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Đạt chuỗi {days} ngày để mở khóa khung {frameName}!'**
  String needStreakToUnlock(int days, String frameName);

  /// No description provided for @streakMilestoneUnlocked.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa cột mốc mới!'**
  String get streakMilestoneUnlocked;

  /// No description provided for @streakMilestoneDaysLabel.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày'**
  String streakMilestoneDaysLabel(int days);

  /// No description provided for @streakMilestoneContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get streakMilestoneContinue;

  /// No description provided for @streakRewardAvatarFrameHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở mục Chuỗi để nhận & đổi khung avatar mới!'**
  String get streakRewardAvatarFrameHint;

  /// No description provided for @streakRewardCameraThemeHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa Khung avatar & Khám phá Chủ đề máy ảnh mới!'**
  String get streakRewardCameraThemeHint;

  /// No description provided for @today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get yesterday;

  /// No description provided for @generalOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get generalOverview;

  /// No description provided for @appearanceAndThemes.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện & Chủ đề'**
  String get appearanceAndThemes;

  /// No description provided for @systemPreferences.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn hệ thống'**
  String get systemPreferences;

  /// No description provided for @accountAndSupport.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản & Hỗ trợ'**
  String get accountAndSupport;

  /// No description provided for @selectThemeMode.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chế độ hiển thị'**
  String get selectThemeMode;

  /// No description provided for @selectLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get selectLanguage;

  /// No description provided for @selectCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Chọn đơn vị tiền tệ'**
  String get selectCurrency;

  /// No description provided for @themeModeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ giao diện'**
  String get themeModeLabel;

  /// No description provided for @vietnameseDong.
  ///
  /// In vi, this message translates to:
  /// **'Đồng Việt Nam'**
  String get vietnameseDong;

  /// No description provided for @usDollar.
  ///
  /// In vi, this message translates to:
  /// **'Đô la Mỹ'**
  String get usDollar;

  /// No description provided for @vndFull.
  ///
  /// In vi, this message translates to:
  /// **'VND (₫ • Đồng Việt Nam)'**
  String get vndFull;

  /// No description provided for @usdFull.
  ///
  /// In vi, this message translates to:
  /// **'USD (\$ • Đô la Mỹ)'**
  String get usdFull;

  /// No description provided for @systemDefault.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định hệ thống'**
  String get systemDefault;

  /// No description provided for @systemDefaultLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định hệ thống (Tự động)'**
  String get systemDefaultLanguage;

  /// No description provided for @conversationsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc trò chuyện'**
  String get conversationsTitle;

  /// No description provided for @noConversationsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cuộc trò chuyện nào'**
  String get noConversationsYet;

  /// No description provided for @startChattingWithFriends.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin cho bạn bè để bắt đầu trò chuyện'**
  String get startChattingWithFriends;

  /// No description provided for @newMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn mới'**
  String get newMessage;

  /// No description provided for @searchConversations.
  ///
  /// In vi, this message translates to:
  /// **'Tìm cuộc trò chuyện...'**
  String get searchConversations;

  /// No description provided for @markAllAsRead.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu tất cả đã đọc'**
  String get markAllAsRead;

  /// No description provided for @startConversation.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu cuộc trò chuyện'**
  String get startConversation;

  /// No description provided for @youReactedToMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã thả cảm xúc {emoji} vào tin nhắn'**
  String youReactedToMessage(String emoji);

  /// No description provided for @friendReactedToMessage.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã thả cảm xúc {emoji} vào tin nhắn'**
  String friendReactedToMessage(String name, String emoji);

  /// No description provided for @repliedToPostSnippet.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả lời bài viết: {text}'**
  String repliedToPostSnippet(String text);

  /// No description provided for @isTyping.
  ///
  /// In vi, this message translates to:
  /// **'Đang soạn tin...'**
  String get isTyping;

  /// No description provided for @youPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Bạn: {text}'**
  String youPrefix(String text);

  /// No description provided for @taggedYouInPost.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã nhắc đến bạn trong một bài viết'**
  String taggedYouInPost(String name);

  /// No description provided for @tagFriends.
  ///
  /// In vi, this message translates to:
  /// **'Gắn thẻ bạn bè'**
  String get tagFriends;

  /// No description provided for @startTypingToTag.
  ///
  /// In vi, this message translates to:
  /// **'Gõ @ để gắn thẻ bạn bè'**
  String get startTypingToTag;

  /// No description provided for @viewTaggedProfile.
  ///
  /// In vi, this message translates to:
  /// **'Xem trang cá nhân'**
  String get viewTaggedProfile;

  /// No description provided for @messageFriend.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin'**
  String get messageFriend;

  /// No description provided for @streakDayCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày'**
  String streakDayCount(int count);

  /// No description provided for @friendRequestSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời'**
  String get friendRequestSent;

  /// No description provided for @messageRecalled.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn đã bị thu hồi'**
  String get messageRecalled;

  /// No description provided for @recallTimeExpired.
  ///
  /// In vi, this message translates to:
  /// **'Đã quá thời hạn 15 phút để thu hồi tin nhắn này'**
  String get recallTimeExpired;

  /// No description provided for @privateCannotTagFriends.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ riêng tư không gắn thẻ bạn bè'**
  String get privateCannotTagFriends;

  /// No description provided for @closeFriendsTagOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ gắn thẻ được bạn bè trong danh sách Bạn thân'**
  String get closeFriendsTagOnly;

  /// No description provided for @privacySection.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get privacySection;

  /// No description provided for @activeStatusTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái hoạt động'**
  String get activeStatusTitle;

  /// No description provided for @activeStatusSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khi tắt, bạn bè sẽ không thấy bạn hoạt động và bạn cũng không thấy trạng thái của họ.'**
  String get activeStatusSubtitle;

  /// No description provided for @chooseWhoCanSeeActive.
  ///
  /// In vi, this message translates to:
  /// **'Chọn người có thể thấy khi bạn hoạt động'**
  String get chooseWhoCanSeeActive;

  /// No description provided for @activeStatusPublic.
  ///
  /// In vi, this message translates to:
  /// **'Công khai'**
  String get activeStatusPublic;

  /// No description provided for @activeStatusPublicDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mọi người trên ứng dụng đều có thể thấy trạng thái hoạt động của bạn.'**
  String get activeStatusPublicDesc;

  /// No description provided for @activeStatusFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get activeStatusFriends;

  /// No description provided for @activeStatusFriendsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè có thể thấy khi bạn hoạt động. Cả hai chỉ thấy nhau khi đều bật.'**
  String get activeStatusFriendsDesc;

  /// No description provided for @activeStatusNoOne.
  ///
  /// In vi, this message translates to:
  /// **'Không ai cả'**
  String get activeStatusNoOne;

  /// No description provided for @activeStatusNoOneDesc.
  ///
  /// In vi, this message translates to:
  /// **'Không ai có thể thấy trạng thái hoạt động của bạn và bạn cũng không thấy của ai.'**
  String get activeStatusNoOneDesc;

  /// No description provided for @rewindTitle.
  ///
  /// In vi, this message translates to:
  /// **'Meme Rewind'**
  String get rewindTitle;

  /// No description provided for @rewindMemories.
  ///
  /// In vi, this message translates to:
  /// **'Kỷ niệm chi tiêu'**
  String get rewindMemories;

  /// No description provided for @rewindSelectPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoảng thời gian'**
  String get rewindSelectPeriod;

  /// No description provided for @rewindWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần'**
  String get rewindWeek;

  /// No description provided for @rewindMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get rewindMonth;

  /// No description provided for @rewindQuarter.
  ///
  /// In vi, this message translates to:
  /// **'Quý'**
  String get rewindQuarter;

  /// No description provided for @rewindYear.
  ///
  /// In vi, this message translates to:
  /// **'Năm'**
  String get rewindYear;

  /// No description provided for @rewindThisWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này'**
  String get rewindThisWeek;

  /// No description provided for @rewindThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get rewindThisMonth;

  /// No description provided for @rewindThisQuarter.
  ///
  /// In vi, this message translates to:
  /// **'Quý này'**
  String get rewindThisQuarter;

  /// No description provided for @rewindThisYear.
  ///
  /// In vi, this message translates to:
  /// **'Năm này'**
  String get rewindThisYear;

  /// No description provided for @rewindOverviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hành trình giai đoạn này'**
  String get rewindOverviewTitle;

  /// No description provided for @rewindOverviewSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng thời gian vừa qua của bạn thế nào?'**
  String get rewindOverviewSubtitle;

  /// No description provided for @rewindTotalExpense.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi tiêu'**
  String get rewindTotalExpense;

  /// No description provided for @rewindTotalIncome.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thu nhập'**
  String get rewindTotalIncome;

  /// No description provided for @rewindTotalTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get rewindTotalTransactions;

  /// No description provided for @rewindBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư còn lại'**
  String get rewindBalance;

  /// No description provided for @rewindSpentMore.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã chi nhiều hơn {percent}% so với kỳ trước'**
  String rewindSpentMore(String percent);

  /// No description provided for @rewindSpentLess.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã chi ít hơn {percent}% so với kỳ trước'**
  String rewindSpentLess(String percent);

  /// No description provided for @rewindSpentEqual.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu tương đương so với kỳ trước'**
  String get rewindSpentEqual;

  /// No description provided for @rewindSpentGentleUp.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã chi nhiều hơn một chút so với kỳ trước'**
  String get rewindSpentGentleUp;

  /// No description provided for @rewindSpentGentleDown.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã tiết kiệm hơn so với kỳ trước'**
  String get rewindSpentGentleDown;

  /// No description provided for @rewindCategoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiền của bạn đi đâu?'**
  String get rewindCategoryTitle;

  /// No description provided for @rewindCategorySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Những danh mục chiếm nhiều chi tiêu nhất'**
  String get rewindCategorySubtitle;

  /// No description provided for @rewindTopCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục hàng đầu'**
  String get rewindTopCategory;

  /// No description provided for @rewindStreakTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi hoạt động của bạn'**
  String get rewindStreakTitle;

  /// No description provided for @rewindStreakDays.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày liên tiếp'**
  String rewindStreakDays(int count);

  /// No description provided for @rewindStreakSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ghi chép chi tiêu đều đặn trong {count} ngày'**
  String rewindStreakSubtitle(int count);

  /// No description provided for @rewindStreakStarter.
  ///
  /// In vi, this message translates to:
  /// **'Mới bắt đầu thôi, cố gắng duy trì nhé!'**
  String get rewindStreakStarter;

  /// No description provided for @rewindStreakZero.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu chuỗi mới ngay hôm nay!'**
  String get rewindStreakZero;

  /// No description provided for @rewindTopExpensesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi đáng nhớ nhất'**
  String get rewindTopExpensesTitle;

  /// No description provided for @rewindTopExpensesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Những khoản chi lớn nhất trong giai đoạn này'**
  String get rewindTopExpensesSubtitle;

  /// No description provided for @rewindBiggestDayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngày chi tiêu nhiều nhất'**
  String get rewindBiggestDayTitle;

  /// No description provided for @rewindBiggestDaySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date} là ngày bạn chi tiêu nhiều nhất'**
  String rewindBiggestDaySubtitle(String date);

  /// No description provided for @rewindTransactionsOnDay.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch trong ngày này'**
  String rewindTransactionsOnDay(int count);

  /// No description provided for @rewindDailySpendingDistribution.
  ///
  /// In vi, this message translates to:
  /// **'Phân bổ chi tiêu hằng ngày'**
  String get rewindDailySpendingDistribution;

  /// No description provided for @rewindMomentsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoảnh khắc chi tiêu'**
  String get rewindMomentsTitle;

  /// No description provided for @rewindMomentsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiền bạc không chỉ là những con số. Đây là những khoảnh khắc gắn liền với chi tiêu của bạn.'**
  String get rewindMomentsSubtitle;

  /// No description provided for @rewindHighlightTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điểm nhấn của kỳ'**
  String get rewindHighlightTitle;

  /// No description provided for @rewindHighlightDominantTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục chiếm ưu thế'**
  String get rewindHighlightDominantTitle;

  /// No description provided for @rewindHighlightDominantDesc.
  ///
  /// In vi, this message translates to:
  /// **'{category} chiếm {percent}% tổng chi tiêu của bạn.'**
  String rewindHighlightDominantDesc(String category, String percent);

  /// No description provided for @rewindHighlightPeakDayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngày chi tiêu cao nhất'**
  String get rewindHighlightPeakDayTitle;

  /// No description provided for @rewindHighlightPeakDayDesc.
  ///
  /// In vi, this message translates to:
  /// **'Vào ngày {date}, bạn đã chi {percent}% tổng chi tiêu của kỳ này.'**
  String rewindHighlightPeakDayDesc(String date, String percent);

  /// No description provided for @rewindHighlightBiggestExpenseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi đáng nhớ'**
  String get rewindHighlightBiggestExpenseTitle;

  /// No description provided for @rewindHighlightBiggestExpenseDesc.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi lớn nhất của bạn là dành cho {category}.'**
  String rewindHighlightBiggestExpenseDesc(String category);

  /// No description provided for @rewindDaysThisWeek.
  ///
  /// In vi, this message translates to:
  /// **'Các ngày trong tuần'**
  String get rewindDaysThisWeek;

  /// No description provided for @rewindDaysRecentInPeriod.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày gần nhất trong kỳ'**
  String get rewindDaysRecentInPeriod;

  /// No description provided for @rewindComparisonTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ này so với kỳ trước'**
  String get rewindComparisonTitle;

  /// No description provided for @rewindComparisonSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thói quen của bạn đang thay đổi thế nào?'**
  String get rewindComparisonSubtitle;

  /// No description provided for @rewindSummaryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đây là hành trình của bạn ✨'**
  String get rewindSummaryTitle;

  /// No description provided for @rewindSummarySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Một chương đáng nhớ cùng Meme App'**
  String get rewindSummarySubtitle;

  /// No description provided for @rewindSaveCard.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ảnh'**
  String get rewindSaveCard;

  /// No description provided for @rewindShareCard.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get rewindShareCard;

  /// No description provided for @rewindSeeYouNext.
  ///
  /// In vi, this message translates to:
  /// **'Hẹn gặp lại bạn ở Rewind tiếp theo ❤️'**
  String get rewindSeeYouNext;

  /// No description provided for @rewindEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nào trong kỳ này'**
  String get rewindEmptyTitle;

  /// No description provided for @rewindEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hãy bắt đầu ghi chép chi tiêu để Meme Rewind có thể kể câu chuyện của bạn nhé!'**
  String get rewindEmptySubtitle;

  /// No description provided for @rewindSaveSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ảnh vào thư viện!'**
  String get rewindSaveSuccess;

  /// No description provided for @rewindShareText.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá hành trình chi tiêu của mình trên Meme App! ✨'**
  String get rewindShareText;

  /// No description provided for @rewindThisPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ này'**
  String get rewindThisPeriod;

  /// No description provided for @rewindPreviousPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ trước'**
  String get rewindPreviousPeriod;

  /// No description provided for @rewindTransactionCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} giao dịch}}'**
  String rewindTransactionCount(int count);

  /// No description provided for @rewindLargestExpense.
  ///
  /// In vi, this message translates to:
  /// **'Khoản chi lớn nhất'**
  String get rewindLargestExpense;

  /// No description provided for @rewindDays.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ngày}}'**
  String rewindDays(int count);

  /// No description provided for @rewindActiveDaysInPeriod.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} ngày hoạt động trong {period}}}'**
  String rewindActiveDaysInPeriod(int count, String period);

  /// No description provided for @groupBadge.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get groupBadge;

  /// No description provided for @groupChat.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm chat'**
  String get groupChat;

  /// No description provided for @groupMembersCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} thành viên}}'**
  String groupMembersCount(int count);

  /// No description provided for @groupChatOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mở nhóm chat'**
  String get groupChatOpen;

  /// No description provided for @systemGroupCreated.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã tạo nhóm \"{group}\"'**
  String systemGroupCreated(String name, String group);

  /// No description provided for @systemGroupMemberAdded.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã thêm {member} vào nhóm'**
  String systemGroupMemberAdded(String name, String member);

  /// No description provided for @systemGroupMemberLeft.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã rời khỏi nhóm'**
  String systemGroupMemberLeft(String name);

  /// No description provided for @systemGroupExpenseLogged.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã thêm chi tiêu {amount} cho \"{category}\"'**
  String systemGroupExpenseLogged(String name, String amount, String category);

  /// No description provided for @postToGroup.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm: {name}'**
  String postToGroup(String name);

  /// No description provided for @groupSpendingVisibleNote.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên trong nhóm có thể xem số tiền chi tiêu'**
  String get groupSpendingVisibleNote;

  /// No description provided for @groupAudience.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm: {name}'**
  String groupAudience(String name);

  /// No description provided for @shortDaysStreak.
  ///
  /// In vi, this message translates to:
  /// **'{count} Ngày'**
  String shortDaysStreak(int count);

  /// No description provided for @tabAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get tabAll;

  /// No description provided for @tabUnread.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đọc'**
  String get tabUnread;

  /// No description provided for @tabGroups.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get tabGroups;

  /// No description provided for @createStory.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tin'**
  String get createStory;

  /// No description provided for @whatAreYouThinking.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang nghĩ gì?'**
  String get whatAreYouThinking;

  /// No description provided for @activeMinutesAgo.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động {minutes} phút trước'**
  String activeMinutesAgo(int minutes);

  /// No description provided for @activeHoursAgo.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động {hours} giờ trước'**
  String activeHoursAgo(int hours);

  /// No description provided for @newMessagesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} tin nhắn mới'**
  String newMessagesCount(int count);

  /// No description provided for @shareNote.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ghi chú...'**
  String get shareNote;

  /// No description provided for @yourNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú của bạn'**
  String get yourNote;

  /// No description provided for @newNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú mới'**
  String get newNote;

  /// No description provided for @shareVerb.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get shareVerb;

  /// No description provided for @deleteNote.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ghi chú'**
  String get deleteNote;

  /// No description provided for @noteSharedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã chia sẻ ghi chú'**
  String get noteSharedSuccess;

  /// No description provided for @noteDeletedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa ghi chú'**
  String get noteDeletedSuccess;

  /// No description provided for @sendDirectMessage.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tin nhắn'**
  String get sendDirectMessage;

  /// No description provided for @youRepliedToTheirNote.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã phản hồi ghi chú của họ'**
  String get youRepliedToTheirNote;

  /// No description provided for @userRepliedToYourNote.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã phản hồi ghi chú của bạn'**
  String userRepliedToYourNote(String name);

  /// No description provided for @sharedWithAudience.
  ///
  /// In vi, this message translates to:
  /// **'Đã chia sẻ với {audience}'**
  String sharedWithAudience(String audience);

  /// No description provided for @audiencePublic.
  ///
  /// In vi, this message translates to:
  /// **'Công khai'**
  String get audiencePublic;

  /// No description provided for @audienceFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get audienceFriends;

  /// No description provided for @expiresIn24Hours.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn sau 24 giờ'**
  String get expiresIn24Hours;

  /// No description provided for @expiresInHours.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn sau {hours} giờ'**
  String expiresInHours(int hours);

  /// No description provided for @shareNewNote.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ghi chú mới'**
  String get shareNewNote;

  /// No description provided for @cameraThemeLockedNotice.
  ///
  /// In vi, this message translates to:
  /// **'Đạt chuỗi 3 ngày để mở khóa giao diện này!'**
  String get cameraThemeLockedNotice;

  /// No description provided for @cameraThemeStreakRequirement.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi 3 ngày'**
  String get cameraThemeStreakRequirement;

  /// No description provided for @cameraThemeStreakBanner.
  ///
  /// In vi, this message translates to:
  /// **'Đạt chuỗi {days} ngày để mở khóa toàn bộ giao diện máy ảnh (Hiện tại: {current} ngày)'**
  String cameraThemeStreakBanner(int days, int current);

  /// No description provided for @cameraThemeUnlockedBanner.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã mở khóa toàn bộ giao diện máy ảnh với chuỗi {current} ngày! 🔥'**
  String cameraThemeUnlockedBanner(int current);

  /// No description provided for @streakProgressFraction.
  ///
  /// In vi, this message translates to:
  /// **'{current}/{total} ngày'**
  String streakProgressFraction(int current, int total);

  /// No description provided for @draftPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp: '**
  String get draftPrefix;

  /// No description provided for @browseTransactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt giao dịch'**
  String get browseTransactionsTitle;

  /// No description provided for @browseTransactionsSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú, danh mục, tài khoản, số tiền...'**
  String get browseTransactionsSearchHint;

  /// No description provided for @timeFilterLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get timeFilterLabel;

  /// No description provided for @timeFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get timeFilterAll;

  /// No description provided for @timeFilterToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get timeFilterToday;

  /// No description provided for @timeFilterLast7Days.
  ///
  /// In vi, this message translates to:
  /// **'7 ngày qua'**
  String get timeFilterLast7Days;

  /// No description provided for @timeFilterThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get timeFilterThisMonth;

  /// No description provided for @timeFilterLastMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get timeFilterLastMonth;

  /// No description provided for @timeFilterThisYear.
  ///
  /// In vi, this message translates to:
  /// **'Năm nay'**
  String get timeFilterThisYear;

  /// No description provided for @typeFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get typeFilterAll;

  /// No description provided for @typeFilterExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu'**
  String get typeFilterExpense;

  /// No description provided for @typeFilterIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập'**
  String get typeFilterIncome;

  /// No description provided for @allCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get allCategories;

  /// No description provided for @noTransactionsFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giao dịch nào'**
  String get noTransactionsFound;

  /// No description provided for @groupFinancialOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tài chính & Quỹ nhóm'**
  String get groupFinancialOverview;

  /// No description provided for @groupFundBalanceAndProgress.
  ///
  /// In vi, this message translates to:
  /// **'Số dư quỹ thực tế & tiến độ'**
  String get groupFundBalanceAndProgress;

  /// No description provided for @groupFundRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Số dư quỹ còn lại'**
  String get groupFundRemaining;

  /// No description provided for @groupFundSurplus.
  ///
  /// In vi, this message translates to:
  /// **'Còn dư'**
  String get groupFundSurplus;

  /// No description provided for @groupFundDeficit.
  ///
  /// In vi, this message translates to:
  /// **'Thâm hụt'**
  String get groupFundDeficit;

  /// No description provided for @groupTotalContributed.
  ///
  /// In vi, this message translates to:
  /// **'Đã góp'**
  String get groupTotalContributed;

  /// No description provided for @groupTotalSpent.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi'**
  String get groupTotalSpent;

  /// No description provided for @groupGoal.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get groupGoal;

  /// No description provided for @groupGoalProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ mục tiêu quỹ'**
  String get groupGoalProgress;

  /// No description provided for @groupExpenseHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử chi tiêu nhóm'**
  String get groupExpenseHistory;

  /// No description provided for @groupNoExpensesYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản chi tiêu nào'**
  String get groupNoExpensesYet;

  /// No description provided for @groupNoExpensesDesc.
  ///
  /// In vi, this message translates to:
  /// **'Các chi tiêu chia sẻ vào nhóm sẽ được hiển thị tại đây'**
  String get groupNoExpensesDesc;

  /// No description provided for @groupExpenseExceedsBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền chi tiêu vượt quá số dư quỹ nhóm hiện có ({balance})'**
  String groupExpenseExceedsBalance(String balance);

  /// No description provided for @groupFundDeposit.
  ///
  /// In vi, this message translates to:
  /// **'Nạp quỹ nhóm'**
  String get groupFundDeposit;

  /// No description provided for @groupDepositSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã nạp tiền vào quỹ nhóm'**
  String get groupDepositSuccess;

  /// No description provided for @groupBalanceShort.
  ///
  /// In vi, this message translates to:
  /// **'Dư: {amount}'**
  String groupBalanceShort(String amount);

  /// No description provided for @groupSpentShort.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi: {amount}'**
  String groupSpentShort(String amount);

  /// No description provided for @member.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get member;

  /// No description provided for @groupFundCategory.
  ///
  /// In vi, this message translates to:
  /// **'Quỹ nhóm'**
  String get groupFundCategory;

  /// No description provided for @momentDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết khoảnh khắc'**
  String get momentDetails;

  /// No description provided for @notFriendsGroupPostNotice.
  ///
  /// In vi, this message translates to:
  /// **'Bạn và người đăng bài chưa là bạn bè nên không thể xem bài viết trên Bảng tin. Dưới đây là chi tiết khoảnh khắc được chia sẻ trong nhóm:'**
  String get notFriendsGroupPostNotice;

  /// No description provided for @groupExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiêu nhóm'**
  String get groupExpense;

  /// No description provided for @spentReason.
  ///
  /// In vi, this message translates to:
  /// **'Mục đích: {reason}'**
  String spentReason(String reason);

  /// No description provided for @spentBy.
  ///
  /// In vi, this message translates to:
  /// **'Người chi: {name}'**
  String spentBy(String name);

  /// No description provided for @seeAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get seeAll;

  /// No description provided for @groupStatsContributionAndExpense.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê Góp & Chi'**
  String get groupStatsContributionAndExpense;

  /// No description provided for @groupStatsFundFlowSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tình hình luân chuyển quỹ nhóm'**
  String get groupStatsFundFlowSubtitle;

  /// No description provided for @groupContributionCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} lượt nạp quỹ'**
  String groupContributionCount(int count);

  /// No description provided for @groupExpenseCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} lần chi tiêu'**
  String groupExpenseCount(int count);

  /// No description provided for @groupFundUsageRatio.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ sử dụng quỹ'**
  String get groupFundUsageRatio;

  /// No description provided for @groupSurplusWithAmount.
  ///
  /// In vi, this message translates to:
  /// **'Còn dư {amount}'**
  String groupSurplusWithAmount(String amount);

  /// No description provided for @groupDeficitWithAmount.
  ///
  /// In vi, this message translates to:
  /// **'Thâm hụt {amount}'**
  String groupDeficitWithAmount(String amount);

  /// No description provided for @groupSpentPercent.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi {percent}%'**
  String groupSpentPercent(String percent);

  /// No description provided for @groupRemainingPercent.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại {percent}%'**
  String groupRemainingPercent(String percent);

  /// No description provided for @groupTopSpendingCategories.
  ///
  /// In vi, this message translates to:
  /// **'Top danh mục chi tiêu quỹ'**
  String get groupTopSpendingCategories;

  /// No description provided for @groupActivitiesAndTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động & Giao dịch quỹ'**
  String get groupActivitiesAndTransactions;

  /// No description provided for @groupFilterAllWithCount.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả ({count})'**
  String groupFilterAllWithCount(int count);

  /// No description provided for @groupFilterContributedWithCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã góp ({count})'**
  String groupFilterContributedWithCount(int count);

  /// No description provided for @groupFilterSpentWithCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi ({count})'**
  String groupFilterSpentWithCount(int count);

  /// No description provided for @groupNoContributionsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản góp nào'**
  String get groupNoContributionsYet;

  /// No description provided for @groupNoFundTransactionsYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch quỹ nào'**
  String get groupNoFundTransactionsYet;

  /// No description provided for @groupNoContributionsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Các khoản nạp vào quỹ nhóm sẽ hiển thị ở đây'**
  String get groupNoContributionsDesc;

  /// No description provided for @groupNoFundTransactionsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Góp quỹ và chi tiêu nhóm sẽ được thống kê tại đây'**
  String get groupNoFundTransactionsDesc;

  /// No description provided for @groupMemberSurplus.
  ///
  /// In vi, this message translates to:
  /// **'Dư: +{amount}'**
  String groupMemberSurplus(String amount);

  /// No description provided for @groupMemberDeficit.
  ///
  /// In vi, this message translates to:
  /// **'Chi vượt: -{amount}'**
  String groupMemberDeficit(String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
