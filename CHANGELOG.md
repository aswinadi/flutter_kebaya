# Changelog - Caroline Lauda Portal (Flutter Client)

All notable changes to the Flutter client application of the Caroline Lauda Kebaya Rental System will be documented in this file.

---

## [1.6.0] - 2026-07-13
### Added
- **Shopping Cart & Checkout Wizard Flow (`CheckoutTab` & `MixMatchTab`)**:
  - Implemented global state management using `RentalProvider` to handle shopping carts.
  - Added a "Masukkan ke Keranjang" button in the Mannequin preview footer of `MixMatchTab` to queue selected tops and bottoms.
  - Added a reactive Floating Action Button (FAB) showing the current cart item count.
  - Refactored `CheckoutTab` into a 2-step checkout wizard (Step 1: review cart, edit custom prices, and search catalog; Step 2: customer details form, event date selector, fitting photo upload, and save transaction with backend Job Order integration).
- **Fitting Photo Gallery Tab (`FittingGalleryTab`)**:
  - Created a new `FittingGalleryTab` showing a grid layout of client fitting photos.
  - Grouped and filterable by month using a dynamic horizontal chip list populated from database events.
  - Displays Invoice Number, Event Date, Event/Customer Name, and gowns rented, with a full-screen zoom preview dialog.
- **Interactive Click-to-Zoom Previews**:
  - Added interactive click-to-zoom previews on clothing item thumbnails in `JobOrderDetailsPane`.
  - Displayed client fitting photo in `JobOrderDetailsPane` with click-to-zoom options.
- **Rentals Chronological Sorting**:
  - Sorted the rentals list in `RentalsTab` by closest event date: upcoming events sorted ascending at the top, past events sorted descending at the bottom.

### Fixed
- **Layout Overflow Fixes**:
  - Replaced Row with Wrap on item card price & availability row in `MixMatchTab` to prevent overflow in narrow views.
  - Wrapped "PRATINJAU PAKAIAN" header in `mix_match_tab.dart` with `Expanded` to prevent right overflow when the "RESET" button appears.
  - Refactored `CheckoutTab` cart panel to use `SingleChildScrollView` and dynamic shrink-wrapped ListViews instead of `Expanded` inside a fixed Column, preventing bottom overflows when the Android keyboard pops up.

## [1.5.0] - 2026-06-14
### Added
- **Simplified Navigation & Home Tab Dashboard (`HomeTab`)**:
  - Re-architected client navigation to simplify the bottom navigation bar and sidebar rail down to 4 core tabs: Beranda (Home), Transaksi (Rental), Jadwal (Calendar), and Pengaturan (Setting).
  - Designed a premium grid-based Home tab dashboard featuring quick stats, date indicators, welcome cards, and shortcut buttons to navigate to sub-pages (Kasir POS, Padu Padan, Katalog, Pekerjaan, Karyawan).
  - Added back button logic to the top AppBar for all sub-pages and intercepting Android back presses with `PopScope` to return to Home.
  - Made the `SettingsTab` accessible to all users, showing profile info for everyone and restricting the date locking period config form to owners.
- **Rental Transaction Management Menu (`RentalsTab`)**:
  - Implemented a dedicated "Transaksi" (Transactions) tab visible to all users (owners and workers).
  - Displays Invoice Number, Event Date, Customer Name/Phone, Notes, Gowns list, and Total Amount (only visible to owners).
  - Supports dynamic query searching and filtering by transaction status (Dipesan, Diambil, Kembali, Batal, Void).
  - Built full **Edit** capabilities (updating customer details, date, status, notes, and **removing/adding rental gowns** inside the transaction) and quick **Void** operations directly from the list view.
- **Dedicated System Settings Tab (`SettingsTab`)**:
  - Added a dedicated "Pengaturan" tab visible to all users to configure the reservation date locking period (owner only) and view user profiles.
- **Indonesian Localization**:
  - Localized 100% of the customer and worker interfaces into Indonesian (navigation, catalog, checkout, calendar, status labels).
- **Multi-Photo Upload Support**:
  - Replaced single-photo capture with camera/gallery multi-selection tools for client outfit fitting and gown condition photos.
- **Dynamic Tags & Filtering**:
  - Enabled comma-separated tagging for gowns and interactive filter chips displaying tag counts in the catalog search bar.
- **Custom Free-text Sizes**:
  - Swapped size dropdowns for custom free-text input fields in inventory management.
- **Multi-Keyword Search**:
  - Upgraded inventory search to split input queries into tokens and match them across gown names, SKUs, colors, description, tags, and sizes.
- **Employee Management Updates**:
  - Added worker profile edit modals and password modification options in the Employee tab.

### Changed
- **Exclude Void/Cancelled Transactions**:
  - Updated calendar day list logic and mix & match dead zones to completely ignore voided and cancelled transactions.
- **Custom Sidebar**:
  - Replaced the built-in `NavigationRail` with a custom scrollable sidebar to prevent viewport vertical height overflows and layout compression issues on small screens.

### Fixed
- **Dropdown and Text Layout Overflows**:
  - Fixed calendar card legends, month chevrons, and text alignment wrapping under small viewports.

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
