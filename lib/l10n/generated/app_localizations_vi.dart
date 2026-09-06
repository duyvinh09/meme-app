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
  String get requestPending => 'Đang chờ';

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

  @override
  String get closeFriends => 'Bạn thân';

  @override
  String get cameraPermissionRequired => 'Bật máy ảnh để sử dụng Meme';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get noCameraAvailable => 'Không tìm thấy máy ảnh';

  @override
  String get dayTab => 'Ngày';

  @override
  String get monthTab => 'Tháng';

  @override
  String get expenseLabel => 'Chi tiêu';

  @override
  String get incomeLabel => 'Thu nhập';

  @override
  String get appIcon => 'Biểu tượng ứng dụng';

  @override
  String get appIconSection => 'Biểu tượng ứng dụng';

  @override
  String get appIconSubtitle => 'Tùy chỉnh biểu tượng Meme trên màn hình chính';

  @override
  String get appIconPickerSubtitle =>
      'Chọn kiểu biểu tượng Meme để hiển thị trên màn hình chính của bạn.';

  @override
  String get appIconClassic => 'Meme Cổ Điển';

  @override
  String get appIconClassicDesc =>
      'Phong cách biểu tượng gốc quen thuộc và vui nhộn';

  @override
  String get appIconNeon => 'Meme Vàng Neon';

  @override
  String get appIconNeonDesc => 'Tông vàng ấm áp, nổi bật và đậm cá tính';

  @override
  String get appIconOcean => 'Meme Xanh Đại Dương';

  @override
  String get appIconOceanDesc =>
      'Tông xanh dương hiện đại, tươi mát và năng động';

  @override
  String get appIconInUse => 'Đang dùng';

  @override
  String appIconChangedSuccess(String name) {
    return 'Đã đổi biểu tượng ứng dụng thành \"$name\"';
  }

  @override
  String get appIconChangeFailed =>
      'Không thể đổi biểu tượng trên thiết bị này';

  @override
  String get cameraTheme => 'Giao diện máy ảnh';

  @override
  String get cameraThemeSection => 'Giao diện máy ảnh';

  @override
  String get cameraThemeSubtitle =>
      'Tùy biến phong cách màu sắc và kính ngắm cho máy ảnh';

  @override
  String get cameraThemePickerSubtitle =>
      'Tùy chỉnh kính ngắm, màu nút chụp và giao diện máy ảnh theo phong cách của bạn.';

  @override
  String get cameraThemeClassic => 'Meme Cổ Điển';

  @override
  String get cameraThemeClassicDesc =>
      'Giao diện tối tinh tế với điểm nhấn xanh ngọc lục bảo neon';

  @override
  String get cameraThemeCyber => 'Cyber Neon';

  @override
  String get cameraThemeCyberDesc =>
      'Phong cách cyberpunk với sắc tím rực rỡ và xanh điện tử';

  @override
  String get cameraThemeSunset => 'Hoàng Hôn Vàng';

  @override
  String get cameraThemeSunsetDesc =>
      'Không gian hoàng hôn ấm áp với ánh hổ phách sang trọng';

  @override
  String get cameraThemeOcean => 'Gió Biển';

  @override
  String get cameraThemeOceanDesc =>
      'Xanh sapphire sâu thẳm, tươi mát và tràn đầy năng lượng';

  @override
  String get cameraThemeMatcha => 'Matcha Thiền';

  @override
  String get cameraThemeMatchaDesc =>
      'Sắc xanh matcha thanh tịnh cùng tông rừng tự nhiên';

  @override
  String get cameraThemeAurora => 'Bắc Cực Quang';

  @override
  String get cameraThemeAuroraDesc =>
      'Ánh sáng phương bắc huyền ảo với làn sóng xanh mòng két và tím';

  @override
  String get cameraThemeSakura => 'Hoa Anh Đào';

  @override
  String get cameraThemeSakuraDesc =>
      'Sắc hồng pastel ngọt ngào và trẻ trung như hoa anh đào nở';

  @override
  String get cameraThemeGalaxy => 'Tinh Vân Thiên Hà';

  @override
  String get cameraThemeGalaxyDesc =>
      'Không gian vũ trụ huyền bí với tím cực tím, hồng magenta và xanh điện';

  @override
  String get cameraThemeLava => 'Dòng Nham Thạch';

  @override
  String get cameraThemeLavaDesc =>
      'Dòng magma rực lửa với đỏ thẫm và ngọn lửa vàng bốc cháy';

  @override
  String get cameraThemeVaporwave => 'Retro Vaporwave';

  @override
  String get cameraThemeVaporwaveDesc =>
      'Năng lượng synthwave thập niên 80 với xanh ngọc, hồng rực và ánh vàng';

  @override
  String cameraThemeChangedSuccess(String name) {
    return 'Đã áp dụng chủ đề \"$name\"';
  }

  @override
  String get chatBubbleThemeTitle => 'Giao diện bong bóng chat';

  @override
  String get chatBubbleSuggestions => 'Gợi ý';

  @override
  String get chatBubbleAppliesToAll =>
      'Kiểu bong bóng này áp dụng cho tất cả cuộc trò chuyện.';

  @override
  String get chatBubblePreviewMe =>
      'Bây giờ bạn có thể đổi kiểu bong bóng chat để cuộc trò chuyện trông mới mẻ hơn. Thật tuyệt!';

  @override
  String get chatBubblePreviewFriend =>
      'Trông đẹp đấy! Mình cũng đổi kiểu ngay đây.';

  @override
  String get chatBubbleSave => 'Lưu';

  @override
  String get chatBubbleCancel => 'Hủy';

  @override
  String friendsCountTitle(int count) {
    return 'Bạn bè ($count)';
  }

  @override
  String get findNewFriends => 'Tìm bạn bè';

  @override
  String get searchInFriends => 'Tìm trong bạn bè...';

  @override
  String get friendsTabAll => 'Tất cả';

  @override
  String get friendsTabClose => 'Bạn thân';

  @override
  String get friendsTabRequests => 'Lời mời';

  @override
  String get sendMessageAction => 'Nhắn tin';

  @override
  String get addToCloseFriends => 'Thêm vào bạn thân';

  @override
  String get removeFromCloseFriends => 'Xóa khỏi bạn thân';

  @override
  String addedToCloseFriends(String name) {
    return 'Đã thêm $name vào bạn thân ⭐';
  }

  @override
  String removedFromCloseFriends(String name) {
    return 'Đã xóa $name khỏi bạn thân';
  }

  @override
  String get noMatchingFriends => 'Không tìm thấy bạn bè phù hợp';

  @override
  String get noCloseFriendsYet => 'Chưa có bạn thân nào';

  @override
  String get noCloseFriendsSubtitle =>
      'Chạm vào biểu tượng ngôi sao bên cạnh bạn bè để thêm họ vào bạn thân';

  @override
  String get typeMessageHint => 'Tin nhắn...';

  @override
  String get emptyConversationPrompt =>
      '✨ Gửi tin nhắn hoặc thả cảm xúc đầu tiên!';

  @override
  String get replyingToSelf => 'Đang trả lời chính bạn';

  @override
  String replyingToUser(String name) {
    return 'Đang trả lời $name';
  }

  @override
  String replyingToPost(String name) {
    return 'Đang trả lời bài viết của $name';
  }

  @override
  String get youRepliedToYourself => 'Bạn đã trả lời chính mình';

  @override
  String youRepliedToUser(String name) {
    return 'Bạn đã trả lời $name';
  }

  @override
  String userRepliedToYou(String name) {
    return '$name đã trả lời bạn';
  }

  @override
  String userRepliedToThemself(String name) {
    return '$name đã trả lời chính họ';
  }

  @override
  String get activeNow => 'Đang hoạt động';

  @override
  String activeAgo(String time) {
    return 'Hoạt động $time trước';
  }

  @override
  String get offlineStatus => 'Ngoại tuyến';

  @override
  String get feedMessageHint => 'Tin nhắn...';

  @override
  String get sendReactionTitle => 'Thả cảm xúc';

  @override
  String get postActivityTitle => 'Hoạt động';

  @override
  String get noPostActivityYet => 'Chưa có hoạt động nào!';

  @override
  String get postViewedStatus => 'Đã xem!';

  @override
  String get oneNewPost => '1 bài viết mới!';

  @override
  String newPostsCount(int count) {
    return '$count bài viết mới!';
  }

  @override
  String get closeFriendBadge => 'Bạn thân';

  @override
  String get viewSentRequests => 'Xem lời mời đã gửi';

  @override
  String get sentRequestsTitle => 'Lời mời đã gửi';

  @override
  String sentRequestsCount(int count) {
    return 'Đã gửi $count lời mời';
  }

  @override
  String get noSentRequestsYet => 'Chưa có lời mời nào đã gửi!';

  @override
  String get sortDefault => 'Mặc định';

  @override
  String get sortNewestFirst => 'Mới nhất trước';

  @override
  String get sortOldestFirst => 'Cũ nhất trước';

  @override
  String get sortBy => 'Sắp xếp theo';

  @override
  String get cancelRequest => 'Hủy';

  @override
  String get requestCancelled => 'Đã hủy lời mời kết bạn';

  @override
  String get noFriendRequestsYet => 'Chưa có lời mời kết bạn nào!';

  @override
  String get reply => 'Trả lời';

  @override
  String get copy => 'Sao chép';

  @override
  String get copiedToClipboard => 'Đã sao chép tin nhắn';

  @override
  String get unsend => 'Thu hồi';

  @override
  String get unsendConfirm => 'Thu hồi tin nhắn?';

  @override
  String get unsendConfirmDesc =>
      'Tin nhắn này sẽ được thu hồi đối với tất cả mọi người trong đoạn chat.';

  @override
  String get deleteForMe => 'Xóa ở phía tôi';

  @override
  String get deleteForMeConfirm => 'Xóa tin nhắn ở phía bạn?';

  @override
  String get deleteForMeConfirmDesc =>
      'Tin nhắn này chỉ bị xóa ở phía bạn. Những người khác vẫn sẽ nhìn thấy.';

  @override
  String get report => 'Báo cáo';

  @override
  String get reportMessage => 'Báo cáo tin nhắn';

  @override
  String get reportMessageDesc => 'Tại sao bạn muốn báo cáo tin nhắn này?';

  @override
  String get reportSpam => 'Spam hoặc làm phiền';

  @override
  String get reportInappropriate => 'Nội dung không phù hợp';

  @override
  String get reportViolence => 'Ngôn từ thù ghét hoặc bạo lực';

  @override
  String get reportOther => 'Lý do khác';

  @override
  String get reportSuccess => 'Cảm ơn bạn. Báo cáo của bạn đã được gửi.';

  @override
  String get selectReaction => 'Chọn cảm xúc';

  @override
  String get streakMaintaining => 'Đang duy trì';

  @override
  String get bestStreakLabel => 'Kỷ lục cá nhân';

  @override
  String get avatarCollection => 'Bộ sưu tập';

  @override
  String framesCount(int unlocked, int total) {
    return '$unlocked/$total Khung';
  }

  @override
  String get dailyMemeStreak => 'Chuỗi Meme Hằng Ngày';

  @override
  String get unlockedStatus => 'Đã mở khóa';

  @override
  String unlockedBadgeCount(int unlocked, int total) {
    return '$unlocked/$total Đã mở';
  }

  @override
  String get hasPostedStreakMotivation =>
      'Bạn đã đăng bài hôm nay. Hãy tiếp tục duy trì phong độ tuyệt vời này!';

  @override
  String get notPostedStreakMotivation =>
      'Hôm nay bạn chưa đăng bài. Hãy chia sẻ một khoảnh khắc để giữ chuỗi nhé!';

  @override
  String get avatarFrameCollectionTitle => 'Bộ sưu tập Khung đại diện';

  @override
  String get currentEquipped => 'Đang sử dụng';

  @override
  String get nextMilestone => 'Cột mốc tiếp theo';

  @override
  String daysLeftToUnlock(int count, String frameName) {
    return 'Còn $count ngày để mở khóa $frameName';
  }

  @override
  String get allFramesUnlocked => 'Đã mở khóa toàn bộ khung avatar';

  @override
  String get allFramesUnlockedDesc =>
      'Bạn đã chinh phục tất cả các cột mốc chuỗi cao nhất!';

  @override
  String needStreakToUnlock(int days, String frameName) {
    return 'Đạt chuỗi $days ngày để mở khóa khung $frameName!';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get generalOverview => 'Tổng quan';

  @override
  String get appearanceAndThemes => 'Giao diện & Chủ đề';

  @override
  String get systemPreferences => 'Tùy chọn hệ thống';

  @override
  String get accountAndSupport => 'Tài khoản & Hỗ trợ';

  @override
  String get selectThemeMode => 'Chọn chế độ hiển thị';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get selectCurrency => 'Chọn đơn vị tiền tệ';

  @override
  String get themeModeLabel => 'Chế độ giao diện';

  @override
  String get vietnameseDong => 'Đồng Việt Nam';

  @override
  String get usDollar => 'Đô la Mỹ';

  @override
  String get vndFull => 'VND (₫ • Đồng Việt Nam)';

  @override
  String get usdFull => 'USD (\$ • Đô la Mỹ)';

  @override
  String get systemDefault => 'Mặc định hệ thống';

  @override
  String get systemDefaultLanguage => 'Mặc định hệ thống (Tự động)';

  @override
  String get conversationsTitle => 'Cuộc trò chuyện';

  @override
  String get noConversationsYet => 'Chưa có cuộc trò chuyện nào';

  @override
  String get startChattingWithFriends =>
      'Nhắn tin cho bạn bè để bắt đầu trò chuyện';

  @override
  String get newMessage => 'Tin nhắn mới';

  @override
  String get searchConversations => 'Tìm cuộc trò chuyện...';

  @override
  String get markAllAsRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get startConversation => 'Bắt đầu cuộc trò chuyện';

  @override
  String youReactedToMessage(String emoji) {
    return 'Bạn đã thả cảm xúc $emoji vào tin nhắn';
  }

  @override
  String friendReactedToMessage(String name, String emoji) {
    return '$name đã thả cảm xúc $emoji vào tin nhắn';
  }

  @override
  String repliedToPostSnippet(String text) {
    return 'Đã trả lời bài viết: $text';
  }

  @override
  String get isTyping => 'Đang soạn tin...';

  @override
  String youPrefix(String text) {
    return 'Bạn: $text';
  }

  @override
  String taggedYouInPost(String name) {
    return '$name đã nhắc đến bạn trong một bài viết';
  }

  @override
  String get tagFriends => 'Gắn thẻ bạn bè';

  @override
  String get startTypingToTag => 'Gõ @ để gắn thẻ bạn bè';

  @override
  String get viewTaggedProfile => 'Xem trang cá nhân';

  @override
  String get messageFriend => 'Nhắn tin';

  @override
  String streakDayCount(int count) {
    return '$count ngày';
  }

  @override
  String get friendRequestSent => 'Đã gửi lời mời';

  @override
  String get messageRecalled => 'Tin nhắn đã bị thu hồi';

  @override
  String get recallTimeExpired =>
      'Đã quá thời hạn 15 phút để thu hồi tin nhắn này';

  @override
  String get privateCannotTagFriends => 'Chế độ riêng tư không gắn thẻ bạn bè';

  @override
  String get closeFriendsTagOnly =>
      'Chỉ gắn thẻ được bạn bè trong danh sách Bạn thân';

  @override
  String get privacySection => 'Quyền riêng tư';

  @override
  String get activeStatusTitle => 'Trạng thái hoạt động';

  @override
  String get activeStatusSubtitle =>
      'Khi tắt, bạn bè sẽ không thấy bạn hoạt động và bạn cũng không thấy trạng thái của họ.';

  @override
  String get chooseWhoCanSeeActive =>
      'Chọn người có thể thấy khi bạn hoạt động';

  @override
  String get activeStatusPublic => 'Công khai';

  @override
  String get activeStatusPublicDesc =>
      'Mọi người trên ứng dụng đều có thể thấy trạng thái hoạt động của bạn.';

  @override
  String get activeStatusFriends => 'Bạn bè';

  @override
  String get activeStatusFriendsDesc =>
      'Bạn bè có thể thấy khi bạn hoạt động. Cả hai chỉ thấy nhau khi đều bật.';

  @override
  String get activeStatusNoOne => 'Không ai cả';

  @override
  String get activeStatusNoOneDesc =>
      'Không ai có thể thấy trạng thái hoạt động của bạn và bạn cũng không thấy của ai.';

  @override
  String get rewindTitle => 'Meme Rewind';

  @override
  String get rewindMemories => 'Kỷ niệm chi tiêu';

  @override
  String get rewindSelectPeriod => 'Chọn khoảng thời gian';

  @override
  String get rewindWeek => 'Tuần';

  @override
  String get rewindMonth => 'Tháng';

  @override
  String get rewindQuarter => 'Quý';

  @override
  String get rewindYear => 'Năm';

  @override
  String get rewindThisWeek => 'Tuần này';

  @override
  String get rewindThisMonth => 'Tháng này';

  @override
  String get rewindThisQuarter => 'Quý này';

  @override
  String get rewindThisYear => 'Năm này';

  @override
  String get rewindOverviewTitle => 'Hành trình giai đoạn này';

  @override
  String get rewindOverviewSubtitle =>
      'Khoảng thời gian vừa qua của bạn thế nào?';

  @override
  String get rewindTotalExpense => 'Tổng chi tiêu';

  @override
  String get rewindTotalIncome => 'Tổng thu nhập';

  @override
  String get rewindTotalTransactions => 'Giao dịch';

  @override
  String get rewindBalance => 'Số dư còn lại';

  @override
  String rewindSpentMore(String percent) {
    return 'Bạn đã chi nhiều hơn $percent% so với kỳ trước';
  }

  @override
  String rewindSpentLess(String percent) {
    return 'Bạn đã chi ít hơn $percent% so với kỳ trước';
  }

  @override
  String get rewindSpentEqual => 'Chi tiêu tương đương so với kỳ trước';

  @override
  String get rewindSpentGentleUp =>
      'Bạn đã chi nhiều hơn một chút so với kỳ trước';

  @override
  String get rewindSpentGentleDown => 'Bạn đã tiết kiệm hơn so với kỳ trước';

  @override
  String get rewindCategoryTitle => 'Tiền của bạn đi đâu?';

  @override
  String get rewindCategorySubtitle =>
      'Những danh mục chiếm nhiều chi tiêu nhất';

  @override
  String get rewindTopCategory => 'Danh mục hàng đầu';

  @override
  String get rewindStreakTitle => 'Chuỗi hoạt động của bạn';

  @override
  String rewindStreakDays(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String rewindStreakSubtitle(int count) {
    return 'Bạn đã ghi chép chi tiêu đều đặn trong $count ngày';
  }

  @override
  String get rewindStreakStarter => 'Mới bắt đầu thôi, cố gắng duy trì nhé!';

  @override
  String get rewindStreakZero => 'Bắt đầu chuỗi mới ngay hôm nay!';

  @override
  String get rewindTopExpensesTitle => 'Khoản chi đáng nhớ nhất';

  @override
  String get rewindTopExpensesSubtitle =>
      'Những khoản chi lớn nhất trong giai đoạn này';

  @override
  String get rewindBiggestDayTitle => 'Ngày chi tiêu nhiều nhất';

  @override
  String rewindBiggestDaySubtitle(String date) {
    return 'Ngày $date là ngày bạn chi tiêu nhiều nhất';
  }

  @override
  String rewindTransactionsOnDay(int count) {
    return '$count giao dịch trong ngày này';
  }

  @override
  String get rewindDailySpendingDistribution => 'Phân bổ chi tiêu hằng ngày';

  @override
  String get rewindMomentsTitle => 'Khoảnh khắc chi tiêu';

  @override
  String get rewindMomentsSubtitle =>
      'Tiền bạc không chỉ là những con số. Đây là những khoảnh khắc gắn liền với chi tiêu của bạn.';

  @override
  String get rewindHighlightTitle => 'Điểm nhấn của kỳ';

  @override
  String get rewindHighlightDominantTitle => 'Danh mục chiếm ưu thế';

  @override
  String rewindHighlightDominantDesc(String category, String percent) {
    return '$category chiếm $percent% tổng chi tiêu của bạn.';
  }

  @override
  String get rewindHighlightPeakDayTitle => 'Ngày chi tiêu cao nhất';

  @override
  String rewindHighlightPeakDayDesc(String date, String percent) {
    return 'Vào ngày $date, bạn đã chi $percent% tổng chi tiêu của kỳ này.';
  }

  @override
  String get rewindHighlightBiggestExpenseTitle => 'Khoản chi đáng nhớ';

  @override
  String rewindHighlightBiggestExpenseDesc(String category) {
    return 'Khoản chi lớn nhất của bạn là dành cho $category.';
  }

  @override
  String get rewindDaysThisWeek => 'Các ngày trong tuần';

  @override
  String get rewindDaysRecentInPeriod => '7 ngày gần nhất trong kỳ';

  @override
  String get rewindComparisonTitle => 'Kỳ này so với kỳ trước';

  @override
  String get rewindComparisonSubtitle =>
      'Thói quen của bạn đang thay đổi thế nào?';

  @override
  String get rewindSummaryTitle => 'Đây là hành trình của bạn ✨';

  @override
  String get rewindSummarySubtitle => 'Một chương đáng nhớ cùng Meme App';

  @override
  String get rewindSaveCard => 'Lưu ảnh';

  @override
  String get rewindShareCard => 'Chia sẻ';

  @override
  String get rewindSeeYouNext => 'Hẹn gặp lại bạn ở Rewind tiếp theo ❤️';

  @override
  String get rewindEmptyTitle => 'Chưa có giao dịch nào trong kỳ này';

  @override
  String get rewindEmptySubtitle =>
      'Hãy bắt đầu ghi chép chi tiêu để Meme Rewind có thể kể câu chuyện của bạn nhé!';

  @override
  String get rewindSaveSuccess => 'Đã lưu ảnh vào thư viện!';

  @override
  String get rewindShareText =>
      'Khám phá hành trình chi tiêu của mình trên Meme App! ✨';

  @override
  String get rewindThisPeriod => 'Kỳ này';

  @override
  String get rewindPreviousPeriod => 'Kỳ trước';

  @override
  String rewindTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giao dịch',
    );
    return '$_temp0';
  }

  @override
  String get rewindLargestExpense => 'Khoản chi lớn nhất';

  @override
  String rewindDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String rewindActiveDaysInPeriod(int count, String period) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày hoạt động trong $period',
    );
    return '$_temp0';
  }

  @override
  String get groupBadge => 'Nhóm';

  @override
  String get groupChat => 'Nhóm chat';

  @override
  String groupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thành viên',
    );
    return '$_temp0';
  }

  @override
  String get groupChatOpen => 'Mở nhóm chat';

  @override
  String systemGroupCreated(String name, String group) {
    return '$name đã tạo nhóm \"$group\"';
  }

  @override
  String systemGroupMemberAdded(String name, String member) {
    return '$name đã thêm $member vào nhóm';
  }

  @override
  String systemGroupMemberLeft(String name) {
    return '$name đã rời khỏi nhóm';
  }

  @override
  String systemGroupExpenseLogged(String name, String amount, String category) {
    return '$name đã thêm chi tiêu $amount cho \"$category\"';
  }

  @override
  String postToGroup(String name) {
    return 'Nhóm: $name';
  }

  @override
  String get groupSpendingVisibleNote =>
      'Thành viên trong nhóm có thể xem số tiền chi tiêu';

  @override
  String groupAudience(String name) {
    return 'Nhóm: $name';
  }

  @override
  String shortDaysStreak(int count) {
    return '$count Ngày';
  }

  @override
  String get tabAll => 'Tất cả';

  @override
  String get tabUnread => 'Chưa đọc';

  @override
  String get tabGroups => 'Nhóm';

  @override
  String get createStory => 'Tạo tin';

  @override
  String get whatAreYouThinking => 'Bạn đang nghĩ gì?';

  @override
  String activeMinutesAgo(int minutes) {
    return 'Hoạt động $minutes phút trước';
  }

  @override
  String activeHoursAgo(int hours) {
    return 'Hoạt động $hours giờ trước';
  }

  @override
  String newMessagesCount(int count) {
    return '$count tin nhắn mới';
  }

  @override
  String get shareNote => 'Chia sẻ ghi chú...';

  @override
  String get yourNote => 'Ghi chú của bạn';

  @override
  String get newNote => 'Ghi chú mới';

  @override
  String get shareVerb => 'Chia sẻ';

  @override
  String get deleteNote => 'Xóa ghi chú';

  @override
  String get noteSharedSuccess => 'Đã chia sẻ ghi chú';

  @override
  String get noteDeletedSuccess => 'Đã xóa ghi chú';

  @override
  String get sendDirectMessage => 'Gửi tin nhắn';

  @override
  String get youRepliedToTheirNote => 'Bạn đã phản hồi ghi chú của họ';

  @override
  String userRepliedToYourNote(String name) {
    return '$name đã phản hồi ghi chú của bạn';
  }

  @override
  String sharedWithAudience(String audience) {
    return 'Đã chia sẻ với $audience';
  }

  @override
  String get audiencePublic => 'Công khai';

  @override
  String get audienceFriends => 'Bạn bè';

  @override
  String get expiresIn24Hours => 'Hết hạn sau 24 giờ';

  @override
  String expiresInHours(int hours) {
    return 'Hết hạn sau $hours giờ';
  }

  @override
  String get shareNewNote => 'Chia sẻ ghi chú mới';

  @override
  String get cameraThemeLockedNotice =>
      'Đạt chuỗi 3 ngày để mở khóa giao diện này!';

  @override
  String get cameraThemeStreakRequirement => 'Chuỗi 3 ngày';

  @override
  String cameraThemeStreakBanner(int days, int current) {
    return 'Đạt chuỗi $days ngày để mở khóa toàn bộ giao diện máy ảnh (Hiện tại: $current ngày)';
  }

  @override
  String cameraThemeUnlockedBanner(int current) {
    return 'Bạn đã mở khóa toàn bộ giao diện máy ảnh với chuỗi $current ngày! 🔥';
  }

  @override
  String streakProgressFraction(int current, int total) {
    return '$current/$total ngày';
  }

  @override
  String get draftPrefix => 'Bản nháp: ';
}
