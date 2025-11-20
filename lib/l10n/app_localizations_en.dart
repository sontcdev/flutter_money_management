// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Finance Manager';

  @override
  String get login => 'Login';

  @override
  String get loginPin => 'Enter PIN';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get home => 'Home';

  @override
  String get transactions => 'Transactions';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get transactionDetail => 'Transaction Detail';

  @override
  String get budgets => 'Budgets';

  @override
  String get addBudget => 'Add Budget';

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get budgetDetail => 'Budget Detail';

  @override
  String get categories => 'Categories';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get category => 'Category';

  @override
  String get account => 'Account';

  @override
  String get type => 'Type';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get note => 'Note';

  @override
  String get receipt => 'Receipt';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirmDelete => 'Are you sure you want to delete?';

  @override
  String get name => 'Name';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get limit => 'Limit';

  @override
  String get period => 'Period';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get custom => 'Custom';

  @override
  String get consumed => 'Consumed';

  @override
  String get remaining => 'Remaining';

  @override
  String get overdraft => 'Overdraft';

  @override
  String get allowOverdraft => 'Allow Overdraft';

  @override
  String get balance => 'Balance';

  @override
  String get currency => 'Currency';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get total => 'Total';

  @override
  String get byCategory => 'By Category';

  @override
  String get topCategories => 'Top Categories';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get logout => 'Logout';

  @override
  String get budgetExceeded => 'Budget Exceeded';

  @override
  String budgetExceededMessage(String remaining) {
    return 'This transaction would exceed the budget. Remaining: $remaining';
  }

  @override
  String get categoryInUse => 'Category is in use by transactions';

  @override
  String get budgetOverlap => 'Budget overlaps with existing budget';

  @override
  String get required => 'This field is required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get attachReceipt => 'Attach Receipt';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String get share => 'Share';

  @override
  String get export => 'Export';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get noCategories => 'No categories';

  @override
  String get noBudgets => 'No budgets';

  @override
  String get noAccounts => 'No accounts';
}
