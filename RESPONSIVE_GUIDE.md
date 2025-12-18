# Auto Dimension (Responsive Design) - Usage Guide

## Overview
The Responsive utility class provides automatic dimension scaling based on screen size, ensuring your app looks great on all devices.

## Setup

### 1. Initialize in App
Add initialization in `app.dart` or `app_bootstrap.dart`:

```dart
@override
Widget build(BuildContext context) {
  // Initialize responsive dimensions
  Responsive.init(context);
  
  return MaterialApp(...);
}
```

## Usage Examples

### Responsive Width & Height
```dart
// Instead of hardcoded values:
Container(
  width: 100,
  height: 50,
)

// Use responsive values:
Container(
  width: Responsive.width(100),
  height: Responsive.height(50),
)
```

### Responsive Font Size
```dart
// Instead of:
Text(
  'Hello',
  style: TextStyle(fontSize: 16),
)

// Use:
Text(
  'Hello',
  style: TextStyle(fontSize: Responsive.sp(16)),
)
```

### Responsive Padding/Margin
```dart
// Instead of:
Padding(
  padding: EdgeInsets.all(16),
  child: ...,
)

// Use:
Padding(
  padding: EdgeInsets.all(Responsive.padding(16)),
  child: ...,
)
```

### Percentage-based Sizing
```dart
// 50% of screen width
Container(
  width: Responsive.widthPercent(50),
)

// 30% of screen height
Container(
  height: Responsive.heightPercent(30),
)
```

### Device-specific Values
```dart
// Different values for different screen sizes
Text(
  'Hello',
  style: TextStyle(
    fontSize: Responsive.responsive(
      small: 14,   // phones < 600px
      medium: 16,  // tablets 600-900px
      large: 18,   // large tablets > 900px
    ),
  ),
)
```

### Device Type Checks
```dart
if (Responsive.isTablet) {
  // Show tablet layout
} else if (Responsive.isSmallPhone) {
  // Show compact layout
} else {
  // Show normal phone layout
}
```

## Design Reference
- Reference device: iPhone 14 Pro (393 x 852)
- All values are scaled proportionally from this reference

## Benefits
- ✅ Consistent UI across all devices
- ✅ Better tablet support
- ✅ Automatic scaling
- ✅ Easy to use
- ✅ No manual calculations needed
