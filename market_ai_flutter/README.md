# MarketAI Flutter App

A responsive Flutter UI implementation of the supplied 20-screen MarketAI reference. It is designed for Android and iOS and uses only Flutter SDK components, so there are no third-party package dependencies.

## Included screens

1. Mobile login
2. OTP verification with custom keypad
3. Profile information
4. Social account connection
5. Business details
6. Home dashboard
7. AI search/prompt
8. Competitor analysis report
9. Create ad from analysis
10. Ad setup
11. AI post creator
12. Generated post preview
13. Schedule/publish post
14. Leads manager
15. ROI tracker with custom chart
16. Reports
17. Report details
18. Settings
19. Subscription plan
20. Help and support

## Run on Windows / Android

1. Extract this folder.
2. Make sure Flutter and Android Studio are installed and `flutter doctor` is clean.
3. Double-click `setup_and_run.bat`, or run it from Command Prompt.

The script generates standard Android/iOS platform files when they are missing, runs `flutter pub get`, and starts the app.

## Run on macOS / iOS

From Terminal inside the project folder:

```bash
./setup_and_run.sh
```

An iOS build requires macOS, Xcode, an Apple development team, and an iPhone or Simulator.

## Manual commands

```bash
flutter create --platforms=android,ios --org com.marketai --project-name market_ai .
flutter pub get
flutter run
```

## Demo behavior

- Enter any valid-looking mobile number.
- Enter any six OTP digits using the built-in keypad.
- Buttons, tabs, dropdowns, filters, dialogs, date/time pickers, navigation, lead details, report actions, post scheduling, plan selection, and settings flows work locally.

## Production integrations still required

The screenshot contains product flows, not API credentials or backend specifications. Therefore these external operations are represented as safe demo interactions:

- Real SMS OTP and authentication
- Facebook/Instagram OAuth
- Competitor data collection and AI model calls
- Meta/Google advertising account publishing
- Social post publishing and scheduling jobs
- Database, file storage, analytics, notifications, payments, email, chat, and phone integrations

Those cannot be made genuinely operational from a screenshot alone. The UI and navigation layer is ready for those services to be connected.
