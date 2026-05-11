import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyMoney'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get totalExpense;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limit;

  /// No description provided for @exceeded.
  ///
  /// In en, this message translates to:
  /// **'Exceeded'**
  String get exceeded;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get addBudget;

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get editBudget;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @quarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get quarterly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @allowOverdraft.
  ///
  /// In en, this message translates to:
  /// **'Allow Overdraft'**
  String get allowOverdraft;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIcon;

  /// No description provided for @categoryColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColor;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @yearlyReport.
  ///
  /// In en, this message translates to:
  /// **'Yearly Report'**
  String get yearlyReport;

  /// No description provided for @topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get topCategories;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDelete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @budgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded!'**
  String get budgetExceeded;

  /// No description provided for @categoryInUse.
  ///
  /// In en, this message translates to:
  /// **'Category is in use and cannot be deleted'**
  String get categoryInUse;

  /// No description provided for @budgetOverlap.
  ///
  /// In en, this message translates to:
  /// **'Budget period overlaps with existing budget'**
  String get budgetOverlap;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get selectAccount;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @attachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Attach Receipt'**
  String get attachReceipt;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @shareTransaction.
  ///
  /// In en, this message translates to:
  /// **'Share Transaction'**
  String get shareTransaction;

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactions;

  /// No description provided for @noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets found'**
  String get noBudgets;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategories;

  /// No description provided for @noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts found'**
  String get noAccounts;

  /// No description provided for @createFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first one!'**
  String get createFirst;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MyMoney'**
  String get welcome;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your money with ease'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track expenses, set budgets, and view reports'**
  String get onboardingSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get byCategory;

  /// No description provided for @byBudget.
  ///
  /// In en, this message translates to:
  /// **'By Budget'**
  String get byBudget;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYear;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importExport.
  ///
  /// In en, this message translates to:
  /// **'Import/Export Data'**
  String get importExport;

  /// No description provided for @languageAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'Language & Display'**
  String get languageAndDisplay;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme Color'**
  String get themeColor;

  /// No description provided for @selectThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Select your favorite interface color'**
  String get selectThemeColor;

  /// No description provided for @budgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Budget Settings'**
  String get budgetSettings;

  /// No description provided for @defaultBudgetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Default Budget Period'**
  String get defaultBudgetPeriod;

  /// No description provided for @manageBudgets.
  ///
  /// In en, this message translates to:
  /// **'Manage Budgets'**
  String get manageBudgets;

  /// No description provided for @viewEditBudgets.
  ///
  /// In en, this message translates to:
  /// **'View and edit budgets'**
  String get viewEditBudgets;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore data'**
  String get backupRestore;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @addEditDeleteCategories.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, delete categories'**
  String get addEditDeleteCategories;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @selectBudgetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Budget Period'**
  String get selectBudgetPeriod;

  /// No description provided for @selectInterfaceColor.
  ///
  /// In en, this message translates to:
  /// **'Select Interface Color'**
  String get selectInterfaceColor;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note'**
  String get noNote;

  /// No description provided for @reportOverview.
  ///
  /// In en, this message translates to:
  /// **'Report Overview'**
  String get reportOverview;

  /// No description provided for @expenseByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense by Category'**
  String get expenseByCategory;

  /// No description provided for @incomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by Category'**
  String get incomeByCategory;

  /// No description provided for @reportByBudget.
  ///
  /// In en, this message translates to:
  /// **'Report by Budget'**
  String get reportByBudget;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noBudgetsYet.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get noBudgetsYet;

  /// No description provided for @noExpenseInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expense in this period'**
  String get noExpenseInPeriod;

  /// No description provided for @noIncomeInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No income in this period'**
  String get noIncomeInPeriod;

  /// No description provided for @selectTimePeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Time Period'**
  String get selectTimePeriod;

  /// No description provided for @byMonth.
  ///
  /// In en, this message translates to:
  /// **'By Month'**
  String get byMonth;

  /// No description provided for @byYear.
  ///
  /// In en, this message translates to:
  /// **'By Year'**
  String get byYear;

  /// No description provided for @monthFormat.
  ///
  /// In en, this message translates to:
  /// **'Month {month}/{year}'**
  String monthFormat(Object month, Object year);

  /// No description provided for @yearFormat.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String yearFormat(Object year);

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Category Type'**
  String get categoryType;

  /// No description provided for @showMoreIcons.
  ///
  /// In en, this message translates to:
  /// **'Show More Icons'**
  String get showMoreIcons;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @noCategoryYet.
  ///
  /// In en, this message translates to:
  /// **'No expense category yet. Tap \"Add\" to create one.'**
  String get noCategoryYet;

  /// No description provided for @transactionsInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Transactions in Period'**
  String get transactionsInPeriod;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @selectTransactionsForBudget.
  ///
  /// In en, this message translates to:
  /// **'Select transactions for budget'**
  String get selectTransactionsForBudget;

  /// No description provided for @noExpenseTransactionInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expense transaction in this period.'**
  String get noExpenseTransactionInPeriod;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @languageDisplay.
  ///
  /// In en, this message translates to:
  /// **'Language & Display'**
  String get languageDisplay;

  /// No description provided for @manageBudgetsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and edit budgets'**
  String get manageBudgetsDesc;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @importExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore data'**
  String get importExportDesc;

  /// No description provided for @manageCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, delete categories'**
  String get manageCategoriesDesc;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @overviewReport.
  ///
  /// In en, this message translates to:
  /// **'Overview Report'**
  String get overviewReport;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'Number of transactions'**
  String get transactionCount;

  /// No description provided for @budgetReports.
  ///
  /// In en, this message translates to:
  /// **'Budget Reports'**
  String get budgetReports;

  /// No description provided for @noExpenseBudgets.
  ///
  /// In en, this message translates to:
  /// **'No expense budgets'**
  String get noExpenseBudgets;

  /// No description provided for @noIncomeBudgets.
  ///
  /// In en, this message translates to:
  /// **'No income budgets'**
  String get noIncomeBudgets;

  /// No description provided for @noExpenseThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expense in this period'**
  String get noExpenseThisPeriod;

  /// No description provided for @noIncomeThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No income in this period'**
  String get noIncomeThisPeriod;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Time Period'**
  String get selectPeriod;

  /// No description provided for @transactionsCount.
  ///
  /// In en, this message translates to:
  /// **'transactions'**
  String get transactionsCount;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Export all transactions to a file for backup or transfer to another device.'**
  String get exportDataDesc;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvDesc.
  ///
  /// In en, this message translates to:
  /// **'Can be opened with Excel'**
  String get exportCsvDesc;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// No description provided for @exportJsonDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard format'**
  String get exportJsonDesc;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @importDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Import transactions from CSV or JSON file. New categories will be created automatically.'**
  String get importDataDesc;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get importFromFile;

  /// No description provided for @importFromFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Select .csv or .json file'**
  String get importFromFileDesc;

  /// No description provided for @pasteCsv.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV'**
  String get pasteCsv;

  /// No description provided for @pasteJson.
  ///
  /// In en, this message translates to:
  /// **'Paste JSON'**
  String get pasteJson;

  /// No description provided for @fromClipboard.
  ///
  /// In en, this message translates to:
  /// **'From clipboard'**
  String get fromClipboard;

  /// No description provided for @templateSection.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get templateSection;

  /// No description provided for @templateDesc.
  ///
  /// In en, this message translates to:
  /// **'Download template file to learn the import file format.'**
  String get templateDesc;

  /// No description provided for @templateCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV Template'**
  String get templateCsv;

  /// No description provided for @templateJson.
  ///
  /// In en, this message translates to:
  /// **'JSON Template'**
  String get templateJson;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download template'**
  String get downloadTemplate;

  /// No description provided for @formatGuide.
  ///
  /// In en, this message translates to:
  /// **'Format Guide'**
  String get formatGuide;

  /// No description provided for @formatDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction date (dd/MM/yyyy)'**
  String get formatDate;

  /// No description provided for @formatType.
  ///
  /// In en, this message translates to:
  /// **'income or expense'**
  String get formatType;

  /// No description provided for @formatAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (VND, no decimals)'**
  String get formatAmount;

  /// No description provided for @formatCategory.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get formatCategory;

  /// No description provided for @formatNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get formatNote;

  /// No description provided for @cannotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot read file'**
  String get cannotReadFile;

  /// No description provided for @unsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file format. Please select a .csv or .json file'**
  String get unsupportedFormat;

  /// No description provided for @fileReadError.
  ///
  /// In en, this message translates to:
  /// **'File read error'**
  String get fileReadError;

  /// No description provided for @noTransactionToExport.
  ///
  /// In en, this message translates to:
  /// **'No transactions to export'**
  String get noTransactionToExport;

  /// No description provided for @exportedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} transactions'**
  String exportedTransactions(Object count);

  /// No description provided for @fileSavedAt.
  ///
  /// In en, this message translates to:
  /// **'File: {path}'**
  String fileSavedAt(Object path);

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error'**
  String get exportError;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get exportSuccess;

  /// No description provided for @fileSavedAtPath.
  ///
  /// In en, this message translates to:
  /// **'File saved at:'**
  String get fileSavedAtPath;

  /// No description provided for @whatNext.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do next?'**
  String get whatNext;

  /// No description provided for @copyContent.
  ///
  /// In en, this message translates to:
  /// **'Copy content'**
  String get copyContent;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Content copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @importFromFormat.
  ///
  /// In en, this message translates to:
  /// **'Import from {format}'**
  String importFromFormat(Object format);

  /// No description provided for @pasteContentHere.
  ///
  /// In en, this message translates to:
  /// **'Paste file content here:'**
  String get pasteContentHere;

  /// No description provided for @emptyContent.
  ///
  /// In en, this message translates to:
  /// **'Empty content'**
  String get emptyContent;

  /// No description provided for @noTransactionToImport.
  ///
  /// In en, this message translates to:
  /// **'No transactions to import'**
  String get noTransactionToImport;

  /// No description provided for @importedTransactions.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} transactions'**
  String importedTransactions(Object count);

  /// No description provided for @createdCategories.
  ///
  /// In en, this message translates to:
  /// **'Created {count} new categories: {names}'**
  String createdCategories(Object count, Object names);

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error'**
  String get importError;

  /// No description provided for @savedTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get savedTemplate;

  /// No description provided for @copiedTemplateToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Template copied to clipboard'**
  String get copiedTemplateToClipboard;

  /// No description provided for @monthStartDay.
  ///
  /// In en, this message translates to:
  /// **'Month Start Day'**
  String get monthStartDay;

  /// No description provided for @monthStartDayDesc.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of each month'**
  String monthStartDayDesc(Object day);

  /// No description provided for @selectMonthStartDay.
  ///
  /// In en, this message translates to:
  /// **'Select month start day'**
  String get selectMonthStartDay;

  /// No description provided for @iconManagement.
  ///
  /// In en, this message translates to:
  /// **'Icon Management'**
  String get iconManagement;

  /// No description provided for @iconManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Search and add new icons for categories'**
  String get iconManagementDesc;

  /// No description provided for @searchIcon.
  ///
  /// In en, this message translates to:
  /// **'Search Icon'**
  String get searchIcon;

  /// No description provided for @searchIconHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name in English (e.g. car, food, money)'**
  String get searchIconHint;

  /// No description provided for @addIcon.
  ///
  /// In en, this message translates to:
  /// **'Add Icon'**
  String get addIcon;

  /// No description provided for @removeIcon.
  ///
  /// In en, this message translates to:
  /// **'Remove Icon'**
  String get removeIcon;

  /// No description provided for @myIcons.
  ///
  /// In en, this message translates to:
  /// **'My Icons'**
  String get myIcons;

  /// No description provided for @availableIcons.
  ///
  /// In en, this message translates to:
  /// **'Available Icons'**
  String get availableIcons;

  /// No description provided for @noIconsFound.
  ///
  /// In en, this message translates to:
  /// **'No icons found'**
  String get noIconsFound;

  /// No description provided for @iconAdded.
  ///
  /// In en, this message translates to:
  /// **'Icon added'**
  String get iconAdded;

  /// No description provided for @iconRemoved.
  ///
  /// In en, this message translates to:
  /// **'Icon removed'**
  String get iconRemoved;

  /// No description provided for @iconAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Icon already added'**
  String get iconAlreadyAdded;

  /// No description provided for @manageTransactions.
  ///
  /// In en, this message translates to:
  /// **'Manage Transactions'**
  String get manageTransactions;

  /// No description provided for @manageTransactionsDesc.
  ///
  /// In en, this message translates to:
  /// **'View, search, and edit all transactions'**
  String get manageTransactionsDesc;

  /// No description provided for @searchByNameOrAmount.
  ///
  /// In en, this message translates to:
  /// **'Search by name or amount'**
  String get searchByNameOrAmount;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @allBudgets.
  ///
  /// In en, this message translates to:
  /// **'All Budgets'**
  String get allBudgets;

  /// No description provided for @editSelected.
  ///
  /// In en, this message translates to:
  /// **'Edit Selected'**
  String get editSelected;

  /// No description provided for @changeCategory.
  ///
  /// In en, this message translates to:
  /// **'Change Category'**
  String get changeCategory;

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get changeDate;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get updateSuccess;

  /// No description provided for @selectNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Select New Category'**
  String get selectNewCategory;

  /// No description provided for @selectNewDate.
  ///
  /// In en, this message translates to:
  /// **'Select New Date'**
  String get selectNewDate;

  /// No description provided for @noBudget.
  ///
  /// In en, this message translates to:
  /// **'No Budget'**
  String get noBudget;

  /// No description provided for @budgetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted'**
  String get budgetDeleted;

  /// No description provided for @confirmDeleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the budget for \"{categoryName}\"?'**
  String confirmDeleteBudget(Object categoryName);

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @chooseSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose save location'**
  String get chooseSaveLocation;

  /// No description provided for @exportedTransactionsSubject.
  ///
  /// In en, this message translates to:
  /// **'MyMoney - Exported Transactions'**
  String get exportedTransactionsSubject;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Cannot share file'**
  String get shareError;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountSection;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVietnamese;

  /// No description provided for @activeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Active Workspace'**
  String get activeWorkspace;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @logoutDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign out and return to login'**
  String get logoutDesc;

  /// No description provided for @allowOverdraftDesc.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded - proceed'**
  String get allowOverdraftDesc;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get signInDesc;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutTitle;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?\n\nYour local data will be kept and synced when you sign in again.'**
  String get signOutConfirm;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out: {error}'**
  String signOutFailed(Object error);

  /// No description provided for @switchWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Switch workspace'**
  String get switchWorkspace;

  /// No description provided for @selectWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select Workspace'**
  String get selectWorkspace;

  /// No description provided for @manageWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Manage Workspaces'**
  String get manageWorkspaces;

  /// No description provided for @switchedWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String switchedWorkspace(Object name);

  /// No description provided for @joinByInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Join by invite code'**
  String get joinByInviteCode;

  /// No description provided for @workspaceSetupIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Workspace setup is incomplete'**
  String get workspaceSetupIncomplete;

  /// No description provided for @workspaceSetupIncompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'No workspace was created for this account.\n\nThis usually means the Supabase auth trigger `on_auth_user_created` is missing or misconfigured.\n\nPlease contact the administrator and ask them to verify:\n- trigger `on_auth_user_created`\n- function `public.handle_new_user()`\n- rows were created in `profiles`, `workspaces`, and `workspace_members`'**
  String get workspaceSetupIncompleteDesc;

  /// No description provided for @ownerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRole;

  /// No description provided for @roleValue.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String roleValue(Object role);

  /// No description provided for @joinWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Join workspace'**
  String get joinWorkspace;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// No description provided for @pasteWorkspaceInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste workspace invite code'**
  String get pasteWorkspaceInviteCode;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @joinedWorkspaceSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Joined workspace successfully'**
  String get joinedWorkspaceSuccessfully;

  /// No description provided for @workspaceInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'You were invited to {workspaceName}'**
  String workspaceInviteMessage(Object workspaceName);

  /// No description provided for @workspaceInviteFrom.
  ///
  /// In en, this message translates to:
  /// **'Invited by {inviter}'**
  String workspaceInviteFrom(Object inviter);

  /// No description provided for @declineInvite.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineInvite;

  /// No description provided for @inviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invite declined'**
  String get inviteDeclined;

  /// No description provided for @noWorkspaceInviteNotifications.
  ///
  /// In en, this message translates to:
  /// **'No workspace invites right now'**
  String get noWorkspaceInviteNotifications;

  /// No description provided for @errorLoadingWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Error loading workspaces: {error}'**
  String errorLoadingWorkspaces(Object error);

  /// No description provided for @workspaceManagement.
  ///
  /// In en, this message translates to:
  /// **'Workspace Management'**
  String get workspaceManagement;

  /// No description provided for @workspaceInviteAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This email is already a workspace member'**
  String get workspaceInviteAlreadyMember;

  /// No description provided for @workspaceInviteInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Email format is invalid'**
  String get workspaceInviteInvalidEmail;

  /// No description provided for @workspaceInviteAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'A pending invite already exists for this email'**
  String get workspaceInviteAlreadyPending;

  /// No description provided for @inviteCreated.
  ///
  /// In en, this message translates to:
  /// **'Invite created'**
  String get inviteCreated;

  /// No description provided for @shareInviteCodeWith.
  ///
  /// In en, this message translates to:
  /// **'Share this invite code with {email}:'**
  String shareInviteCodeWith(Object email);

  /// No description provided for @inviteRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Invite refreshed'**
  String get inviteRefreshed;

  /// No description provided for @shareNewInviteCodeWith.
  ///
  /// In en, this message translates to:
  /// **'Share this new invite code with {email}:'**
  String shareNewInviteCodeWith(Object email);

  /// No description provided for @noActiveWorkspaceSelected.
  ///
  /// In en, this message translates to:
  /// **'No active workspace selected'**
  String get noActiveWorkspaceSelected;

  /// No description provided for @workspaceOwnerDescription.
  ///
  /// In en, this message translates to:
  /// **'You are the owner of this workspace.'**
  String get workspaceOwnerDescription;

  /// No description provided for @inviteMember.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get inviteMember;

  /// No description provided for @inviteMemberDesc.
  ///
  /// In en, this message translates to:
  /// **'Create an invite code for a member email. The code stays valid for 7 days.'**
  String get inviteMemberDesc;

  /// No description provided for @memberEmail.
  ///
  /// In en, this message translates to:
  /// **'Member email'**
  String get memberEmail;

  /// No description provided for @emailExample.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailExample;

  /// No description provided for @refreshInvite.
  ///
  /// In en, this message translates to:
  /// **'Refresh invite'**
  String get refreshInvite;

  /// No description provided for @createInvite.
  ///
  /// In en, this message translates to:
  /// **'Create invite'**
  String get createInvite;

  /// No description provided for @membersSection.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersSection;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembersFound;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @failedToLoadMembers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members: {error}'**
  String failedToLoadMembers(Object error);

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMember;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this workspace?'**
  String removeMemberConfirm(Object name);

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String memberRemoved(Object name);

  /// No description provided for @memberOwnerYouLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} (owner, you)'**
  String memberOwnerYouLabel(Object name);

  /// No description provided for @memberYouLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String memberYouLabel(Object name);

  /// No description provided for @memberOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} (owner)'**
  String memberOwnerLabel(Object name);

  /// No description provided for @joinTimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Join time unavailable'**
  String get joinTimeUnavailable;

  /// No description provided for @joinedAt.
  ///
  /// In en, this message translates to:
  /// **'Joined {dateTime}'**
  String joinedAt(Object dateTime);

  /// No description provided for @userIdValue.
  ///
  /// In en, this message translates to:
  /// **'User ID: {id}'**
  String userIdValue(Object id);

  /// No description provided for @statusValue.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusValue(Object status);

  /// No description provided for @userShortLabel.
  ///
  /// In en, this message translates to:
  /// **'User {id}'**
  String userShortLabel(Object id);

  /// No description provided for @pendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending invites'**
  String get pendingInvites;

  /// No description provided for @noPendingInvites.
  ///
  /// In en, this message translates to:
  /// **'No pending invites'**
  String get noPendingInvites;

  /// No description provided for @declinedInvites.
  ///
  /// In en, this message translates to:
  /// **'Declined invites'**
  String get declinedInvites;

  /// No description provided for @noDeclinedInvites.
  ///
  /// In en, this message translates to:
  /// **'No declined invites'**
  String get noDeclinedInvites;

  /// No description provided for @revokedInvites.
  ///
  /// In en, this message translates to:
  /// **'Revoked invites'**
  String get revokedInvites;

  /// No description provided for @noRevokedInvites.
  ///
  /// In en, this message translates to:
  /// **'No revoked invites'**
  String get noRevokedInvites;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopied;

  /// No description provided for @inviteRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invite revoked'**
  String get inviteRevoked;

  /// No description provided for @failedToLoadInvites.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invites: {error}'**
  String failedToLoadInvites(Object error);

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @declinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedStatus;

  /// No description provided for @declinedAt.
  ///
  /// In en, this message translates to:
  /// **'Declined at {dateTime}'**
  String declinedAt(Object dateTime);

  /// No description provided for @revokedStatus.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get revokedStatus;

  /// No description provided for @revokedAt.
  ///
  /// In en, this message translates to:
  /// **'Revoked at {dateTime}'**
  String revokedAt(Object dateTime);

  /// No description provided for @filterInvitesByEmail.
  ///
  /// In en, this message translates to:
  /// **'Filter by email'**
  String get filterInvitesByEmail;

  /// No description provided for @filterInvitesByEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Search invite email'**
  String get filterInvitesByEmailHint;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @sortInvites.
  ///
  /// In en, this message translates to:
  /// **'Sort invites'**
  String get sortInvites;

  /// No description provided for @sortByNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortByNewest;

  /// No description provided for @sortByOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortByOldest;

  /// No description provided for @sortByEmail.
  ///
  /// In en, this message translates to:
  /// **'Email A-Z'**
  String get sortByEmail;

  /// No description provided for @invitedUserJoinHint.
  ///
  /// In en, this message translates to:
  /// **'The invited user can open Workspace Selection and choose Join by invite code.'**
  String get invitedUserJoinHint;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @expiredToday.
  ///
  /// In en, this message translates to:
  /// **'Expired today'**
  String get expiredToday;

  /// No description provided for @expiredOneDayAgo.
  ///
  /// In en, this message translates to:
  /// **'Expired 1 day ago'**
  String get expiredOneDayAgo;

  /// No description provided for @expiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Expired {days} days ago'**
  String expiredDaysAgo(Object days);

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @expiresInOneDay.
  ///
  /// In en, this message translates to:
  /// **'Expires in 1 day'**
  String get expiresInOneDay;

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String expiresInDays(Object days);

  /// No description provided for @expiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredStatus;

  /// No description provided for @urgentStatus.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentStatus;

  /// No description provided for @expiringSoonStatus.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get expiringSoonStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @failedToLoadWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Failed to load workspaces: {error}'**
  String failedToLoadWorkspaces(Object error);

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @enterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmailAddress;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @enterEmailResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email to reset password'**
  String get enterEmailResetPassword;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get passwordResetEmailSent;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Please try again.'**
  String get failedToSendResetEmail;

  /// No description provided for @signInToSyncAcrossDevices.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data across devices'**
  String get signInToSyncAcrossDevices;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidEmailOrPassword;

  /// No description provided for @verifyEmailBeforeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before signing in'**
  String get verifyEmailBeforeSignIn;

  /// No description provided for @networkErrorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection'**
  String get networkErrorCheckConnection;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later'**
  String get tooManyAttempts;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again'**
  String get signInFailed;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @accountCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreatedTitle;

  /// No description provided for @accountCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully.\n\nPlease check your email and click the verification link to activate your account.\n\nAfter verification, you can sign in to start using the app.'**
  String get accountCreatedMessage;

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to Sign In'**
  String get goToSignIn;

  /// No description provided for @emailVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerifiedTitle;

  /// No description provided for @emailVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your email has been verified successfully. You can continue using the app now.'**
  String get emailVerifiedMessage;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAccountToSync.
  ///
  /// In en, this message translates to:
  /// **'Create your account to sync across devices'**
  String get createAccountToSync;

  /// No description provided for @verifyEmailBeforeSignInHint.
  ///
  /// In en, this message translates to:
  /// **'You will need to verify your email before signing in'**
  String get verifyEmailBeforeSignInHint;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordCallbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reset link is valid. Enter a new password to complete the recovery process.'**
  String get resetPasswordCallbackMessage;

  /// No description provided for @resetPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get resetPasswordAction;

  /// No description provided for @passwordResetCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordResetCompleteTitle;

  /// No description provided for @passwordResetCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated successfully.'**
  String get passwordResetCompleteMessage;

  /// No description provided for @displayNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Display Name (Optional)'**
  String get displayNameOptional;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get displayNameHint;

  /// No description provided for @atLeastSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeastSixCharacters;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reenterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterYourPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailAlreadyRegistered;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please use a stronger password'**
  String get weakPassword;

  /// No description provided for @genericTryAgainError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again'**
  String get genericTryAgainError;

  /// No description provided for @transactionSavedReceiptUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved, but receipt upload failed.'**
  String get transactionSavedReceiptUploadFailed;

  /// No description provided for @transactionSavedReceiptUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved, but receipt update failed.'**
  String get transactionSavedReceiptUpdateFailed;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(Object error);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @receiptWillBeRemovedOnSave.
  ///
  /// In en, this message translates to:
  /// **'Receipt will be removed when you save.'**
  String get receiptWillBeRemovedOnSave;

  /// No description provided for @onlyCreatorCanChangeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Only the transaction creator can change the receipt.'**
  String get onlyCreatorCanChangeReceipt;

  /// No description provided for @confirmDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get confirmDeleteTransaction;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noTransactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get noTransactionsThisMonth;

  /// No description provided for @noTransactionsNearestDate.
  ///
  /// In en, this message translates to:
  /// **'No transactions. Showing nearest date: {date}'**
  String noTransactionsNearestDate(Object date);

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories: {error}'**
  String errorLoadingCategories(Object error);

  /// No description provided for @errorLoadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Error loading transactions: {error}'**
  String errorLoadingTransactions(Object error);

  /// No description provided for @amountRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get amountRequiredError;

  /// No description provided for @limitRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter limit'**
  String get limitRequiredError;

  /// No description provided for @selectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select category'**
  String get selectCategoryError;

  /// No description provided for @categoryNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter category name'**
  String get categoryNameRequiredError;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No route defined for {route}'**
  String routeNotFound(Object route);

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @budgetOverview.
  ///
  /// In en, this message translates to:
  /// **'Budget Overview'**
  String get budgetOverview;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get onTrack;

  /// No description provided for @nearLimit.
  ///
  /// In en, this message translates to:
  /// **'Near Limit'**
  String get nearLimit;

  /// No description provided for @noBudgetsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No budgets match this filter'**
  String get noBudgetsMatchFilter;

  /// No description provided for @byUsagePercent.
  ///
  /// In en, this message translates to:
  /// **'By Usage %'**
  String get byUsagePercent;

  /// No description provided for @byAmount.
  ///
  /// In en, this message translates to:
  /// **'By Amount'**
  String get byAmount;

  /// No description provided for @byName.
  ///
  /// In en, this message translates to:
  /// **'By Name'**
  String get byName;

  /// No description provided for @editBudgetAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get editBudgetAction;

  /// No description provided for @startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your finances'**
  String get startTracking;

  /// No description provided for @noTransactionsMatch.
  ///
  /// In en, this message translates to:
  /// **'No transactions match your search'**
  String get noTransactionsMatch;

  /// No description provided for @createFirstBudget.
  ///
  /// In en, this message translates to:
  /// **'Create your first budget to track your spending'**
  String get createFirstBudget;

  /// No description provided for @addBudgetAction.
  ///
  /// In en, this message translates to:
  /// **'Add Budget'**
  String get addBudgetAction;

  /// No description provided for @adjustSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get adjustSearchTerms;

  /// No description provided for @noExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'No Expense'**
  String get noExpenseTitle;

  /// No description provided for @noIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'No Income'**
  String get noIncomeTitle;

  /// No description provided for @noExpenseTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No expense transactions found'**
  String get noExpenseTransactionsFound;

  /// No description provided for @noIncomeTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No income transactions found'**
  String get noIncomeTransactionsFound;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String versionLabel(Object version, Object buildNumber);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
