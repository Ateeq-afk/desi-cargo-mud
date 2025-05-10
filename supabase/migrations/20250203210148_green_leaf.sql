/*
  # Remove Customer Data

  This migration removes all customer-related tables, functions, and triggers.
  It uses CASCADE to ensure all dependent objects are properly removed.

  1. Drop Tables
    - customer_article_rates
    - customers

  2. Drop Functions and Triggers
    - get_customers_with_details
    - update_customer_timestamps
    - validate_customer_data

  3. Update Bookings
    - Remove customer references
*/

-- Drop triggers first
DROP TRIGGER IF EXISTS validate_customer_data ON customers CASCADE;
DROP TRIGGER IF EXISTS update_customer_timestamps ON customers CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS get_customers_with_details(uuid) CASCADE;
DROP FUNCTION IF EXISTS validate_customer_data() CASCADE;
DROP FUNCTION IF EXISTS update_customer_timestamps() CASCADE;

-- Drop tables with CASCADE to handle dependencies
DROP TABLE IF EXISTS customer_article_rates CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- Update bookings table to remove customer references
ALTER TABLE bookings 
DROP COLUMN IF EXISTS sender_id CASCADE,
DROP COLUMN IF EXISTS receiver_id CASCADE;