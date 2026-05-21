-- ShambaDoc PostgreSQL Database Schema
-- Version: 1.0
-- Date: May 2026

-- Enable PostGIS extension for geospatial queries (optional but recommended)
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- Table: scans
-- Stores all crop disease diagnosis scans
CREATE TABLE IF NOT EXISTS scans (
    id SERIAL PRIMARY KEY,
    scan_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255),
    disease_name VARCHAR(255) NOT NULL,
    confidence DECIMAL(5,4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    crop_type VARCHAR(100) DEFAULT 'Unknown',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    region VARCHAR(100),
    scanned_at TIMESTAMP NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for scans
CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id);
CREATE INDEX IF NOT EXISTS idx_scans_disease ON scans(disease_name);
CREATE INDEX IF NOT EXISTS idx_scans_crop_type ON scans(crop_type);
CREATE INDEX IF NOT EXISTS idx_scans_scanned_at ON scans(scanned_at);
CREATE INDEX IF NOT EXISTS idx_scans_location ON scans(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_scans_region ON scans(region);

-- Table: feedback
-- Stores user feedback on diagnosis accuracy
CREATE TABLE IF NOT EXISTS feedback (
    id SERIAL PRIMARY KEY,
    scan_id VARCHAR(255) NOT NULL REFERENCES scans(scan_id) ON DELETE CASCADE,
    user_id VARCHAR(255),
    was_correct BOOLEAN NOT NULL,
    correct_disease VARCHAR(255),
    notes TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_feedback_scan_id ON feedback(scan_id);
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback(user_id);

-- Table: agro_dealers
-- Stores agro-dealer / input supplier locations
CREATE TABLE IF NOT EXISTS agro_dealers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(255),
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    county VARCHAR(100),
    products TEXT[], -- PostgreSQL array type
    is_verified BOOLEAN DEFAULT false,
    is_sponsored BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dealers_location ON agro_dealers(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_dealers_active ON agro_dealers(is_active);
CREATE INDEX IF NOT EXISTS idx_dealers_county ON agro_dealers(county);

-- Table: users (optional extension for user profiles)
CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(255) PRIMARY KEY,
    phone_number VARCHAR(50) UNIQUE,
    display_name VARCHAR(255),
    email VARCHAR(255),
    county VARCHAR(100),
    farm_size_hectares DECIMAL(8,2),
    preferred_language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Table: disease_outbreaks (for V2 regional alerts)
CREATE TABLE IF NOT EXISTS disease_outbreaks (
    id SERIAL PRIMARY KEY,
    disease_name VARCHAR(255) NOT NULL,
    crop_type VARCHAR(100),
    county VARCHAR(100),
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    case_count INTEGER DEFAULT 0,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger
DROP TRIGGER IF EXISTS update_scans_updated_at ON scans;
CREATE TRIGGER update_scans_updated_at
    BEFORE UPDATE ON scans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_dealers_updated_at ON agro_dealers;
CREATE TRIGGER update_dealers_updated_at
    BEFORE UPDATE ON agro_dealers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Seed data: demo agro-dealers
INSERT INTO agro_dealers (name, phone, email, address, latitude, longitude, county, products, is_verified, is_active)
VALUES
    ('Kisumu Agrovet', '+254712345678', 'kisumu@agrovet.co.ke', 'Oginga Odinga St, Kisumu', -0.1022, 34.7617, 'Kisumu', ARRAY['Fungicides', 'Seeds', 'Fertilizers'], true, true),
    ('Nakuru Farm Inputs', '+254723456789', 'nakuru@farminputs.co.ke', 'Nakuru Town Centre', -0.3031, 36.0663, 'Nakuru', ARRAY['Herbicides', 'Pesticides', 'Tools'], true, true),
    ('Eldoret Seeds & Chemicals', '+254734567890', 'eldoret@seeds.co.ke', 'Eldoret CBD', 0.5143, 35.2698, 'Uasin Gishu', ARRAY['Seeds', 'Fertilizers', 'Sprayers'], true, true),
    ('Mombasa Agro Supplies', '+254745678901', 'mombasa@agro.co.ke', 'Mombasa Island', -4.0435, 39.6682, 'Mombasa', ARRAY['Irrigation', 'Fertilizers'], false, true),
    ('Nairobi Agro Centre', '+254756789012', 'nairobi@agrocentre.co.ke', 'Industrial Area, Nairobi', -1.2921, 36.8219, 'Nairobi', ARRAY['Seeds', 'Fungicides', 'PPE'], true, true)
ON CONFLICT DO NOTHING;

-- V2 product extensions
-- These tables and columns support the full software roadmap in docs/software_design.md.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS role VARCHAR(30) DEFAULT 'farmer'
        CHECK (role IN ('farmer', 'dealer', 'sacco_admin', 'analyst', 'agronomist', 'admin')),
    ADD COLUMN IF NOT EXISTS sync_consent BOOLEAN DEFAULT false;

CREATE TABLE IF NOT EXISTS plots (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    county VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    area_hectares DECIMAL(8,2),
    planted_at DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_plots_user_id ON plots(user_id);
CREATE INDEX IF NOT EXISTS idx_plots_crop_type ON plots(crop_type);

ALTER TABLE scans
    ADD COLUMN IF NOT EXISTS plot_id INTEGER REFERENCES plots(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS confidence_tier VARCHAR(20)
        CHECK (confidence_tier IN ('high', 'uncertain', 'low')),
    ADD COLUMN IF NOT EXISTS severity VARCHAR(20)
        CHECK (severity IN ('early', 'moderate', 'severe')),
    ADD COLUMN IF NOT EXISTS model_source VARCHAR(20) DEFAULT 'offline'
        CHECK (model_source IN ('offline', 'cloud', 'human')),
    ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) DEFAULT 'synced'
        CHECK (sync_status IN ('pending', 'synced', 'failed'));

CREATE INDEX IF NOT EXISTS idx_scans_plot_id ON scans(plot_id);
CREATE INDEX IF NOT EXISTS idx_scans_confidence_tier ON scans(confidence_tier);
CREATE INDEX IF NOT EXISTS idx_scans_severity ON scans(severity);

ALTER TABLE feedback
    ADD COLUMN IF NOT EXISTS crop_recovered BOOLEAN,
    ADD COLUMN IF NOT EXISTS treatment_used TEXT;

CREATE TABLE IF NOT EXISTS follow_up_reminders (
    id SERIAL PRIMARY KEY,
    scan_id VARCHAR(255) NOT NULL REFERENCES scans(scan_id) ON DELETE CASCADE,
    user_id VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    due_at TIMESTAMP NOT NULL,
    reminder_type VARCHAR(30) NOT NULL CHECK (reminder_type IN ('day_7', 'day_14', 'custom')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'completed', 'skipped')),
    crop_recovered BOOLEAN,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_due ON follow_up_reminders(user_id, due_at);
CREATE INDEX IF NOT EXISTS idx_reminders_status ON follow_up_reminders(status);

ALTER TABLE agro_dealers
    ADD COLUMN IF NOT EXISTS sponsored_until TIMESTAMP,
    ADD COLUMN IF NOT EXISTS whatsapp_number VARCHAR(50);

CREATE INDEX IF NOT EXISTS idx_dealers_sponsored ON agro_dealers(is_sponsored, sponsored_until);

CREATE TABLE IF NOT EXISTS dealer_leads (
    id SERIAL PRIMARY KEY,
    dealer_id INTEGER REFERENCES agro_dealers(id) ON DELETE SET NULL,
    scan_id VARCHAR(255) REFERENCES scans(scan_id) ON DELETE SET NULL,
    user_id VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    action VARCHAR(30) NOT NULL CHECK (action IN ('map_view', 'phone_tap', 'whatsapp_tap', 'directions_tap')),
    disease_name VARCHAR(255),
    product_query VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dealer_leads_dealer_id ON dealer_leads(dealer_id);
CREATE INDEX IF NOT EXISTS idx_dealer_leads_created_at ON dealer_leads(created_at);

CREATE TABLE IF NOT EXISTS disease_knowledge (
    id SERIAL PRIMARY KEY,
    disease_name VARCHAR(255) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(255),
    description_en TEXT NOT NULL,
    description_sw TEXT,
    treatment_en TEXT NOT NULL,
    treatment_sw TEXT,
    dosage TEXT,
    organic_option TEXT,
    chemical_option TEXT,
    severity_guidance JSONB,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (disease_name, crop_type)
);

CREATE INDEX IF NOT EXISTS idx_disease_knowledge_crop ON disease_knowledge(crop_type);

CREATE TABLE IF NOT EXISTS subscriptions (
    id SERIAL PRIMARY KEY,
    owner_user_id VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    plan_type VARCHAR(30) NOT NULL CHECK (plan_type IN ('farmer_premium', 'sacco_group', 'dealer_sponsored', 'b2b_dashboard')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('trialing', 'active', 'past_due', 'cancelled', 'expired')),
    member_limit INTEGER,
    monthly_price_kes INTEGER,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    renews_at TIMESTAMP,
    cancelled_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_owner ON subscriptions(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

CREATE TABLE IF NOT EXISTS mpesa_payments (
    id SERIAL PRIMARY KEY,
    subscription_id INTEGER REFERENCES subscriptions(id) ON DELETE SET NULL,
    user_id VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    phone_number VARCHAR(50) NOT NULL,
    amount_kes INTEGER NOT NULL,
    checkout_request_id VARCHAR(255) UNIQUE,
    merchant_request_id VARCHAR(255),
    mpesa_receipt_number VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'cancelled')),
    raw_callback JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mpesa_checkout_request ON mpesa_payments(checkout_request_id);

CREATE TABLE IF NOT EXISTS weather_risk_alerts (
    id SERIAL PRIMARY KEY,
    county VARCHAR(100) NOT NULL,
    crop_type VARCHAR(100) NOT NULL,
    disease_name VARCHAR(255) NOT NULL,
    risk_level VARCHAR(20) NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    message_en TEXT NOT NULL,
    message_sw TEXT,
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    source VARCHAR(100) DEFAULT 'open-meteo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_weather_alerts_county_crop ON weather_risk_alerts(county, crop_type);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_valid_until ON weather_risk_alerts(valid_until);

CREATE TABLE IF NOT EXISTS human_escalations (
    id SERIAL PRIMARY KEY,
    scan_id VARCHAR(255) REFERENCES scans(scan_id) ON DELETE CASCADE,
    user_id VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    assigned_to VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in_review', 'resolved', 'closed')),
    farmer_note TEXT,
    agronomist_diagnosis VARCHAR(255),
    agronomist_advice TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_escalations_status ON human_escalations(status);
