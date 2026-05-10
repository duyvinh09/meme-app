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
  /// **'Yêu cầu kết bạn đã được gửi trước đó'**
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
