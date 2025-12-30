-- PSM Enterprise - Database Schema
-- Compatible with: PostgreSQL, Supabase, Neon, CockroachDB

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================
-- CLOUD PROVIDERS
-- =====================
CREATE TABLE IF NOT EXISTS cloud_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('active', 'pending', 'offline', 'error')),
    region VARCHAR(50),
    endpoint_url TEXT,
    api_key_encrypted TEXT,
    services_count INTEGER DEFAULT 0,
    monthly_cost DECIMAL(10, 2) DEFAULT 0.00,
    free_tier_limit JSONB,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- SERVICES
-- =====================
CREATE TABLE IF NOT EXISTS services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID REFERENCES cloud_providers(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    tier VARCHAR(50) DEFAULT 'free',
    quota JSONB,
    usage JSONB DEFAULT '{}',
    endpoint_url TEXT,
    health_check_url TEXT,
    last_health_check TIMESTAMPTZ,
    last_health_status VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider_id, name)
);

-- =====================
-- API REQUESTS LOG
-- =====================
CREATE TABLE IF NOT EXISTS api_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID REFERENCES services(id),
    endpoint VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INTEGER,
    latency_ms INTEGER,
    request_size INTEGER,
    response_size INTEGER,
    user_agent TEXT,
    ip_address INET,
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partition by month for performance
CREATE INDEX idx_api_requests_created_at ON api_requests(created_at);
CREATE INDEX idx_api_requests_service ON api_requests(service_id);

-- =====================
-- USERS
-- =====================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    wallet_address VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('admin', 'user', 'viewer')),
    api_key_hash VARCHAR(255),
    api_calls_today INTEGER DEFAULT 0,
    api_calls_month INTEGER DEFAULT 0,
    last_api_call TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- MEDIA ITEMS (Jellyfin sync)
-- =====================
CREATE TABLE IF NOT EXISTS media_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jellyfin_id VARCHAR(100) UNIQUE,
    title VARCHAR(500) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('movie', 'series', 'episode', 'music', 'other')),
    year INTEGER,
    duration_minutes INTEGER,
    file_path TEXT,
    file_size_bytes BIGINT,
    quality VARCHAR(20),
    codec VARCHAR(50),
    processed BOOLEAN DEFAULT FALSE,
    ai_tags JSONB DEFAULT '[]',
    ai_description TEXT,
    poster_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_media_type ON media_items(type);
CREATE INDEX idx_media_processed ON media_items(processed);

-- =====================
-- PROCESSING QUEUE
-- =====================
CREATE TABLE IF NOT EXISTS processing_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_type VARCHAR(50) NOT NULL,
    item_id UUID NOT NULL,
    operation VARCHAR(100) NOT NULL,
    priority INTEGER DEFAULT 5,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    last_error TEXT,
    scheduled_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    result JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_queue_status ON processing_queue(status);
CREATE INDEX idx_queue_scheduled ON processing_queue(scheduled_at);

-- =====================
-- PAYMENTS (Solana)
-- =====================
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    transaction_signature VARCHAR(100) UNIQUE NOT NULL,
    amount_sol DECIMAL(20, 9),
    amount_usdc DECIMAL(20, 6),
    amount_usd DECIMAL(10, 2),
    from_wallet VARCHAR(100) NOT NULL,
    to_wallet VARCHAR(100) NOT NULL,
    payment_type VARCHAR(50) NOT NULL,
    reference_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'failed')),
    confirmed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);

-- =====================
-- HEALTH CHECKS
-- =====================
CREATE TABLE IF NOT EXISTS health_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID REFERENCES services(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL,
    latency_ms INTEGER,
    status_code INTEGER,
    error_message TEXT,
    checked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_health_service ON health_checks(service_id);
CREATE INDEX idx_health_checked_at ON health_checks(checked_at);

-- =====================
-- VIEWS
-- =====================
CREATE OR REPLACE VIEW cloud_overview AS
SELECT
    cp.name AS provider,
    cp.status AS provider_status,
    cp.region,
    COUNT(s.id) AS total_services,
    COUNT(CASE WHEN s.status = 'active' THEN 1 END) AS active_services,
    cp.monthly_cost
FROM cloud_providers cp
LEFT JOIN services s ON s.provider_id = cp.id
GROUP BY cp.id;

CREATE OR REPLACE VIEW daily_api_stats AS
SELECT
    DATE(created_at) AS date,
    COUNT(*) AS total_requests,
    COUNT(CASE WHEN status_code < 400 THEN 1 END) AS successful,
    COUNT(CASE WHEN status_code >= 400 THEN 1 END) AS failed,
    AVG(latency_ms)::INTEGER AS avg_latency_ms,
    SUM(request_size) AS total_request_bytes,
    SUM(response_size) AS total_response_bytes
FROM api_requests
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- =====================
-- FUNCTIONS
-- =====================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_cloud_providers_updated_at
    BEFORE UPDATE ON cloud_providers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_services_updated_at
    BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_media_items_updated_at
    BEFORE UPDATE ON media_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =====================
-- SEED DATA
-- =====================
INSERT INTO cloud_providers (name, slug, status, region, services_count) VALUES
    ('Microsoft Azure', 'azure', 'active', 'eastus', 9),
    ('Oracle Cloud', 'oracle', 'active', 'us-chicago-1', 4),
    ('Vercel', 'vercel', 'active', 'global', 7),
    ('Cloudflare', 'cloudflare', 'pending', 'global', 7),
    ('Amazon AWS', 'aws', 'pending', 'us-east-1', 9),
    ('Google Cloud', 'gcp', 'pending', 'us-central1', 7),
    ('Supabase', 'supabase', 'pending', 'global', 5),
    ('Netlify', 'netlify', 'active', 'global', 4),
    ('Deno Deploy', 'deno', 'active', 'global', 2)
ON CONFLICT (slug) DO UPDATE SET
    status = EXCLUDED.status,
    services_count = EXCLUDED.services_count;
