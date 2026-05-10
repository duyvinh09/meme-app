// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get appearance => 'Giao diện';

  @override
  String get light => 'Sáng';

  @override
  String get dark => 'Tối';

  @override
  String get system => 'Theo hệ thống';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get vnd => 'VNĐ';

  @override
  String get usd => 'USD';

  @override
  String exchangeRateUpdated(String rate) {
    return 'Đã cập nhật tỷ giá: $rate';
  }

  @override
  String get updating => 'Đang cập nhật';

  @override
  String get update => 'Cập nhật';

  @override
  String get profile => 'Cá nhân';

  @override
  String get user => 'Người dùng';

  @override
  String joined(String date) {
    return 'Tham gia: $date';
  }

  @override
  String friends(int count) {
    return '$count Bạn bè';
  }

  @override
  String get groups => 'Nhóm';

  @override
  String get changeEmail => 'Đổi email đăng nhập';

  @override
  String get feedback => 'Góp ý';

  @override
  String get deleteAccount => 'Xoá tài khoản';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get deleteAccountQuestion => 'Xoá tài khoản?';

  @override
  String get deleteAccountWarning =>
      'Hành động này sẽ xoá tài khoản của bạn khỏi Meme. Bạn sẽ không thể đăng nhập lại bằng tài khoản này.';

  @override
  String get deleteAccountNote =>
      'Nếu bạn chỉ muốn rời app tạm thời, hãy chọn Đăng xuất thay vì xoá tài khoản.';

  @override
  String get enterCurrentPassword => 'Nhập mật khẩu hiện tại';

  @override
  String get cancel => 'Huỷ';

  @override
  String get pleaseEnterPassword => 'Vui lòng nhập mật khẩu hiện tại';

  @override
  String get accountNotFound => 'Không tìm thấy tài khoản hiện tại';

  @override
  String get deleteAccountError =>
      'Không thể xoá tài khoản. Vui lòng kiểm tra mật khẩu hoặc đăng nhập lại.';

  @override
  String get goodMorning => 'Chào buổi sáng';

  @override
  String get goodAfternoon => 'Chào buổi chiều';

  @override
  String get goodEvening => 'Chào buổi tối';

  @override
  String get noTransactionsToday => 'Hôm nay bạn chưa thêm giao dịch nào.';

  @override
  String receivedToday(String amount) {
    return 'Đã nhận $amount hôm nay';
  }

  @override
  String spentToday(String amount) {
    return 'Đã chi $amount hôm nay';
  }

  @override
  String get you => 'Bạn';

  @override
  String get recentTransactions => 'Giao dịch gần đây';

  @override
  String transactionCount(int count) {
    return '$count giao dịch';
  }

  @override
  String get noTransactions => 'Chưa có giao dịch nào';

  @override
  String get addFirstTransaction =>
      'Hãy thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu';

  @override
  String get login => 'Đăng nhập';

  @override
  String get register => 'Đăng ký';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get dontHaveAccount => 'Chưa có tài khoản? ';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản? ';

  @override
  String get welcomeBack => 'Chào mừng trở lại 👋';

  @override
  String get loginSubtitle =>
      'Đăng nhập để tiếp tục lưu ảnh, ghi chú và chi tiêu của bạn.';

  @override
  String get appSlogan =>
      'Lưu khoảnh khắc chi tiêu theo cách vui hơn, thật hơn.';

  @override
  String get pleaseEnterPasswordLogin => 'Vui lòng nhập mật khẩu';

  @override
  String get pleaseEnterName => 'Vui lòng nhập tên hiển thị';

  @override
  String get createNewAccount => 'Tạo tài khoản mới ✨';

  @override
  String get registerSlogan =>
      'Bắt đầu lưu khoảnh khắc chi tiêu theo cách vui hơn, thật hơn.';

  @override
  String get joinMeme => 'Tham gia Meme';

  @override
  String get registerSubtitle =>
      'Tạo hồ sơ để quản lý chi tiêu, lưu ảnh và kết nối với bạn bè.';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Dùng 3-20 ký tự: chữ thường, số, dấu . hoặc _';

  @override
  String get passwordHint => 'Mật khẩu tối thiểu 6 ký tự';

  @override
  String get currentBalance => 'Số dư hiện tại';

  @override
  String get totalIncome => 'Tổng thu';

  @override
  String get totalExpense => 'Tổng chi';

  @override
  String get streak => 'Chuỗi duy trì';

  @override
  String daysStreak(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String get streakLevel1 => 'Cực đỉnh';

  @override
  String get streakLevel2 => 'Ổn áp';

  @override
  String get streakLevel3 => 'Đều đặn';

  @override
  String get streakLevel4 => 'Đang lên mood';

  @override
  String get streakLevel5 => 'Bắt đầu thôi';

  @override
  String get personalBudget => 'Ngân sách cá nhân';

  @override
  String get budgetTitle => 'Ngân sách cá nhân';

  @override
  String get budgetSubtitle => 'Tạo chủ đề và đặt mục tiêu tiền';

  @override
  String get budgetNote =>
      'Các danh mục mặc định như Ăn uống, Mua sắm, Đi lại sẽ không có giới hạn. Ngân sách ở đây là chủ đề cá nhân do bạn tự tạo.';

  @override
  String get budgetOverview => 'Tổng quan ngân sách';

  @override
  String monthYear(int month, int year) {
    return 'Tháng $month $year';
  }

  @override
  String get overLimit => 'Đã vượt mục tiêu';

  @override
  String remainingAmount(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String get budgetGoal => 'Mục tiêu';

  @override
  String get usedAmount => 'Đã dùng';

  @override
  String get deleteBudgetQuestion => 'Xoá ngân sách?';

  @override
  String deleteBudgetWarning(String name) {
    return 'Bạn có chắc muốn xoá chủ đề \"$name\" không? Các giao dịch đã tạo trước đó vẫn giữ nguyên, chỉ xoá mục tiêu ngân sách này.';
  }

  @override
  String get delete => 'Xoá';

  @override
  String budgetDeleted(String name) {
    return 'Đã xoá \"$name\"';
  }

  @override
  String get noBudgetThemes => 'Chưa có chủ đề ngân sách';

  @override
  String get noBudgetThemesSubtitle =>
      'Tạo một chủ đề như Picnic, Mua iPad hoặc Đi du lịch để đặt mục tiêu tiền riêng.';

  @override
  String get personalThemes => 'Chủ đề cá nhân';

  @override
  String get trackSpentVsGoal => 'Theo dõi số tiền đã dùng so với mục tiêu';

  @override
  String get monthly => 'Hằng tháng';

  @override
  String get daily => 'Hằng ngày';

  @override
  String get weekly => 'Hằng tuần';

  @override
  String get biweekly => '2 tuần/lần';

  @override
  String get yearly => 'Hằng năm';

  @override
  String get custom => 'Tuỳ chỉnh';

  @override
  String get total => 'Tổng';

  @override
  String get category => 'Danh mục';

  @override
  String get allSpending => 'Tất cả chi tiêu';

  @override
  String get syncFromCategory => 'Đồng bộ từ danh mục';

  @override
  String get budgetNameLabel => 'Tên ngân sách';

  @override
  String get budgetNameHint => 'VD: Chi tiêu hằng ngày';

  @override
  String get budgetAmountLabel => 'Số tiền ngân sách';

  @override
  String get period => 'Chu kỳ';

  @override
  String get budgetType => 'Loại ngân sách';

  @override
  String get color => 'Màu';

  @override
  String get icon => 'Biểu tượng';

  @override
  String get createBudget => 'Tạo ngân sách';

  @override
  String get addBudget => 'Thêm ngân sách';

  @override
  String get editBudget => 'Chỉnh sửa ngân sách';

  @override
  String get cancelLabel => 'Huỷ';

  @override
  String get pleaseEnterBudgetName => 'Vui lòng nhập tên ngân sách';

  @override
  String get pleaseEnterBudgetAmount => 'Vui lòng nhập số tiền ngân sách';

  @override
  String get budgetAmountPositive => 'Số tiền ngân sách phải lớn hơn 0';

  @override
  String cannotCreateBudget(String error) {
    return 'Không thể tạo ngân sách: $error';
  }

  @override
  String get budgetUpdated => 'Đã cập nhật ngân sách';

  @override
  String get budgetUnchanged => 'Không có thay đổi để cập nhật';

  @override
  String cannotUpdateBudget(String error) {
    return 'Không thể cập nhật ngân sách: $error';
  }

  @override
  String cannotDeleteBudget(String error) {
    return 'Không thể xoá ngân sách: $error';
  }

  @override
  String get budgetAnalysis => 'Phân tích ngân sách';

  @override
  String get deleteBudget => 'Xoá ngân sách';

  @override
  String loadBudgetError(String error) {
    return 'Lỗi tải ngân sách:\n$error';
  }

  @override
  String get budgetHistory => 'Lịch sử ngân sách';

  @override
  String get average => 'Trung bình';

  @override
  String get overBudget => 'Vượt ngân sách';

  @override
  String get bestPeriod => 'Kỳ tốt nhất';

  @override
  String get worstPeriod => 'Kỳ tệ nhất';

  @override
  String get periodCount => 'Số kỳ';

  @override
  String get compareOverPeriods => 'So sánh qua từng kỳ';

  @override
  String get budgetLimitLegend => 'Giới hạn ngân sách';

  @override
  String get withinBudgetLegend => 'Trong ngân sách';

  @override
  String get overBudgetLegend => 'Vượt ngân sách!';

  @override
  String get periodDetail => 'Chi tiết từng kỳ';

  @override
  String get currentPeriod => 'Hiện tại';

  @override
  String remainingLabel(String amount) {
    return 'Còn lại: $amount';
  }

  @override
  String budgetLimitLabel(String amount) {
    return 'Ngân sách: $amount';
  }

  @override
  String get overBudgetWarning => 'Vượt ngân sách!';

  @override
  String get budgetNamePreview => 'Tên ngân sách';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get forgotPasswordInstruction =>
      'Nhập email đã đăng ký để nhận liên kết đặt lại mật khẩu.';

  @override
  String get recoveryPassword => 'Khôi phục mật khẩu';

  @override
  String get recoveryPasswordSubtitle =>
      'Hệ thống sẽ gửi cho bạn một email để đặt lại mật khẩu.';

  @override
  String get enterEmail => 'Nhập email';

  @override
  String get recoveryEmailSent => 'Đã gửi email khôi phục mật khẩu';

  @override
  String get couldNotSendRecoveryEmail => 'Không thể gửi email khôi phục';

  @override
  String get sendRecoveryEmail => 'Gửi email khôi phục';

  @override
  String get backToLogin => 'Quay lại đăng nhập';

  @override
  String get editProfile => 'Sửa hồ sơ';

  @override
  String get name => 'Tên';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get profileUpdated => 'Cập nhật hồ sơ thành công';

  @override
  String get profileUpdateFailed => 'Cập nhật hồ sơ thất bại';

  @override
  String get changeEmailTitle => 'Đổi email đăng nhập';

  @override
  String get changeEmailSubtitle =>
      'Cập nhật email dùng để đăng nhập tài khoản của bạn';

  @override
  String get currentEmail => 'Email hiện tại';

  @override
  String get unknown => 'Không rõ';

  @override
  String get newEmailInfo => 'Thông tin email mới';

  @override
  String get newEmail => 'Email mới';

  @override
  String get enterNewEmail => 'Nhập email mới của bạn';

  @override
  String get enterPasswordToConfirm => 'Nhập mật khẩu để xác nhận';

  @override
  String get changeEmailNotice =>
      'Để bảo vệ tài khoản, bạn cần nhập lại mật khẩu hiện tại trước khi đổi email đăng nhập.';

  @override
  String get updateEmail => 'Cập nhật email';

  @override
  String get invalidEmail => 'Email mới không hợp lệ';

  @override
  String get emailSameAsCurrent => 'Email mới đang trùng với email hiện tại';

  @override
  String get emailChangedSuccessfully => 'Đã đổi email đăng nhập thành công';

  @override
  String get feedbackTitle => 'Góp ý';

  @override
  String get sendFeedback => 'Gửi phản hồi';

  @override
  String get feedbackSubtitle =>
      'Chia sẻ ý kiến, đề xuất hoặc báo lỗi để Meme ngày càng hoàn thiện hơn.';

  @override
  String get yourEmail => 'Email của bạn';

  @override
  String get emailPrefilledNote =>
      'Email này được điền sẵn từ tài khoản của bạn.';

  @override
  String get yourFeedback => 'Phản hồi của bạn *';

  @override
  String get feedbackHint =>
      'Chia sẻ ý kiến, báo lỗi hoặc đề xuất tính năng mới...';

  @override
  String get sending => 'Đang gửi...';

  @override
  String get invalidEmailGeneric => 'Email không hợp lệ';

  @override
  String get pleaseEnterFeedback => 'Vui lòng nhập nội dung góp ý';

  @override
  String feedbackTooLong(int count) {
    return 'Nội dung góp ý không được quá $count ký tự';
  }

  @override
  String get feedbackEmailSubject => 'Góp ý từ ứng dụng Meme';

  @override
  String feedbackEmailBody(
      String name, String username, String email, String message) {
    return 'Xin chào Admin,\n\nBạn vừa nhận được một góp ý mới từ ứng dụng Meme.\n\nThông tin người gửi:\n- Tên: $name\n- Username: $username\n- Email: $email\n\nNội dung góp ý:\n$message\n\n---\nEmail này được tạo tự động từ màn Góp ý của app Meme.';
  }

  @override
  String get feedbackSentEmail => 'Đã mở email để gửi góp ý cho admin';

  @override
  String get feedbackSaved =>
      'Đã lưu góp ý. Thiết bị chưa mở được ứng dụng email.';

  @override
  String feedbackError(String error) {
    return 'Không thể gửi góp ý: $error';
  }

  @override
  String get friendsTitle => 'Bạn bè';

  @override
  String get friendsSearchHint => 'Tìm kiếm bạn bè...';

  @override
  String get noFriends => 'Chưa có bạn bè';

  @override
  String get noFriendsSubtitle =>
      'Thêm bạn bè để chia sẻ chi tiêu và tham gia nhóm.';

  @override
  String get addFriend => 'Thêm bạn bè';

  @override
  String get deleteFriendQuestion => 'Xoá bạn bè?';

  @override
  String deleteFriendWarning(String name) {
    return 'Bạn có chắc muốn xoá $name khỏi danh sách bạn bè?';
  }

  @override
  String get deleteFriendGroupsNote =>
      'Người này vẫn sẽ ở trong các nhóm chung. Nếu muốn xoá khỏi nhóm, bạn cần vào nhóm để chỉnh sửa thành viên hoặc rời nhóm.';

  @override
  String friendDeleted(String name) {
    return 'Đã xoá $name khỏi danh sách bạn bè';
  }

  @override
  String get addFriendTitle => 'Thêm bạn bè';

  @override
  String get addFriendSearchHint => 'Nhập username hoặc email...';

  @override
  String get noUsersFound => 'Không tìm thấy người dùng';

  @override
  String get sendFriendRequest => 'Thêm';

  @override
  String requestSent(String name) {
    return 'Đã gửi yêu cầu kết bạn tới $name';
  }

  @override
  String alreadyFriends(String name) {
    return 'Bạn và $name đã là bạn bè';
  }

  @override
  String get requestPending => 'Yêu cầu kết bạn đã được gửi trước đó';

  @override
  String get friendRequests => 'Lời mời kết bạn';

  @override
  String get friendRequestsReceivedTab => 'Đã nhận';

  @override
  String get friendRequestsSentTab => 'Đã gửi';

  @override
  String get noFriendRequests => 'Không có yêu cầu nào';

  @override
  String get noSentFriendRequests => 'Chưa gửi lời mời nào';

  @override
  String get noFriendRequestsReceivedSubtitle =>
      'Khi người dùng Meme khác gửi yêu cầu kết bạn cho bạn, chúng sẽ xuất hiện ở đây';

  @override
  String get noFriendRequestsSentSubtitle =>
      'Những lời mời kết bạn bạn đã gửi sẽ hiển thị ở đây';

  @override
  String sentRequestToUsername(String username) {
    return 'Yêu cầu gửi đến @$username';
  }

  @override
  String get requestPendingStatus => 'Chờ duyệt';

  @override
  String get friendBadgeInvitationSent => 'Đã gửi lời mời';

  @override
  String get friendBadgeAlreadyFriendsLabel => 'Bạn bè';

  @override
  String get friendRequestCancelled => 'Đã huỷ lời mời';

  @override
  String get accept => 'Chấp nhận';

  @override
  String get decline => 'Từ chối';

  @override
  String requestAccepted(String name) {
    return 'Đã chấp nhận lời mời kết bạn từ $name';
  }

  @override
  String requestDeclined(String name) {
    return 'Đã từ chối lời mời kết bạn từ $name';
  }

  @override
  String get groupsTitle => 'Nhóm';

  @override
  String get noGroups => 'Chưa có nhóm';

  @override
  String get noGroupsSubtitle =>
      'Tạo nhóm để quản lý chi tiêu chung với bạn bè.';

  @override
  String get createGroup => 'Tạo nhóm';

  @override
  String get createVerb => 'Tạo';

  @override
  String membersCount(int count) {
    return '$count thành viên';
  }

  @override
  String get deleteGroupQuestion => 'Xoá nhóm?';

  @override
  String deleteGroupWarning(String name) {
    return 'Bạn có chắc muốn xoá nhóm \"$name\"?';
  }

  @override
  String get contribution => 'Đóng góp';

  @override
  String get goal => 'Mục tiêu';

  @override
  String get noGroupTransactions => 'Chưa có giao dịch nhóm';

  @override
  String get addGroupTransaction => 'Thêm giao dịch nhóm';

  @override
  String get editGroup => 'Sửa nhóm';

  @override
  String get leaveGroup => 'Rời';

  @override
  String get leaveGroupQuestion => 'Rời nhóm?';

  @override
  String leaveGroupWarning(String name) {
    return 'Bạn có chắc muốn rời khỏi nhóm \"$name\"?';
  }

  @override
  String get groupName => 'Tên nhóm';

  @override
  String get groupNameHint => 'Nhập tên nhóm';

  @override
  String get description => 'Mô tả';

  @override
  String get descriptionHint => 'Nhập mô tả nhóm (tuỳ chọn)';

  @override
  String get contributionGoal => 'Mục tiêu đóng góp';

  @override
  String get contributionGoalHint => 'Đặt số tiền mục tiêu (tuỳ chọn)';

  @override
  String get members => 'Thành viên';

  @override
  String get addMembers => 'Thêm thành viên';

  @override
  String selectedCount(int count) {
    return '$count đã chọn';
  }

  @override
  String get groupSaved => 'Đã lưu thông tin nhóm';

  @override
  String get groupCreated => 'Đã tạo nhóm thành công';

  @override
  String get currentUserNotFound => 'Không tìm thấy người dùng hiện tại';

  @override
  String get groupNoMembersToContribute =>
      'Nhóm chưa có thành viên để đóng góp';

  @override
  String get youAreNotMember => 'Bạn không còn thuộc nhóm này';

  @override
  String get addContribution => 'Thêm tiền đóng góp';

  @override
  String get selectMember => 'Chọn thành viên';

  @override
  String get youAreContributingFor => 'Bạn đang đóng góp cho';

  @override
  String get amount => 'Số tiền';

  @override
  String get enterValidAmount => 'Nhập số tiền hợp lệ';

  @override
  String get canOnlyAddForSelf => 'Bạn chỉ có thể thêm tiền cho chính mình';

  @override
  String get contributionAdded => 'Đã thêm tiền đóng góp';

  @override
  String cannotAddContribution(String error) {
    return 'Không thể thêm đóng góp: $error';
  }

  @override
  String get saving => 'Đang lưu...';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get groupNotFound => 'Không tìm thấy nhóm';

  @override
  String get group => 'Nhóm';

  @override
  String get groupDetails => 'Chi tiết nhóm';

  @override
  String get groupOwner => 'Chủ nhóm';

  @override
  String get groupColor => 'Màu nhóm';

  @override
  String ofAmount(String amount) {
    return 'trên $amount';
  }

  @override
  String reachedPercentage(int percentage) {
    return 'Đã đạt $percentage%';
  }

  @override
  String get contributingMembers => 'Thành viên đóng góp';

  @override
  String get noMembersYet => 'Chưa có thành viên nào';

  @override
  String paidAmount(String amount) {
    return 'Đã đóng $amount';
  }

  @override
  String get groupOptions => 'Tuỳ chọn nhóm';

  @override
  String get editGroupSubtitle => 'Đổi tên, màu, mục tiêu hoặc thành viên';

  @override
  String get deleteGroup => 'Xoá';

  @override
  String get deleteGroupSubtitle => 'Xoá nhóm này cho tất cả thành viên';

  @override
  String get leaveGroupSubtitle => 'Rời khỏi nhóm này';

  @override
  String get deleteGroupConfirmation =>
      'Bạn có chắc muốn xoá nhóm này không? Hành động này sẽ xoá nhóm khỏi tất cả thành viên.';

  @override
  String get leaveGroupConfirmation =>
      'Bạn có chắc muốn rời khỏi nhóm này không?';

  @override
  String get groupDeleted => 'Đã xoá nhóm';

  @override
  String get youLeftGroup => 'Bạn đã rời nhóm';

  @override
  String cannotDeleteGroup(String error) {
    return 'Không thể xoá nhóm: $error';
  }

  @override
  String cannotLeaveGroup(String error) {
    return 'Không thể rời nhóm: $error';
  }

  @override
  String get ownerMustBeInGroup => 'Chủ nhóm luôn phải ở trong nhóm';

  @override
  String get onlyOwnerCanEditGroup => 'Chỉ chủ nhóm mới có thể chỉnh sửa nhóm';

  @override
  String get groupInfoNotFound => 'Không tìm thấy thông tin nhóm';

  @override
  String get pleaseEnterGroupName => 'Vui lòng nhập tên nhóm';

  @override
  String get groupNameTooLong => 'Tên nhóm tối đa 50 ký tự';

  @override
  String get pleaseEnterGoalAmount => 'Vui lòng nhập số tiền mục tiêu';

  @override
  String get groupUpdated => 'Đã cập nhật nhóm';

  @override
  String groupUpdateFailedWithError(String error) {
    return 'Cập nhật nhóm thất bại: $error';
  }

  @override
  String get noPermissionToEditGroup => 'Bạn không có quyền chỉnh sửa nhóm này';

  @override
  String get onlyOwnerCanEditNote =>
      'Chỉ chủ nhóm mới có thể đổi thông tin, mời thành viên hoặc xoá thành viên khỏi nhóm.';

  @override
  String get goalAmount => 'Số tiền mục tiêu';

  @override
  String goalAmountHintExample(String example) {
    return 'Số tiền mục tiêu, ví dụ $example';
  }

  @override
  String get groupMembers => 'Thành viên nhóm';

  @override
  String get groupMembersNote =>
      'Chọn bạn bè để mời vào nhóm. Thành viên cũ vẫn được giữ lại dù không còn là bạn bè.';

  @override
  String get noMembersOrFriends => 'Chưa có thành viên hoặc bạn bè để hiển thị';

  @override
  String get currentMember => 'Thành viên hiện tại';

  @override
  String get notFriendsAnymore => 'Không còn là bạn bè';

  @override
  String get groupMemberManagementNote =>
      'Khi thêm thành viên mới, nhóm sẽ xuất hiện trong tài khoản của họ. Khi bỏ chọn thành viên, nhóm sẽ bị xoá khỏi danh sách nhóm của người đó.';

  @override
  String get gettingLocation => 'Đang lấy vị trí...';

  @override
  String get currentLocationSaved => 'Đã lưu vị trí hiện tại';

  @override
  String get noLocation => 'Không có vị trí';

  @override
  String get skipPhoto => 'Bỏ qua ảnh';

  @override
  String get food => 'Ăn uống';

  @override
  String get shopping => 'Mua sắm';

  @override
  String get transport => 'Di chuyển';

  @override
  String get education => 'Giáo dục';

  @override
  String get other => 'Khác';

  @override
  String get salary => 'Lương';

  @override
  String get gift => 'Quà tặng';

  @override
  String get entertainment => 'Giải trí';

  @override
  String get private => 'Riêng tư';

  @override
  String get everyone => 'Mọi người';

  @override
  String get maxAmountDigits => 'Tối đa 10 chữ số';

  @override
  String get addDetails => 'Thêm chi tiết';

  @override
  String get overBudgetLimitTitle => 'Vượt mục tiêu ngân sách';

  @override
  String overBudgetLimitWarning(String name, String limit, String over) {
    return 'Giao dịch này sẽ khiến chủ đề \"$name\" vượt mục tiêu $limit khoảng $over. Bạn vẫn muốn lưu chứ?';
  }

  @override
  String get saveAnyway => 'Vẫn lưu';

  @override
  String shareType(String type) {
    return 'Loại: $type';
  }

  @override
  String shareCategory(String category) {
    return 'Danh mục: $category';
  }

  @override
  String shareAmount(String amount) {
    return 'Số tiền: $amount';
  }

  @override
  String shareDetails(String details) {
    return 'Chi tiết: $details';
  }

  @override
  String sharePrivacy(String privacy) {
    return 'Quyền riêng tư: $privacy';
  }

  @override
  String get cannotShareNow => 'Không thể chia sẻ lúc này';

  @override
  String get amountLimitExceeded => 'Số tiền vượt quá giới hạn 10 chữ số';

  @override
  String savedWithOverLimit(String category) {
    return 'Đã lưu, nhưng chủ đề \"$category\" đã vượt mục tiêu.';
  }

  @override
  String get transactionSavedSuccessfully => 'Lưu giao dịch thành công';

  @override
  String get transactionSaveFailed => 'Lưu giao dịch thất bại';

  @override
  String get limitLabel => 'Mục tiêu';

  @override
  String get retake => 'Chụp lại';

  @override
  String get share => 'Chia sẻ';

  @override
  String get statsTitle => 'Thống kê';

  @override
  String get income => 'Thu nhập';

  @override
  String get expense => 'Chi tiêu';

  @override
  String get month => 'Tháng';

  @override
  String get year => 'Năm';

  @override
  String get backToThisMonth => 'Về tháng này';

  @override
  String get backToThisYear => 'Về năm này';

  @override
  String get selectMonthStats => 'Chọn tháng thống kê';

  @override
  String get current => 'Hiện tại';

  @override
  String monthLabel(int month) {
    return 'Tháng $month';
  }

  @override
  String shortMonth(int month) {
    return 'thg $month';
  }

  @override
  String get selectYearStats => 'Chọn năm thống kê';

  @override
  String get olderYears => 'Năm cũ hơn';

  @override
  String get newerYears => 'Năm mới hơn';

  @override
  String get totalExpenseLabel => 'Tổng chi tiêu';

  @override
  String get totalIncomeLabel => 'Tổng thu nhập';

  @override
  String get compareToPreviousMonth => 'so với tháng trước';

  @override
  String get compareToPreviousYear => 'so với năm trước';

  @override
  String get expenseByCategoryMonth => 'Chi tiêu theo danh mục tháng này';

  @override
  String get incomeByCategoryMonth => 'Thu nhập theo danh mục tháng này';

  @override
  String get expenseByCategoryYear => 'Chi tiêu theo danh mục năm này';

  @override
  String get incomeByCategoryYear => 'Thu nhập theo danh mục năm này';

  @override
  String get noExpenseDataMonth => 'Không có dữ liệu chi tiêu tháng này';

  @override
  String get noIncomeDataMonth => 'Không có dữ liệu thu nhập tháng này';

  @override
  String get noExpenseDataYear => 'Không có dữ liệu chi tiêu năm này';

  @override
  String get noIncomeDataYear => 'Không có dữ liệu thu nhập năm này';

  @override
  String get expenseNoChange =>
      'Chi tiêu của bạn không thay đổi so với kỳ trước.';

  @override
  String get incomeNoChange =>
      'Thu nhập của bạn không thay đổi so với kỳ trước.';

  @override
  String expenseMore(String percent) {
    return 'Bạn đã chi nhiều hơn $percent% so với kỳ trước.';
  }

  @override
  String incomeMore(String percent) {
    return 'Bạn đã nhận nhiều hơn $percent% so với kỳ trước.';
  }

  @override
  String expenseLess(String percent) {
    return 'Bạn đã chi ít hơn $percent% so với kỳ trước.';
  }

  @override
  String incomeLess(String percent) {
    return 'Bạn đã nhận ít hơn $percent% so với kỳ trước.';
  }

  @override
  String previousPeriodAmount(String amount) {
    return 'Kỳ trước: $amount';
  }

  @override
  String get categories => 'Danh mục';

  @override
  String get map => 'Bản đồ';

  @override
  String get transactionMap => 'Bản đồ giao dịch';

  @override
  String get mapControl => 'Điều khiển bản đồ';

  @override
  String get controlling => 'Đang điều khiển';

  @override
  String get tapToControlMap => 'Chạm để điều khiển bản đồ';

  @override
  String get tapControllingToDisable =>
      'Chạm \"Đang điều khiển\" để tắt tương tác bản đồ.';

  @override
  String get recentTransactionsOverview => 'Tổng quan các giao dịch gần đây.';

  @override
  String get mapEmptyTitle => 'Chưa có dữ liệu bản đồ';

  @override
  String get mapEmptySubtitle =>
      'Các giao dịch mới sau khi bạn cấp quyền vị trí sẽ được hiển thị trên bản đồ.';

  @override
  String mapSummary(int transactions, int locations) {
    return '$transactions giao dịch tại $locations vị trí';
  }

  @override
  String mapTransactionsHere(int count) {
    return '$count giao dịch ở đây';
  }

  @override
  String get expenseDetails => 'Chi tiết chi tiêu';

  @override
  String get incomeDetails => 'Chi tiết thu nhập';

  @override
  String percentOfTotalExpense(int percent) {
    return '$percent% tổng chi tiêu';
  }

  @override
  String percentOfTotalIncome(int percent) {
    return '$percent% tổng thu nhập';
  }

  @override
  String get noUser => 'Không có người dùng';

  @override
  String loadFeedError(String error) {
    return 'Lỗi tải feed:\n$error';
  }

  @override
  String get emptyFeedFriends => 'Feed bạn bè đang trống';

  @override
  String get emptyFeedFriendsSubtitle =>
      'Khi bạn hoặc bạn bè chia sẻ giao dịch ở chế độ \"Bạn bè\", bài đăng sẽ xuất hiện ở đây.';

  @override
  String get noPostsYet => 'Chưa có bài đăng nào';

  @override
  String get youHaveNoPosts => 'Bạn chưa có bài đăng nào';

  @override
  String userHasNoPosts(String name) {
    return '$name chưa có bài đăng nào';
  }

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(int count) {
    return '${count}ph';
  }

  @override
  String hoursAgo(int count) {
    return '${count}g';
  }

  @override
  String daysAgo(int count) {
    return '${count}ngày';
  }

  @override
  String dateAt(String date) {
    return 'ngày $date';
  }

  @override
  String get noPhotosInFeed => 'Chưa có ảnh nào trong feed';

  @override
  String get allPhotos => 'Tất cả ảnh';

  @override
  String get calendarTransactionsTitle => 'Lịch giao dịch';

  @override
  String get selectMonth => 'Chọn tháng';

  @override
  String get todayLabel => 'Hôm nay';

  @override
  String get dayDetailEmpty => 'Không có giao dịch trong ngày này';

  @override
  String get momentViewerEmpty => 'Không có giao dịch để hiển thị';

  @override
  String get momentViewerSaveVideo => 'Lưu video vào máy';

  @override
  String get momentViewerSaveImage => 'Lưu ảnh vào máy';

  @override
  String get momentViewerDeleteTransaction => 'Xoá giao dịch';

  @override
  String get momentViewerVideoNoLink => 'Video này chưa có link để lưu vào máy';

  @override
  String get momentViewerImageNoLink =>
      'Ảnh dạng icon/category không thể lưu trực tiếp vào máy';

  @override
  String get momentViewerSaveVideoSuccess => 'Đã lưu video vào máy';

  @override
  String get momentViewerSaveImageSuccess => 'Đã lưu ảnh vào máy';

  @override
  String get momentViewerSaveVideoFailed => 'Lưu video thất bại';

  @override
  String get momentViewerSaveImageFailed => 'Lưu ảnh thất bại';

  @override
  String get momentViewerCannotSaveVideo => 'Không thể lưu video vào máy';

  @override
  String get momentViewerCannotSaveImage => 'Không thể lưu ảnh vào máy';

  @override
  String get momentViewerDeleteConfirmTitle => 'Xoá giao dịch';

  @override
  String get momentViewerDeleteConfirmMessage =>
      'Bạn có chắc muốn xoá giao dịch này không?';

  @override
  String get momentViewerDeleted => 'Đã xoá giao dịch';

  @override
  String get momentViewerDeleteFailed => 'Xoá giao dịch thất bại';

  @override
  String momentViewerUploadTime(String time, String date) {
    return 'lúc $time ngày $date';
  }

  @override
  String get tabHome => 'Trang chủ';

  @override
  String get tabStats => 'Thống kê';

  @override
  String get tabFriends => 'Bạn bè';

  @override
  String get tabBudget => 'Ngân sách';

  @override
  String get tabLoading => 'Đang tải';

  @override
  String get someone => 'Người này';

  @override
  String get manageCategories => 'Danh mục';

  @override
  String get categoriesExpenseTab => 'Chi tiêu';

  @override
  String get categoriesIncomeTab => 'Thu nhập';

  @override
  String get addCustomCategory => 'Thêm danh mục';

  @override
  String get categoryNameHint => 'Tên danh mục (tiếng Việt)';

  @override
  String get categoryTypeLabel => 'Loại';

  @override
  String get categoryIconLabel => 'Biểu tượng';

  @override
  String get categoryColorLabel => 'Màu';

  @override
  String get saveCategory => 'Lưu danh mục';

  @override
  String get categorySaved => 'Đã lưu danh mục';

  @override
  String get categoryNameRequired => 'Vui lòng nhập tên danh mục';

  @override
  String get categoryDuplicate => 'Bạn đã có danh mục trùng tên';

  @override
  String get categoryReserved =>
      'Tên này dành cho danh mục mặc định của ứng dụng';

  @override
  String get categoryNameTooLong => 'Tên quá dài (tối đa 50 ký tự)';

  @override
  String get categorySaveFailed => 'Không thể lưu danh mục';

  @override
  String get deleteCategoryTitle => 'Xoá danh mục';

  @override
  String deleteCategoryMessage(String name) {
    return 'Xoá \"$name\"? Các giao dịch đã lưu vẫn giữ nguyên.';
  }

  @override
  String get deleteCategoryConfirmAction => 'Xoá';

  @override
  String get categoryDeleted => 'Đã xoá danh mục';

  @override
  String get categoryDeleteFailed => 'Không thể xoá danh mục';

  @override
  String get categoriesExpenseEmpty =>
      'Chưa có danh mục chi tiêu tùy chỉnh. Chạm + để thêm.';

  @override
  String get categoriesIncomeEmpty =>
      'Chưa có danh mục thu nhập tùy chỉnh. Chạm + để thêm.';

  @override
  String get builtinCategoriesHeading => 'Danh mục mặc định (không chỉnh sửa)';

  @override
  String get yourCategoriesHeading => 'Danh mục của bạn';

  @override
  String get editCustomCategory => 'Sửa danh mục';

  @override
  String get categoryUpdated => 'Đã cập nhật danh mục';

  @override
  String get categoryUpdateFailed => 'Không thể cập nhật danh mục';

  @override
  String get categoryNotFound => 'Danh mục không còn tồn tại';
}
