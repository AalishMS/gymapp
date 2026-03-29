# Issues Report

## Issue 1: RenderFlex Overflow in workout_screen.dart

**File:** `lib/screens/workout_screen.dart`  
**Line:** 727-749 (the `title` property of ListTile)  
**Root Cause:** The `Row` widget inside the `title` property of a `ListTile` has no width constraints. The Row's content (weight/reps text + optional RPE container) exceeds the available 139.4 pixels by 1.3 pixels.

**Current Code (lines 727-749):**
```dart
title: Row(
  children: [
    Text('${set.weight} kg x ${set.reps}'),
    if (set.rpe != null) ...[
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getRpeColor(set.rpe!).withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'RPE ${set.rpe}',
          style: TextStyle(fontSize: 10, color: _getRpeColor(set.rpe!)),
        ),
      ),
    ],
  ],
),
```

**Fix Steps:**
1. Wrap the `Row` with `Expanded` to constrain it to available space

**Status:** Fixed ✅
   ```dart
   title: Expanded(
     child: Row(
       children: [
         Text('${set.weight} kg x ${set.reps}'),
         if (set.rpe != null) ...[
           const SizedBox(width: 8),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
             decoration: BoxDecoration(
               color: _getRpeColor(set.rpe!).withOpacity(0.2),
               borderRadius: BorderRadius.circular(4),
             ),
             child: Text(
               'RPE ${set.rpe}',
               style: TextStyle(fontSize: 10, color: _getRpeColor(set.rpe!)),
             ),
           ),
         ],
       ],
     ),
   ),
   ```

---

## Issue 2: Widget Test Failure

**File:** `test/widget_test.dart`  
**Line:** 1-30 (entire file)  
**Root Cause:** The test is the default Flutter counter app test that:
1. Does not initialize Hive before running the app
2. Tests for a counter widget that doesn't exist in the gymapp

**Error Details:**
- `HiveError: Box not found. Did you forget to call Hive.openBox()?`
- The test expects text "0" which doesn't exist in the gymapp

**Fix Steps:**
1. Replace the test file with proper gymapp tests that:
   - Initialize Hive using `Hive.initFlutter()` before pumpWidget
   - Test actual gymapp functionality (e.g., app renders without error)

**Status:** Fixed ✅

---

## Summary

| Issue | File | Line(s) | Severity | Status |
|-------|------|---------|----------|--------|
| RenderFlex overflow | workout_screen.dart | 727 | Medium (visual glitch) | Fixed |
| Test failure | widget_test.dart | All | High (blocks CI) | Fixed |
