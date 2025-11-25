// path: README_REPORT.md

# Report Calendar Screen

## Overview
This module implements a calendar-based transaction report screen matching the design specifications from `/mnt/data/5ea94648-5d90-4ba0-a066-03611ff9eeb5.jpg`.

## Features
- **Calendar Month View**: Displays dates with income/expense badges
- **Month Navigation**: Navigate between months using chevrons
- **Summary Bar**: Shows total income, expense, and net for the period
- **Transaction List**: Grouped by date with category icons and amounts
- **Interactions**:
  - Tap date cell to scroll to transactions for that day
  - Long-press transaction for Edit/Delete/Share menu
  - Pull-to-refresh to reload data
  - Delete confirmation dialog

## Visual Design
- **Colors**:
  - Income: Blue (#2196F3)
  - Expense: Orange-red (#FF6B3D)
  - Selected date: Pale pink (#FFE4E8)
  - Today: Light gray border
- **Layout**: Calendar grid (7 columns Mon-Sun) with transaction list below
- **Formatting**: Vietnamese locale, currency symbol 'đ'

## Files Structure
```
lib/src/
├── ui/
│   ├── screens/
│   │   └── report_calendar_screen.dart    # Main screen
│   └── widgets/
│       ├── calendar_grid.dart             # Calendar month grid
│       ├── calendar_date_cell.dart        # Individual date cell
│       ├── summary_bar.dart               # Income/Expense/Net summary
│       ├── transaction_group_header.dart  # Date group header
│       ├── transaction_list_item.dart     # Transaction row
│       └── confirm_delete_dialog.dart     # Delete confirmation
├── providers/
│   └── report_providers.dart              # Riverpod state management
├── services/
│   └── report_service.dart                # Data fetching service
└── theme/
    └── report_theme.dart                  # Colors and styles

test/
└── report_calendar_widget_test.dart       # Widget tests
```

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Localizations (if needed)
```bash
flutter gen-l10n
```

### 3. Wire into App Router
Add to `lib/src/app_router.dart`:
```dart
case '/report-calendar':
  return MaterialPageRoute(builder: (_) => const ReportCalendarScreen());
```

### 4. Add Navigation from Home
In `lib/src/ui/screens/home_screen.dart` or navigation menu:
```dart
Navigator.pushNamed(context, '/report-calendar');
```

### 5. Database Integration (TODO)
The `report_service.dart` currently uses stub data and the existing transaction repository. To integrate with actual Drift queries:

1. Open `lib/src/services/report_service.dart`
2. Replace stub methods with actual Drift queries:
   - `getCalendarData()`: Query transactions grouped by date
   - `getMonthlySummary()`: Aggregate income/expense sums
   - `getTransactionGroups()`: Fetch and group transactions by date

Example Drift query for calendar data:
```dart
final transactions = await (db.select(db.transactions)
  ..where((t) => t.date.isBetweenValues(startDate, endDate))
  ..orderBy([(t) => OrderingTerm.desc(t.date)]))
  .get();
```

## Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/report_calendar_widget_test.dart

# Run with coverage
flutter test --coverage
```

## Usage Example
```dart
// Navigate to report screen
Navigator.pushNamed(context, '/report-calendar');

// Or use directly
MaterialPageRoute(builder: (_) => const ReportCalendarScreen());
```

## Provider Usage
The screen uses several Riverpod providers:
- `selectedMonthProvider`: Current selected month
- `selectedDateProvider`: Currently selected date in calendar
- `calendarDataProvider`: Calendar cell data with badges
- `monthlySummaryProvider`: Monthly income/expense/net totals
- `transactionGroupsProvider`: Transaction list grouped by date
- `transactionListNotifierProvider`: Actions (refresh, delete, navigate months)

## Customization
To customize colors, spacing, or text styles, edit `lib/src/theme/report_theme.dart`.

## Notes
- Date range follows design: 15th of previous month to 14th of next month
- All amounts stored as integer cents for precision
- Display formatting uses `intl` package with Vietnamese locale
- Calendar starts weeks on Monday (T2) as per Vietnamese convention
- Supports dark mode via AppTheme integration

## Reference
Visual design reference: `/mnt/data/5ea94648-5d90-4ba0-a066-03611ff9eeb5.jpg`

## Compatibility
- Flutter SDK: 3.32.7+
- Dart: 3.0.0+
- Dependencies: hooks_riverpod, drift, intl, flutter_hooks

