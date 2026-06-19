# Bitedash Quick Start

## What this app is

Bitedash is a multi-vendor restaurant delivery app with:

- A **Yii2 Advanced REST API backend** (`backend/` for web, `common/` for shared models)
- A **Flutter mobile app** (`mobile_app/`)
- A **React admin dashboard** (`admin/`)

The API is versioned under `/v1` (e.g., `/v1/restaurant`, `/v1/order`).

## Quick setup

### Backend

```bash
cd /opt/lampp/htdocs/bitedash
composer install
```

Configure the database in `common/config/db.php`.

Import the schema:

```bash
mysql -uroot -h127.0.0.1 -e "CREATE DATABASE IF NOT EXISTS bitedash CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -uroot -h127.0.0.1 bitedash < /opt/lampp/htdocs/bitedash/mysql_schema.sql
```

Run from web root pointing to `backend/web/index.php`.

### Admin UI

```bash
cd /opt/lampp/htdocs/bitedash/admin
npm install
npm start
```

### Mobile app

```bash
cd /opt/lampp/htdocs/bitedash/mobile_app
flutter pub get
flutter run
```

## Sample credentials

- `customer@example.com` / `Test1234!`
- `owner@example.com` / `Test1234!`
- `agent@example.com` / `Test1234!`
- `admin@example.com` / `Test1234!`

## Where to learn more

- Full architecture and API details: `README_FULL.md`
- Database schema: `mysql_schema.sql`
- UML and ER diagrams: `bitedash_*.(puml|mmd|pdf|png)`