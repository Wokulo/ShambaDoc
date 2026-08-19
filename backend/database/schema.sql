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
    confidence_tier VARCHAR(20),
    severity VARCHAR(20),
    crop_type VARCHAR(100) DEFAULT 'Unknown',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    region VARCHAR(100),
    scanned_at TIMESTAMP NOT NULL,
    image_url TEXT,
    plot_id INTEGER REFERENCES plots(id) ON DELETE SET NULL,
    model_source VARCHAR(20) DEFAULT 'offline' CHECK (model_source IN ('offline', 'cloud', 'human')),
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('pending', 'synced', 'failed')),
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
CREATE INDEX IF NOT EXISTS idx_scans_plot_id ON scans(plot_id);
CREATE INDEX IF NOT EXISTS idx_scans_confidence_tier ON scans(confidence_tier);
CREATE INDEX IF NOT EXISTS idx_scans_severity ON scans(severity);

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
--
-- The ON CONFLICT below needs a unique index to bite: `id` is a SERIAL, so it is
-- freshly generated on every INSERT and never conflicts. Without this index the
-- seed rows are re-inserted on each deploy (preDeployCommand runs migrate every
-- time) and the dealer map fills up with duplicates.
--
-- Drop any duplicates a pre-fix deploy already created, keeping the lowest id,
-- so the unique index can be built on an existing database.
DELETE FROM agro_dealers a
    USING agro_dealers b
    WHERE a.id > b.id AND a.name = b.name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_dealers_name_unique ON agro_dealers(name);

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

-- Ecosystem tables for Connected Agriculture Platform

-- Farmer profiles (extended user data)
CREATE TABLE IF NOT EXISTS farmer_profiles (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    county VARCHAR(100) NOT NULL,
    sub_county VARCHAR(100),
    ward VARCHAR(100),
    farm_size_hectares DECIMAL(8,2),
    primary_crops TEXT[],
    farming_experience_years INTEGER,
    phone_number VARCHAR(50),
    profile_photo_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_farmer_profiles_user_id ON farmer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_farmer_profiles_county ON farmer_profiles(county);

-- Farms / plots (extend existing plots table)
ALTER TABLE plots ADD COLUMN IF NOT EXISTS farmer_profile_id INTEGER REFERENCES farmer_profiles(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_plots_farmer_profile_id ON plots(farmer_profile_id);

-- Agronomists
CREATE TABLE IF NOT EXISTS agronomists (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE REFERENCES users(uid) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    professional_title VARCHAR(255),
    qualification VARCHAR(255),
    specialization TEXT[],
    county VARCHAR(100) NOT NULL,
    sub_county VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(50),
    email VARCHAR(255),
    availability VARCHAR(50) DEFAULT 'available' CHECK (availability IN ('available', 'busy', 'unavailable')),
    years_of_experience INTEGER,
    profile_photo_url TEXT,
    bio TEXT,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'under_review', 'verified', 'rejected')),
    rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agronomists_county ON agronomists(county);
CREATE INDEX IF NOT EXISTS idx_agronomists_verification ON agronomists(verification_status);
CREATE INDEX IF NOT EXISTS idx_agronomists_location ON agronomists(latitude, longitude);

-- Government agricultural officers
CREATE TABLE IF NOT EXISTS government_officers (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE REFERENCES users(uid) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    professional_title VARCHAR(255),
    designation VARCHAR(255) NOT NULL,
    department VARCHAR(255),
    county VARCHAR(100) NOT NULL,
    sub_county VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(50),
    email VARCHAR(255),
    office_address TEXT,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'under_review', 'verified', 'rejected')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_gov_officers_county ON government_officers(county);
CREATE INDEX IF NOT EXISTS idx_gov_officers_verification ON government_officers(verification_status);

-- Agrovets (extended dealer profiles)
CREATE TABLE IF NOT EXISTS agrovets (
    id SERIAL PRIMARY KEY,
    dealer_id INTEGER UNIQUE REFERENCES agro_dealers(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    owner_name VARCHAR(255),
    license_number VARCHAR(100),
    license_verified BOOLEAN DEFAULT false,
    physical_address TEXT NOT NULL,
    county VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(50),
    email VARCHAR(255),
    opening_hours JSONB,
    delivery_available BOOLEAN DEFAULT false,
    delivery_radius_km INTEGER,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'under_review', 'verified', 'rejected')),
    rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    review_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agrovets_county ON agrovets(county);
CREATE INDEX IF NOT EXISTS idx_agrovets_verification ON agrovets(verification_status);
CREATE INDEX IF NOT EXISTS idx_agrovets_location ON agrovets(latitude, longitude);

-- Agrovet products
CREATE TABLE IF NOT EXISTS agrovet_products (
    id SERIAL PRIMARY KEY,
    agrovet_id INTEGER REFERENCES agrovets(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    price_kes DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'KES',
    stock_status VARCHAR(20) DEFAULT 'in_stock' CHECK (stock_status IN ('in_stock', 'low_stock', 'out_of_stock', 'pre_order')),
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agrovet_products_agrovet_id ON agrovet_products(agrovet_id);
CREATE INDEX IF NOT EXISTS idx_agrovet_products_category ON agrovet_products(category);

-- SACCOs
CREATE TABLE IF NOT EXISTS saccos (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE,
    county VARCHAR(100) NOT NULL,
    sub_county VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(50),
    email VARCHAR(255),
    physical_address TEXT,
    website_url TEXT,
    description TEXT,
    membership_requirements TEXT,
    services_offered TEXT[],
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'under_review', 'verified', 'rejected')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_saccos_county ON saccos(county);
CREATE INDEX IF NOT EXISTS idx_saccos_verification ON saccos(verification_status);

-- SACCO financial products
CREATE TABLE IF NOT EXISTS financial_products (
    id SERIAL PRIMARY KEY,
    sacco_id INTEGER REFERENCES saccos(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    product_type VARCHAR(50) NOT NULL CHECK (product_type IN ('loan', 'savings', 'insurance', 'investment')),
    description TEXT,
    interest_rate_min DECIMAL(5,2),
    interest_rate_max DECIMAL(5,2),
    loan_limit_min_kes INTEGER,
    loan_limit_max_kes INTEGER,
    repayment_period_months INTEGER,
    eligibility_criteria TEXT,
    required_documents TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_financial_products_sacco_id ON financial_products(sacco_id);

-- Insurance providers
CREATE TABLE IF NOT EXISTS insurance_providers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100) UNIQUE,
    county VARCHAR(100) NOT NULL,
    sub_county VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(50),
    email VARCHAR(255),
    physical_address TEXT,
    website_url TEXT,
    description TEXT,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'under_review', 'verified', 'rejected')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_insurance_providers_county ON insurance_providers(county);
CREATE INDEX IF NOT EXISTS idx_insurance_providers_verification ON insurance_providers(verification_status);

-- Insurance products
CREATE TABLE IF NOT EXISTS insurance_products (
    id SERIAL PRIMARY KEY,
    provider_id INTEGER REFERENCES insurance_providers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    product_type VARCHAR(50) NOT NULL CHECK (product_type IN ('crop', 'livestock', 'weather', 'comprehensive')),
    coverage_description TEXT,
    premium_range_kes VARCHAR(255),
    eligibility_criteria TEXT,
    covered_perils TEXT[],
    claim_process TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_insurance_products_provider_id ON insurance_products(provider_id);

-- Consultations
CREATE TABLE IF NOT EXISTS consultations (
    id SERIAL PRIMARY KEY,
    scan_id VARCHAR(255) REFERENCES scans(scan_id) ON DELETE SET NULL,
    farmer_id VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    agronomist_id VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    government_officer_id VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    consultation_type VARCHAR(30) NOT NULL CHECK (consultation_type IN ('chat', 'video', 'farm_visit', 'phone', 'agrovet_inquiry', 'sacco_inquiry', 'insurance_inquiry', 'insurance_claim', 'government_support')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled')),
    farmer_message TEXT,
    agronomist_response TEXT,
    agronomist_diagnosis VARCHAR(255),
    agronomist_advice TEXT,
    scheduled_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_consultations_farmer_id ON consultations(farmer_id);
CREATE INDEX IF NOT EXISTS idx_consultations_agronomist_id ON consultations(agronomist_id);
CREATE INDEX IF NOT EXISTS idx_consultations_status ON consultations(status);

-- Appointments
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER REFERENCES consultations(id) ON DELETE CASCADE,
    farmer_id VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    provider_id VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    provider_type VARCHAR(20) NOT NULL CHECK (provider_type IN ('agronomist', 'government_officer', 'agrovet')),
    appointment_date TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show')),
    notes TEXT,
    location TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_appointments_farmer_id ON appointments(farmer_id);
CREATE INDEX IF NOT EXISTS idx_appointments_provider_id ON appointments(provider_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    consultation_id INTEGER REFERENCES consultations(id) ON DELETE CASCADE,
    sender_id VARCHAR(255) NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    receiver_id VARCHAR(255) NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    content TEXT NOT NULL,
    attachment_url TEXT,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_messages_consultation_id ON messages(consultation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN ('disease_alert', 'agronomist_response', 'consultation_reminder', 'government_announcement', 'agrovet_response', 'insurance_update', 'sacco_update', 'platform')),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Agricultural advisories
CREATE TABLE IF NOT EXISTS agricultural_advisories (
    id SERIAL PRIMARY KEY,
    author_id VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    author_type VARCHAR(20) NOT NULL CHECK (author_type IN ('government_officer', 'agronomist', 'admin')),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    crop_types TEXT[],
    counties TEXT[],
    severity_level VARCHAR(20) CHECK (severity_level IN ('info', 'warning', 'urgent')),
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_advisories_author ON agricultural_advisories(author_id);
CREATE INDEX IF NOT EXISTS idx_advisories_published ON agricultural_advisories(is_published, published_at);

-- Government programs
CREATE TABLE IF NOT EXISTS government_programs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    program_type VARCHAR(50) NOT NULL,
    target_crops TEXT[],
    target_counties TEXT[],
    eligibility_criteria TEXT,
    benefits_description TEXT,
    application_start_date TIMESTAMP,
    application_end_date TIMESTAMP,
    program_start_date TIMESTAMP,
    program_end_date TIMESTAMP,
    contact_person VARCHAR(255),
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    application_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_gov_programs_active ON government_programs(is_active);
CREATE INDEX IF NOT EXISTS idx_gov_programs_dates ON government_programs(application_start_date, application_end_date);

-- Agricultural events
CREATE TABLE IF NOT EXISTS agricultural_events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('training', 'field_day', 'exhibition', 'webinar', 'consultation')),
    organizer_type VARCHAR(20) NOT NULL CHECK (organizer_type IN ('government', 'agronomist', 'sacco', 'insurance', 'agrovet')),
    organizer_id VARCHAR(255),
    county VARCHAR(100) NOT NULL,
    sub_county VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    event_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    venue TEXT,
    registration_required BOOLEAN DEFAULT false,
    registration_url TEXT,
    max_participants INTEGER,
    is_free BOOLEAN DEFAULT true,
    price_kes INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_agricultural_events_county ON agricultural_events(county);
CREATE INDEX IF NOT EXISTS idx_agricultural_events_date ON agricultural_events(event_date);

-- Reviews
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('agronomist', 'government_officer', 'agrovet', 'insurance_provider', 'sacco')),
    target_id INTEGER NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reviews_target ON reviews(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);

-- Verification requests
CREATE TABLE IF NOT EXISTS verification_requests (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    requester_type VARCHAR(20) NOT NULL CHECK (requester_type IN ('agronomist', 'government_officer', 'agrovet', 'sacco', 'insurance_provider')),
    target_id INTEGER,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'verified', 'rejected')),
    reviewed_by VARCHAR(255) REFERENCES users(uid) ON DELETE SET NULL,
    review_notes TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_verification_requests_user_id ON verification_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON verification_requests(status);

-- Locations (shared location master)
CREATE TABLE IF NOT EXISTS locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location_type VARCHAR(50) NOT NULL CHECK (location_type IN ('county', 'sub_county', 'ward', 'town', 'market')),
    parent_id INTEGER REFERENCES locations(id) ON DELETE SET NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    county VARCHAR(100),
    sub_county VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(location_type);
CREATE INDEX IF NOT EXISTS idx_locations_county ON locations(county);

-- Seed sample ecosystem data
INSERT INTO farmer_profiles (user_id, full_name, county, sub_county, farm_size_hectares, primary_crops, farming_experience_years, phone_number, is_verified)
VALUES
    ('demo-farmer-1', 'John Mwangi', 'Kiambu', 'Kikuyu', 2.5, ARRAY['Maize', 'Coffee', 'Avocado'], 15, '+254712345678', true)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO agronomists (full_name, professional_title, qualification, specialization, county, sub_county, phone, email, availability, years_of_experience, verification_status, rating, review_count, is_active)
VALUES
    ('Dr. Grace Wairimu', 'Senior Agronomist', 'PhD Crop Science', ARRAY['Maize', 'Potato', 'Tomato'], 'Kiambu', 'Kikuyu', '+254723456789', 'grace.wairimu@agri.co.ke', 'available', 12, 'verified', 4.8, 24, true),
    ('James Kipchoge', 'Plant Pathologist', 'MSc Plant Pathology', ARRAY['Wheat', 'Barley', 'Sorghum'], 'Nakuru', 'Nakuru Town', '+254734567890', 'james.k@agri.co.ke', 'available', 8, 'verified', 4.5, 18, true)
ON CONFLICT DO NOTHING;

INSERT INTO government_officers (full_name, professional_title, designation, department, county, sub_county, phone, email, verification_status, is_active)
VALUES
    ('Hon. Mary Njeri', 'County Agriculture Officer', 'Chief Officer', 'Ministry of Agriculture', 'Kiambu', 'Kiambu Town', '+254745678901', 'mary.njeri@kilimo.go.ke', 'verified', true),
    ('Mr. Peter Ochieng', 'Agricultural Extension Officer', 'Extension Officer', 'Ministry of Agriculture', 'Kisumu', 'Kisumu Central', '+254756789012', 'peter.o@kilimo.go.ke', 'verified', true)
ON CONFLICT DO NOTHING;

INSERT INTO saccos (name, registration_number, county, sub_county, phone, email, physical_address, description, membership_requirements, services_offered, verification_status, is_active)
VALUES
    ('Kiambu Farmers SACCO', 'SACC-001-2026', 'Kiambu', 'Kikuyu', '+254767890123', 'info@kiambufarmers.co.ke', 'Kikuyu Town, Kiambu', 'Empowering farmers through affordable credit and savings.', 'Must be a resident of Kiambu County with farming activity.', ARRAY['Agricultural Loans', 'Savings', 'Input Financing'], 'verified', true),
    ('Nakuru Agribusiness SACCO', 'SACC-002-2026', 'Nakuru', 'Nakuru Town', '+254778901234', 'info@nakuruagri.co.ke', 'Nakuru CBD', 'Supporting agribusiness entrepreneurs in Nakuru.', 'Active agribusiness in Nakuru County.', ARRAY['Farm Equipment Loans', 'Crop Insurance', 'Savings'], 'pending', true)
ON CONFLICT DO NOTHING;

INSERT INTO insurance_providers (name, registration_number, county, sub_county, phone, email, physical_address, description, verification_status, is_active)
VALUES
    ('AgriShield Insurance', 'AINS-001-2026', 'Nairobi', 'Westlands', '+254789012345', 'support@agrishield.co.ke', 'Westlands, Nairobi', 'Specialized crop and livestock insurance for smallholder farmers.', 'verified', true),
    ('Mkulima Protect', 'AINS-002-2026', 'Kisumu', 'Kisumu Central', '+254790123456', 'info@mkulimaprotect.co.ke', 'Kisumu Town', 'Affordable weather-indexed crop insurance.', 'pending', true)
ON CONFLICT DO NOTHING;

INSERT INTO agricultural_events (title, description, event_type, organizer_type, organizer_id, county, sub_county, event_date, venue, registration_required, is_free, max_participants)
VALUES
    ('Modern Maize Farming Techniques', 'Hands-on training on drought-resistant maize varieties and proper spacing.', 'training', 'government', 'gov-1', 'Kiambu', 'Kikuyu', '2026-09-15T09:00:00', 'Kikuyu Agricultural Showground', true, true, 200),
    ('Coffee Pest Management Field Day', 'Field demonstration on integrated pest management for coffee farms.', 'field_day', 'agronomist', 'agro-1', 'Kiambu', 'Kiambu Town', '2026-09-20T10:00:00', 'Kiambu Research Station', true, true, 150)
ON CONFLICT DO NOTHING;
