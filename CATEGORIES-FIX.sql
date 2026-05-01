-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  Thailand Market — Categories Fix                               ║
-- ║  Run ถ้า categories ไม่แสดงใน seller-portal หรือ add-product   ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════
-- STEP 1: RLS — อนุญาตทุกคน (รวม anon) อ่าน categories ได้
-- ════════════════════════════════════════════════════════════════
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='categories'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON categories'; END LOOP;
END $$;

-- ทุกคนอ่านได้ (รวม anon / unauthenticated)
CREATE POLICY "categories_anon_read" ON categories
  FOR SELECT USING (is_active = true);

-- Admin จัดการทั้งหมด
CREATE POLICY "categories_admin_all" ON categories
  FOR ALL TO authenticated
  USING ((SELECT role FROM users WHERE email = auth.jwt()->>'email' LIMIT 1) = 'admin');

-- ════════════════════════════════════════════════════════════════
-- STEP 2: INSERT 12 parent categories (ถ้ายังไม่มี)
-- ════════════════════════════════════════════════════════════════
INSERT INTO categories (id, name_th, name_en, slug, icon, sort_order, is_active)
VALUES
  ('00000000-0000-0000-0000-000000000001','อุปกรณ์อิเล็กทรอนิกส์','Electronic Devices','electronic-devices','📱',1,true),
  ('00000000-0000-0000-0000-000000000002','อุปกรณ์เสริมอิเล็กทรอนิกส์','Electronic Accessories','electronic-accessories','🔌',2,true),
  ('00000000-0000-0000-0000-000000000003','ทีวีและเครื่องใช้ไฟฟ้า','TV & Home Appliances','tv-home-appliances','📺',3,true),
  ('00000000-0000-0000-0000-000000000004','สุขภาพและความงาม','Health & Beauty','health-beauty','💄',4,true),
  ('00000000-0000-0000-0000-000000000005','แม่และเด็ก / ของเล่น','Babies & Toys','babies-toys','🍼',5,true),
  ('00000000-0000-0000-0000-000000000006','ของชำและสัตว์เลี้ยง','Groceries & Pets','groceries-pets','🛒',6,true),
  ('00000000-0000-0000-0000-000000000007','บ้านและไลฟ์สไตล์','Home & Lifestyle','home-lifestyle','🏠',7,true),
  ('00000000-0000-0000-0000-000000000008','แฟชั่นผู้หญิง','Women''s Fashion','womens-fashion','👗',8,true),
  ('00000000-0000-0000-0000-000000000009','แฟชั่นผู้ชาย','Men''s Fashion','mens-fashion','👔',9,true),
  ('00000000-0000-0000-0000-000000000010','แฟชั่นเด็ก','Kid''s Fashion','kids-fashion','👧',10,true),
  ('00000000-0000-0000-0000-000000000011','กีฬาและการเดินทาง','Sports & Travel','sports-travel','🏋️',11,true),
  ('00000000-0000-0000-0000-000000000012','ยานยนต์','Automotive','automotive','🚗',12,true)
ON CONFLICT (id) DO UPDATE SET
  name_th=EXCLUDED.name_th, icon=EXCLUDED.icon,
  sort_order=EXCLUDED.sort_order, is_active=true;

-- ════════════════════════════════════════════════════════════════
-- STEP 3: INSERT sub-categories
-- ════════════════════════════════════════════════════════════════
INSERT INTO categories (name_th, name_en, slug, icon, parent_id, sort_order, is_active)
VALUES
  -- อุปกรณ์อิเล็กทรอนิกส์
  ('โทรศัพท์มือถือ','Mobiles','mobiles','📱','00000000-0000-0000-0000-000000000001',1,true),
  ('แท็บเล็ต','Tablets','tablets','📟','00000000-0000-0000-0000-000000000001',2,true),
  ('โน้ตบุ๊ก','Laptops','laptops','💻','00000000-0000-0000-0000-000000000001',3,true),
  ('คอมพิวเตอร์ตั้งโต๊ะ','Desktops','desktops','🖥️','00000000-0000-0000-0000-000000000001',4,true),
  ('กล้องถ่ายรูป','Cameras','cameras','📷','00000000-0000-0000-0000-000000000001',5,true),
  ('เครื่องเล่นเกม','Gaming','gaming','🎮','00000000-0000-0000-0000-000000000001',6,true),
  -- อุปกรณ์เสริม
  ('อุปกรณ์เสริมมือถือ','Mobile Accessories','mobile-accessories','📱','00000000-0000-0000-0000-000000000002',1,true),
  ('เครื่องเสียง','Audio','audio','🎧','00000000-0000-0000-0000-000000000002',2,true),
  ('Wearables','Wearables','wearables','⌚','00000000-0000-0000-0000-000000000002',3,true),
  ('Gadgets','Gadgets','gadgets','🔧','00000000-0000-0000-0000-000000000002',4,true),
  -- ทีวีและเครื่องใช้ไฟฟ้า
  ('ทีวีและวิดีโอ','TV & Video','tv-video','📺','00000000-0000-0000-0000-000000000003',1,true),
  ('เครื่องใช้ไฟฟ้าขนาดใหญ่','Large Appliances','large-appliances','🫙','00000000-0000-0000-0000-000000000003',2,true),
  ('เครื่องครัวขนาดเล็ก','Small Appliances','small-appliances','☕','00000000-0000-0000-0000-000000000003',3,true),
  ('เครื่องปรับอากาศ','Air Conditioner','air-conditioner','❄️','00000000-0000-0000-0000-000000000003',4,true),
  -- สุขภาพและความงาม
  ('ดูแลผิวหน้า','Skincare','skincare','✨','00000000-0000-0000-0000-000000000004',1,true),
  ('เครื่องสำอาง','Makeup','makeup','💄','00000000-0000-0000-0000-000000000004',2,true),
  ('ดูแลเส้นผม','Hair Care','hair-care','💇','00000000-0000-0000-0000-000000000004',3,true),
  ('น้ำหอม','Perfume','perfume','🌸','00000000-0000-0000-0000-000000000004',4,true),
  ('วิตามินและอาหารเสริม','Supplements','supplements','💊','00000000-0000-0000-0000-000000000004',5,true),
  -- แม่และเด็ก
  ('แม่และเด็ก','Mother & Baby','mother-baby','👶','00000000-0000-0000-0000-000000000005',1,true),
  ('ของเล่นและเกม','Toys & Games','toys-games','🎲','00000000-0000-0000-0000-000000000005',2,true),
  ('นมผงและอาหารเด็ก','Baby Food','baby-food','🍼','00000000-0000-0000-0000-000000000005',3,true),
  -- ของชำและสัตว์เลี้ยง
  ('เครื่องดื่ม','Beverages','beverages','🥤','00000000-0000-0000-0000-000000000006',1,true),
  ('ของชำ','Groceries','groceries','🛒','00000000-0000-0000-0000-000000000006',2,true),
  ('อาหารสัตว์เลี้ยง','Pet Food','pet-food','🦴','00000000-0000-0000-0000-000000000006',3,true),
  ('อุปกรณ์สัตว์เลี้ยง','Pet Accessories','pet-accessories','🐾','00000000-0000-0000-0000-000000000006',4,true),
  -- บ้านและไลฟ์สไตล์
  ('เฟอร์นิเจอร์','Furniture','furniture','🛋️','00000000-0000-0000-0000-000000000007',1,true),
  ('โคมไฟ','Lighting','lighting','💡','00000000-0000-0000-0000-000000000007',2,true),
  ('ของตกแต่งบ้าน','Home Decor','home-decor','🖼️','00000000-0000-0000-0000-000000000007',3,true),
  ('ครัวและอุปกรณ์','Kitchen','kitchen','🍳','00000000-0000-0000-0000-000000000007',4,true),
  ('ต้นไม้และพืชสวน','Plants','plants','🪴','00000000-0000-0000-0000-000000000007',5,true),
  -- แฟชั่น
  ('เสื้อผ้าผู้หญิง','Women Clothing','women-clothing','👗','00000000-0000-0000-0000-000000000008',1,true),
  ('รองเท้าผู้หญิง','Women Shoes','women-shoes','👠','00000000-0000-0000-0000-000000000008',2,true),
  ('กระเป๋าผู้หญิง','Women Bags','women-bags','👜','00000000-0000-0000-0000-000000000008',3,true),
  ('เสื้อผ้าผู้ชาย','Men Clothing','men-clothing','👔','00000000-0000-0000-0000-000000000009',1,true),
  ('รองเท้าผู้ชาย','Men Shoes','men-shoes','👟','00000000-0000-0000-0000-000000000009',2,true),
  -- กีฬา
  ('ออกกำลังกาย','Exercise','exercise','🏋️','00000000-0000-0000-0000-000000000011',1,true),
  ('กิจกรรมกลางแจ้ง','Outdoor','outdoor','🏕️','00000000-0000-0000-0000-000000000011',2,true),
  ('จักรยาน','Cycling','cycling','🚴','00000000-0000-0000-0000-000000000011',3,true),
  -- ยานยนต์
  ('อุปกรณ์เสริมรถยนต์','Car Accessories','car-accessories','🪄','00000000-0000-0000-0000-000000000012',1,true),
  ('น้ำมันและของเหลว','Car Oil','car-oil','🛢️','00000000-0000-0000-0000-000000000012',2,true),
  ('กล้องติดรถ','Dashcam','dashcam','📹','00000000-0000-0000-0000-000000000012',3,true),
  ('ยางและล้อ','Tires','tires','🛞','00000000-0000-0000-0000-000000000012',4,true)
ON CONFLICT (slug) DO NOTHING;

-- ════════════════════════════════════════════════════════════════
-- STEP 4: RLS products (anon อ่านได้)
-- ════════════════════════════════════════════════════════════════
DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE tablename='products'
  LOOP EXECUTE 'DROP POLICY IF EXISTS "'||r.policyname||'" ON products'; END LOOP;
END $$;

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- anon + authenticated อ่าน active products ได้
CREATE POLICY "products_anon_read" ON products
  FOR SELECT USING (status = 'active');

-- seller insert/update ของตัวเอง
CREATE POLICY "products_seller_write" ON products
  FOR ALL TO authenticated
  USING (
    seller_id IN (SELECT id FROM sellers WHERE user_id IN
      (SELECT id FROM users WHERE email = auth.jwt()->>'email'))
    OR (SELECT role FROM users WHERE email = auth.jwt()->>'email' LIMIT 1) = 'admin'
  );

-- ════════════════════════════════════════════════════════════════
-- STEP 5: VERIFY
-- ════════════════════════════════════════════════════════════════
SELECT '=== CATEGORIES ===' AS info;
SELECT id, name_th, icon, parent_id IS NULL AS is_parent, sort_order
FROM categories WHERE is_active = true
ORDER BY parent_id NULLS FIRST, sort_order
LIMIT 20;

SELECT '=== POLICIES ===' AS info;
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('categories','products')
ORDER BY tablename, cmd;

SELECT '=== COUNTS ===' AS info;
SELECT
  (SELECT COUNT(*) FROM categories WHERE is_active=true AND parent_id IS NULL) AS parent_cats,
  (SELECT COUNT(*) FROM categories WHERE is_active=true AND parent_id IS NOT NULL) AS sub_cats,
  (SELECT COUNT(*) FROM products WHERE status='active') AS active_products;
