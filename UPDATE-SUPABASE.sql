-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  Thailand Market — UPDATE SUPABASE (Complete Master File)           ║
-- ║  Run ไฟล์เดียวนี้ใน Supabase SQL Editor → New Query → Run All      ║
-- ║  ครอบคลุมทุกหน้า: index · storefront · profile · wishlist ·        ║
-- ║                   seller-portal · onboarding · checkout             ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════
-- STEP 1 : EXTENSIONS
-- ════════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ════════════════════════════════════════════════════════════════════
-- STEP 2 : USERS — patch columns + RLS
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS birthday    DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender      TEXT
  CHECK (gender IN ('male','female','other') OR gender IS NULL);
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone       TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url  TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS seller_id   UUID;
ALTER TABLE users ADD COLUMN IF NOT EXISTS loyalty_pts INTEGER NOT NULL DEFAULT 0;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='users'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON users'; END LOOP; END $$;

CREATE POLICY "users_select_auth" ON users
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "users_update_own" ON users
  FOR UPDATE TO authenticated
  USING  (email = auth.jwt()->>'email')
  WITH CHECK (email = auth.jwt()->>'email');
CREATE POLICY "users_insert_auth" ON users
  FOR INSERT TO authenticated WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════════
-- STEP 3 : CATEGORIES RLS
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='categories'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON categories'; END LOOP; END $$;

CREATE POLICY "categories_public_read" ON categories
  FOR SELECT USING (is_active = true);
CREATE POLICY "categories_admin_all" ON categories
  FOR ALL TO authenticated
  USING ((SELECT role FROM users WHERE email=auth.jwt()->>'email' LIMIT 1)='admin');

-- ════════════════════════════════════════════════════════════════════
-- STEP 4 : PRODUCTS RLS + seller_id column
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE products ADD COLUMN IF NOT EXISTS seller_id UUID REFERENCES sellers(id);
ALTER TABLE products ADD COLUMN IF NOT EXISTS flash_price DECIMAL(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS weight     DECIMAL(8,2);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='products'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON products'; END LOOP; END $$;

CREATE POLICY "products_public_read" ON products
  FOR SELECT USING (status = 'active');
CREATE POLICY "products_seller_insert" ON products
  FOR INSERT TO authenticated
  WITH CHECK (
    seller_id IN (SELECT id FROM sellers WHERE user_id IN
      (SELECT id FROM users WHERE email=auth.jwt()->>'email'))
    OR (SELECT role FROM users WHERE email=auth.jwt()->>'email' LIMIT 1)='admin'
  );
CREATE POLICY "products_seller_update" ON products
  FOR UPDATE TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id IN
      (SELECT id FROM users WHERE email=auth.jwt()->>'email'))
    OR (SELECT role FROM users WHERE email=auth.jwt()->>'email' LIMIT 1)='admin'
  );

-- ════════════════════════════════════════════════════════════════════
-- STEP 5 : SELLERS RLS
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='sellers'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON sellers'; END LOOP; END $$;

CREATE POLICY "sellers_select_all" ON sellers
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "sellers_insert_auth" ON sellers
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "sellers_update_own" ON sellers
  FOR UPDATE TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));

-- ════════════════════════════════════════════════════════════════════
-- STEP 6 : WISHLIST table + RLS
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS wishlist (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);
CREATE INDEX IF NOT EXISTS idx_wishlist_user    ON wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_product ON wishlist(product_id);

ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='wishlist'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON wishlist'; END LOOP; END $$;

CREATE POLICY "wish_select_own" ON wishlist FOR SELECT TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));
CREATE POLICY "wish_insert_own" ON wishlist FOR INSERT TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));
CREATE POLICY "wish_delete_own" ON wishlist FOR DELETE TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));

-- ════════════════════════════════════════════════════════════════════
-- STEP 7 : ADDRESSES table + RLS
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS addresses (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  phone       TEXT NOT NULL,
  line1       TEXT NOT NULL,
  subdistrict TEXT,
  district    TEXT,
  province    TEXT NOT NULL,
  postcode    TEXT NOT NULL,
  tag         TEXT DEFAULT 'บ้าน',
  is_default  BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_addresses_user ON addresses(user_id);

ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='addresses'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON addresses'; END LOOP; END $$;

CREATE POLICY "addr_select_own" ON addresses FOR SELECT TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));
CREATE POLICY "addr_insert_own" ON addresses FOR INSERT TO authenticated
  WITH CHECK (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));
CREATE POLICY "addr_update_own" ON addresses FOR UPDATE TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));
CREATE POLICY "addr_delete_own" ON addresses FOR DELETE TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));

-- trigger updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at=NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS addresses_updated_at ON addresses;
CREATE TRIGGER addresses_updated_at BEFORE UPDATE ON addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ════════════════════════════════════════════════════════════════════
-- STEP 8 : ORDERS RLS
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='orders'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON orders'; END LOOP; END $$;

CREATE POLICY "orders_select_own" ON orders FOR SELECT TO authenticated
  USING (
    user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email')
    OR (SELECT role FROM users WHERE email=auth.jwt()->>'email' LIMIT 1) IN ('admin','seller')
  );
CREATE POLICY "orders_insert_auth" ON orders
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "orders_update_own" ON orders FOR UPDATE TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));

-- ════════════════════════════════════════════════════════════════════
-- STEP 9 : ORDER_ITEMS RLS
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='order_items'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON order_items'; END LOOP; END $$;

CREATE POLICY "oi_select_own" ON order_items FOR SELECT TO authenticated
  USING (order_id IN (
    SELECT id FROM orders WHERE user_id IN
      (SELECT id FROM users WHERE email=auth.jwt()->>'email')
  ));
CREATE POLICY "oi_insert_auth" ON order_items
  FOR INSERT TO authenticated WITH CHECK (true);

-- ════════════════════════════════════════════════════════════════════
-- STEP 10 : REVIEWS RLS
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='reviews'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON reviews'; END LOOP; END $$;

CREATE POLICY "reviews_select_all" ON reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert_auth" ON reviews FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "reviews_update_own" ON reviews FOR UPDATE TO authenticated
  USING (user_id IN (SELECT id FROM users WHERE email=auth.jwt()->>'email'));

-- ════════════════════════════════════════════════════════════════════
-- STEP 11 : COUPONS RLS
-- ════════════════════════════════════════════════════════════════════
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='coupons'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON coupons'; END LOOP; END $$;

CREATE POLICY "coupons_public_read" ON coupons
  FOR SELECT USING (is_active = true);
CREATE POLICY "coupons_admin_all" ON coupons FOR ALL TO authenticated
  USING ((SELECT role FROM users WHERE email=auth.jwt()->>'email' LIMIT 1)='admin');

-- ════════════════════════════════════════════════════════════════════
-- STEP 12 : STORAGE BUCKETS
-- ════════════════════════════════════════════════════════════════════
-- product-images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('product-images','product-images',true,5242880,
  ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO UPDATE SET
  public=true, file_size_limit=5242880,
  allowed_mime_types=ARRAY['image/jpeg','image/png','image/webp','image/gif'];

-- profile-images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('profile-images','profile-images',true,5242880,
  ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO UPDATE SET
  public=true, file_size_limit=5242880,
  allowed_mime_types=ARRAY['image/jpeg','image/png','image/webp','image/gif'];

-- Storage policies
DROP POLICY IF EXISTS "public_read_product_images"  ON storage.objects;
DROP POLICY IF EXISTS "auth_upload_product_images"  ON storage.objects;
DROP POLICY IF EXISTS "public_read_profile_images"  ON storage.objects;
DROP POLICY IF EXISTS "auth_upload_profile_images"  ON storage.objects;
DROP POLICY IF EXISTS "auth_update_profile_images"  ON storage.objects;
DROP POLICY IF EXISTS "auth_delete_profile_images"  ON storage.objects;

CREATE POLICY "public_read_product_images" ON storage.objects
  FOR SELECT USING (bucket_id='product-images');
CREATE POLICY "auth_upload_product_images" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id='product-images');

CREATE POLICY "public_read_profile_images" ON storage.objects
  FOR SELECT USING (bucket_id='profile-images');
CREATE POLICY "auth_upload_profile_images" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id='profile-images' AND name LIKE 'avatars/%');
CREATE POLICY "auth_update_profile_images" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id='profile-images' AND name LIKE 'avatars/%');
CREATE POLICY "auth_delete_profile_images" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id='profile-images' AND name LIKE 'avatars/%');

-- ════════════════════════════════════════════════════════════════════
-- STEP 13 : AUTO-CREATE USER ROW TRIGGER
-- ════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
  INSERT INTO public.users (email, display_name, role, is_active, loyalty_pts)
  VALUES (
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email,'@',1)),
    COALESCE(NEW.raw_user_meta_data->>'role','buyer'),
    true, 0
  )
  ON CONFLICT (email) DO UPDATE SET updated_at=NOW();
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- ════════════════════════════════════════════════════════════════════
-- STEP 14 : BACKFILL Auth users → users table
-- ════════════════════════════════════════════════════════════════════
INSERT INTO public.users (email, display_name, role, is_active, loyalty_pts)
SELECT au.email,
  COALESCE(au.raw_user_meta_data->>'display_name', split_part(au.email,'@',1)),
  COALESCE(au.raw_user_meta_data->>'role','buyer'), true, 0
FROM auth.users au
LEFT JOIN public.users pu ON pu.email=au.email
WHERE pu.id IS NULL
ON CONFLICT (email) DO NOTHING;

-- ════════════════════════════════════════════════════════════════════
-- STEP 15 : SAMPLE DATA (seller + orders + coupons)
-- ════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  v_uid       UUID;
  v_seller_id UUID;
  v_order_id  UUID;
  v_prod_ids  UUID[];
  v_prod      RECORD;
  v_total     DECIMAL;
  v_statuses  TEXT[] := ARRAY['delivered','delivered','delivered','shipped','processing','confirmed','pending','cancelled'];
  v_methods   TEXT[] := ARRAY['credit_card','promptpay','cod','credit_card','promptpay'];
  i INT; j INT;
BEGIN
  -- ── Seller ──
  SELECT id INTO v_uid FROM public.users ORDER BY created_at LIMIT 1;
  IF v_uid IS NULL THEN RAISE NOTICE 'No users found'; RETURN; END IF;

  INSERT INTO public.sellers (user_id,shop_name,description,status,is_verified,rating_avg,rating_count,total_sales)
  VALUES (v_uid,'Thailand Market Official','ร้านค้าหลักของ Thailand Market','active',true,4.9,1247,2847)
  ON CONFLICT (user_id) DO UPDATE SET status='active',is_verified=true,updated_at=NOW()
  RETURNING id INTO v_seller_id;

  IF v_seller_id IS NULL THEN
    SELECT id INTO v_seller_id FROM sellers WHERE user_id=v_uid LIMIT 1;
  END IF;

  UPDATE public.users SET role=CASE WHEN role='admin' THEN 'admin' ELSE 'seller' END,
    seller_id=v_seller_id WHERE id=v_uid;

  -- เชื่อม products กับ seller
  UPDATE products SET seller_id=v_seller_id WHERE seller_id IS NULL AND status='active';

  -- ── Orders (30 ออเดอร์) ──
  SELECT ARRAY(SELECT id FROM products WHERE status='active' ORDER BY created_at) INTO v_prod_ids;

  DELETE FROM order_items WHERE order_id IN (
    SELECT id FROM orders WHERE order_number LIKE 'TM2026%' AND user_id=v_uid);
  DELETE FROM orders WHERE order_number LIKE 'TM2026%' AND user_id=v_uid;

  FOR i IN 1..30 LOOP
    v_total := 0;
    INSERT INTO orders (
      user_id, order_number, status,
      payment_method, payment_status,
      shipping_name, shipping_phone, shipping_addr,
      shipping_fee, discount_amount,
      confirmed_at, shipped_at, delivered_at,
      created_at, updated_at
    ) VALUES (
      v_uid,
      'TM2026'||LPAD(i::TEXT,8,'0'),
      v_statuses[(i % array_length(v_statuses,1))+1],
      v_methods[(i % array_length(v_methods,1))+1],
      CASE WHEN v_statuses[(i%array_length(v_statuses,1))+1] IN
        ('delivered','shipped','processing','confirmed') THEN 'paid' ELSE 'unpaid' END,
      'ผู้ซื้อตัวอย่าง '||i,
      '08'||LPAD(((i*7+1234567) % 100000000)::TEXT,8,'0'),
      'บ้านเลขที่ '||(i*10+1)||' ถ.สุขุมวิท กรุงเทพ 10110',
      CASE WHEN i%4=0 THEN 0 ELSE 50 END,
      CASE WHEN i%5=0 THEN 100 ELSE 0 END,
      CASE WHEN v_statuses[(i%array_length(v_statuses,1))+1]!='pending'
        THEN NOW()-((i*3%90+1)||' days')::INTERVAL ELSE NULL END,
      CASE WHEN v_statuses[(i%array_length(v_statuses,1))+1] IN ('shipped','delivered')
        THEN NOW()-((i*3%90-1)||' days')::INTERVAL ELSE NULL END,
      CASE WHEN v_statuses[(i%array_length(v_statuses,1))+1]='delivered'
        THEN NOW()-((i*3%30)||' days')::INTERVAL ELSE NULL END,
      NOW()-((i*3%90+1)||' days')::INTERVAL,
      NOW()
    ) RETURNING id INTO v_order_id;

    FOR j IN 1..(i%3+1) LOOP
      IF array_length(v_prod_ids,1) IS NULL THEN EXIT; END IF;
      SELECT * INTO v_prod FROM products
        WHERE id=v_prod_ids[((i+j-1)%array_length(v_prod_ids,1))+1];
      IF v_prod.id IS NULL THEN CONTINUE; END IF;
      INSERT INTO order_items (order_id,product_id,name_th,thumbnail,price,qty,subtotal)
      VALUES (v_order_id,v_prod.id,v_prod.name_th,v_prod.thumbnail,
              v_prod.price,(j%3)+1,v_prod.price*((j%3)+1));
      v_total := v_total + v_prod.price*((j%3)+1);
      UPDATE products SET sold_count=COALESCE(sold_count,0)+(j%3+1) WHERE id=v_prod.id;
    END LOOP;

    UPDATE orders SET
      total_amount=v_total + CASE WHEN i%4=0 THEN 0 ELSE 50 END
                           - CASE WHEN i%5=0 THEN 100 ELSE 0 END
    WHERE id=v_order_id;
  END LOOP;

  UPDATE public.users SET loyalty_pts=3850 WHERE id=v_uid;
  RAISE NOTICE 'Created 30 orders for user: %', v_uid;
END $$;

-- ── Coupons ──
INSERT INTO coupons (code,title,type,value,min_purchase,max_discount,is_active,expires_at)
VALUES
  ('SAVE50',  'ลด ฿50 ขั้นต่ำ ฿300',      'fixed',    50,  300, 50,  true, NOW()+INTERVAL'30 days'),
  ('TM10PCT', 'ลด 10% ทุกหมวดหมู่',        'percent',  10,  500, 200, true, NOW()+INTERVAL'30 days'),
  ('FREESHIP','ส่งฟรีทุกออเดอร์',           'free_ship', 0,   0,  0,  true, NOW()+INTERVAL'30 days'),
  ('SAVE200', 'ลด ฿200 เมื่อซื้อครบ ฿1000','fixed',   200, 1000,200, true, NOW()+INTERVAL'15 days'),
  ('FLASH20', 'Flash Sale ลด 20%',          'percent',  20,  200, 500,true, NOW()+INTERVAL'7 days'),
  ('TM20NEW', 'ลด 20% สมาชิกใหม่',         'percent',  20,  300, 400,true, NOW()+INTERVAL'7 days')
ON CONFLICT (code) DO NOTHING;

-- ── Reviews ──
DO $$
DECLARE
  v_uid UUID;
  v_prod RECORD;
  v_order_id UUID;
  v_bodies TEXT[][] := ARRAY[
    ARRAY['สินค้าดีมาก คุณภาพเกินราคา','ของแท้ ส่งไวมาก ประทับใจ'],
    ARRAY['สินค้าตรงปก ส่งเร็ว','ใช้งานดีตามโฆษณา คุ้มค่ามาก'],
    ARRAY['ประทับใจมาก จะกลับมาซื้อ','ราคาดี คุณภาพดี ส่งเร็ว'],
    ARRAY['ของแท้ 100% ส่งไวมาก','สินค้าสวย ตรงตามรูป ชอบมาก'],
    ARRAY['ดีเยี่ยม บรรจุภัณฑ์แน่น','คุณภาพดี ราคาสมเหตุสมผล']
  ];
  i INT := 1;
BEGIN
  SELECT id INTO v_uid FROM public.users ORDER BY created_at LIMIT 1;
  IF v_uid IS NULL THEN RETURN; END IF;
  FOR v_prod IN SELECT id FROM products WHERE status='active' LIMIT 10 LOOP
    SELECT o.id INTO v_order_id FROM orders o
      WHERE o.user_id=v_uid AND o.status='delivered' ORDER BY RANDOM() LIMIT 1;
    INSERT INTO reviews (product_id,user_id,order_id,rating,title,body,is_verified)
    VALUES (v_prod.id,v_uid,v_order_id,CASE WHEN i%5=0 THEN 4 ELSE 5 END,
      v_bodies[((i-1)%5)+1][1], v_bodies[((i-1)%5)+1][2], true)
    ON CONFLICT DO NOTHING;
    i := i+1;
  END LOOP;
END $$;

-- ── Flash Sale events ──
INSERT INTO flash_sale_events (title,start_at,end_at,is_active)
VALUES
  ('Flash Sale 20:00',  NOW()+INTERVAL'1 hour',  NOW()+INTERVAL'4 hours', true),
  ('Midnight Sale',     NOW()+INTERVAL'6 hours',  NOW()+INTERVAL'8 hours', false),
  ('Weekend Flash',     NOW()+INTERVAL'2 days',   NOW()+INTERVAL'2 days 4 hours', false)
ON CONFLICT DO NOTHING;

-- ════════════════════════════════════════════════════════════════════
-- STEP 16 : VERIFY — ดูผลลัพธ์
-- ════════════════════════════════════════════════════════════════════
SELECT '=== TABLES ===' AS section;
SELECT tablename, rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname='public'
  AND tablename IN ('users','categories','products','sellers','brands',
    'orders','order_items','reviews','wishlist','addresses','coupons',
    'flash_sale_events','site_settings','notifications')
ORDER BY tablename;

SELECT '=== ROW COUNTS ===' AS section;
SELECT 'users'      AS tbl, COUNT(*) AS rows FROM users
UNION ALL SELECT 'categories', COUNT(*) FROM categories WHERE is_active=true
UNION ALL SELECT 'products',   COUNT(*) FROM products   WHERE status='active'
UNION ALL SELECT 'sellers',    COUNT(*) FROM sellers
UNION ALL SELECT 'orders',     COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items
UNION ALL SELECT 'wishlist',   COUNT(*) FROM wishlist
UNION ALL SELECT 'addresses',  COUNT(*) FROM addresses
UNION ALL SELECT 'reviews',    COUNT(*) FROM reviews
UNION ALL SELECT 'coupons',    COUNT(*) FROM coupons WHERE is_active=true
ORDER BY tbl;

SELECT '=== POLICIES ===' AS section;
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('users','products','sellers','orders','wishlist','addresses','reviews')
ORDER BY tablename, cmd;

SELECT '=== STORAGE BUCKETS ===' AS section;
SELECT id, name, public, file_size_limit FROM storage.buckets
WHERE id IN ('product-images','profile-images');

SELECT '=== USERS ===' AS section;
SELECT id, email, display_name, role, loyalty_pts,
  CASE WHEN avatar_url IS NOT NULL THEN '✅ มีรูป' ELSE '❌ ไม่มีรูป' END AS avatar,
  seller_id IS NOT NULL AS is_seller
FROM users ORDER BY created_at DESC LIMIT 5;

SELECT '=== ORDERS BY STATUS ===' AS section;
SELECT status, COUNT(*) AS cnt, SUM(total_amount) AS revenue
FROM orders GROUP BY status ORDER BY cnt DESC;
