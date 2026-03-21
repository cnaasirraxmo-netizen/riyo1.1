# Firebase Analytics Verification Guide

To ensure that Google Analytics is properly receiving data, follow these steps to verify and debug the implementation.

## 1. Enable DebugView on Android
To see events in real-time in the Firebase Console's "DebugView", run the following command via ADB:

```bash
adb shell setprop debug.firebase.analytics.app com.riyo.app
```

To disable debug mode:
```bash
adb shell setprop debug.firebase.analytics.app .none.
```

## 2. Enable DebugView on iOS
1. In Xcode, select **Product** > **Scheme** > **Edit Scheme...**
2. Select **Run** from the left menu.
3. Select the **Arguments** tab.
4. In the **Arguments Passed On Launch** section, add:
   `-FIRDebugEnabled`

To disable debug mode:
   `-FIRDebugDisabled`

## 3. Verify in Firebase Console
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select your project.
3. Navigate to **Analytics** > **DebugView**.
4. Interact with your app (open screens, click buttons).
5. You should see events appearing on the timeline within seconds.

## 4. Check Google Analytics (GA4)
1. Go to the [Google Analytics dashboard](https://analytics.google.com/).
2. Select the GA4 property linked to your Firebase project.
3. Check the **Real-time** report to see active users and event counts.
   *Note: It may take up to 24-48 hours for data to populate in standard reports.*

## 5. Implementation Details
* **Automatic Screen Tracking**: Handled by `FirebaseAnalyticsObserver` in `lib/main.dart`.
* **Custom Events**: Centralized in `lib/services/analytics_service.dart`.
* **User Properties**: Can be set using `AnalyticsService.setUserProperty()`.
