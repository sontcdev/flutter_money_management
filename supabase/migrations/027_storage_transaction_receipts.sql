-- Migration 027: Create Storage bucket and policies for transaction receipts

BEGIN;

INSERT INTO storage.buckets (id, name, public)
VALUES ('transaction-receipts', 'transaction-receipts', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY transaction_receipts_select_member
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'transaction-receipts'
    AND split_part(name, '/', 1) = 'workspaces'
    AND is_workspace_member(split_part(name, '/', 2)::uuid)
  );

CREATE POLICY transaction_receipts_insert_creator
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'transaction-receipts'
    AND split_part(name, '/', 1) = 'workspaces'
    AND split_part(name, '/', 3) = 'transactions'
    AND EXISTS (
      SELECT 1
      FROM public.transactions
      WHERE transactions.id = split_part(name, '/', 4)::uuid
        AND transactions.workspace_id = split_part(name, '/', 2)::uuid
        AND transactions.created_by_user_id = auth.uid()
    )
  );

CREATE POLICY transaction_receipts_delete_creator
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'transaction-receipts'
    AND split_part(name, '/', 1) = 'workspaces'
    AND split_part(name, '/', 3) = 'transactions'
    AND EXISTS (
      SELECT 1
      FROM public.transactions
      WHERE transactions.id = split_part(name, '/', 4)::uuid
        AND transactions.workspace_id = split_part(name, '/', 2)::uuid
        AND transactions.created_by_user_id = auth.uid()
    )
  );

COMMENT ON POLICY transaction_receipts_select_member ON storage.objects
IS 'Workspace members can view receipt objects';

COMMENT ON POLICY transaction_receipts_insert_creator ON storage.objects
IS 'Transaction creators can upload receipt objects';

COMMENT ON POLICY transaction_receipts_delete_creator ON storage.objects
IS 'Transaction creators can delete receipt objects';

COMMIT;
