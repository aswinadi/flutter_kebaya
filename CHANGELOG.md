# Changelog - Caroline Lauda Portal (Flutter Client)

All notable changes to the Flutter client application of the Caroline Lauda Kebaya Rental System will be documented in this file.

---

## [1.4.0] - 2026-05-30
### Added
- **New Mix & Match Product Catalogue**:
  - Implemented a responsive "Mix & Match" catalogue screen supporting a hybrid selection flow (browse first or filter by date first).
  - Built a 3-pane layout for desktop/tablet: left pane for Tops, right pane for Bottoms, and a stacked center pane displaying a mannequin preview card (640px height) and a monthly availability calendar.
  - Added a monthly calendar grid checking item bookings dynamically. Displays orange indicator dots when the selected top is blocked, and red dots when the selected bottom is blocked (under $\pm 14$ days rule).
  - Added header Date Filter that highlights available items with an `[Available]` badge, dims booked items, and labels them with a `[Reserved]` badge.
  - Configured tabbed vertical scrolling lists for mobile viewports.
  - Added widget tests validating catalog listing, outfit preview selection, and total price calculation.
- **Username-Based Authentication**:
  - Swapped email inputs with username text fields on the login screen.
  - Added app version label `Version 1.0.0 (Build 1)` to the login screen.
- **Default Ngrok API Host**:
  - Configured the development entrypoint `main.dart` and `api_service.dart` to default fallback to the Ngrok tunnel `https://biogeographic-raylan-interdentally.ngrok-free.dev`.

### Changed
- **Dashboard Navigation**:
  - Registered "Mix & Match" as the second tab inside the mobile bottom navigation bar and tablet side navigation rail.

---

## [1.3.0] - 2026-05-30
### Added
- **Pickup & Deadline Time Selectors**:
  - Picking a date during Mix-and-Match checkout now opens a time picker, allowing POS workers to specify the exact pickup hour (defaulting to 10:00 AM on cancel).
  - Picking a due date on alteration technical controls now prompts owners with a time picker to track exact completion deadlines.
  - Display formats updated to show `EEEE, MMMM d, y • HH:mm` for pickup times and `d MMM y • HH:mm` for job deadlines.
- **Calendar Block Period Dash Markers**:
  - The schedule calendar cell now displays horizontal dashes of the transaction's unique color to visualize active block/buffer periods ($\pm 14$ days).
  - Selected day cells render subtle white outlines around dot and dash indicators to pop clearly on the dark purple background.
- **Job Order Integration on Details Card**:
  - The calendar details cards now fetch and display related alteration details: item name/SKU, status badges (`PENDING`, `IN PROGRESS`, `COMPLETED`), custom technical instructions, deadlines, and total tailor man-days logged.
  - Formatted layout into clean **Active Bookings** and **Blocking / Buffer Periods** subsections.
- **High-Contrast Text Safety**:
  - Enforced explicit dark styling (`Colors.black87`, `Colors.grey[700]`, and `Colors.grey[800]`) on all schedule panel card elements to guarantee sharp text visibility regardless of system theme/dark mode overrides.

### Changed
- **Branding Renaming**:
  - Updated all title and label references to **Caroline Lauda**.

---

## [1.2.0] - 2026-05-30
### Added
- **Multi-Environment Entries**:
  - Created `AppConfig` and separate entries: `main_dev.dart` (local serve) and `main_prod.dart` (cloud server).
  - Displays a red `DEV` debug banner in the top-right corner on development builds.
- **Checkout Availability Checks**:
  - Integrated `/api/rentals/availability` calls on date selection to disable blocked items and prevent double-booking.
- **Reservation Calendar Schedule Tab**:
  - Added custom monthly calendar view tab with mobile/tablet responsive layouts.
  - Navigation entries added to bottom navigation bar (mobile) and navigation rail (tablet).

### Fixed
- **Dropdown Width Overflows**:
  - Added `isExpanded: true` to category and size dropdown form fields in `inventory_form_screen.dart` and `inventory_tab.dart` filters to prevent layout overflow warnings.
