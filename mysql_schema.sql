-- Bitedash MySQL schema for a multi-vendor restaurant delivery app
-- Using utf8mb4 and InnoDB for transactional integrity

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS delivery_status_history;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS promotions;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS kyc_records;
DROP TABLE IF EXISTS delivery_agents;
DROP TABLE IF EXISTS payment_methods;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS menu_items;
DROP TABLE IF EXISTS menu_categories;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS addresses;
DROP TABLE IF EXISTS price_requests;
DROP TABLE IF EXISTS system_settings;
DROP TABLE IF EXISTS cities;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   email VARCHAR(255) NOT NULL UNIQUE,
   password_hash VARCHAR(255) NOT NULL,
   full_name VARCHAR(255) NOT NULL,
   phone VARCHAR(50),
   role ENUM('customer','restaurant_owner','delivery_agent','admin') NOT NULL DEFAULT 'customer',
   status ENUM('pending','active','suspended','deleted') NOT NULL DEFAULT 'pending',
   location_enabled TINYINT(1) NOT NULL DEFAULT 1,
   city_id BIGINT UNSIGNED NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX idx_users_city (city_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cities (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   name VARCHAR(100) NOT NULL,
   country VARCHAR(100) NOT NULL,
   latitude DECIMAL(10,8),
   longitude DECIMAL(11,8),
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   UNIQUE KEY uq_city_country (name, country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE system_settings (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   setting_key VARCHAR(100) NOT NULL UNIQUE,
   setting_value TEXT NOT NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE refresh_tokens (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   user_id BIGINT UNSIGNED NOT NULL,
   token VARCHAR(64) NOT NULL UNIQUE,
   expires_at DATETIME NOT NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_refresh_token_user (user_id),
   CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE addresses (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   user_id BIGINT UNSIGNED NULL,
   restaurant_id BIGINT UNSIGNED NULL,
   label VARCHAR(100),
   street VARCHAR(255),
   city VARCHAR(100),
   state VARCHAR(100),
   country VARCHAR(100),
   postal_code VARCHAR(50),
   latitude DECIMAL(10,8),
   longitude DECIMAL(11,8),
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_user_address (user_id),
   INDEX idx_restaurant_address (restaurant_id),
   CONSTRAINT fk_addresses_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
   CONSTRAINT fk_addresses_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE restaurants (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   owner_id BIGINT UNSIGNED NOT NULL,
   name VARCHAR(255) NOT NULL,
   description TEXT,
   address_id BIGINT UNSIGNED,
   status ENUM('draft','pending','active','suspended','closed') NOT NULL DEFAULT 'pending',
   is_open TINYINT(1) NOT NULL DEFAULT 0,
   latitude DECIMAL(10,8),
   longitude DECIMAL(11,8),
   city_id BIGINT UNSIGNED NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   UNIQUE KEY uq_restaurant_owner_name (owner_id, name),
   INDEX idx_restaurant_owner (owner_id),
   INDEX idx_restaurants_city (city_id),
   CONSTRAINT fk_restaurants_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
   CONSTRAINT fk_restaurants_address FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE SET NULL,
   CONSTRAINT fk_restaurants_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE menu_categories (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   restaurant_id BIGINT UNSIGNED NOT NULL,
   name VARCHAR(150) NOT NULL,
   description TEXT,
   priority INT NOT NULL DEFAULT 0,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_menu_category_restaurant (restaurant_id),
   CONSTRAINT fk_menu_categories_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE menu_items (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   restaurant_id BIGINT UNSIGNED NOT NULL,
   category_id BIGINT UNSIGNED NULL,
   name VARCHAR(255) NOT NULL,
   description TEXT,
   price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   currency CHAR(3) NOT NULL DEFAULT 'USD',
   rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
   quantity INT UNSIGNED DEFAULT 0,
   stock_quantity INT UNSIGNED DEFAULT 0,
   is_available TINYINT(1) NOT NULL DEFAULT 1,
   preparation_time INT NOT NULL DEFAULT 15,
   city_id BIGINT UNSIGNED NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX idx_menu_item_restaurant (restaurant_id),
   INDEX idx_menu_item_category (category_id),
   INDEX idx_menu_items_city (city_id),
   CONSTRAINT fk_menu_items_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
   CONSTRAINT fk_menu_items_category FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE SET NULL,
   CONSTRAINT fk_menu_items_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE payment_methods (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   user_id BIGINT UNSIGNED NOT NULL,
   type ENUM('cash','credit_card','mobile_money','bank_transfer') NOT NULL,
   label VARCHAR(100),
   provider VARCHAR(100),
   details TEXT,
   is_enabled TINYINT(1) NOT NULL DEFAULT 1,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_payment_method_user (user_id),
   CONSTRAINT fk_payment_methods_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE kyc_records (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   user_id BIGINT UNSIGNED NOT NULL,
   entity_type ENUM('user','restaurant','delivery_agent') NOT NULL,
   document_type ENUM('id_card','passport','driver_license','business_license') NOT NULL,
   document_number VARCHAR(100),
   document_image_url VARCHAR(512),
   status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
   verified_at DATETIME NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_kyc_user (user_id),
   CONSTRAINT fk_kyc_records_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE delivery_agents (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    vehicle_type ENUM('bike','car','taxi','scooter') NOT NULL,
    vehicle_registration VARCHAR(100),
    agency_name VARCHAR(255),
    rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
    price_per_km DECIMAL(10,2) NOT NULL DEFAULT 1.50,
    is_fixed_price TINYINT(1) NOT NULL DEFAULT 0,
    fixed_price DECIMAL(10,2) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    photo_url VARCHAR(512),
    city_id BIGINT UNSIGNED NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    last_seen_at DATETIME NULL,
    status ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_delivery_agent_user (user_id),
    INDEX idx_delivery_agent_location (latitude, longitude),
    INDEX idx_delivery_agents_city (city_id),
    CONSTRAINT fk_delivery_agents_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_agents_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE price_requests (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   delivery_agent_id BIGINT UNSIGNED NOT NULL,
   proposed_price DECIMAL(10,2) NOT NULL,
   admin_remark TEXT,
   status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX idx_price_requests_agent (delivery_agent_id),
   CONSTRAINT fk_price_requests_agent FOREIGN KEY (delivery_agent_id) REFERENCES delivery_agents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_city_preferences (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   user_id BIGINT UNSIGNED NOT NULL,
   city_id BIGINT UNSIGNED NOT NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   UNIQUE KEY uq_user_city (user_id),
   INDEX idx_user_city_pref (user_id),
   CONSTRAINT fk_user_city_prefs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
   CONSTRAINT fk_user_city_prefs_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    guest_email VARCHAR(255) NULL,
    guest_phone VARCHAR(50) NULL,
    guest_token VARCHAR(255) NULL,
    payment_stub TEXT NULL,
   restaurant_id BIGINT UNSIGNED NOT NULL,
   delivery_agent_id BIGINT UNSIGNED NULL,
   address_id BIGINT UNSIGNED NULL,
   reservation_id BIGINT UNSIGNED NULL,
   order_type ENUM('delivery','pickup','reservation') NOT NULL,
   status ENUM('pending','accepted','preparing','picked_up','delivering','completed','cancelled','failed') NOT NULL DEFAULT 'pending',
   sub_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   tax DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   discount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   requested_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   delivered_at DATETIME NULL,
   customer_latitude DECIMAL(10,8),
   customer_longitude DECIMAL(11,8),
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX idx_order_user (user_id),
   INDEX idx_order_restaurant (restaurant_id),
   INDEX idx_order_agent (delivery_agent_id),
   INDEX idx_order_customer_location (customer_latitude, customer_longitude),
   CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
   CONSTRAINT fk_orders_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
   CONSTRAINT fk_orders_delivery_agent FOREIGN KEY (delivery_agent_id) REFERENCES delivery_agents(id) ON DELETE SET NULL,
   CONSTRAINT fk_orders_address FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE SET NULL,
   CONSTRAINT fk_orders_reservation FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE order_items (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   order_id BIGINT UNSIGNED NOT NULL,
   menu_item_id BIGINT UNSIGNED NOT NULL,
   quantity INT UNSIGNED NOT NULL DEFAULT 1,
   unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   total_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   notes TEXT,
   INDEX idx_order_item_order (order_id),
   INDEX idx_order_item_menu_item (menu_item_id),
   CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
   CONSTRAINT fk_order_items_menu_item FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reservations (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   user_id BIGINT UNSIGNED NOT NULL,
   restaurant_id BIGINT UNSIGNED NOT NULL,
   party_size INT UNSIGNED NOT NULL,
   reservation_time DATETIME NOT NULL,
   status ENUM('pending','confirmed','cancelled','completed') NOT NULL DEFAULT 'pending',
   special_requests TEXT,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX idx_reservation_user (user_id),
   INDEX idx_reservation_restaurant (restaurant_id),
   CONSTRAINT fk_reservations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
   CONSTRAINT fk_reservations_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE payments (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   order_id BIGINT UNSIGNED NOT NULL,
   user_id BIGINT UNSIGNED NOT NULL,
   payment_method_id BIGINT UNSIGNED NULL,
   amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
   currency CHAR(3) NOT NULL DEFAULT 'USD',
   status ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
   transaction_reference VARCHAR(255),
   paid_at DATETIME NULL,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_payment_order (order_id),
   INDEX idx_payment_user (user_id),
   CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
   CONSTRAINT fk_payments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
   CONSTRAINT fk_payments_payment_method FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ratings (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   reviewer_id BIGINT UNSIGNED NOT NULL,
   target_type ENUM('restaurant','menu_item','delivery_agent','order') NOT NULL,
   target_id BIGINT UNSIGNED NOT NULL,
   rating INT UNSIGNED NOT NULL,
   comment TEXT,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_rating_reviewer (reviewer_id),
   CONSTRAINT fk_ratings_reviewer FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE promotions (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   restaurant_id BIGINT UNSIGNED NOT NULL,
   code VARCHAR(100) NOT NULL,
   description TEXT,
   discount_percent DECIMAL(5,2) DEFAULT NULL,
   discount_amount DECIMAL(10,2) DEFAULT NULL,
   valid_from DATETIME NOT NULL,
   valid_until DATETIME NOT NULL,
   is_active TINYINT(1) NOT NULL DEFAULT 1,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_promotion_restaurant (restaurant_id),
   CONSTRAINT fk_promotions_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE rider_requests (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    customer_id BIGINT UNSIGNED,
    customer_lat DECIMAL(10,8),
    customer_lng DECIMAL(11,8),
    status ENUM('pending','accepted','cancelled') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rider_request_order (order_id),
    INDEX idx_rider_request_customer (customer_id),
    CONSTRAINT fk_rider_requests_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_rider_requests_customer FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE rider_applications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rider_request_id BIGINT UNSIGNED NOT NULL,
    delivery_agent_id BIGINT UNSIGNED NOT NULL,
    price_offer DECIMAL(10,2),
    status ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_application_rider_request (rider_request_id),
    INDEX idx_application_agent (delivery_agent_id),
    CONSTRAINT fk_rider_applications_request FOREIGN KEY (rider_request_id) REFERENCES rider_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_rider_applications_agent FOREIGN KEY (delivery_agent_id) REFERENCES delivery_agents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE coupons (
     id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
     restaurant_id BIGINT UNSIGNED NULL,
     delivery_agent_id BIGINT UNSIGNED NULL,
     code VARCHAR(100) NOT NULL,
     description TEXT,
     discount_percent DECIMAL(5,2) DEFAULT NULL,
     discount_amount DECIMAL(10,2) DEFAULT NULL,
     valid_from DATETIME NOT NULL,
     valid_until DATETIME NOT NULL,
     max_uses INT UNSIGNED DEFAULT 0,
     used_count INT UNSIGNED DEFAULT 0,
     min_order_amount DECIMAL(10,2) DEFAULT 0.00,
     is_active TINYINT(1) NOT NULL DEFAULT 1,
     created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
     INDEX idx_coupon_restaurant (restaurant_id),
     INDEX idx_coupon_agent (delivery_agent_id),
     CONSTRAINT fk_coupons_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
     CONSTRAINT fk_coupons_agent FOREIGN KEY (delivery_agent_id) REFERENCES delivery_agents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE notifications (
   id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   user_id BIGINT UNSIGNED NULL,
   category ENUM('customer','restaurant_owner','delivery_agent','admin','all') NOT NULL DEFAULT 'all',
   title VARCHAR(255) NOT NULL,
   message TEXT NOT NULL,
   link VARCHAR(512) DEFAULT NULL,
   is_read TINYINT(1) NOT NULL DEFAULT 0,
   created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   INDEX idx_notifications_user (user_id),
   CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE delivery_status_history (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    status ENUM('pending','accepted','preparing','picked_up','delivering','completed','cancelled','failed') NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    note VARCHAR(255),
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_delivery_status_order (order_id),
    CONSTRAINT fk_delivery_status_history_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ads (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    owner_id BIGINT UNSIGNED NULL,
    agent_id BIGINT UNSIGNED NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(512),
    target_type ENUM('restaurant','rider') NOT NULL,
    status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    budget DECIMAL(10,2),
    start_date DATETIME,
    end_date DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ads_owner (owner_id),
    INDEX idx_ads_agent (agent_id),
    CONSTRAINT fk_ads_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ads_agent FOREIGN KEY (agent_id) REFERENCES delivery_agents(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE chat_messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    sender_id BIGINT UNSIGNED NOT NULL,
    receiver_id BIGINT UNSIGNED NOT NULL,
    message TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_chat_order (order_id),
    INDEX idx_chat_sender (sender_id),
    INDEX idx_chat_receiver (receiver_id),
    CONSTRAINT fk_chat_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_receiver FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- Sample data for Cameroon cities
INSERT INTO cities (id, name, country, latitude, longitude) VALUES
(1, 'Yaoundé', 'Cameroon', 3.8480, 11.5186),
(2, 'Douala', 'Cameroon', 4.0511, 9.7629),
(3, 'Garoua', 'Cameroon', 9.3044, 13.3866),
(4, 'Bamenda', 'Cameroon', 5.9667, 10.1500),
(5, 'Buea', 'Cameroon', 4.1527, 9.2447);

-- Sample system settings
INSERT INTO system_settings (setting_key, setting_value) VALUES
('default_price_per_km', '0.50'),
('default_delivery_fee', '2.50'),
('delivery_fee_fixed', '0'),
('app_name', 'Bitedash'),
('app_version', '1.0.0');

-- Sample users (password: Test1234!)
INSERT INTO users (id, email, password_hash, full_name, phone, role, status, city_id) VALUES
(1, 'customer@example.com', '$2y$10$EqlnOtKR/qLVhYGrLLFR2ux05VqRL.84n4clsQdtpS0hb/eyy1xCa', 'John Customer', '+10000000001', 'customer', 'active', 1),
(2, 'owner@example.com', '$2y$10$EqlnOtKR/qLVhYGrLLFR2ux05VqRL.84n4clsQdtpS0hb/eyy1xCa', 'Jane Owner', '+10000000002', 'restaurant_owner', 'active', 1),
(3, 'rider@example.com', '$2y$10$EqlnOtKR/qLVhYGrLLFR2ux05VqRL.84n4clsQdtpS0hb/eyy1xCa', 'Mike Rider', '+10000000003', 'delivery_agent', 'active', 1),
(4, 'admin@example.com', '$2y$10$EqlnOtKR/qLVhYGrLLFR2ux05VqRL.84n4clsQdtpS0hb/eyy1xCa', 'Admin User', '+10000000004', 'admin', 'active', 1);