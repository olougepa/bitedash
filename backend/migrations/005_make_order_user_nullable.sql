-- Allow guest orders by making order.user_id nullable
ALTER TABLE `orders`
  MODIFY COLUMN `user_id` BIGINT UNSIGNED NULL;
