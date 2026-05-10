-- Migration 006: Error Reports Table
-- Bảng lưu trữ các báo cáo lỗi từ người dùng

CREATE TABLE IF NOT EXISTS public.error_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  error_type text NOT NULL,
  error_message text NOT NULL,
  stack_trace text,
  device_info jsonb,
  app_version text,
  platform text,
  context jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Index để tìm kiếm nhanh theo user và thời gian
CREATE INDEX IF NOT EXISTS idx_error_reports_user_id ON public.error_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_error_reports_created_at ON public.error_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_error_reports_error_type ON public.error_reports(error_type);

-- Enable RLS
ALTER TABLE public.error_reports ENABLE ROW LEVEL SECURITY;

-- Policy: Users can insert their own error reports
CREATE POLICY "Users can insert their own error reports"
  ON public.error_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can view their own error reports
CREATE POLICY "Users can view their own error reports"
  ON public.error_reports
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Service role can do everything
CREATE POLICY "Service role has full access"
  ON public.error_reports
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Function để tạo error report
CREATE OR REPLACE FUNCTION public.create_error_report(
  p_error_type text,
  p_error_message text,
  p_stack_trace text DEFAULT NULL,
  p_device_info jsonb DEFAULT NULL,
  p_app_version text DEFAULT NULL,
  p_platform text DEFAULT NULL,
  p_context jsonb DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  v_report_id uuid;
BEGIN
  INSERT INTO public.error_reports (
    user_id,
    error_type,
    error_message,
    stack_trace,
    device_info,
    app_version,
    platform,
    context
  )
  VALUES (
    auth.uid(),
    p_error_type,
    p_error_message,
    p_stack_trace,
    p_device_info,
    p_app_version,
    p_platform,
    p_context
  )
  RETURNING id INTO v_report_id;

  RETURN v_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_error_report(text, text, text, jsonb, text, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_error_report(text, text, text, jsonb, text, text, jsonb) TO service_role;
