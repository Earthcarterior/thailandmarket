-- ══════════════════════════════════════════════════════════════
-- Thailand Market — Complete Supabase Setup (All Tables + Seed)
-- Run ใน Supabase SQL Editor → New Query → Run
-- ══════════════════════════════════════════════════════════════

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── DROP existing tables (clean slate) ────────────────────────
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS admin_notifications CASCADE;
DROP TABLE IF EXISTS product_attributes CASCADE;
DROP TABLE IF EXISTS product_variants CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS banners CASCADE;
DROP TABLE IF EXISTS coupons CASCADE;
DROP TABLE IF EXISTS brands CASCADE;
DROP TABLE IF EXISTS flash_sale_events CASCADE;

-- ══════════════════════════════════════════════════════════════
-- TABLES
-- ══════════════════════════════════════════════════════════════

-- ── USERS ──────────────────────────────────────────────────────
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email         TEXT UNIQUE NOT NULL,
  display_name  TEXT NOT NULL DEFAULT 'ผู้ใช้',
  avatar_url    TEXT,
  role          TEXT NOT NULL DEFAULT 'buyer' CHECK (role IN ('buyer','seller','admin')),
  seller_id     UUID,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  loyalty_pts   INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id),
  shop_name     TEXT NOT NULL,
  shop_logo     TEXT,
  shop_banner   TEXT,
  description   TEXT,
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','suspended')),
  is_verified   BOOLEAN NOT NULL DEFAULT false,
  rating_avg    DECIMAL(3,2) NOT NULL DEFAULT 0,
  rating_count  INTEGER NOT NULL DEFAULT 0,
  total_sales   INTEGER NOT NULL DEFAULT 0,
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
  deleted_at        TIMESTAMPTZ,

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
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code          TEXT UNIQUE NOT NULL,
  title         TEXT NOT NULL,
  description   TEXT,
  type          TEXT NOT NULL DEFAULT 'fixed' CHECK (type IN ('fixed','percent','free_ship')),
  value         DECIMAL(10,2) NOT NULL DEFAULT 0,
  min_purchase  DECIMAL(10,2) NOT NULL DEFAULT 0,
  max_discount  DECIMAL(10,2),
  used_count    INTEGER NOT NULL DEFAULT 0,
  max_uses      INTEGER,
  starts_at     TIMESTAMPTZ DEFAULT NOW(),
  expires_at    TIMESTAMPTZ,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── FLASH SALE EVENTS ──────────────────────────────────────────
CREATE TABLE flash_sale_events (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title       TEXT NOT NULL DEFAULT 'Flash Sale',
  starts_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at     TIMESTAMPTZ NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── NOTIFICATIONS ──────────────────────────────────────────────
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT,
  data        JSONB,
  is_read     BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE admin_notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type        TEXT NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT,
  data        JSONB,
  is_read     BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════
-- INDEXES
-- ══════════════════════════════════════════════════════════════
CREATE INDEX idx_products_status     ON products(status);
CREATE INDEX idx_products_category   ON products(category_id);
CREATE INDEX idx_products_flash      ON products(is_flash_sale) WHERE is_flash_sale = true;
CREATE INDEX idx_products_featured   ON products(is_featured) WHERE is_featured = true;
CREATE INDEX idx_products_created    ON products(created_at DESC);
CREATE INDEX idx_products_price      ON products(price);
CREATE INDEX idx_categories_parent   ON categories(parent_id);
CREATE INDEX idx_users_email         ON users(email);
CREATE INDEX idx_sellers_user        ON sellers(user_id);
CREATE INDEX idx_notifications_user  ON notifications(user_id, is_read);

-- ══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ══════════════════════════════════════════════════════════════
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE flash_sale_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Public read policies
CREATE POLICY "public_read_categories" ON categories FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_active_products" ON products FOR SELECT USING (status = 'active');
CREATE POLICY "public_read_banners" ON banners FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_coupons" ON coupons FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_brands" ON brands FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_flash_events" ON flash_sale_events FOR SELECT USING (is_active = true);
CREATE POLICY "public_read_sellers" ON sellers FOR SELECT USING (status = 'active');

-- Auth write policies
CREATE POLICY "auth_insert_products" ON products FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "auth_update_own_products" ON products FOR UPDATE TO authenticated
  USING (auth.uid()::text = created_by::text OR created_by IS NULL);
CREATE POLICY "auth_read_own_products" ON products FOR SELECT TO authenticated
  USING (status = 'active' OR auth.uid()::text = created_by::text OR created_by IS NULL);
CREATE POLICY "auth_manage_users" ON users FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_read_notifications" ON notifications FOR SELECT TO authenticated
  USING (auth.uid()::text IN (SELECT email FROM users WHERE id = notifications.user_id));

-- ══════════════════════════════════════════════════════════════
-- TRIGGERS
-- ══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER sellers_updated_at BEFORE UPDATE ON sellers FOR EACH ROW EXECUTE FUNCTION update_updated_at();

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

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Categories (12 หมวดหลัก + UUID-safe)
-- ══════════════════════════════════════════════════════════════
INSERT INTO categories (id, name_th, name_en, slug, icon, sort_order, is_active) VALUES
  ('00000000-0000-0000-0000-000000000001','อุปกรณ์อิเล็กทรอนิกส์',    'Electronic Devices',     'electronic-devices',    '📱',1, true),
  ('00000000-0000-0000-0000-000000000002','อุปกรณ์เสริมอิเล็กทรอนิกส์','Electronic Accessories', 'electronic-accessories','🔌',2, true),
  ('00000000-0000-0000-0000-000000000003','ทีวีและเครื่องใช้ไฟฟ้า',    'TV & Home Appliances',   'tv-home-appliances',    '📺',3, true),
  ('00000000-0000-0000-0000-000000000004','สุขภาพและความงาม',          'Health & Beauty',        'health-beauty',         '💄',4, true),
  ('00000000-0000-0000-0000-000000000005','แม่และเด็ก / ของเล่น',      'Babies & Toys',          'babies-toys',           '🍼',5, true),
  ('00000000-0000-0000-0000-000000000006','ของชำและสัตว์เลี้ยง',       'Groceries & Pets',       'groceries-pets',        '🛒',6, true),
  ('00000000-0000-0000-0000-000000000007','บ้านและไลฟ์สไตล์',          'Home & Lifestyle',       'home-lifestyle',        '🏠',7, true),
  ('00000000-0000-0000-0000-000000000008','แฟชั่นผู้หญิง',             'Women''s Fashion',       'womens-fashion',        '👗',8, true),
  ('00000000-0000-0000-0000-000000000009','แฟชั่นผู้ชาย',              'Men''s Fashion',         'mens-fashion',          '👔',9, true),
  ('00000000-0000-0000-0000-000000000010','แฟชั่นเด็ก',                'Kid''s Fashion',         'kids-fashion',          '👧',10,true),
  ('00000000-0000-0000-0000-000000000011','กีฬาและการเดินทาง',         'Sports & Travel',        'sports-travel',         '🏋️',11,true),
  ('00000000-0000-0000-0000-000000000012','ยานยนต์',                   'Automotive',             'automotive',            '🚗',12,true);

-- หมวดย่อย: Electronic Devices
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('โทรศัพท์มือถือ','Mobiles','mobiles','📱','00000000-0000-0000-0000-000000000001',1,true),
  ('แท็บเล็ต','Tablets','tablets','📟','00000000-0000-0000-0000-000000000001',2,true),
  ('โน้ตบุ๊ก','Laptops','laptops','💻','00000000-0000-0000-0000-000000000001',3,true),
  ('คอมพิวเตอร์ตั้งโต๊ะ','Desktops','desktops','🖥️','00000000-0000-0000-0000-000000000001',4,true),
  ('กล้องถ่ายรูป','Cameras','cameras','📷','00000000-0000-0000-0000-000000000001',5,true),
  ('โดรน','Drones','drones','🛸','00000000-0000-0000-0000-000000000001',6,true),
  ('เครื่องเล่นเกม','Console Gaming','console-gaming','🎮','00000000-0000-0000-0000-000000000001',7,true);

-- หมวดย่อย: Health & Beauty
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('ดูแลผิวหน้า','Skincare','skincare','✨','00000000-0000-0000-0000-000000000004',1,true),
  ('เครื่องสำอาง','Make-Up','makeup','💄','00000000-0000-0000-0000-000000000004',2,true),
  ('ดูแลเส้นผม','Hair Care','hair-care','💇','00000000-0000-0000-0000-000000000004',3,true),
  ('น้ำหอม','Fragrances','fragrances','🌸','00000000-0000-0000-0000-000000000004',4,true),
  ('วิตามินและอาหารเสริม','Vitamins','vitamins','💊','00000000-0000-0000-0000-000000000004',5,true);

-- หมวดย่อย: Home & Lifestyle + ต้นไม้ + ช่าง
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('เฟอร์นิเจอร์','Furniture','furniture','🛋️','00000000-0000-0000-0000-000000000007',1,true),
  ('โคมไฟ','Lighting','lighting','💡','00000000-0000-0000-0000-000000000007',2,true),
  ('ของตกแต่งบ้าน','Home Décor','home-decor','🖼️','00000000-0000-0000-0000-000000000007',3,true),
  ('ครัวและอุปกรณ์','Kitchen','kitchen-dining','🍳','00000000-0000-0000-0000-000000000007',4,true),
  ('ต้นไม้และพืชสวน','Plants & Garden','plants-gardening','🪴','00000000-0000-0000-0000-000000000007',5,true),
  ('ช่างและวัสดุก่อสร้าง','Hardware','hardware-building','🔨','00000000-0000-0000-0000-000000000007',6,true);

-- หมวดย่อย: Women Fashion
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('เสื้อผ้าผู้หญิง','Women Clothing','womens-clothing','👗','00000000-0000-0000-0000-000000000008',1,true),
  ('รองเท้าผู้หญิง','Women Shoes','womens-shoes','👠','00000000-0000-0000-0000-000000000008',2,true),
  ('กระเป๋าผู้หญิง','Women Bags','womens-bags','👜','00000000-0000-0000-0000-000000000008',3,true),
  ('เครื่องประดับ','Accessories','womens-accessories','💍','00000000-0000-0000-0000-000000000008',4,true);

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Brands
-- ══════════════════════════════════════════════════════════════
INSERT INTO brands (name,slug,icon,is_featured,sort_order,is_active) VALUES
  ('Samsung','samsung','📱',true,1,true),
  ('Apple','apple','🍎',true,2,true),
  ('LG','lg','📺',true,3,true),
  ('IKEA','ikea','🛋️',true,4,true),
  ('Panasonic','panasonic','❄️',true,5,true),
  ('Nike','nike','👟',true,6,true),
  ('L''Oreal','loreal','💄',true,7,true),
  ('Royal Canin','royal-canin','🐾',true,8,true);

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Banners
-- ══════════════════════════════════════════════════════════════
INSERT INTO banners (title,subtitle,icon,cta_text,cta_url,bg_color,text_color,discount,type,sort_order,is_active) VALUES
  ('บ้านสวย เริ่มต้นที่นี่','เฟอร์นิเจอร์และของตกแต่งบ้าน','🏠','ช้อปเลย →','storefront-live.html?cat=00000000-0000-0000-0000-000000000007','#0A0A0A','#FFFFFF','ลดสูงสุด 40%','main',1,true),
  ('Fashion Week Sale','เสื้อผ้า รองเท้า กระเป๋า','👗','ดูเลย','storefront-live.html?cat=00000000-0000-0000-0000-000000000008','#1a1a2e','#FFFFFF','-60%','side',2,true),
  ('Tech Special Deal','Gadgets & Electronics','💻','ช้อป','storefront-live.html?cat=00000000-0000-0000-0000-000000000001','#0f0f23','#FFFFFF','-50%','side',3,true);

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Coupons
-- ══════════════════════════════════════════════════════════════
INSERT INTO coupons (code,title,type,value,min_purchase,expires_at,is_active) VALUES
  ('SAVE50','ลด ฿50','fixed',50,300,NOW() + INTERVAL '30 days',true),
  ('TM10PCT','ลด 10%','percent',10,500,NOW() + INTERVAL '30 days',true),
  ('FREESHIP','ส่งฟรี','free_ship',0,0,NOW() + INTERVAL '30 days',true);

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Flash Sale Event
-- ══════════════════════════════════════════════════════════════
INSERT INTO flash_sale_events (title,starts_at,ends_at,is_active) VALUES
  ('Flash Sale ประจำวัน',NOW(),NOW() + INTERVAL '3 hours',true);

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Sample Products (10 รายการตัวอย่าง)
-- ══════════════════════════════════════════════════════════════
INSERT INTO products (name_th,name_en,slug,description,price,compare_price,discount_percent,stock_quantity,category_id,images,thumbnail,tags,status,is_featured,is_recommended,is_flash_sale,rating_avg,rating_count,sold_count) VALUES
  ('Samsung Galaxy S24 Ultra 256GB','Samsung Galaxy S24 Ultra','samsung-s24-ultra','สมาร์ทโฟนเรือธง S Pen built-in กล้อง 200MP',32900,38900,15,50,'00000000-0000-0000-0000-000000000001','{}',null,ARRAY['smartphone','samsung','5g'],'active',true,true,true,4.9,567,234),
  ('โซฟา L-Shape Velvet Premium','L-Shape Velvet Sofa','sofa-l-shape-velvet','โซฟา L-shape ผ้า Velvet นุ่มสบาย โครงไม้แข็งแรง',8900,14500,39,15,'00000000-0000-0000-0000-000000000007','{}',null,ARRAY['โซฟา','เฟอร์นิเจอร์','ห้องนั่งเล่น'],'active',true,true,true,4.8,234,89),
  ('SK-II Facial Treatment Essence 230ml','SK-II FTE','sk2-facial-treatment','เซรั่มบำรุงผิวชื่อดัง PITERA 90% ผิวกระจ่างใส',2890,4500,36,200,'00000000-0000-0000-0000-000000000004','{}',null,ARRAY['skincare','sk2','serum'],'active',true,true,true,4.9,3420,1567),
  ('Nike Air Max 270 React','Nike Air Max 270','nike-air-max-270','รองเท้า Air Max 270 React ใส่สบาย รองรับแรงกระแทก',2490,3990,38,100,'00000000-0000-0000-0000-000000000008','{}',null,ARRAY['nike','shoes','running'],'active',true,true,false,4.7,892,445),
  ('Royal Canin Maxi Adult 15kg','Royal Canin Dog Food','royal-canin-15kg','อาหารสุนัขพันธุ์ใหญ่ สูตร Adult คุณภาพสูง',1890,2490,24,80,'00000000-0000-0000-0000-000000000006','{}',null,ARRAY['สุนัข','อาหารสัตว์','royal-canin'],'active',true,false,true,4.8,678,334),
  ('Bosch Drill GSB 18V-55 Professional','Bosch Drill Set','bosch-drill-gsb18v','สว่านกระแทกไร้สาย 18V แรงบิดสูง พร้อมกระเป๋า',3890,5200,25,30,'00000000-0000-0000-0000-000000000007','{}',null,ARRAY['เครื่องมือช่าง','bosch','สว่าน'],'active',false,true,false,4.7,312,156),
  ('เสื้อ Oversized Linen Summer 2026','Oversized Linen Shirt','oversized-linen-2026','เสื้อ Oversized ผ้าลินิน ระบายอากาศดี ใส่สบาย',890,1290,31,200,'00000000-0000-0000-0000-000000000008','{}',null,ARRAY['เสื้อ','linen','oversized','ใหม่'],'active',false,true,false,4.6,1820,890),
  ('Samsung Galaxy Tab S9 FE WiFi','Samsung Tab S9 FE','samsung-tab-s9-fe','แท็บเล็ตหน้าจอ 10.9 นิ้ว RAM 6GB Storage 128GB',14900,18900,21,40,'00000000-0000-0000-0000-000000000001','{}',null,ARRAY['tablet','samsung','ipad'],'active',true,true,false,4.8,456,223),
  ('Philips LED Panel 18W Square 3000K','Philips LED Panel','philips-led-18w','หลอดไฟ LED Panel ฝังฝ้า 18W แสงสีเหลือง',380,520,27,500,'00000000-0000-0000-0000-000000000007','{}',null,ARRAY['ไฟ','led','philips'],'active',false,false,false,4.5,234,567),
  ('LANEIGE Lip Sleeping Mask Berry 20g','Laneige Lip Mask','laneige-lip-berry','มาส์กริมฝีปากสูตร Berry ราตรีกาล บำรุงล้ำลึก',490,650,25,300,'00000000-0000-0000-0000-000000000004','{}',null,ARRAY['skincare','laneige','ลิป'],'active',true,true,false,4.9,5670,2345);

-- ══════════════════════════════════════════════════════════════
-- STORAGE BUCKET
-- ══════════════════════════════════════════════════════════════
INSERT INTO storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
VALUES ('product-images','product-images',true,10485760,
        ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "public_read_images" ON storage.objects
  FOR SELECT USING (bucket_id='product-images');
CREATE POLICY "auth_upload_images" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id='product-images');


-- ══════════════════════════════════════════════════════════════
-- ADDITIONAL TABLES (Orders, Reviews, Wishlist, Variants)
-- ══════════════════════════════════════════════════════════════

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
  order_number    TEXT UNIQUE NOT NULL,
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
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES products(id),
  variant_id  UUID REFERENCES product_variants(id),
  name_th     TEXT NOT NULL,
  thumbnail   TEXT,
  price       DECIMAL(10,2) NOT NULL,
  qty         INTEGER NOT NULL DEFAULT 1,
  subtotal    DECIMAL(12,2) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id  UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- ── INDEXES (additional) ───────────────────────────────────────
CREATE INDEX idx_orders_user      ON orders(user_id);
CREATE INDEX idx_orders_status    ON orders(status);
CREATE INDEX idx_orders_number    ON orders(order_number);
CREATE INDEX idx_order_items_ord  ON order_items(order_id);
CREATE INDEX idx_reviews_product  ON reviews(product_id);
CREATE INDEX idx_wishlist_user    ON wishlist(user_id);

-- ── RLS (additional) ──────────────────────────────────────────
ALTER TABLE orders          ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items     ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews         ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist        ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- Orders: users read/create own
CREATE POLICY "auth_own_orders" ON orders FOR ALL TO authenticated
  USING (auth.uid()::text IN (SELECT email FROM users WHERE id = orders.user_id));
CREATE POLICY "auth_insert_order" ON orders FOR INSERT TO authenticated WITH CHECK (true);

-- Order items: read if owns order
CREATE POLICY "auth_read_order_items" ON order_items FOR SELECT TO authenticated
  USING (order_id IN (SELECT id FROM orders));

-- Reviews: public read
CREATE POLICY "public_read_reviews" ON reviews FOR SELECT USING (true);
CREATE POLICY "auth_insert_reviews" ON reviews FOR INSERT TO authenticated WITH CHECK (true);

-- Wishlist: own
CREATE POLICY "auth_own_wishlist" ON wishlist FOR ALL TO authenticated
  USING (auth.uid()::text IN (SELECT email FROM users WHERE id = wishlist.user_id));
CREATE POLICY "auth_insert_wishlist" ON wishlist FOR INSERT TO authenticated WITH CHECK (true);

-- Product variants: public read
CREATE POLICY "public_read_variants" ON product_variants FOR SELECT USING (true);

-- ── TRIGGER: Auto-update order updated_at ────────────────────
CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── FUNCTION: Update product rating after review ─────────────
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE products SET
    rating_avg = (SELECT ROUND(AVG(rating)::numeric, 2) FROM reviews WHERE product_id = NEW.product_id),
    rating_count = (SELECT COUNT(*) FROM reviews WHERE product_id = NEW.product_id)
  WHERE id = NEW.product_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER review_rating_sync
  AFTER INSERT OR UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_product_rating();

-- ── FUNCTION: Generate order number ──────────────────────────
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number = 'TM' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                       LPAD(NEXTVAL('order_seq')::text, 5, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS order_seq START 1;
CREATE TRIGGER order_number_gen
  BEFORE INSERT ON orders FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Sample Reviews
-- ══════════════════════════════════════════════════════════════
INSERT INTO reviews (product_id, rating, title, body, is_verified)
SELECT id, 5, 'สินค้าดีมาก!', 'คุณภาพดีเกินราคา ส่งเร็ว แพ็คเกจสวยงาม แนะนำเลย', true
FROM products WHERE status = 'active' LIMIT 5;

INSERT INTO reviews (product_id, rating, title, body, is_verified)
SELECT id, 4, 'ประทับใจ', 'ใช้งานได้ดี ตรงปก จะกลับมาซื้ออีก', true
FROM products WHERE status = 'active' LIMIT 3;

-- ══════════════════════════════════════════════════════════════
-- SEED DATA: Admin User (เพิ่มหลัง login ครั้งแรก)
-- ══════════════════════════════════════════════════════════════
-- หมายเหตุ: รัน SQL นี้หลังจาก Login ใน admin-cms.html ครั้งแรกแล้ว
-- แทนที่ admin@yoursite.com ด้วย email ที่ใช้สมัคร Supabase Auth
INSERT INTO users (email, display_name, role, is_active)
VALUES ('admin@thailandmarket.com', 'Admin', 'admin', true)
ON CONFLICT (email) DO UPDATE SET role = 'admin', is_active = true;

-- ══════════════════════════════════════════════════════════════
-- FINAL VERIFY
-- ══════════════════════════════════════════════════════════════
SELECT
  (SELECT COUNT(*) FROM categories WHERE parent_id IS NULL)   AS หมวดหลัก,
  (SELECT COUNT(*) FROM categories WHERE parent_id IS NOT NULL) AS หมวดย่อย,
  (SELECT COUNT(*) FROM products WHERE status='active')        AS สินค้า_active,
  (SELECT COUNT(*) FROM products WHERE is_flash_sale=true)     AS flash_sale,
  (SELECT COUNT(*) FROM banners WHERE is_active=true)          AS banners,
  (SELECT COUNT(*) FROM coupons WHERE is_active=true)          AS coupons,
  (SELECT COUNT(*) FROM brands WHERE is_active=true)           AS brands,
  (SELECT COUNT(*) FROM reviews)                               AS reviews,
  (SELECT COUNT(*) FROM users)                                 AS users;

