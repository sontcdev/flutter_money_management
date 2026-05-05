-- Migration 001: Extensions and helper functions
-- Enable required extensions and create base helper functions

-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Helper function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper function to normalize text (lowercase + trim)
CREATE OR REPLACE FUNCTION normalize_name(input_text text)
RETURNS text AS $$
BEGIN
  RETURN lower(trim(input_text));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
