-- Add a flag to mark users whose password is stored as a secure hash
ALTER TABLE `users` 
  ADD COLUMN IF NOT EXISTS `password_hashed` TINYINT(1) NOT NULL DEFAULT 0;
