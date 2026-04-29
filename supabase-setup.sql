-- ══════════════════════════════════════════════════════════
-- Thailand Market — Supabase Setup for Browser-only CMS
-- Run in: Supabase Dashboard → SQL Editor → New Query
-- ══════════════════════════════════════════════════════════

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── USERS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email            TEXT UNIQUE NOT NULL,
  display_name     TEXT NOT NULL DEFAULT 'ผู้ใช้',
  role             TEXT NOT NULL DEFAULT 'buyer'
                   CHECK (role IN ('buyer','seller','admin')),
  seller_id        UUID,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── CATEGORIES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categories (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_th       TEXT NOT NULL,
  name_en       TEXT,
  slug          TEXT UNIQUE NOT NULL,
  icon          TEXT,
  parent_id     UUID REFERENCES categories(id),
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  product_count INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── PRODUCTS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id       UUID REFERENCES categories(id),
  created_by        UUID,

  name_th           TEXT NOT NULL,
  name_en           TEXT,
  slug              TEXT UNIQUE,
  description       TEXT,
  product_type      TEXT DEFAULT 'product'
                    CHECK (product_type IN ('product','service','digital')),

  price             DECIMAL(10,2) NOT NULL DEFAULT 0,
  compare_price     DECIMAL(10,2),
  discount_percent  INTEGER NOT NULL DEFAULT 0,

  stock_quantity    INTEGER NOT NULL DEFAULT 0,
  sku               TEXT,
  weight_grams      INTEGER,

  images            TEXT[] DEFAULT '{}',
  thumbnail         TEXT,

  tags              TEXT[] DEFAULT '{}',
  status            TEXT NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft','pending_review','active','inactive','rejected','deleted')),

  approved_at       TIMESTAMPTZ,
  rejected_at       TIMESTAMPTZ,
  rejection_reason  TEXT,
  deleted_at        TIMESTAMPTZ,

  view_count        INTEGER NOT NULL DEFAULT 0,
  sold_count        INTEGER NOT NULL DEFAULT 0,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── INDEXES ───────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_products_status   ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_created  ON products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_price    ON products(price);
CREATE INDEX IF NOT EXISTS idx_users_email       ON users(email);

-- ── RLS (Row Level Security) ───────────────────────────────
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Everyone can read active categories
CREATE POLICY "public_read_categories" ON categories
  FOR SELECT USING (is_active = true);

-- Everyone can read active products  
CREATE POLICY "public_read_products" ON products
  FOR SELECT USING (status = 'active');

-- Authenticated users can insert products
CREATE POLICY "auth_insert_products" ON products
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Users can update their own products
CREATE POLICY "auth_update_own_products" ON products
  FOR UPDATE TO authenticated
  USING (auth.uid()::text = created_by::text OR created_by IS NULL);

-- Users can read their own (non-active) products too
CREATE POLICY "auth_read_own_products" ON products
  FOR SELECT TO authenticated
  USING (status = 'active' OR auth.uid()::text = created_by::text OR created_by IS NULL);

-- Users table: read own profile
CREATE POLICY "read_own_profile" ON users
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "insert_own_profile" ON users
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "update_own_profile" ON users
  FOR UPDATE TO authenticated
  USING (true);

-- ── TRIGGERS ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update category product_count
CREATE OR REPLACE FUNCTION sync_product_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status='active' AND (OLD.status IS NULL OR OLD.status!='active') THEN
    UPDATE categories SET product_count=product_count+1 WHERE id=NEW.category_id;
  ELSIF OLD.status='active' AND NEW.status!='active' THEN
    UPDATE categories SET product_count=GREATEST(product_count-1,0) WHERE id=NEW.category_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_count_sync
  AFTER INSERT OR UPDATE OF status ON products
  FOR EACH ROW EXECUTE FUNCTION sync_product_count();

-- ── SEED: Categories ──────────────────────────────────────
INSERT INTO categories (name_th, name_en, slug, icon, sort_order) VALUES
  ('Home & Furniture',  'Home & Furniture', 'home-furniture', '🏠', 1),
  ('แฟชั่น',           'Fashion',          'fashion',        '👗', 2),
  ('Beauty & Health',   'Beauty & Health',  'beauty-health',  '💄', 3),
  ('อาหารและของสด',    'Grocery',          'grocery',        '🛒', 4),
  ('Tech & Gadgets',    'Tech & Gadgets',   'tech',           '💻', 5),
  ('ยานยนต์',          'Automotive',       'automotive',     '🚗', 6),
  ('สัตว์เลี้ยง',      'Pets',             'pets',           '🐾', 7),
  ('การศึกษา',         'Education',        'education',      '📚', 8),
  ('บริการ',           'Services',         'services',       '🛎️', 9),
  ('ดิจิทัล',          'Digital',          'digital',        '💾', 10)
ON CONFLICT (slug) DO NOTHING;

-- ── STORAGE BUCKET ────────────────────────────────────────
-- Run separately in Supabase Dashboard > Storage > New Bucket
-- OR run this SQL:
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images', 
  true,
  10485760,
  ARRAY['image/jpeg','image/png','image/webp','image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Storage policy: anyone can view
CREATE POLICY "public_read_images" ON storage.objects
  FOR SELECT USING (bucket_id = 'product-images');

-- Authenticated users can upload
CREATE POLICY "auth_upload_images" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'product-images');

-- Users can delete own uploads
CREATE POLICY "auth_delete_own_images" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'product-images');
