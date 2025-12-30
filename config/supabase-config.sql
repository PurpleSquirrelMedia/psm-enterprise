-- PSM Enterprise - Supabase Configuration
-- Run this in Supabase SQL Editor after creating project

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Row Level Security Policies

-- Cloud Providers table
ALTER TABLE cloud_providers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access" ON cloud_providers
  FOR SELECT USING (true);

CREATE POLICY "Admin write access" ON cloud_providers
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Services table
ALTER TABLE services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access" ON services
  FOR SELECT USING (true);

CREATE POLICY "Admin write access" ON services
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- API Requests (insert only for logging)
ALTER TABLE api_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Insert access" ON api_requests
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin read access" ON api_requests
  FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');

-- Users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid()::text = id::text);

-- Payments table
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own payments" ON payments
  FOR SELECT USING (auth.uid()::text = user_id::text);

-- Create Realtime subscriptions
ALTER PUBLICATION supabase_realtime ADD TABLE cloud_providers;
ALTER PUBLICATION supabase_realtime ADD TABLE services;
ALTER PUBLICATION supabase_realtime ADD TABLE health_checks;

-- Create storage bucket for media
INSERT INTO storage.buckets (id, name, public)
VALUES ('media', 'media', true)
ON CONFLICT DO NOTHING;

-- Storage policies
CREATE POLICY "Public read access" ON storage.objects
  FOR SELECT USING (bucket_id = 'media');

CREATE POLICY "Authenticated upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'media' AND auth.role() = 'authenticated');

-- Edge Functions to deploy:
-- 1. /api/status - Service status
-- 2. /api/health - Health check
-- 3. /api/clouds - Cloud mesh status
-- 4. /api/process - AI processing trigger

-- Database Functions
CREATE OR REPLACE FUNCTION get_cloud_health()
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total', (SELECT COUNT(*) FROM cloud_providers),
    'active', (SELECT COUNT(*) FROM cloud_providers WHERE status = 'active'),
    'pending', (SELECT COUNT(*) FROM cloud_providers WHERE status = 'pending'),
    'offline', (SELECT COUNT(*) FROM cloud_providers WHERE status = 'offline'),
    'services', (SELECT COUNT(*) FROM services),
    'uptime', ROUND((SELECT COUNT(*)::NUMERIC FROM cloud_providers WHERE status = 'active') /
              NULLIF((SELECT COUNT(*)::NUMERIC FROM cloud_providers), 0) * 100, 2)
  ) INTO result;
  RETURN result;
END;
$$;

-- Trigger for auto-updating timestamps
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    AND table_name IN ('cloud_providers', 'services', 'users', 'media_items')
  LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS update_%I_modtime ON %I;
      CREATE TRIGGER update_%I_modtime
        BEFORE UPDATE ON %I
        FOR EACH ROW
        EXECUTE FUNCTION update_modified_column();
    ', t, t, t, t);
  END LOOP;
END;
$$;
