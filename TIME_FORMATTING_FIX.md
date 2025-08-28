# Time Formatting Fix for Printer Service

## Problem Description

The check-in stickers were displaying time in 24-hour format (e.g., "05:56") instead of the expected 12-hour format with AM/PM (e.g., "01:56 PM"). Additionally, the time was being displayed in UTC instead of the local timezone, causing an 8-hour difference (e.g., 6:00 AM instead of 2:00 PM).

## Root Cause

The `_formatTime` method in `PrinterService` was using 24-hour format and not converting UTC time to local timezone:
```dart
String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
```

This resulted in times like:
- 13:00 instead of 01:00 PM
- 05:56 instead of 05:56 AM
- 00:30 instead of 12:30 AM
- **6:00 AM (UTC) instead of 2:00 PM (local time)** - 8-hour timezone difference

## Solution Implemented

Updated the `_formatTime` method to properly format time in 12-hour format with AM/PM and convert UTC to local timezone:

```dart
String _formatTime(DateTime dateTime) {
  // Convert UTC time to local timezone
  final localDateTime = dateTime.toLocal();
  
  final hour = localDateTime.hour;
  final minute = localDateTime.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  
  // Convert to 12-hour format
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  
  return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
}
```

## How It Works

### **Time Conversion Logic:**
1. **Convert UTC to local timezone** using `dateTime.toLocal()`
2. **Extract hour and minute** from local DateTime
3. **Determine AM/PM** based on hour (≥12 = PM, <12 = AM)
4. **Convert to 12-hour format:**
   - 0 → 12 (midnight)
   - 1-11 → 1-11 (morning)
   - 12 → 12 (noon)
   - 13-23 → 1-11 (afternoon/evening)
5. **Format with padding** and AM/PM suffix

### **Examples:**
- **00:00 UTC** → "12:00 AM" (midnight local time)
- **05:56 UTC** → "05:56 AM" (early morning local time)
- **12:00 UTC** → "12:00 PM" (noon local time)
- **13:00 UTC** → "01:00 PM" (1 PM local time)
- **23:30 UTC** → "11:30 PM" (11:30 PM local time)

**Timezone Conversion Example:**
- **6:00 AM UTC** → **2:00 PM Local Time** (8-hour difference)

## Affected Areas

This fix affects all printed check-in stickers:

1. **Child Check-in Stickers** - Time displayed in header
2. **Guardian Check-in Stickers** - Time displayed in header
3. **Any other printed materials** using the `_formatTime` method

## Testing

### **Test Cases:**
1. **Morning times** (00:00 - 11:59) → Should show AM
2. **Noon** (12:00) → Should show "12:00 PM"
3. **Afternoon/Evening** (12:01 - 23:59) → Should show PM
4. **Midnight** (00:00) → Should show "12:00 AM"

### **Expected Results:**
- **Before fix**: "05:56" (24-hour format, UTC time)
- **After fix**: "05:56 AM" (12-hour format with AM/PM, local timezone)
- **Timezone fix**: 6:00 AM UTC now correctly shows as 2:00 PM local time

## Benefits

1. **User-friendly**: More familiar 12-hour format for most users
2. **Clear AM/PM**: Eliminates confusion about morning vs evening
3. **Correct timezone**: Shows local time instead of UTC
4. **Consistent**: Matches common time display conventions
5. **Professional**: Better appearance on printed materials

## Implementation Details

- **File**: `lib/core/services/printer_service.dart`
- **Method**: `_formatTime(DateTime dateTime)`
- **Change**: Simple method update, no breaking changes
- **Dependencies**: None, uses only DateTime properties

## Future Considerations

If you need different time formats in the future, consider:

1. **Adding format parameter** to support multiple formats
2. **Localization** for different regional preferences
3. **Configurable format** in app settings
4. **Time zone handling** for multi-location churches

## Conclusion

The time formatting issue has been resolved. Check-in stickers will now display time in the proper 12-hour format with AM/PM indicators and correct local timezone, making them more user-friendly and professional-looking.

**Example Output:**
- ✅ **Before**: "05:56" (unclear if AM or PM, UTC time)
- ✅ **After**: "05:56 AM" (clear morning time, local timezone)
- ✅ **Timezone**: 6:00 AM UTC now correctly shows as 2:00 PM local time
