# Caroline Lauda Portal (Flutter Client)

A cross-platform Flutter application for the Caroline Lauda Kebaya Rental POS checkouts, inventory tracking, and tailor production alterations.

---

## Features

### 1. Interactive Product Catalogue & Inventory
- Search and filter gown pieces by category (top/bottom) and sizes.
- Detailed gown cards showing SKU, descriptions, and rental rates (restricted to Owner).

### 2. POS Mix-and-Match Checkout
- Real-time gown conflict checks (enforcing 28-day block buffer rules).
- Live camera integration for client fitting photos and pre-rental condition photos (audit trail).
- Date & time picker to set pickup schedule.

### 3. Production & Alteration Jobs
- Lists alteration tasks chronologically by deadline.
- Detailed control pane: status tracker (`PENDING`, `IN PROGRESS`, `COMPLETED`), deadline editor, technical notes editor, and labor logs.
- Worker labor logging (tagging man-days, specialty craft categories, and comments).

### 4. Reservation Schedule Calendar
- Responsive calendar view tab (split view on tablet/desktop, stacked list on mobile).
- Mapped transaction colors representing different bookings.
- **Dots vs Dashes**: Displays solid dots on actual event pickup dates, and horizontal dashes for the $\pm 14$ days dead-zone buffer periods.
- Dual-section details panel listing Active Bookings and Blocking Periods with left-accent borders of matching transaction colors.

### 5. Catalogue Mix & Match
- A responsive 3-pane interactive screen to visually stack top and bottom items to preview outfits (mannequin preview).
- Integrates a monthly calendar grid displaying specific reservation block-periods (orange dots for tops, red dots for bottoms).
- Header Date Filter dims booked items and shows availability status badges.

---

## Getting Started

### Prerequisites
- Flutter SDK (stable version)
- Dart SDK

---

## Environment Entry Points

The app is built with a multi-environment setup. Choose the appropriate entry point:

### 1. Development Environment
Connects to development Ngrok tunnel `https://biogeographic-raylan-interdentally.ngrok-free.dev` by default and overlays a red `DEV` debug banner in the top-right corner.
- **Run command**:
  ```bash
  flutter run -t lib/main_dev.dart
  ```

### 2. Production Environment
Connects to production host `https://api.cenini-kebaya.com`.
- **Run command**:
  ```bash
  flutter run -t lib/main_prod.dart
  ```

---

## Verification
### 1. Static Analysis
Run Linter and Dart static analyzer checks:
```bash
flutter analyze
```

### 2. Running Widget Tests
Run the client widget smoke and logic tests:
```bash
flutter test
```
