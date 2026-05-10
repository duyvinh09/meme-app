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
  String get streak => 'Daily Streak';

  @override
  String daysStreak(int count) {
    return '$count days streak';
  }

  @override
  String get streakLevel1 => 'Excellent';

  @override
  String get streakLevel2 => 'Great';

  @override
  String get streakLevel3 => 'Steady';

  @override
  String get streakLevel4 => 'Getting there';

  @override
  String get streakLevel5 => 'Let\'s start';

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
  String get requestPending => 'Friend request already sent';

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
}
