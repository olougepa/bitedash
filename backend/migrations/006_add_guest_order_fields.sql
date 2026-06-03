-- Add guest lookup fields to orders for anonymous checkout
ALTER TABLE `orders`
  ADD COLUMN `guest_email` VARCHAR(255) NULL AFTER `user_id`,
  ADD COLUMN `guest_token` VARCHAR(255) NULL AFTER `guest_email`,
  ADD COLUMN `payment_stub` TEXT NULL AFTER `guest_token`;
