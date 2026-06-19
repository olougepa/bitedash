# Bitedash Application Documentation

## Overview

Bitedash is a full-stack restaurant delivery platform that supports:

- **Customers** placing delivery or pickup orders from restaurants.
- **Restaurant owners** managing menus, orders, and restaurant status.
- **Delivery agents** viewing assigned orders and delivery details.
- **Admins** overseeing platform data through a dedicated back-office dashboard.

The app is built from three main parts:

1. `backend/` — Yii2 REST API server.
2. `mobile_app/` — Flutter mobile client for customers, owners, and delivery agents.
3. `admin/` — React admin panel using Material UI.

## Architecture

### Backend

- Framework: **Yii2 Advanced Template** (refactored)
- Language: **PHP 8.1+**
- API Mode: **REST** with versioned module (`v1`)
- JWT support via `firebase/php-jwt`
- Database: **MySQL / MariaDB** with `utf8mb4` and **InnoDB**
- Key API controllers (in `backend/modules/v1/controllers/`):
  - `AuthController` — authentication and token handling
  - `UserController` — user profile and registration
  - `RestaurantController` — restaurant listings and owner restaurant management
  - `MenuItemController` — menu item browsing and updates
  - `OrderController` — order placement, guest orders, and status updates
  - `PaymentController` — payment records and stubs
  - `DeliveryAgentController` — delivery assignments and agent status
  - `NotificationController` — notifications by user category
  - `DocsController` — OpenAPI spec and Swagger UI

Backend routes are declared in `backend/config/web.php` under the `v1` module: `/v1/restaurant`, `/v1/order`, `/v1/user`, `/v1/delivery-agent`, `/v1/payment`, `/v1/notification`, `/v1/menu-item`, `/v1/auth`.

### Mobile App

- Framework: **Flutter**
- Languages: **Dart**
- Key packages:
  - `http` for REST API calls
  - `provider` for state management
  - `flutter_dotenv` for runtime configuration
  - `google_maps_flutter` for delivery tracking and maps
  - `shared_preferences` for local storage
  - `flutter_secure_storage` for secure token storage

The mobile client supports:

- Restaurant discovery
- Menu browsing
- Cart and checkout flows
- Delivery tracking screen
- Guest checkout paths and profile-based authentication
- Push-style notification handling via in-app notification records

### Admin Dashboard

- Framework: **React**
- UI: **Material UI**
- HTTP client: **Axios**
- Routing: **react-router-dom**

The admin portal is designed for:

- Managing restaurants and menu items
- Reviewing orders and payment records
- Viewing notifications and user data
- Wiring front-end actions to the backend REST API

## Database

The database schema is defined in `mysql_schema.sql` and includes tables for:

- `users`
- `addresses`
- `restaurants`
- `menu_categories`
- `menu_items`
- `payment_methods`
- `kyc_records`
- `delivery_agents`
- `orders`
- `order_items`
- `reservations`
- `payments`
- `ratings`
- `promotions`
- `notifications`

The schema uses foreign keys and indexes to support relationships such as:

- users -> restaurants (owner)
- restaurants -> menu_categories -> menu_items
- orders -> restaurants, users, delivery_agents, addresses
- payments -> orders, users, payment_methods
- notifications -> users

Diagrams are included to visualize the app structure:

- `bitedash_use_case_diagram.*`
- `bitedash_class_diagram.*`
- `bitedash_activity_diagram.*`
- `bitedash_sequence_diagram.*`
- `bitedash_er_diagram.*`
- `bitedash_normalized_relational_diagram.*`

## Local Setup

### Prerequisites

- PHP 8.1+
- Composer
- Node.js + npm
- Flutter SDK
- MySQL / MariaDB
- XAMPP or local PHP/Apache if desired

### Backend Setup

1. Install PHP dependencies from project root:

```bash
cd /opt/lampp/htdocs/bitedash
composer install
```

2. Configure database in `common/config/db.php`.

3. Create and import the schema:

```bash
mysql -uroot -h127.0.0.1 -e "CREATE DATABASE IF NOT EXISTS bitedash CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -uroot -h127.0.0.1 bitedash < /opt/lampp/htdocs/bitedash/mysql_schema.sql
```

4. Seed sample data if needed.

5. Start the backend server using your local PHP web server or XAMPP.

### Admin Setup

```bash
cd /opt/lampp/htdocs/bitedash/admin
npm install
npm start
```

The admin uses Create React App and serves on the default development port (usually `http://localhost:3000`).

### Mobile App Setup

```bash
cd /opt/lampp/htdocs/bitedash/mobile_app
flutter pub get
flutter run
```

If the mobile client uses environment variables, ensure `.env` is configured before launch.

## API Endpoints

The application exposes REST resources under the `v1/` module:

- `GET /v1/restaurant`
- `POST /v1/order`
- `GET /v1/order/{id}`
- `POST /v1/auth/login`
- `POST /v1/auth/register`
- `POST /v1/auth/refresh`
- `GET /v1/auth/profile`
- `GET /v1/menu-item`
- `GET /v1/notification`
- `POST /v1/payment`

API responses are JSON-formatted and the backend expects JSON request bodies for REST actions.

## Sample Accounts

Common sample credentials for testing:

- `customer@example.com` / `Test1234!`
- `owner@example.com` / `Test1234!`
- `agent@example.com` / `Test1234!`
- `admin@example.com` / `Test1234!`

## Development Notes

- The backend is configured with pretty URLs and strict route parsing.
- The mobile app uses provider state management and secure token storage for auth.
- The admin UI is a lightweight React dashboard wired to the backend API.
- The database schema includes guest order support via `guest_email` and `guest_token`.

## Useful Commands

- Backend composer install: `composer install`
- Admin start: `npm start`
- Mobile dependency install: `flutter pub get`
- Schema import: `mysql -uroot -h127.0.0.1 bitedash < mysql_schema.sql`

## Diagrams and Assets

You can render the PlantUML files with a PlantUML viewer or VS Code PlantUML extension. The Mermaid files can be viewed with Mermaid preview extensions.

## Next Enhancements

Potential next steps for the app include:

- Full JWT auth/refresh token flow
- Real payment gateway integration
- Push notification support
- Customer loyalty and promo code engine
- Owner and delivery agent dashboards
- In-app messaging and order chat
- Delivery heatmaps and driver tracking
