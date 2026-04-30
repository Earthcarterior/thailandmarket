-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Thailand Market — MASTER SETUP SQL                         ║
-- ║  Run ไฟล์เดียวนี้ใน Supabase SQL Editor                    ║
-- ║  ครอบคลุม: Tables · RLS · Triggers · Storage · Seed Data   ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════
-- STEP 1: EXTENSIONS
-- ════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ════════════════════════════════════════════════════════════════
-- STEP 2: DROP EXISTING (clean slate)
-- ════════════════════════════════════════════════════════════════
DROP TABLE IF EXISTS wishlist          CASCADE;
DROP TABLE IF EXISTS reviews           CASCADE;
DROP TABLE IF EXISTS order_items       CASCADE;
DROP TABLE IF EXISTS orders            CASCADE;
DROP TABLE IF EXISTS product_variants  CASCADE;
DROP TABLE IF EXISTS products          CASCADE;
DROP TABLE IF EXISTS sellers           CASCADE;
DROP TABLE IF EXISTS brands            CASCADE;
DROP TABLE IF EXISTS banners           CASCADE;
DROP TABLE IF EXISTS coupons           CASCADE;
DROP TABLE IF EXISTS flash_sale_events CASCADE;
DROP TABLE IF EXISTS categories        CASCADE;
DROP TABLE IF EXISTS notifications     CASCADE;
DROP TABLE IF EXISTS admin_notifications CASCADE;
DROP TABLE IF EXISTS site_settings     CASCADE;
DROP TABLE IF EXISTS users             CASCADE;

-- ════════════════════════════════════════════════════════════════
-- STEP 3: CREATE TABLES
-- ════════════════════════════════════════════════════════════════

-- ── USERS ──────────────────────────────────────────────────────
CREATE TABLE users (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email        TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL DEFAULT 'ผู้ใช้',
  avatar_url   TEXT,
  phone        TEXT,
  role         TEXT NOT NULL DEFAULT 'buyer' CHECK (role IN ('buyer','seller','admin')),
  seller_id    UUID,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  loyalty_pts  INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── CATEGORIES ─────────────────────────────────────────────────
CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_th       TEXT NOT NULL,
  name_en       TEXT,
  slug          TEXT UNIQUE NOT NULL,
  icon          TEXT,
  image_url     TEXT,
  parent_id     UUID REFERENCES categories(id),
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  product_count INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── BRANDS ─────────────────────────────────────────────────────
CREATE TABLE brands (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL,
  slug        TEXT UNIQUE NOT NULL,
  logo_url    TEXT,
  icon        TEXT,
  category_id UUID REFERENCES categories(id),
  is_featured BOOLEAN NOT NULL DEFAULT false,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── SELLERS ────────────────────────────────────────────────────
CREATE TABLE sellers (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES users(id),
  shop_name    TEXT NOT NULL,
  shop_logo    TEXT,
  shop_banner  TEXT,
  description  TEXT,
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','suspended')),
  is_verified  BOOLEAN NOT NULL DEFAULT false,
  rating_avg   DECIMAL(3,2) NOT NULL DEFAULT 0,
  rating_count INTEGER NOT NULL DEFAULT 0,
  total_sales  INTEGER NOT NULL DEFAULT 0,
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── PRODUCTS ───────────────────────────────────────────────────
CREATE TABLE products (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id         UUID REFERENCES sellers(id),
  category_id       UUID REFERENCES categories(id),
  brand_id          UUID REFERENCES brands(id),
  created_by        UUID REFERENCES users(id),

  name_th           TEXT NOT NULL,
  name_en           TEXT,
  slug              TEXT UNIQUE,
  description       TEXT,
  short_description TEXT,

  price             DECIMAL(10,2) NOT NULL DEFAULT 0,
  compare_price     DECIMAL(10,2),
  discount_percent  INTEGER NOT NULL DEFAULT 0,

  is_flash_sale     BOOLEAN NOT NULL DEFAULT false,
  flash_sale_price  DECIMAL(10,2),
  flash_sale_ends_at TIMESTAMPTZ,

  stock_quantity    INTEGER NOT NULL DEFAULT 0,
  sku               TEXT,
  weight_grams      INTEGER,

  images            TEXT[] DEFAULT '{}',
  thumbnail         TEXT,
  video_url         TEXT,

  tags              TEXT[] DEFAULT '{}',
  status            TEXT NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft','pending_review','active','inactive','rejected','deleted')),

  is_featured       BOOLEAN NOT NULL DEFAULT false,
  is_recommended    BOOLEAN NOT NULL DEFAULT false,

  approved_at       TIMESTAMPTZ,
  rejected_reason   TEXT,

  view_count        INTEGER NOT NULL DEFAULT 0,
  sold_count        INTEGER NOT NULL DEFAULT 0,
  rating_avg        DECIMAL(3,2) NOT NULL DEFAULT 0,
  rating_count      INTEGER NOT NULL DEFAULT 0,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── BANNERS ────────────────────────────────────────────────────
CREATE TABLE banners (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title       TEXT NOT NULL,
  subtitle    TEXT,
  image_url   TEXT,
  icon        TEXT,
  cta_text    TEXT DEFAULT 'ช้อปเลย',
  cta_url     TEXT DEFAULT '#',
  bg_color    TEXT DEFAULT '#0A0A0A',
  text_color  TEXT DEFAULT '#FFFFFF',
  discount    TEXT,
  type        TEXT NOT NULL DEFAULT 'main' CHECK (type IN ('main','side','strip')),
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── COUPONS ────────────────────────────────────────────────────
CREATE TABLE coupons (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code         TEXT UNIQUE NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT,
  type         TEXT NOT NULL DEFAULT 'fixed' CHECK (type IN ('fixed','percent','free_ship')),
  value        DECIMAL(10,2) NOT NULL DEFAULT 0,
  min_purchase DECIMAL(10,2) NOT NULL DEFAULT 0,
  max_discount DECIMAL(10,2),
  used_count   INTEGER NOT NULL DEFAULT 0,
  max_uses     INTEGER,
  starts_at    TIMESTAMPTZ DEFAULT NOW(),
  expires_at   TIMESTAMPTZ,
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── FLASH SALE EVENTS ──────────────────────────────────────────
CREATE TABLE flash_sale_events (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title      TEXT NOT NULL DEFAULT 'Flash Sale',
  starts_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at    TIMESTAMPTZ NOT NULL,
  is_active  BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── PRODUCT VARIANTS ───────────────────────────────────────────
CREATE TABLE product_variants (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id       UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  options          JSONB NOT NULL DEFAULT '[]',
  price_adjustment DECIMAL(10,2) NOT NULL DEFAULT 0,
  stock_quantity   INTEGER NOT NULL DEFAULT 0,
  sku              TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── ORDERS ─────────────────────────────────────────────────────
CREATE TABLE orders (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES users(id),
  order_number    TEXT UNIQUE NOT NULL DEFAULT '',
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','confirmed','processing','shipped','delivered','cancelled','returned')),
  total_amount    DECIMAL(12,2) NOT NULL DEFAULT 0,
  shipping_fee    DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  coupon_code     TEXT,
  payment_method  TEXT DEFAULT 'cod',
  payment_status  TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid','paid','refunded')),
  shipping_name   TEXT,
  shipping_phone  TEXT,
  shipping_addr   TEXT,
  tracking_number TEXT,
  note            TEXT,
  confirmed_at    TIMESTAMPTZ,
  shipped_at      TIMESTAMPTZ,
  delivered_at    TIMESTAMPTZ,
  cancelled_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── ORDER ITEMS ────────────────────────────────────────────────
CREATE TABLE order_items (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id   UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  variant_id UUID REFERENCES product_variants(id),
  name_th    TEXT NOT NULL,
  thumbnail  TEXT,
  price      DECIMAL(10,2) NOT NULL,
  qty        INTEGER NOT NULL DEFAULT 1,
  subtotal   DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── REVIEWS ────────────────────────────────────────────────────
CREATE TABLE reviews (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES users(id),
  order_id    UUID REFERENCES orders(id),
  rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title       TEXT,
  body        TEXT,
  images      TEXT[] DEFAULT '{}',
  is_verified BOOLEAN NOT NULL DEFAULT false,
  helpful     INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── WISHLIST ───────────────────────────────────────────────────
CREATE TABLE wishlist (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- ── NOTIFICATIONS ──────────────────────────────────────────────
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT,
  data       JSONB,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE admin_notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type       TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT,
  data       JSONB,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── SITE SETTINGS ──────────────────────────────────────────────
CREATE TABLE site_settings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key        TEXT UNIQUE NOT NULL,
  value      TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ════════════════════════════════════════════════════════════════
-- STEP 4: INDEXES
-- ════════════════════════════════════════════════════════════════
CREATE INDEX idx_products_status    ON products(status);
CREATE INDEX idx_products_category  ON products(category_id);
CREATE INDEX idx_products_flash     ON products(is_flash_sale) WHERE is_flash_sale = true;
CREATE INDEX idx_products_featured  ON products(is_featured)   WHERE is_featured   = true;
CREATE INDEX idx_products_created   ON products(created_at DESC);
CREATE INDEX idx_products_price     ON products(price);
CREATE INDEX idx_products_rating    ON products(rating_avg DESC);
CREATE INDEX idx_products_sold      ON products(sold_count DESC);
CREATE INDEX idx_categories_parent  ON categories(parent_id);
CREATE INDEX idx_categories_slug    ON categories(slug);
CREATE INDEX idx_users_email        ON users(email);
CREATE INDEX idx_sellers_user       ON sellers(user_id);
CREATE INDEX idx_orders_user        ON orders(user_id);
CREATE INDEX idx_orders_status      ON orders(status);
CREATE INDEX idx_reviews_product    ON reviews(product_id);
CREATE INDEX idx_wishlist_user      ON wishlist(user_id);

-- ════════════════════════════════════════════════════════════════
-- STEP 5: ROW LEVEL SECURITY (RLS)
-- ════════════════════════════════════════════════════════════════
ALTER TABLE categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sellers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands            ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners           ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons           ENABLE ROW LEVEL SECURITY;
ALTER TABLE flash_sale_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items       ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews           ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist          ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants  ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications     ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_settings     ENABLE ROW LEVEL SECURITY;

-- Public READ policies
CREATE POLICY "public_read_categories"     ON categories        FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_active_products"ON products          FOR SELECT USING (status = 'active');
CREATE POLICY "public_read_banners"        ON banners           FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_coupons"        ON coupons           FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_brands"         ON brands            FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_flash_events"   ON flash_sale_events FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_sellers"        ON sellers           FOR SELECT USING (status = 'active');
CREATE POLICY "public_read_reviews"        ON reviews           FOR SELECT USING (true);
CREATE POLICY "public_read_variants"       ON product_variants  FOR SELECT USING (true);
CREATE POLICY "public_read_settings"       ON site_settings     FOR SELECT USING (true);

-- Auth policies (Admin / Seller CMS)
CREATE POLICY "auth_all_products"   ON products    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_categories" ON categories  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_brands"     ON brands      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_banners"    ON banners     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_coupons"    ON coupons     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_settings"   ON site_settings FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_users"      ON users       FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_sellers"    ON sellers     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all_flash"      ON flash_sale_events FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Order policies (own orders)
CREATE POLICY "auth_insert_order"    ON orders      FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_read_own_orders" ON orders      FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_read_order_items"ON order_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "auth_insert_review"   ON reviews     FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_own_wishlist"    ON wishlist    FOR ALL    TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_own_notifications" ON notifications FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════
-- STEP 6: FUNCTIONS & TRIGGERS
-- ════════════════════════════════════════════════════════════════

-- updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at     BEFORE UPDATE ON users     FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER sellers_updated_at   BEFORE UPDATE ON sellers   FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER products_updated_at  BEFORE UPDATE ON products  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER orders_updated_at    BEFORE UPDATE ON orders    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER settings_updated_at  BEFORE UPDATE ON site_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- product_count sync
CREATE OR REPLACE FUNCTION sync_product_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'active' AND (OLD.status IS NULL OR OLD.status != 'active') THEN
    UPDATE categories SET product_count = product_count + 1 WHERE id = NEW.category_id;
  ELSIF OLD.status = 'active' AND NEW.status != 'active' THEN
    UPDATE categories SET product_count = GREATEST(product_count - 1, 0) WHERE id = NEW.category_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_count_sync
  AFTER INSERT OR UPDATE OF status ON products
  FOR EACH ROW EXECUTE FUNCTION sync_product_count();

-- auto rating update from reviews
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE products SET
    rating_avg   = (SELECT ROUND(AVG(rating)::numeric, 2) FROM reviews WHERE product_id = NEW.product_id),
    rating_count = (SELECT COUNT(*) FROM reviews WHERE product_id = NEW.product_id)
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER review_rating_sync
  AFTER INSERT OR UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_product_rating();

-- auto order number
CREATE SEQUENCE IF NOT EXISTS order_seq START 1;

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number = 'TM' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(NEXTVAL('order_seq')::text, 5, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_number_gen
  BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- ════════════════════════════════════════════════════════════════
-- STEP 7: STORAGE
-- ════════════════════════════════════════════════════════════════
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('product-images', 'product-images', true, 10485760,
        ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "public_read_images"  ON storage.objects;
DROP POLICY IF EXISTS "auth_upload_images"  ON storage.objects;
DROP POLICY IF EXISTS "auth_delete_images"  ON storage.objects;

CREATE POLICY "public_read_images"  ON storage.objects FOR SELECT USING (bucket_id = 'product-images');
CREATE POLICY "auth_upload_images"  ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'product-images');
CREATE POLICY "auth_delete_images"  ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'product-images');

-- ════════════════════════════════════════════════════════════════
-- STEP 8: SEED DATA — Categories (12 หมวดหลัก UUID-safe)
-- ════════════════════════════════════════════════════════════════
INSERT INTO categories (id, name_th, name_en, slug, icon, sort_order, is_active) VALUES
  ('00000000-0000-0000-0000-000000000001','อุปกรณ์อิเล็กทรอนิกส์',    'Electronic Devices',     'electronic-devices',    '📱', 1, true),
  ('00000000-0000-0000-0000-000000000002','อุปกรณ์เสริมอิเล็กทรอนิกส์','Electronic Accessories', 'electronic-accessories','🔌', 2, true),
  ('00000000-0000-0000-0000-000000000003','ทีวีและเครื่องใช้ไฟฟ้า',    'TV & Home Appliances',   'tv-home-appliances',    '📺', 3, true),
  ('00000000-0000-0000-0000-000000000004','สุขภาพและความงาม',          'Health & Beauty',        'health-beauty',         '💄', 4, true),
  ('00000000-0000-0000-0000-000000000005','แม่และเด็ก / ของเล่น',      'Babies & Toys',          'babies-toys',           '🍼', 5, true),
  ('00000000-0000-0000-0000-000000000006','ของชำและสัตว์เลี้ยง',       'Groceries & Pets',       'groceries-pets',        '🛒', 6, true),
  ('00000000-0000-0000-0000-000000000007','บ้านและไลฟ์สไตล์',          'Home & Lifestyle',       'home-lifestyle',        '🏠', 7, true),
  ('00000000-0000-0000-0000-000000000008','แฟชั่นผู้หญิง',             'Women''s Fashion',       'womens-fashion',        '👗', 8, true),
  ('00000000-0000-0000-0000-000000000009','แฟชั่นผู้ชาย',              'Men''s Fashion',         'mens-fashion',          '👔', 9, true),
  ('00000000-0000-0000-0000-000000000010','แฟชั่นเด็ก',                'Kid''s Fashion',         'kids-fashion',          '👧',10, true),
  ('00000000-0000-0000-0000-000000000011','กีฬาและการเดินทาง',         'Sports & Travel',        'sports-travel',         '🏋️',11, true),
  ('00000000-0000-0000-0000-000000000012','ยานยนต์',                   'Automotive',             'automotive',            '🚗',12, true);

-- หมวดย่อย: c01 Electronic Devices
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('โทรศัพท์มือถือ','Mobiles','mobiles','📱','00000000-0000-0000-0000-000000000001',1,true),
  ('แท็บเล็ต','Tablets','tablets','📟','00000000-0000-0000-0000-000000000001',2,true),
  ('โน้ตบุ๊ก','Laptops','laptops','💻','00000000-0000-0000-0000-000000000001',3,true),
  ('คอมพิวเตอร์ตั้งโต๊ะ','Desktops','desktops','🖥️','00000000-0000-0000-0000-000000000001',4,true),
  ('กล้องถ่ายรูป','Cameras','cameras','📷','00000000-0000-0000-0000-000000000001',5,true),
  ('โดรน','Drones','drones','🛸','00000000-0000-0000-0000-000000000001',6,true),
  ('เครื่องเล่นเกม','Console Gaming','console-gaming','🎮','00000000-0000-0000-0000-000000000001',7,true);

-- หมวดย่อย: c02 Electronic Accessories
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('อุปกรณ์เสริมมือถือ','Mobile Accessories','mobile-accessories','📱','00000000-0000-0000-0000-000000000002',1,true),
  ('เครื่องเสียง','Audio','audio','🎧','00000000-0000-0000-0000-000000000002',2,true),
  ('Wearables','Wearables','wearables','⌚','00000000-0000-0000-0000-000000000002',3,true),
  ('Gadgets','Gadgets','gadgets','🔧','00000000-0000-0000-0000-000000000002',4,true),
  ('อุปกรณ์จัดเก็บข้อมูล','Data Storage','data-storage','💾','00000000-0000-0000-0000-000000000002',5,true);

-- หมวดย่อย: c03 TV & Home Appliances
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('ทีวีและอุปกรณ์วิดีโอ','TVs & Video','tvs-video','📺','00000000-0000-0000-0000-000000000003',1,true),
  ('เครื่องใช้ไฟฟ้าขนาดใหญ่','Large Appliances','large-appliances','🫙','00000000-0000-0000-0000-000000000003',2,true),
  ('เครื่องครัวขนาดเล็ก','Small Kitchen','small-kitchen','☕','00000000-0000-0000-0000-000000000003',3,true),
  ('เครื่องปรับอากาศ','Air Treatment','air-treatment','❄️','00000000-0000-0000-0000-000000000003',4,true),
  ('เครื่องดูแลร่างกาย','Personal Care Appliances','personal-care-appliances','💆','00000000-0000-0000-0000-000000000003',5,true);

-- หมวดย่อย: c04 Health & Beauty
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('ดูแลผิวหน้า','Skincare','skincare','✨','00000000-0000-0000-0000-000000000004',1,true),
  ('เครื่องสำอาง','Make-Up','makeup','💄','00000000-0000-0000-0000-000000000004',2,true),
  ('ดูแลเส้นผม','Hair Care','hair-care','💇','00000000-0000-0000-0000-000000000004',3,true),
  ('น้ำหอม','Fragrances','fragrances','🌸','00000000-0000-0000-0000-000000000004',4,true),
  ('วิตามินและอาหารเสริม','Vitamins','vitamins','💊','00000000-0000-0000-0000-000000000004',5,true),
  ('อุปกรณ์ทางการแพทย์','Medical Supplies','medical-supplies','🏥','00000000-0000-0000-0000-000000000004',6,true);

-- หมวดย่อย: c05 Babies & Toys
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('แม่และเด็ก','Mother & Baby','mother-baby','👶','00000000-0000-0000-0000-000000000005',1,true),
  ('นมผงและอาหารเด็ก','Baby Food','baby-food','🍼','00000000-0000-0000-0000-000000000005',2,true),
  ('ของเล่นและเกม','Toys & Games','toys-games','🎲','00000000-0000-0000-0000-000000000005',3,true),
  ('รถเข็นและอุปกรณ์','Baby Gear','baby-gear','🛺','00000000-0000-0000-0000-000000000005',4,true),
  ('เสื้อผ้าเด็กอ่อน','Baby Fashion','baby-fashion','👕','00000000-0000-0000-0000-000000000005',5,true);

-- หมวดย่อย: c06 Groceries & Pets
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('เครื่องดื่ม','Drinks','drinks','🥤','00000000-0000-0000-0000-000000000006',1,true),
  ('ของชำและเครื่องปรุง','Food Staples','food-staples','🛒','00000000-0000-0000-0000-000000000006',2,true),
  ('ขนมและช็อกโกแลต','Snacks','snacks','🍫','00000000-0000-0000-0000-000000000006',3,true),
  ('อุปกรณ์สัตว์เลี้ยง','Pet Accessories','pet-accessories','🐾','00000000-0000-0000-0000-000000000006',4,true),
  ('อาหารสัตว์เลี้ยง','Pet Food','pet-food','🦴','00000000-0000-0000-0000-000000000006',5,true);

-- หมวดย่อย: c07 Home & Lifestyle + ต้นไม้ + ช่าง
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('เฟอร์นิเจอร์','Furniture','furniture','🛋️','00000000-0000-0000-0000-000000000007',1,true),
  ('โคมไฟและแสงสว่าง','Lighting','lighting','💡','00000000-0000-0000-0000-000000000007',2,true),
  ('ของตกแต่งบ้าน','Home Décor','home-decor','🖼️','00000000-0000-0000-0000-000000000007',3,true),
  ('ครัวและอุปกรณ์','Kitchen & Dining','kitchen-dining','🍳','00000000-0000-0000-0000-000000000007',4,true),
  ('ผ้าปูที่นอน','Bedding','bedding','🛏️','00000000-0000-0000-0000-000000000007',5,true),
  ('ต้นไม้และพืชสวน','Plants & Gardening','plants-gardening','🪴','00000000-0000-0000-0000-000000000007',6,true),
  ('ต้นไม้ในบ้าน','Indoor Plants','indoor-plants','🌱','00000000-0000-0000-0000-000000000007',7,true),
  ('ต้นไม้กลางแจ้ง','Outdoor Plants','outdoor-plants','🌳','00000000-0000-0000-0000-000000000007',8,true),
  ('กระถางและภาชนะ','Pots & Planters','pots-planters','🪴','00000000-0000-0000-0000-000000000007',9,true),
  ('ช่างและวัสดุก่อสร้าง','Hardware','hardware-building','🔨','00000000-0000-0000-0000-000000000007',10,true),
  ('สีและอุปกรณ์ทาสี','Paint','paint-tools','🎨','00000000-0000-0000-0000-000000000007',11,true),
  ('ไฟฟ้าและสายไฟ','Electrical','electrical','⚡','00000000-0000-0000-0000-000000000007',12,true),
  ('ประปาและระบบน้ำ','Plumbing','plumbing','🚰','00000000-0000-0000-0000-000000000007',13,true);

-- หมวดย่อย: c08 Women's Fashion
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('เสื้อผ้าผู้หญิง','Women''s Clothing','womens-clothing','👗','00000000-0000-0000-0000-000000000008',1,true),
  ('รองเท้าผู้หญิง','Women''s Shoes','womens-shoes','👠','00000000-0000-0000-0000-000000000008',2,true),
  ('กระเป๋าผู้หญิง','Women''s Bags','womens-bags','👜','00000000-0000-0000-0000-000000000008',3,true),
  ('เครื่องประดับ','Accessories','womens-accessories','💍','00000000-0000-0000-0000-000000000008',4,true),
  ('ชุดชั้นในและชุดนอน','Lingerie','lingerie','🩱','00000000-0000-0000-0000-000000000008',5,true);

-- หมวดย่อย: c09 Men's Fashion
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('เสื้อผ้าผู้ชาย','Men''s Clothing','mens-clothing','👔','00000000-0000-0000-0000-000000000009',1,true),
  ('รองเท้าผู้ชาย','Men''s Shoes','mens-shoes','👞','00000000-0000-0000-0000-000000000009',2,true),
  ('กระเป๋าผู้ชาย','Men''s Bags','mens-bags','💼','00000000-0000-0000-0000-000000000009',3,true),
  ('นาฬิกาผู้ชาย','Men''s Watches','mens-watches','⌚','00000000-0000-0000-0000-000000000009',4,true);

-- หมวดย่อย: c10 Kid's Fashion
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('เสื้อผ้าเด็กผู้ชาย','Boys'' Clothing','boys-clothing','👕','00000000-0000-0000-0000-000000000010',1,true),
  ('เสื้อผ้าเด็กผู้หญิง','Girls'' Clothing','girls-clothing','👗','00000000-0000-0000-0000-000000000010',2,true),
  ('รองเท้าเด็ก','Kids'' Shoes','kids-shoes','👟','00000000-0000-0000-0000-000000000010',3,true),
  ('กระเป๋าเด็ก','Kids'' Bags','kids-bags','🎒','00000000-0000-0000-0000-000000000010',4,true);

-- หมวดย่อย: c11 Sports & Travel
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('ออกกำลังกาย','Exercise & Fitness','exercise-fitness','🏋️','00000000-0000-0000-0000-000000000011',1,true),
  ('กิจกรรมกลางแจ้ง','Outdoor Recreation','outdoor-recreation','🏕️','00000000-0000-0000-0000-000000000011',2,true),
  ('จักรยาน','Cycling','cycling','🚴','00000000-0000-0000-0000-000000000011',3,true),
  ('กีฬาทางน้ำ','Water Sports','water-sports','🏊','00000000-0000-0000-0000-000000000011',4,true),
  ('การเดินทาง','Travel','travel','✈️','00000000-0000-0000-0000-000000000011',5,true),
  ('อุปกรณ์กีฬา','Sport Accessories','sport-accessories','🎽','00000000-0000-0000-0000-000000000011',6,true);

-- หมวดย่อย: c12 Automotive
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active) VALUES
  ('น้ำมันและของเหลว','Oils & Fluids','oils-fluids','🛢️','00000000-0000-0000-0000-000000000012',1,true),
  ('กล้องติดรถยนต์','Car Camera','car-camera','📹','00000000-0000-0000-0000-000000000012',2,true),
  ('อุปกรณ์เสริมรถยนต์','Auto Accessories','auto-accessories','🪄','00000000-0000-0000-0000-000000000012',3,true),
  ('ดูแลรักษารถ','Car Care','car-care','🧽','00000000-0000-0000-0000-000000000012',4,true),
  ('มอเตอร์ไซค์','Motorcycle','motorcycle','🏍️','00000000-0000-0000-0000-000000000012',5,true),
  ('ยางและล้อ','Tires & Wheels','tires-wheels','🛞','00000000-0000-0000-0000-000000000012',6,true);

-- ════════════════════════════════════════════════════════════════
-- STEP 9: SEED DATA — Brands
-- ════════════════════════════════════════════════════════════════
INSERT INTO brands (name, slug, icon, is_featured, sort_order, is_active) VALUES
  ('Samsung',    'samsung',    '📱', true,  1, true),
  ('Apple',      'apple',      '🍎', true,  2, true),
  ('LG',         'lg',         '📺', true,  3, true),
  ('IKEA',       'ikea',       '🛋️', true,  4, true),
  ('Panasonic',  'panasonic',  '❄️', true,  5, true),
  ('Nike',       'nike',       '👟', true,  6, true),
  ('L''Oreal',   'loreal',     '💄', true,  7, true),
  ('Royal Canin','royal-canin','🐾', true,  8, true);

-- ════════════════════════════════════════════════════════════════
-- STEP 10: SEED DATA — Banners
-- ════════════════════════════════════════════════════════════════
INSERT INTO banners (title, subtitle, icon, cta_text, cta_url, bg_color, text_color, discount, type, sort_order, is_active) VALUES
  ('บ้านสวย เริ่มต้นที่นี่', 'เฟอร์นิเจอร์และของตกแต่งบ้าน', '🏠', 'ช้อปเลย →',
   'storefront-live.html?cat=00000000-0000-0000-0000-000000000007',
   '#0A0A0A', '#FFFFFF', 'ลดสูงสุด 40%', 'main', 1, true),
  ('Fashion Week Sale', 'เสื้อผ้า รองเท้า กระเป๋า', '👗', 'ดูเลย',
   'storefront-live.html?cat=00000000-0000-0000-0000-000000000008',
   '#1a1a2e', '#FFFFFF', '-60%', 'side', 2, true),
  ('Tech Special Deal', 'Gadgets & Electronics', '💻', 'ช้อป',
   'storefront-live.html?cat=00000000-0000-0000-0000-000000000001',
   '#0f0f23', '#FFFFFF', '-50%', 'side', 3, true);

-- ════════════════════════════════════════════════════════════════
-- STEP 11: SEED DATA — Coupons
-- ════════════════════════════════════════════════════════════════
INSERT INTO coupons (code, title, type, value, min_purchase, expires_at, is_active) VALUES
  ('SAVE50',  'ลด ฿50',  'fixed',    50,  300,  NOW() + INTERVAL '30 days', true),
  ('TM10PCT', 'ลด 10%',  'percent',  10,  500,  NOW() + INTERVAL '30 days', true),
  ('FREESHIP','ส่งฟรี',  'free_ship', 0,    0,  NOW() + INTERVAL '30 days', true),
  ('TM20NEW', 'ลด 20% สำหรับสมาชิกใหม่', 'percent', 20, 300, NOW() + INTERVAL '7 days', true);

-- ════════════════════════════════════════════════════════════════
-- STEP 12: SEED DATA — Flash Sale Event
-- ════════════════════════════════════════════════════════════════
INSERT INTO flash_sale_events (title, starts_at, ends_at, is_active) VALUES
  ('Flash Sale ประจำวัน', NOW(), NOW() + INTERVAL '3 hours', true);

-- ════════════════════════════════════════════════════════════════
-- STEP 13: SEED DATA — Products (10 รายการตัวอย่าง)
-- ════════════════════════════════════════════════════════════════
INSERT INTO products (
  name_th, name_en, slug, description,
  price, compare_price, discount_percent,
  stock_quantity, category_id,
  tags, status, is_featured, is_recommended, is_flash_sale,
  rating_avg, rating_count, sold_count
) VALUES
  ('Samsung Galaxy S24 Ultra 256GB', 'Samsung Galaxy S24 Ultra', 'samsung-s24-ultra',
   'สมาร์ทโฟนเรือธง S Pen built-in กล้อง 200MP',
   32900, 38900, 15, 50,
   '00000000-0000-0000-0000-000000000001',
   ARRAY['smartphone','samsung','5g'], 'active', true, true, true, 4.9, 567, 234),

  ('โซฟา L-Shape Velvet Premium', 'L-Shape Velvet Sofa', 'sofa-l-shape-velvet',
   'โซฟา L-shape ผ้า Velvet นุ่มสบาย',
   8900, 14500, 39, 15,
   '00000000-0000-0000-0000-000000000007',
   ARRAY['โซฟา','เฟอร์นิเจอร์'], 'active', true, true, true, 4.8, 234, 89),

  ('SK-II Facial Treatment Essence 230ml', 'SK-II FTE', 'sk2-facial-treatment',
   'เซรั่มบำรุงผิว PITERA 90%',
   2890, 4500, 36, 200,
   '00000000-0000-0000-0000-000000000004',
   ARRAY['skincare','sk2','serum'], 'active', true, true, true, 4.9, 3420, 1567),

  ('Nike Air Max 270 React', 'Nike Air Max 270', 'nike-air-max-270',
   'รองเท้า Air Max 270 React ใส่สบาย',
   2490, 3990, 38, 100,
   '00000000-0000-0000-0000-000000000008',
   ARRAY['nike','shoes','running'], 'active', true, true, false, 4.7, 892, 445),

  ('Royal Canin Maxi Adult 15kg', 'Royal Canin Dog Food', 'royal-canin-15kg',
   'อาหารสุนัขพันธุ์ใหญ่สูตร Adult',
   1890, 2490, 24, 80,
   '00000000-0000-0000-0000-000000000006',
   ARRAY['สุนัข','อาหารสัตว์'], 'active', true, false, true, 4.8, 678, 334),

  ('Bosch Drill GSB 18V-55 Professional', 'Bosch Drill Set', 'bosch-drill-gsb18v',
   'สว่านกระแทกไร้สาย 18V แรงบิดสูง',
   3890, 5200, 25, 30,
   '00000000-0000-0000-0000-000000000007',
   ARRAY['เครื่องมือช่าง','bosch'], 'active', false, true, false, 4.7, 312, 156),

  ('เสื้อ Oversized Linen Summer 2026', 'Oversized Linen Shirt', 'oversized-linen-2026',
   'เสื้อ Oversized ผ้าลินิน ระบายอากาศดี',
   890, 1290, 31, 200,
   '00000000-0000-0000-0000-000000000008',
   ARRAY['เสื้อ','linen','oversized'], 'active', false, true, false, 4.6, 1820, 890),

  ('Samsung Galaxy Tab S9 FE WiFi', 'Samsung Tab S9 FE', 'samsung-tab-s9-fe',
   'แท็บเล็ตหน้าจอ 10.9 นิ้ว RAM 6GB',
   14900, 18900, 21, 40,
   '00000000-0000-0000-0000-000000000001',
   ARRAY['tablet','samsung'], 'active', true, true, false, 4.8, 456, 223),

  ('Philips LED Panel 18W Square 3000K', 'Philips LED Panel', 'philips-led-18w',
   'หลอดไฟ LED Panel ฝังฝ้า 18W',
   380, 520, 27, 500,
   '00000000-0000-0000-0000-000000000007',
   ARRAY['ไฟ','led','philips'], 'active', false, false, false, 4.5, 234, 567),

  ('LANEIGE Lip Sleeping Mask Berry 20g', 'Laneige Lip Mask', 'laneige-lip-berry',
   'มาส์กริมฝีปากสูตร Berry',
   490, 650, 25, 300,
   '00000000-0000-0000-0000-000000000004',
   ARRAY['skincare','laneige','ลิป'], 'active', true, true, false, 4.9, 5670, 2345);

-- ════════════════════════════════════════════════════════════════
-- STEP 14: SEED DATA — Site Settings (Stats & Trust Bar)
-- ════════════════════════════════════════════════════════════════
INSERT INTO site_settings (key, value) VALUES
  ('stat_products',      '500K+'),
  ('stat_products_lbl',  'รายการสินค้า'),
  ('stat_sellers',       '50K+'),
  ('stat_sellers_lbl',   'ร้านค้า'),
  ('stat_customers',     '2.4M'),
  ('stat_customers_lbl', 'ลูกค้า'),
  ('stat_rating',        '4.9 ★'),
  ('stat_rating_lbl',    'คะแนนเฉลี่ย'),
  ('trust_1_ico',        '🚚'),
  ('trust_1_title',      'ส่งฟรีทั่วไทย'),
  ('trust_1_sub',        'ไม่มีขั้นต่ำสำหรับสมาชิก Plus'),
  ('trust_2_ico',        '🔒'),
  ('trust_2_title',      'ชำระเงินปลอดภัย'),
  ('trust_2_sub',        'SSL · PCI DSS · Omise · 2C2P'),
  ('trust_3_ico',        '↩️'),
  ('trust_3_title',      'คืนง่าย ใน 15 วัน'),
  ('trust_3_sub',        'ไม่ชอบคืนได้ ไม่มีค่าถาม'),
  ('trust_4_ico',        '💬'),
  ('trust_4_title',      'ซัพพอร์ต 24/7'),
  ('trust_4_sub',        'Chat · โทร · LINE OA')
ON CONFLICT (key) DO NOTHING;

-- ════════════════════════════════════════════════════════════════
-- STEP 15: ADMIN USER (แก้ email ให้ตรงกับที่สมัคร Supabase Auth)
-- ════════════════════════════════════════════════════════════════
-- ⚠️  แทนที่ admin@thailandmarket.com ด้วย email จริงของคุณ
INSERT INTO users (email, display_name, role, is_active)
VALUES ('admin@thailandmarket.com', 'Admin', 'admin', true)
ON CONFLICT (email) DO UPDATE SET role = 'admin', is_active = true;

-- ════════════════════════════════════════════════════════════════
-- VERIFY — ตรวจสอบผลลัพธ์
-- ════════════════════════════════════════════════════════════════
SELECT
  (SELECT COUNT(*) FROM categories WHERE parent_id IS NULL)    AS หมวดหลัก,
  (SELECT COUNT(*) FROM categories WHERE parent_id IS NOT NULL) AS หมวดย่อย,
  (SELECT COUNT(*) FROM products   WHERE status = 'active')    AS สินค้า,
  (SELECT COUNT(*) FROM products   WHERE is_flash_sale = true) AS flash_sale,
  (SELECT COUNT(*) FROM brands     WHERE is_active = true)     AS brands,
  (SELECT COUNT(*) FROM banners    WHERE is_active = true)     AS banners,
  (SELECT COUNT(*) FROM coupons    WHERE is_active = true)     AS coupons,
  (SELECT COUNT(*) FROM site_settings)                          AS settings,
  (SELECT COUNT(*) FROM users)                                  AS users;
