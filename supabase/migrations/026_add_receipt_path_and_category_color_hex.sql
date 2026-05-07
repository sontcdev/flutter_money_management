-- Migration 026: add receipt path and store category colors as ARGB hex text

BEGIN;

ALTER TABLE public.transactions
ADD COLUMN IF NOT EXISTS receipt_path text;

COMMENT ON COLUMN public.transactions.receipt_path
IS 'Local or remote receipt asset path for a transaction';

ALTER TABLE public.categories
ADD COLUMN IF NOT EXISTS color_value_v2 text;

UPDATE public.categories
SET color_value_v2 = UPPER(LPAD((color_value::bit(32))::text, 8, '0'))
WHERE color_value_v2 IS NULL;

UPDATE public.categories
SET color_value_v2 = 'FF9E9E9E'
WHERE color_value_v2 IS NULL
   OR color_value_v2 !~ '^[0-9A-F]{8}$';

ALTER TABLE public.categories
DROP COLUMN color_value;

ALTER TABLE public.categories
RENAME COLUMN color_value_v2 TO color_value;

ALTER TABLE public.categories
ALTER COLUMN color_value SET NOT NULL;

ALTER TABLE public.categories
ADD CONSTRAINT categories_color_value_hex_check
CHECK (color_value ~ '^[0-9A-F]{8}$');

COMMENT ON COLUMN public.categories.color_value
IS 'Flutter ARGB color stored as uppercase 8-char hex string (AARRGGBB)';

COMMIT;
