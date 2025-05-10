-- First drop any foreign key constraints
ALTER TABLE bookings
DROP CONSTRAINT IF EXISTS bookings_sender_id_fkey,
DROP CONSTRAINT IF EXISTS bookings_receiver_id_fkey;

-- Drop tables in correct order (child tables first)
DROP TABLE IF EXISTS customer_article_rates;
DROP TABLE IF EXISTS customers;

-- Update bookings table to remove customer references
ALTER TABLE bookings 
DROP COLUMN IF EXISTS sender_id,
DROP COLUMN IF EXISTS receiver_id;