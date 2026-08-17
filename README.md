# Finance Tracker

Flutter app for tracking money lent (udhari) and personal expenses in Indian Rupees (₹).

## Features

- Sign up / sign in (Laravel Sanctum)
- Dashboard with pending udhari, received credit, and expense totals
- Unified ledger for credit given and expenses
- Person management
- Mark credit as received with date and note

## Setup

```bash
cd D:\finance-tracker
flutter pub get
flutter run
```

Start the backend first (see [finance-tracker-backend](../finance-tracker-backend)).

Default API URL: `http://127.0.0.1:8000/api`  
Android emulator: `http://10.0.2.2:8000/api`

## Tech

- Flutter + Provider
- INR formatting via `intl` `en_IN` locale
