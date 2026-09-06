// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get english => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get currency => 'Currency';

  @override
  String get vnd => 'VND';

  @override
  String get usd => 'USD';

  @override
  String exchangeRateUpdated(String rate) {
    return 'Exchange rate updated: $rate';
  }

  @override
  String get updating => 'Updating';

  @override
  String get update => 'Update';

  @override
  String get profile => 'Profile';

  @override
  String get user => 'User';

  @override
  String joined(String date) {
    return 'Joined: $date';
  }

  @override
  String friends(int count) {
    return '$count Friends';
  }

  @override
  String get groups => 'Groups';

  @override
  String get changeEmail => 'Change login email';

  @override
  String get feedback => 'Feedback';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccountQuestion => 'Delete account?';

  @override
  String get deleteAccountWarning =>
      'This action will delete your account from Meme. You will not be able to log in again with this account.';

  @override
  String get deleteAccountNote =>
      'If you only want to leave the app temporarily, choose Logout instead of deleting your account.';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get cancel => 'Cancel';

  @override
  String get pleaseEnterPassword => 'Please enter your current password';

  @override
  String get accountNotFound => 'Current account not found';

  @override
  String get deleteAccountError =>
      'Could not delete account. Please check your password or log in again.';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get noTransactionsToday =>
      'You haven\'t added any transactions today.';

  @override
  String receivedToday(String amount) {
    return 'Received $amount today';
  }

  @override
  String spentToday(String amount) {
    return 'Spent $amount today';
  }

  @override
  String get you => 'You';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String transactionCount(int count) {
    return '$count transactions';
  }

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get addFirstTransaction =>
      'Add your first transaction to start tracking';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get welcomeBack => 'Welcome back 👋';

  @override
  String get loginSubtitle =>
      'Log in to continue saving photos, notes and your spending.';

  @override
  String get appSlogan => 'Save spending moments in a funner, more real way.';

  @override
  String get pleaseEnterPasswordLogin => 'Please enter password';

  @override
  String get pleaseEnterName => 'Please enter display name';

  @override
  String get createNewAccount => 'Create new account ✨';

  @override
  String get registerSlogan =>
      'Start saving spending moments in a funner, more real way.';

  @override
  String get joinMeme => 'Join Meme';

  @override
  String get registerSubtitle =>
      'Create a profile to manage spending, save photos and connect with friends.';

  @override
  String get displayName => 'Display name';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Use 3-20 characters: lowercase, numbers, . or _';

  @override
  String get passwordHint => 'Password minimum 6 characters';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get totalIncome => 'Total Income';

  @override
  String get totalExpense => 'Total Expense';

  @override
  String get streak => 'Streak';

  @override
  String daysStreak(int count) {
    return '$count Days';
  }

  @override
  String get streakLevel1 => 'Top Legend 🏆';

  @override
  String get streakLevel2 => 'Fire Master 🔥';

  @override
  String get streakLevel3 => 'Super Streak ⚡';

  @override
  String get streakLevel4 => 'Growing Fast 🌱';

  @override
  String get streakLevel5 => 'Start Streak ✨';

  @override
  String get personalBudget => 'Personal Budget';

  @override
  String get budgetTitle => 'Personal Budget';

  @override
  String get budgetSubtitle => 'Create themes and set money goals';

  @override
  String get budgetNote =>
      'Default categories like Food, Shopping, Transport will have no limits. Budgets here are personal themes created by you.';

  @override
  String get budgetOverview => 'Budget Overview';

  @override
  String monthYear(int month, int year) {
    return 'Month $month $year';
  }

  @override
  String get overLimit => 'Over target';

  @override
  String remainingAmount(String amount) {
    return 'Remaining $amount';
  }

  @override
  String get budgetGoal => 'Goal';

  @override
  String get usedAmount => 'Used';

  @override
  String get deleteBudgetQuestion => 'Delete budget?';

  @override
  String deleteBudgetWarning(String name) {
    return 'Are you sure you want to delete the theme \"$name\"? Previously created transactions will remain, only this budget goal will be deleted.';
  }

  @override
  String get delete => 'Delete';

  @override
  String budgetDeleted(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get noBudgetThemes => 'No budget themes';

  @override
  String get noBudgetThemesSubtitle =>
      'Create a theme like Picnic, Buy iPad or Travel to set a separate money goal.';

  @override
  String get personalThemes => 'Personal Themes';

  @override
  String get trackSpentVsGoal => 'Track spent amount versus goal';

  @override
  String get monthly => 'Monthly';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get biweekly => 'Bi-weekly';

  @override
  String get yearly => 'Yearly';

  @override
  String get custom => 'Custom';

  @override
  String get total => 'Total';

  @override
  String get category => 'Category';

  @override
  String get allSpending => 'All spending';

  @override
  String get syncFromCategory => 'Sync from category';

  @override
  String get budgetNameLabel => 'Budget Name';

  @override
  String get budgetNameHint => 'e.g., Daily spending';

  @override
  String get budgetAmountLabel => 'Budget Amount';

  @override
  String get period => 'Period';

  @override
  String get budgetType => 'Budget Type';

  @override
  String get color => 'Color';

  @override
  String get icon => 'Icon';

  @override
  String get createBudget => 'Create Budget';

  @override
  String get addBudget => 'Add Budget';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get pleaseEnterBudgetName => 'Please enter budget name';

  @override
  String get pleaseEnterBudgetAmount => 'Please enter budget amount';

  @override
  String get budgetAmountPositive => 'Budget amount must be greater than 0';

  @override
  String cannotCreateBudget(String error) {
    return 'Could not create budget: $error';
  }

  @override
  String get budgetUpdated => 'Budget updated';

  @override
  String get budgetUnchanged => 'No changes to update';

  @override
  String cannotUpdateBudget(String error) {
    return 'Could not update budget: $error';
  }

  @override
  String cannotDeleteBudget(String error) {
    return 'Could not delete budget: $error';
  }

  @override
  String get budgetAnalysis => 'Budget analysis';

  @override
  String get deleteBudget => 'Delete budget';

  @override
  String loadBudgetError(String error) {
    return 'Load budget error:\n$error';
  }

  @override
  String get budgetHistory => 'Budget History';

  @override
  String get average => 'Average';

  @override
  String get overBudget => 'Over budget';

  @override
  String get bestPeriod => 'Best period';

  @override
  String get worstPeriod => 'Worst period';

  @override
  String get periodCount => 'Period count';

  @override
  String get compareOverPeriods => 'Compare over periods';

  @override
  String get budgetLimitLegend => 'Budget limit';

  @override
  String get withinBudgetLegend => 'Within budget';

  @override
  String get overBudgetLegend => 'Over budget!';

  @override
  String get periodDetail => 'Period detail';

  @override
  String get currentPeriod => 'Current';

  @override
  String remainingLabel(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String budgetLimitLabel(String amount) {
    return 'Budget: $amount';
  }

  @override
  String get overBudgetWarning => 'Over budget!';

  @override
  String get budgetNamePreview => 'Budget Name';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordInstruction =>
      'Enter your registered email to receive a password reset link.';

  @override
  String get recoveryPassword => 'Recover Password';

  @override
  String get recoveryPasswordSubtitle =>
      'The system will send you an email to reset your password.';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get recoveryEmailSent => 'Password recovery email sent';

  @override
  String get couldNotSendRecoveryEmail => 'Could not send recovery email';

  @override
  String get sendRecoveryEmail => 'Send recovery email';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get changeEmailTitle => 'Change login email';

  @override
  String get changeEmailSubtitle =>
      'Update the email used to log into your account';

  @override
  String get currentEmail => 'Current Email';

  @override
  String get unknown => 'Unknown';

  @override
  String get newEmailInfo => 'New email information';

  @override
  String get newEmail => 'New Email';

  @override
  String get enterNewEmail => 'Enter your new email';

  @override
  String get enterPasswordToConfirm => 'Enter password to confirm';

  @override
  String get changeEmailNotice =>
      'To protect your account, you need to re-enter your current password before changing your login email.';

  @override
  String get updateEmail => 'Update Email';

  @override
  String get invalidEmail => 'Invalid new email';

  @override
  String get emailSameAsCurrent => 'New email is the same as current email';

  @override
  String get emailChangedSuccessfully => 'Login email changed successfully';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get feedbackSubtitle =>
      'Share your thoughts, suggestions or bug reports to make Meme better.';

  @override
  String get yourEmail => 'Your email';

  @override
  String get emailPrefilledNote =>
      'This email is pre-filled from your account.';

  @override
  String get yourFeedback => 'Your feedback *';

  @override
  String get feedbackHint =>
      'Share ideas, report bugs or suggest new features...';

  @override
  String get sending => 'Sending...';

  @override
  String get invalidEmailGeneric => 'Invalid email';

  @override
  String get pleaseEnterFeedback => 'Please enter your feedback';

  @override
  String feedbackTooLong(int count) {
    return 'Feedback cannot exceed $count characters';
  }

  @override
  String get feedbackEmailSubject => 'Feedback from Meme app';

  @override
  String feedbackEmailBody(
      String name, String username, String email, String message) {
    return 'Hello Admin,\n\nYou have just received a new feedback from the Meme app.\n\nSender information:\n- Name: $name\n- Username: $username\n- Email: $email\n\nFeedback content:\n$message\n\n---\nThis email was automatically generated from the Feedback screen of the Meme app.';
  }

  @override
  String get feedbackSentEmail => 'Opened email app to send feedback to admin';

  @override
  String get feedbackSaved =>
      'Feedback saved. Email app could not be opened on this device.';

  @override
  String feedbackError(String error) {
    return 'Could not send feedback: $error';
  }

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsSearchHint => 'Search friends...';

  @override
  String get noFriends => 'No friends yet';

  @override
  String get noFriendsSubtitle =>
      'Add friends to share spending and join groups.';

  @override
  String get addFriend => 'Add Friend';

  @override
  String get deleteFriendQuestion => 'Delete Friend?';

  @override
  String deleteFriendWarning(String name) {
    return 'Are you sure you want to remove $name from your friends list?';
  }

  @override
  String get deleteFriendGroupsNote =>
      'This person will still appear in groups you share. To remove them from a group, open that group and edit members or leave the group.';

  @override
  String friendDeleted(String name) {
    return 'Removed $name from friends';
  }

  @override
  String get addFriendTitle => 'Add Friend';

  @override
  String get addFriendSearchHint => 'Enter username or email...';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get sendFriendRequest => 'Add';

  @override
  String requestSent(String name) {
    return 'Friend request sent to $name';
  }

  @override
  String alreadyFriends(String name) {
    return 'You are already friends with $name';
  }

  @override
  String get requestPending => 'Pending';

  @override
  String get friendRequests => 'Friend Requests';

  @override
  String get friendRequestsReceivedTab => 'Received';

  @override
  String get friendRequestsSentTab => 'Sent';

  @override
  String get noFriendRequests => 'No pending requests';

  @override
  String get noSentFriendRequests => 'No sent requests';

  @override
  String get noFriendRequestsReceivedSubtitle =>
      'When other Meme users send you friend requests, they will appear here.';

  @override
  String get noFriendRequestsSentSubtitle =>
      'Friend requests you sent will appear here.';

  @override
  String sentRequestToUsername(String username) {
    return 'Request sent to @$username';
  }

  @override
  String get requestPendingStatus => 'Pending';

  @override
  String get friendBadgeInvitationSent => 'Invitation sent';

  @override
  String get friendBadgeAlreadyFriendsLabel => 'Friends';

  @override
  String get friendRequestCancelled => 'Friend request withdrawn';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String requestAccepted(String name) {
    return 'Accepted friend request from $name';
  }

  @override
  String requestDeclined(String name) {
    return 'Declined friend request from $name';
  }

  @override
  String get groupsTitle => 'Groups';

  @override
  String get noGroups => 'No groups yet';

  @override
  String get noGroupsSubtitle =>
      'Create a group to manage shared spending with friends.';

  @override
  String get createGroup => 'Create Group';

  @override
  String get createVerb => 'Create';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get deleteGroupQuestion => 'Delete Group?';

  @override
  String deleteGroupWarning(String name) {
    return 'Are you sure you want to delete group \"$name\"?';
  }

  @override
  String get contribution => 'Contribution';

  @override
  String get goal => 'Goal';

  @override
  String get noGroupTransactions => 'No group transactions yet';

  @override
  String get addGroupTransaction => 'Add Group Transaction';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get leaveGroup => 'Leave';

  @override
  String get leaveGroupQuestion => 'Leave Group?';

  @override
  String leaveGroupWarning(String name) {
    return 'Are you sure you want to leave \"$name\"?';
  }

  @override
  String get groupName => 'Group Name';

  @override
  String get groupNameHint => 'Enter group name';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Enter group description (optional)';

  @override
  String get contributionGoal => 'Contribution Goal';

  @override
  String get contributionGoalHint => 'Set a goal amount (optional)';

  @override
  String get members => 'Members';

  @override
  String get addMembers => 'Add Members';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get groupSaved => 'Group saved successfully';

  @override
  String get groupCreated => 'Group created successfully';

  @override
  String get currentUserNotFound => 'Current user not found';

  @override
  String get groupNoMembersToContribute => 'Group has no members to contribute';

  @override
  String get youAreNotMember => 'You are no longer a member of this group';

  @override
  String get addContribution => 'Add Contribution';

  @override
  String get selectMember => 'Select Member';

  @override
  String get youAreContributingFor => 'You are contributing for';

  @override
  String get amount => 'Amount';

  @override
  String get enterValidAmount => 'Please enter a valid amount';

  @override
  String get canOnlyAddForSelf => 'You can only add contribution for yourself';

  @override
  String get contributionAdded => 'Contribution added';

  @override
  String cannotAddContribution(String error) {
    return 'Could not add contribution: $error';
  }

  @override
  String get saving => 'Saving...';

  @override
  String get confirm => 'Confirm';

  @override
  String get groupNotFound => 'Group not found';

  @override
  String get group => 'Group';

  @override
  String get groupDetails => 'Group Details';

  @override
  String get groupOwner => 'Group Owner';

  @override
  String get groupColor => 'Group Color';

  @override
  String ofAmount(String amount) {
    return 'of $amount';
  }

  @override
  String reachedPercentage(int percentage) {
    return 'Reached $percentage%';
  }

  @override
  String get contributingMembers => 'Contributing Members';

  @override
  String get noMembersYet => 'No members yet';

  @override
  String paidAmount(String amount) {
    return 'Paid $amount';
  }

  @override
  String get groupOptions => 'Group Options';

  @override
  String get editGroupSubtitle => 'Change name, color, goal or members';

  @override
  String get deleteGroup => 'Delete';

  @override
  String get deleteGroupSubtitle => 'Delete this group for all members';

  @override
  String get leaveGroupSubtitle => 'Leave this group';

  @override
  String get deleteGroupConfirmation =>
      'Are you sure you want to delete this group? This action will remove the group for all members.';

  @override
  String get leaveGroupConfirmation =>
      'Are you sure you want to leave this group?';

  @override
  String get groupDeleted => 'Group deleted';

  @override
  String get youLeftGroup => 'You have left the group';

  @override
  String cannotDeleteGroup(String error) {
    return 'Could not delete group: $error';
  }

  @override
  String cannotLeaveGroup(String error) {
    return 'Could not leave group: $error';
  }

  @override
  String get ownerMustBeInGroup => 'Group owner must always be in the group';

  @override
  String get onlyOwnerCanEditGroup => 'Only the group owner can edit the group';

  @override
  String get groupInfoNotFound => 'Group information not found';

  @override
  String get pleaseEnterGroupName => 'Please enter group name';

  @override
  String get groupNameTooLong => 'Group name must be at most 50 characters';

  @override
  String get pleaseEnterGoalAmount => 'Please enter a goal amount';

  @override
  String get groupUpdated => 'Group updated';

  @override
  String groupUpdateFailedWithError(String error) {
    return 'Failed to update group: $error';
  }

  @override
  String get noPermissionToEditGroup =>
      'You don\'t have permission to edit this group';

  @override
  String get onlyOwnerCanEditNote =>
      'Only the group owner can change information, invite members, or remove members from the group.';

  @override
  String get goalAmount => 'Goal Amount';

  @override
  String goalAmountHintExample(String example) {
    return 'Goal amount, e.g. $example';
  }

  @override
  String get groupMembers => 'Group Members';

  @override
  String get groupMembersNote =>
      'Select friends to invite to the group. Existing members are kept even if they are no longer friends.';

  @override
  String get noMembersOrFriends => 'No members or friends to display';

  @override
  String get currentMember => 'Current member';

  @override
  String get notFriendsAnymore => 'Not friends anymore';

  @override
  String get groupMemberManagementNote =>
      'When adding new members, the group will appear in their account. When unselecting a member, the group will be removed from their group list.';

  @override
  String get gettingLocation => 'Getting location...';

  @override
  String get currentLocationSaved => 'Current location saved';

  @override
  String get noLocation => 'No location';

  @override
  String get skipPhoto => 'Skip photo';

  @override
  String get food => 'Food';

  @override
  String get shopping => 'Shopping';

  @override
  String get transport => 'Transport';

  @override
  String get education => 'Education';

  @override
  String get other => 'Other';

  @override
  String get salary => 'Salary';

  @override
  String get gift => 'Gift';

  @override
  String get entertainment => 'Entertainment';

  @override
  String get private => 'Private';

  @override
  String get everyone => 'Everyone';

  @override
  String get maxAmountDigits => 'Max 10 digits';

  @override
  String get addDetails => 'Add details';

  @override
  String get overBudgetLimitTitle => 'Over budget target';

  @override
  String overBudgetLimitWarning(String name, String limit, String over) {
    return 'This transaction will cause the theme \"$name\" to exceed the target of $limit by about $over. Do you still want to save?';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String shareType(String type) {
    return 'Type: $type';
  }

  @override
  String shareCategory(String category) {
    return 'Category: $category';
  }

  @override
  String shareAmount(String amount) {
    return 'Amount: $amount';
  }

  @override
  String shareDetails(String details) {
    return 'Details: $details';
  }

  @override
  String sharePrivacy(String privacy) {
    return 'Privacy: $privacy';
  }

  @override
  String get cannotShareNow => 'Cannot share at this time';

  @override
  String get amountLimitExceeded => 'Amount exceeds the 10-digit limit';

  @override
  String savedWithOverLimit(String category) {
    return 'Saved, but theme \"$category\" has exceeded target.';
  }

  @override
  String get transactionSavedSuccessfully => 'Transaction saved successfully';

  @override
  String get transactionSaveFailed => 'Failed to save transaction';

  @override
  String get limitLabel => 'Limit';

  @override
  String get retake => 'Retake';

  @override
  String get share => 'Share';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get backToThisMonth => 'Back to this month';

  @override
  String get backToThisYear => 'Back to this year';

  @override
  String get selectMonthStats => 'Select stats month';

  @override
  String get current => 'Current';

  @override
  String monthLabel(int month) {
    return 'Month $month';
  }

  @override
  String shortMonth(int month) {
    return 'mo $month';
  }

  @override
  String get selectYearStats => 'Select stats year';

  @override
  String get olderYears => 'Older years';

  @override
  String get newerYears => 'Newer years';

  @override
  String get totalExpenseLabel => 'Total Expense';

  @override
  String get totalIncomeLabel => 'Total Income';

  @override
  String get compareToPreviousMonth => 'vs previous month';

  @override
  String get compareToPreviousYear => 'vs previous year';

  @override
  String get expenseByCategoryMonth => 'Expense by category this month';

  @override
  String get incomeByCategoryMonth => 'Income by category this month';

  @override
  String get expenseByCategoryYear => 'Expense by category this year';

  @override
  String get incomeByCategoryYear => 'Income by category this year';

  @override
  String get noExpenseDataMonth => 'No expense data for this month';

  @override
  String get noIncomeDataMonth => 'No income data for this month';

  @override
  String get noExpenseDataYear => 'No expense data for this year';

  @override
  String get noIncomeDataYear => 'No income data for this year';

  @override
  String get expenseNoChange =>
      'Your spending hasn\'t changed from the previous period.';

  @override
  String get incomeNoChange =>
      'Your income hasn\'t changed from the previous period.';

  @override
  String expenseMore(String percent) {
    return 'You spent $percent% more than the previous period.';
  }

  @override
  String incomeMore(String percent) {
    return 'You received $percent% more than the previous period.';
  }

  @override
  String expenseLess(String percent) {
    return 'You spent $percent% less than the previous period.';
  }

  @override
  String incomeLess(String percent) {
    return 'You received $percent% less than the previous period.';
  }

  @override
  String previousPeriodAmount(String amount) {
    return 'Previous period: $amount';
  }

  @override
  String get categories => 'Categories';

  @override
  String get map => 'Map';

  @override
  String get transactionMap => 'Transaction Map';

  @override
  String get mapControl => 'Map Control';

  @override
  String get controlling => 'Controlling';

  @override
  String get tapToControlMap => 'Tap to control map';

  @override
  String get tapControllingToDisable =>
      'Tap \"Controlling\" to disable map interaction.';

  @override
  String get recentTransactionsOverview => 'Recent transactions overview.';

  @override
  String get mapEmptyTitle => 'No map data yet';

  @override
  String get mapEmptySubtitle =>
      'New transactions will appear on the map after location access is granted.';

  @override
  String mapSummary(int transactions, int locations) {
    return '$transactions transactions at $locations locations';
  }

  @override
  String mapTransactionsHere(int count) {
    return '$count transactions here';
  }

  @override
  String get expenseDetails => 'Expense Details';

  @override
  String get incomeDetails => 'Income Details';

  @override
  String percentOfTotalExpense(int percent) {
    return '$percent% of total expense';
  }

  @override
  String percentOfTotalIncome(int percent) {
    return '$percent% of total income';
  }

  @override
  String get noUser => 'No user';

  @override
  String loadFeedError(String error) {
    return 'Load feed error:\n$error';
  }

  @override
  String get emptyFeedFriends => 'Friend feed is empty';

  @override
  String get emptyFeedFriendsSubtitle =>
      'When you or your friends share transactions in \"Friends\" mode, posts will appear here.';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get youHaveNoPosts => 'You have no posts yet';

  @override
  String userHasNoPosts(String name) {
    return '$name has no posts yet';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h';
  }

  @override
  String daysAgo(int count) {
    return '${count}d';
  }

  @override
  String dateAt(String date) {
    return 'on $date';
  }

  @override
  String get noPhotosInFeed => 'No photos in feed yet';

  @override
  String get allPhotos => 'All photos';

  @override
  String get calendarTransactionsTitle => 'Transaction Calendar';

  @override
  String get selectMonth => 'Select month';

  @override
  String get todayLabel => 'Today';

  @override
  String get dayDetailEmpty => 'No transactions on this day';

  @override
  String get momentViewerEmpty => 'No transactions to display';

  @override
  String get momentViewerSaveVideo => 'Save video to device';

  @override
  String get momentViewerSaveImage => 'Save image to device';

  @override
  String get momentViewerDeleteTransaction => 'Delete transaction';

  @override
  String get momentViewerVideoNoLink => 'This video has no link to save';

  @override
  String get momentViewerImageNoLink =>
      'Icon/category images cannot be saved directly';

  @override
  String get momentViewerSaveVideoSuccess => 'Saved video to device';

  @override
  String get momentViewerSaveImageSuccess => 'Saved image to device';

  @override
  String get momentViewerSaveVideoFailed => 'Failed to save video';

  @override
  String get momentViewerSaveImageFailed => 'Failed to save image';

  @override
  String get momentViewerCannotSaveVideo => 'Cannot save video to device';

  @override
  String get momentViewerCannotSaveImage => 'Cannot save image to device';

  @override
  String get momentViewerDeleteConfirmTitle => 'Delete transaction';

  @override
  String get momentViewerDeleteConfirmMessage =>
      'Are you sure you want to delete this transaction?';

  @override
  String get momentViewerDeleted => 'Transaction deleted';

  @override
  String get momentViewerDeleteFailed => 'Failed to delete transaction';

  @override
  String momentViewerUploadTime(String time, String date) {
    return 'at $time on $date';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabFriends => 'Friends';

  @override
  String get tabBudget => 'Budget';

  @override
  String get tabLoading => 'Loading';

  @override
  String get someone => 'This person';

  @override
  String get manageCategories => 'Categories';

  @override
  String get categoriesExpenseTab => 'Expense';

  @override
  String get categoriesIncomeTab => 'Income';

  @override
  String get addCustomCategory => 'New category';

  @override
  String get categoryNameHint => 'Name (English)';

  @override
  String get categoryTypeLabel => 'Type';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get categoryColorLabel => 'Color';

  @override
  String get saveCategory => 'Save category';

  @override
  String get categorySaved => 'Category saved';

  @override
  String get categoryNameRequired => 'Please enter a category name';

  @override
  String get categoryDuplicate => 'You already have a category with this name';

  @override
  String get categoryReserved =>
      'This name is reserved for a built-in category';

  @override
  String get categoryNameTooLong => 'Name is too long (max 50 characters)';

  @override
  String get categorySaveFailed => 'Could not save category';

  @override
  String get deleteCategoryTitle => 'Delete category';

  @override
  String deleteCategoryMessage(String name) {
    return 'Remove \"$name\"? Existing transactions are not deleted.';
  }

  @override
  String get deleteCategoryConfirmAction => 'Delete';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get categoryDeleteFailed => 'Could not delete category';

  @override
  String get categoriesExpenseEmpty =>
      'No custom expense categories yet. Tap + to add one.';

  @override
  String get categoriesIncomeEmpty =>
      'No custom income categories yet. Tap + to add one.';

  @override
  String get builtinCategoriesHeading => 'App defaults (read-only)';

  @override
  String get yourCategoriesHeading => 'Your categories';

  @override
  String get editCustomCategory => 'Edit category';

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String get categoryUpdateFailed => 'Could not update category';

  @override
  String get categoryNotFound => 'Category no longer exists';

  @override
  String get closeFriends => 'Close friends';

  @override
  String get cameraPermissionRequired => 'Enable camera to use Meme';

  @override
  String get openSettings => 'Open settings';

  @override
  String get noCameraAvailable => 'No camera found';

  @override
  String get dayTab => 'Day';

  @override
  String get monthTab => 'Month';

  @override
  String get expenseLabel => 'Expense';

  @override
  String get incomeLabel => 'Income';

  @override
  String get appIcon => 'App Icon';

  @override
  String get appIconSection => 'App Icon';

  @override
  String get appIconSubtitle =>
      'Customize Meme launcher icon on your home screen';

  @override
  String get appIconPickerSubtitle =>
      'Choose a Meme icon style to display on your phone\'s home screen.';

  @override
  String get appIconClassic => 'Classic Meme';

  @override
  String get appIconClassicDesc => 'The original classic and fun icon style';

  @override
  String get appIconNeon => 'Neon Gold Meme';

  @override
  String get appIconNeonDesc => 'Warm yellow tone, bold and distinctive';

  @override
  String get appIconOcean => 'Ocean Blue Meme';

  @override
  String get appIconOceanDesc => 'Modern blue tone, fresh and vibrant';

  @override
  String get appIconInUse => 'In Use';

  @override
  String appIconChangedSuccess(String name) {
    return 'Changed app icon to \"$name\"';
  }

  @override
  String get appIconChangeFailed => 'Cannot change app icon on this device';

  @override
  String get cameraTheme => 'Camera Theme';

  @override
  String get cameraThemeSection => 'Camera Theme';

  @override
  String get cameraThemeSubtitle =>
      'Customize color style and viewfinder for the camera';

  @override
  String get cameraThemePickerSubtitle =>
      'Customize the viewfinder, shutter button colors, and camera interface to match your style.';

  @override
  String get cameraThemeClassic => 'Classic Meme';

  @override
  String get cameraThemeClassicDesc =>
      'Sleek dark interface with classic emerald neon accent';

  @override
  String get cameraThemeCyber => 'Cyber Neon';

  @override
  String get cameraThemeCyberDesc =>
      'Cyberpunk vibe with radiant purple and electric cyan';

  @override
  String get cameraThemeSunset => 'Sunset Gold';

  @override
  String get cameraThemeSunsetDesc =>
      'Warm twilight atmosphere with luxury amber glow';

  @override
  String get cameraThemeOcean => 'Ocean Breeze';

  @override
  String get cameraThemeOceanDesc =>
      'Deep sapphire blue, refreshing and energetic';

  @override
  String get cameraThemeMatcha => 'Matcha Zen';

  @override
  String get cameraThemeMatchaDesc =>
      'Calming matcha green and natural forest tones';

  @override
  String get cameraThemeAurora => 'Aurora Borealis';

  @override
  String get cameraThemeAuroraDesc =>
      'Mystical northern lights with vibrant teal and purple waves';

  @override
  String get cameraThemeSakura => 'Sakura Pink';

  @override
  String get cameraThemeSakuraDesc =>
      'Sweet and youthful pastel pink with blooming floral hues';

  @override
  String get cameraThemeGalaxy => 'Galaxy Nebula';

  @override
  String get cameraThemeGalaxyDesc =>
      'Deep celestial space with ultraviolet, magenta, and electric blue';

  @override
  String get cameraThemeLava => 'Lava Fire';

  @override
  String get cameraThemeLavaDesc =>
      'Fiery magma with blazing crimson and golden flame accents';

  @override
  String get cameraThemeVaporwave => 'Retro Vaporwave';

  @override
  String get cameraThemeVaporwaveDesc =>
      '80s synthwave energy with neon turquoise, hot magenta, and gold';

  @override
  String cameraThemeChangedSuccess(String name) {
    return 'Applied theme \"$name\"';
  }

  @override
  String get chatBubbleThemeTitle => 'Chat Bubble Theme';

  @override
  String get chatBubbleSuggestions => 'Suggested';

  @override
  String get chatBubbleAppliesToAll =>
      'This bubble style applies to all conversations.';

  @override
  String get chatBubblePreviewMe =>
      'Now you can change your chat bubble style and conversations will get a fresh look. So cool!';

  @override
  String get chatBubblePreviewFriend =>
      'Looks great! I\'m changing my style now too.';

  @override
  String get chatBubbleSave => 'Save';

  @override
  String get chatBubbleCancel => 'Cancel';

  @override
  String friendsCountTitle(int count) {
    return 'Friends ($count)';
  }

  @override
  String get findNewFriends => 'Find friends';

  @override
  String get searchInFriends => 'Search in friends...';

  @override
  String get friendsTabAll => 'All';

  @override
  String get friendsTabClose => 'Close Friends';

  @override
  String get friendsTabRequests => 'Requests';

  @override
  String get sendMessageAction => 'Message';

  @override
  String get addToCloseFriends => 'Add to close friends';

  @override
  String get removeFromCloseFriends => 'Remove from close friends';

  @override
  String addedToCloseFriends(String name) {
    return 'Added $name to close friends ⭐';
  }

  @override
  String removedFromCloseFriends(String name) {
    return 'Removed $name from close friends';
  }

  @override
  String get noMatchingFriends => 'No matching friends found';

  @override
  String get noCloseFriendsYet => 'No close friends yet';

  @override
  String get noCloseFriendsSubtitle =>
      'Tap the star icon next to a friend to add them to close friends';

  @override
  String get typeMessageHint => 'Message...';

  @override
  String get emptyConversationPrompt => '✨ Send the first message or reaction!';

  @override
  String get replyingToSelf => 'Replying to yourself';

  @override
  String replyingToUser(String name) {
    return 'Replying to $name';
  }

  @override
  String replyingToPost(String name) {
    return 'Replying to $name\'s post';
  }

  @override
  String get youRepliedToYourself => 'You replied to yourself';

  @override
  String youRepliedToUser(String name) {
    return 'You replied to $name';
  }

  @override
  String userRepliedToYou(String name) {
    return '$name replied to you';
  }

  @override
  String userRepliedToThemself(String name) {
    return '$name replied to themself';
  }

  @override
  String get activeNow => 'Active now';

  @override
  String activeAgo(String time) {
    return 'Active $time ago';
  }

  @override
  String get offlineStatus => 'Offline';

  @override
  String get feedMessageHint => 'Message...';

  @override
  String get sendReactionTitle => 'React';

  @override
  String get postActivityTitle => 'Activity';

  @override
  String get noPostActivityYet => 'No activity yet!';

  @override
  String get postViewedStatus => 'Viewed!';

  @override
  String get oneNewPost => '1 new post!';

  @override
  String newPostsCount(int count) {
    return '$count new posts!';
  }

  @override
  String get closeFriendBadge => 'Close Friend';

  @override
  String get viewSentRequests => 'View sent requests';

  @override
  String get sentRequestsTitle => 'Sent Requests';

  @override
  String sentRequestsCount(int count) {
    return 'Sent $count requests';
  }

  @override
  String get noSentRequestsYet => 'No sent requests yet!';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortNewestFirst => 'Newest first';

  @override
  String get sortOldestFirst => 'Oldest first';

  @override
  String get sortBy => 'Sort by';

  @override
  String get cancelRequest => 'Cancel';

  @override
  String get requestCancelled => 'Friend request cancelled';

  @override
  String get noFriendRequestsYet => 'No friend requests yet!';

  @override
  String get reply => 'Reply';

  @override
  String get copy => 'Copy';

  @override
  String get copiedToClipboard => 'Message copied';

  @override
  String get unsend => 'Unsend';

  @override
  String get unsendConfirm => 'Recall message?';

  @override
  String get unsendConfirmDesc =>
      'This message will be recalled for everyone in this chat.';

  @override
  String get deleteForMe => 'Delete for me';

  @override
  String get deleteForMeConfirm => 'Delete message for me?';

  @override
  String get deleteForMeConfirmDesc =>
      'This message will only be deleted on your side. Others will still see it.';

  @override
  String get report => 'Report';

  @override
  String get reportMessage => 'Report message';

  @override
  String get reportMessageDesc => 'Why do you want to report this message?';

  @override
  String get reportSpam => 'Spam or harassment';

  @override
  String get reportInappropriate => 'Inappropriate content';

  @override
  String get reportViolence => 'Hate speech or violence';

  @override
  String get reportOther => 'Other reason';

  @override
  String get reportSuccess => 'Thank you. Your report has been submitted.';

  @override
  String get selectReaction => 'Select reaction';

  @override
  String get streakMaintaining => 'Maintaining';

  @override
  String get bestStreakLabel => 'Personal Best';

  @override
  String get avatarCollection => 'Collection';

  @override
  String framesCount(int unlocked, int total) {
    return '$unlocked/$total Frames';
  }

  @override
  String get dailyMemeStreak => 'Daily Meme Streak';

  @override
  String get unlockedStatus => 'Unlocked';

  @override
  String unlockedBadgeCount(int unlocked, int total) {
    return '$unlocked/$total Unlocked';
  }

  @override
  String get hasPostedStreakMotivation =>
      'You posted today. Keep this wonderful momentum going!';

  @override
  String get notPostedStreakMotivation =>
      'Not posted today. Share a moment to maintain your streak!';

  @override
  String get avatarFrameCollectionTitle => 'Avatar Frame Collection';

  @override
  String get currentEquipped => 'Equipped';

  @override
  String get nextMilestone => 'Next Milestone';

  @override
  String daysLeftToUnlock(int count, String frameName) {
    return '$count days left to unlock $frameName';
  }

  @override
  String get allFramesUnlocked => 'All avatar frames unlocked';

  @override
  String get allFramesUnlockedDesc =>
      'You have conquered all the highest streak milestones!';

  @override
  String needStreakToUnlock(int days, String frameName) {
    return 'Reach a $days-day streak to unlock $frameName frame!';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get generalOverview => 'Overview';

  @override
  String get appearanceAndThemes => 'Appearance & Theme';

  @override
  String get systemPreferences => 'System Preferences';

  @override
  String get accountAndSupport => 'Account & Support';

  @override
  String get selectThemeMode => 'Select Display Theme';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get themeModeLabel => 'Theme Mode';

  @override
  String get vietnameseDong => 'Vietnamese Dong';

  @override
  String get usDollar => 'US Dollar';

  @override
  String get vndFull => 'VND (₫ • Vietnamese Dong)';

  @override
  String get usdFull => 'USD (\$ • US Dollar)';

  @override
  String get systemDefault => 'System Default';

  @override
  String get systemDefaultLanguage => 'System Default (Auto)';

  @override
  String get conversationsTitle => 'Conversations';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get startChattingWithFriends =>
      'Message your friends to start chatting';

  @override
  String get newMessage => 'New Message';

  @override
  String get searchConversations => 'Search conversations...';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String youReactedToMessage(String emoji) {
    return 'You reacted $emoji to message';
  }

  @override
  String friendReactedToMessage(String name, String emoji) {
    return '$name reacted $emoji to message';
  }

  @override
  String repliedToPostSnippet(String text) {
    return 'Replied to post: $text';
  }

  @override
  String get isTyping => 'Typing...';

  @override
  String youPrefix(String text) {
    return 'You: $text';
  }

  @override
  String taggedYouInPost(String name) {
    return '$name mentioned you in a post';
  }

  @override
  String get tagFriends => 'Tag friends';

  @override
  String get startTypingToTag => 'Type @ to tag friends';

  @override
  String get viewTaggedProfile => 'View profile';

  @override
  String get messageFriend => 'Message';

  @override
  String streakDayCount(int count) {
    return '$count days';
  }

  @override
  String get friendRequestSent => 'Request Sent';

  @override
  String get messageRecalled => 'Message recalled';

  @override
  String get recallTimeExpired =>
      'The 15-minute window to recall this message has expired';

  @override
  String get privateCannotTagFriends => 'Cannot tag friends in private mode';

  @override
  String get closeFriendsTagOnly =>
      'Can only tag friends in your Close Friends list';

  @override
  String get privacySection => 'Privacy';

  @override
  String get activeStatusTitle => 'Active Status';

  @override
  String get activeStatusSubtitle =>
      'When off, friends cannot see when you are active and you will not see their active status either.';

  @override
  String get chooseWhoCanSeeActive => 'Choose who can see when you\'re active';

  @override
  String get activeStatusPublic => 'Public';

  @override
  String get activeStatusPublicDesc =>
      'Anyone on the app can see your activity status.';

  @override
  String get activeStatusFriends => 'Friends';

  @override
  String get activeStatusFriendsDesc =>
      'Friends can see your activity status. You\'ll see each other\'s activity status only if both of you set it to active.';

  @override
  String get activeStatusNoOne => 'No one';

  @override
  String get activeStatusNoOneDesc =>
      'No one can see your activity status, and you cannot see the activity status of friends.';

  @override
  String get rewindTitle => 'Meme Rewind';

  @override
  String get rewindMemories => 'Spending Memories';

  @override
  String get rewindSelectPeriod => 'Select Period';

  @override
  String get rewindWeek => 'Week';

  @override
  String get rewindMonth => 'Month';

  @override
  String get rewindQuarter => 'Quarter';

  @override
  String get rewindYear => 'Year';

  @override
  String get rewindThisWeek => 'This Week';

  @override
  String get rewindThisMonth => 'This Month';

  @override
  String get rewindThisQuarter => 'This Quarter';

  @override
  String get rewindThisYear => 'This Year';

  @override
  String get rewindOverviewTitle => 'This Period\'s Journey';

  @override
  String get rewindOverviewSubtitle => 'How did this time go for you?';

  @override
  String get rewindTotalExpense => 'Total Spending';

  @override
  String get rewindTotalIncome => 'Total Income';

  @override
  String get rewindTotalTransactions => 'Transactions';

  @override
  String get rewindBalance => 'Remaining Balance';

  @override
  String rewindSpentMore(String percent) {
    return 'You spent $percent% more than last period';
  }

  @override
  String rewindSpentLess(String percent) {
    return 'You spent $percent% less than last period';
  }

  @override
  String get rewindSpentEqual => 'Spending was similar to last period';

  @override
  String get rewindSpentGentleUp =>
      'You spent a little more than the previous period';

  @override
  String get rewindSpentGentleDown =>
      'You were more economical than the previous period';

  @override
  String get rewindCategoryTitle => 'Where did your money go?';

  @override
  String get rewindCategorySubtitle =>
      'Categories that took most of your spending';

  @override
  String get rewindTopCategory => 'Top Category';

  @override
  String get rewindStreakTitle => 'Your Active Streak';

  @override
  String rewindStreakDays(int count) {
    return '$count days in a row';
  }

  @override
  String rewindStreakSubtitle(int count) {
    return 'You recorded spending consistently for $count days';
  }

  @override
  String get rewindStreakStarter => 'Just getting started, keep it up!';

  @override
  String get rewindStreakZero => 'Start a new streak today!';

  @override
  String get rewindTopExpensesTitle => 'Most Memorable Expenses';

  @override
  String get rewindTopExpensesSubtitle =>
      'Top largest spendings in this period';

  @override
  String get rewindBiggestDayTitle => 'Highest Spending Day';

  @override
  String rewindBiggestDaySubtitle(String date) {
    return '$date was your highest spending day';
  }

  @override
  String rewindTransactionsOnDay(int count) {
    return '$count transactions on this day';
  }

  @override
  String get rewindDailySpendingDistribution => 'Daily spending distribution';

  @override
  String get rewindMomentsTitle => 'Spending Moments';

  @override
  String get rewindMomentsSubtitle =>
      'Money is more than just numbers. These are the moments behind your spending.';

  @override
  String get rewindHighlightTitle => 'Your Period Highlight';

  @override
  String get rewindHighlightDominantTitle => 'Dominant Category';

  @override
  String rewindHighlightDominantDesc(String category, String percent) {
    return '$category accounted for $percent% of your total spending.';
  }

  @override
  String get rewindHighlightPeakDayTitle => 'Peak Spending Day';

  @override
  String rewindHighlightPeakDayDesc(String date, String percent) {
    return 'On $date, you spent $percent% of your total spending for this period.';
  }

  @override
  String get rewindHighlightBiggestExpenseTitle => 'Memorable Expense';

  @override
  String rewindHighlightBiggestExpenseDesc(String category) {
    return 'Your largest expense was on $category.';
  }

  @override
  String get rewindDaysThisWeek => 'Days this week';

  @override
  String get rewindDaysRecentInPeriod => 'Recent 7 days in period';

  @override
  String get rewindComparisonTitle => 'This Period vs Previous';

  @override
  String get rewindComparisonSubtitle => 'How are your habits evolving?';

  @override
  String get rewindSummaryTitle => 'This is your journey ✨';

  @override
  String get rewindSummarySubtitle => 'A memorable chapter with Meme App';

  @override
  String get rewindSaveCard => 'Save Image';

  @override
  String get rewindShareCard => 'Share';

  @override
  String get rewindSeeYouNext => 'See you in the next Rewind ❤️';

  @override
  String get rewindEmptyTitle => 'No transactions in this period yet';

  @override
  String get rewindEmptySubtitle =>
      'Start logging your spendings so Meme Rewind can tell your story!';

  @override
  String get rewindSaveSuccess => 'Saved image to gallery!';

  @override
  String get rewindShareText => 'Check out my spending journey on Meme App! ✨';

  @override
  String get rewindThisPeriod => 'This period';

  @override
  String get rewindPreviousPeriod => 'Previous period';

  @override
  String rewindTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get rewindLargestExpense => 'Largest Expense';

  @override
  String rewindDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String rewindActiveDaysInPeriod(int count, String period) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active days in $period',
      one: '1 active day in $period',
    );
    return '$_temp0';
  }

  @override
  String get groupBadge => 'Group';

  @override
  String get groupChat => 'Group Chat';

  @override
  String groupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get groupChatOpen => 'Group Chat';

  @override
  String systemGroupCreated(String name, String group) {
    return '$name created group \"$group\"';
  }

  @override
  String systemGroupMemberAdded(String name, String member) {
    return '$name added $member to the group';
  }

  @override
  String systemGroupMemberLeft(String name) {
    return '$name left the group';
  }

  @override
  String systemGroupExpenseLogged(String name, String amount, String category) {
    return '$name shared spending of $amount for \"$category\"';
  }

  @override
  String postToGroup(String name) {
    return 'Group: $name';
  }

  @override
  String get groupSpendingVisibleNote =>
      'Group members can view spending amount';

  @override
  String groupAudience(String name) {
    return 'Group: $name';
  }

  @override
  String shortDaysStreak(int count) {
    return '$count Days';
  }

  @override
  String get tabAll => 'All';

  @override
  String get tabUnread => 'Unread';

  @override
  String get tabGroups => 'Groups';

  @override
  String get createStory => 'Add story';

  @override
  String get whatAreYouThinking => 'What\'s on your mind?';

  @override
  String activeMinutesAgo(int minutes) {
    return 'Active ${minutes}m ago';
  }

  @override
  String activeHoursAgo(int hours) {
    return 'Active ${hours}h ago';
  }

  @override
  String newMessagesCount(int count) {
    return '$count new messages';
  }

  @override
  String get shareNote => 'Share a note...';

  @override
  String get yourNote => 'Your note';

  @override
  String get newNote => 'New note';

  @override
  String get shareVerb => 'Share';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get noteSharedSuccess => 'Note shared';

  @override
  String get noteDeletedSuccess => 'Note deleted';

  @override
  String get sendDirectMessage => 'Send message';

  @override
  String get youRepliedToTheirNote => 'You replied to their note';

  @override
  String userRepliedToYourNote(String name) {
    return '$name replied to your note';
  }

  @override
  String sharedWithAudience(String audience) {
    return 'Shared with $audience';
  }

  @override
  String get audiencePublic => 'Public';

  @override
  String get audienceFriends => 'Friends';

  @override
  String get expiresIn24Hours => 'Expires in 24 hours';

  @override
  String expiresInHours(int hours) {
    return 'Expires in $hours hours';
  }

  @override
  String get shareNewNote => 'Share a new note';

  @override
  String get cameraThemeLockedNotice =>
      'Reach a 3-day streak to unlock this camera theme!';

  @override
  String get cameraThemeStreakRequirement => '3-day streak';

  @override
  String cameraThemeStreakBanner(int days, int current) {
    return 'Reach a $days-day streak to unlock all camera themes (Current: $current days)';
  }

  @override
  String cameraThemeUnlockedBanner(int current) {
    return 'You have unlocked all camera themes with a $current-day streak! 🔥';
  }

  @override
  String streakProgressFraction(int current, int total) {
    return '$current/$total days';
  }

  @override
  String get draftPrefix => 'Draft: ';
}
