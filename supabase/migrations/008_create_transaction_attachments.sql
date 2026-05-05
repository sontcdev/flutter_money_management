-- Migration 008: Create transaction_attachments table
-- Metadata for receipts/invoices stored in Supabase Storage

CREATE TABLE transaction_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  storage_bucket text NOT NULL,
  storage_path text NOT NULL,
  file_name text NOT NULL,
  mime_type text,
  file_size bigint,
  checksum text,
  uploaded_by_user_id uuid NOT NULL REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Indexes
CREATE INDEX transaction_attachments_transaction_id_idx ON transaction_attachments(transaction_id);
CREATE INDEX transaction_attachments_workspace_id_idx ON transaction_attachments(workspace_id);

-- Comments
COMMENT ON TABLE transaction_attachments IS 'Metadata for transaction receipts/invoices';
COMMENT ON COLUMN transaction_attachments.storage_bucket IS 'Supabase Storage bucket name';
COMMENT ON COLUMN transaction_attachments.storage_path IS 'Path within bucket';
