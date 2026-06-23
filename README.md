# BadmintonSphere 🏸

A cross-platform badminton court booking app built with **Flutter** and powered by **Supabase**. Users can browse courts, register an account, book time slots (with optional add-ons), and manage their bookings. Admins get a dashboard to manage users and view all bookings.

## Features

### For Users
- Browse available courts with photos, pricing (RM/hour), capacity, and facilities
- Register and log in
- Book a court by date, start/end time, and duration
- Add optional extras (add-ons) to a booking
- View, edit, and cancel personal bookings
- Manage profile details

### For Admins
- Separate admin login (role-based)
- Admin dashboard listing all users and their bookings
- Edit and delete users

## Tech Stack

| Layer        | Technology |
|--------------|------------|
| Frontend     | Flutter (Dart `^3.8.1`), Material Design |
| Backend / DB | [Supabase](https://supabase.com) (PostgreSQL + REST) |
| Config       | `flutter_dotenv` for environment variables |
| Local cache  | `sqflite` |

Key packages: `supabase_flutter`, `flutter_dotenv`, `sqflite`, `path`, `cupertino_icons`.

## Project Structure

```
.
├── backend/                  # Supabase service-role config (.env only)
└── eventsphere/              # Flutter application
    ├── lib/
    │   ├── main.dart                 # App entry point + Supabase init
    │   ├── database/
    │   │   └── supabase_service.dart # All Supabase queries (users, courts, addons, bookings)
    │   ├── models/                   # Data models: User, Admin, Court, Addon, Booking
    │   └── screens/                  # UI screens (home, login, register, booking, dashboards, profile…)
    └── assets/                       # Court images
```

## Data Model

The app expects the following Supabase (PostgreSQL) tables:

- **users** — `id`, `full_name`, `email`, `phone`, `username`, `password`, `role` (`user` | `admin`)
- **courts** — `id`, `court_name`, `court_type`, `price_per_hour`, `capacity`, `facilities`
- **addons** — `id`, `addon_name`, `description`, `price`
- **bookings** — `id`, `user_id`, `court_id`, `booking_date`, `start_time`, `end_time`, `duration_hours`, `base_price`, `addons_total`, `total_amount`, `status`, `booked_at`
- **booking_addons** — join table linking `booking_id` ↔ `addon_id`

> ⚠️ **Security note:** This project stores and compares passwords as plain text and authenticates against the `users` table directly. This is fine for a learning/demo project, but do **not** use this approach in production. Use Supabase Auth and hashed passwords instead.

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.8.1`)
- A [Supabase](https://supabase.com) project with the tables above

### Setup

1. **Clone the repo**
   ```bash
   git clone <repo-url>
   cd Eventbooking-app-main/eventsphere
   ```

2. **Create the `.env` file** in `eventsphere/`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

   The `backend/.env` holds the service-role key (server-side only — never ship this in the app):
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration Notes

- The `.env` file is registered as a Flutter asset in `pubspec.yaml`, so it is bundled into the app at build time.
- Court images in `assets/` are matched to courts by name (e.g. "Court A" → `assets/courtA.jpg`). Courts without a matching image fall back to a default gradient placeholder.
- Prices are displayed in Malaysian Ringgit (RM).

## License

This project is provided as-is for educational purposes.
