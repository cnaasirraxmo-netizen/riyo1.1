# Notification Icon Setup Instructions

To follow Android's professional notification guidelines, your notification icon must be a **white-only mask** on a **transparent background**.

## Step 1: Create the Source Image
1. Take your app's "R" logo.
2. Convert it to strictly white (hex #FFFFFF).
3. Ensure the rest of the image is 100% transparent.
4. Save it as `ic_notification.png`.

## Step 2: Generate Densities
Place the following sizes of `ic_notification.png` in their respective folders:

| Density | Size (px) | Path |
| :--- | :--- | :--- |
| mdpi | 24x24 | `android/app/src/main/res/drawable-mdpi/ic_notification.png` |
| hdpi | 36x36 | `android/app/src/main/res/drawable-hdpi/ic_notification.png` |
| xhdpi | 48x48 | `android/app/src/main/res/drawable-xhdpi/ic_notification.png` |
| xxhdpi | 72x72 | `android/app/src/main/res/drawable-xxhdpi/ic_notification.png` |
| xxxhdpi | 96x96 | `android/app/src/main/res/drawable-xxxhdpi/ic_notification.png` |

## Step 3: Automated Regeneration
To automatically derive the notification icon from the main APK logo if you have a source `icon.png`:
- Use the **Android Asset Studio** (https://romannurik.github.io/AndroidAssetStudio/icons-notification.html)
- Upload your logo.
- Name it `ic_notification`.
- Download the zip and extract to `android/app/src/main/res/`.

## Flutter Configuration
The app is already configured in `lib/services/notification_service.dart` to use `@drawable/ic_notification`. Once you place the files, notifications will automatically show the stylized "R" in the status bar.
