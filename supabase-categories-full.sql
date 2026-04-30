-- ══════════════════════════════════════════════════════════════
-- Thailand Market — Categories FINAL (Dynamic UUID, ครบทุกหมวด)
-- Run ใน Supabase SQL Editor → New Query → Run
-- ไม่ต้อง hardcode UUID — ใช้ SELECT id FROM categories WHERE slug
-- ══════════════════════════════════════════════════════════════

-- ── ลบข้อมูลเก่าก่อน ──────────────────────────────────────
-- NULL out FK ก่อนเพื่อหลีกเลี่ยง constraint error
UPDATE products SET category_id = NULL WHERE category_id IS NOT NULL;
DELETE FROM categories WHERE parent_id IS NOT NULL;
DELETE FROM categories WHERE parent_id IS NULL;

-- ══════════════════════════════════════════════════════════════
-- STEP 1 — 12 หมวดหลัก
-- ══════════════════════════════════════════════════════════════
INSERT INTO categories (name_th, name_en, slug, icon, sort_order, is_active) VALUES
  ('อุปกรณ์อิเล็กทรอนิกส์',     'Electronic Devices',      'electronic-devices',    '📱', 1,  true),
  ('อุปกรณ์เสริมอิเล็กทรอนิกส์', 'Electronic Accessories',  'electronic-accessories','🔌', 2,  true),
  ('ทีวีและเครื่องใช้ไฟฟ้า',     'TV & Home Appliances',    'tv-home-appliances',    '📺', 3,  true),
  ('สุขภาพและความงาม',           'Health & Beauty',         'health-beauty',         '💄', 4,  true),
  ('แม่และเด็ก / ของเล่น',       'Babies & Toys',           'babies-toys',           '🍼', 5,  true),
  ('ของชำและสัตว์เลี้ยง',        'Groceries & Pets',        'groceries-pets',        '🛒', 6,  true),
  ('บ้านและไลฟ์สไตล์',           'Home & Lifestyle',        'home-lifestyle',        '🏠', 7,  true),
  ('แฟชั่นผู้หญิง',              'Women''s Fashion',        'womens-fashion',        '👗', 8,  true),
  ('แฟชั่นผู้ชาย',               'Men''s Fashion',          'mens-fashion',          '👔', 9,  true),
  ('แฟชั่นเด็ก',                 'Kid''s Fashion',          'kids-fashion',          '👧', 10, true),
  ('กีฬาและการเดินทาง',          'Sports & Travel',         'sports-travel',         '🏋️',11, true),
  ('ยานยนต์',                    'Automotive & Motorcycles','automotive',            '🚗', 12, true);

-- ══════════════════════════════════════════════════════════════
-- STEP 2 — หมวดย่อย (ใช้ slug lookup — ไม่ต้อง hardcode UUID)
-- ══════════════════════════════════════════════════════════════

-- ── c01: Electronic Devices (12 หมวดย่อย) ────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('โทรศัพท์มือถือ',       'Mobiles',            'mobiles',           '📱',(SELECT id FROM categories WHERE slug='electronic-devices'),1,true),
  ('แท็บเล็ต',             'Tablets',            'tablets',           '📟',(SELECT id FROM categories WHERE slug='electronic-devices'),2,true),
  ('โน้ตบุ๊ก',             'Laptops',            'laptops',           '💻',(SELECT id FROM categories WHERE slug='electronic-devices'),3,true),
  ('คอมพิวเตอร์ตั้งโต๊ะ', 'Desktops',           'desktops',          '🖥️',(SELECT id FROM categories WHERE slug='electronic-devices'),4,true),
  ('กล้อง DSLR',           'DSLR Cameras',       'dslr',              '📷',(SELECT id FROM categories WHERE slug='electronic-devices'),5,true),
  ('กล้อง Mirrorless',     'Mirrorless Cameras', 'mirrorless',        '📸',(SELECT id FROM categories WHERE slug='electronic-devices'),6,true),
  ('กล้อง Point & Shoot',  'Point & Shoot',      'point-shoot',       '📷',(SELECT id FROM categories WHERE slug='electronic-devices'),7,true),
  ('กล้อง Instant',        'Instant Camera',     'instant-camera',    '🖼️',(SELECT id FROM categories WHERE slug='electronic-devices'),8,true),
  ('กล้องวิดีโอ / Action', 'Action Cameras',     'action-cameras',    '🎥',(SELECT id FROM categories WHERE slug='electronic-devices'),9,true),
  ('โดรน',                 'Drones',             'drones',            '🛸',(SELECT id FROM categories WHERE slug='electronic-devices'),10,true),
  ('กล้องวงจรปิด',         'Security Cameras',   'security-cameras',  '📹',(SELECT id FROM categories WHERE slug='electronic-devices'),11,true),
  ('เครื่องเล่นเกม Console','Console Gaming',    'console-gaming',    '🎮',(SELECT id FROM categories WHERE slug='electronic-devices'),12,true);

-- ── c02: Electronic Accessories (10 หมวดย่อย) ────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('อุปกรณ์เสริมมือถือ',  'Mobile Accessories',  'mobile-accessories', '📱',(SELECT id FROM categories WHERE slug='electronic-accessories'),1,true),
  ('เครื่องเสียง',         'Audio',               'audio',              '🎧',(SELECT id FROM categories WHERE slug='electronic-accessories'),2,true),
  ('Wearables',            'Wearables',           'wearables',          '⌚',(SELECT id FROM categories WHERE slug='electronic-accessories'),3,true),
  ('Gadgets',              'Gadgets',             'gadgets',            '🔧',(SELECT id FROM categories WHERE slug='electronic-accessories'),4,true),
  ('อุปกรณ์จัดเก็บข้อมูล','Data Storage',        'data-storage',       '💾',(SELECT id FROM categories WHERE slug='electronic-accessories'),5,true),
  ('อุปกรณ์เสริม PC',      'PC Accessories',      'pc-accessories',     '🖱️',(SELECT id FROM categories WHERE slug='electronic-accessories'),6,true),
  ('ชิ้นส่วนคอมพิวเตอร์', 'Computer Components', 'computer-components','🔩',(SELECT id FROM categories WHERE slug='electronic-accessories'),7,true),
  ('อุปกรณ์เครือข่าย',     'Network Components',  'network-components', '📡',(SELECT id FROM categories WHERE slug='electronic-accessories'),8,true),
  ('อุปกรณ์เสริม Console', 'Console Accessories', 'console-accessories','🎮',(SELECT id FROM categories WHERE slug='electronic-accessories'),9,true),
  ('อุปกรณ์เสริมกล้อง',    'Camera Accessories',  'camera-accessories', '🎞️',(SELECT id FROM categories WHERE slug='electronic-accessories'),10,true);

-- ── c03: TV & Home Appliances (7 หมวดย่อย) ───────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('ทีวีและอุปกรณ์วิดีโอ',    'TVs & Video',              'tvs-video',               '📺',(SELECT id FROM categories WHERE slug='tv-home-appliances'),1,true),
  ('เครื่องใช้ไฟฟ้าขนาดใหญ่', 'Large Appliances',         'large-appliances',        '🫙',(SELECT id FROM categories WHERE slug='tv-home-appliances'),2,true),
  ('เครื่องครัวขนาดเล็ก',     'Small Kitchen Appliances', 'small-kitchen',           '☕',(SELECT id FROM categories WHERE slug='tv-home-appliances'),3,true),
  ('เครื่องปรับอากาศ',         'Air Treatment',            'air-treatment',           '❄️',(SELECT id FROM categories WHERE slug='tv-home-appliances'),4,true),
  ('เครื่องใช้ไฟฟ้าในบ้าน',   'Household Appliances',     'household-appliances',    '🔌',(SELECT id FROM categories WHERE slug='tv-home-appliances'),5,true),
  ('เครื่องดูแลร่างกาย',      'Personal Care Appliances', 'personal-care-appliances','💆',(SELECT id FROM categories WHERE slug='tv-home-appliances'),6,true),
  ('อะไหล่และอุปกรณ์เสริม',   'Parts & Accessories',      'appliance-parts',         '🔧',(SELECT id FROM categories WHERE slug='tv-home-appliances'),7,true);

-- ── c04: Health & Beauty (12 หมวดย่อย) ───────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('ดูแลผิวหน้า',          'Skincare',              'skincare',        '✨',(SELECT id FROM categories WHERE slug='health-beauty'),1,true),
  ('เครื่องสำอาง',         'Make-Up',               'makeup',          '💄',(SELECT id FROM categories WHERE slug='health-beauty'),2,true),
  ('ดูแลเส้นผม',           'Hair Care',             'hair-care',       '💇',(SELECT id FROM categories WHERE slug='health-beauty'),3,true),
  ('ดูแลร่างกาย',          'Bath & Body',           'bath-body',       '🛁',(SELECT id FROM categories WHERE slug='health-beauty'),4,true),
  ('ของใช้ส่วนตัว',        'Personal Care',         'personal-care',   '🪥',(SELECT id FROM categories WHERE slug='health-beauty'),5,true),
  ('น้ำหอม',               'Fragrances',            'fragrances',      '🌸',(SELECT id FROM categories WHERE slug='health-beauty'),6,true),
  ('เครื่องมือความงาม',    'Beauty Tools',          'beauty-tools',    '💅',(SELECT id FROM categories WHERE slug='health-beauty'),7,true),
  ('ผลิตภัณฑ์ผู้ชาย',      'Men''s Care',           'mens-care',       '🧴',(SELECT id FROM categories WHERE slug='health-beauty'),8,true),
  ('วิตามินและอาหารเสริม', 'Vitamins & Supplements','vitamins',        '💊',(SELECT id FROM categories WHERE slug='health-beauty'),9,true),
  ('อุปกรณ์ทางการแพทย์',   'Medical Supplies',      'medical-supplies','🏥',(SELECT id FROM categories WHERE slug='health-beauty'),10,true),
  ('ผ้าอ้อมผู้ใหญ่',       'Adult Diapers',         'adult-diapers',   '🩲',(SELECT id FROM categories WHERE slug='health-beauty'),11,true),
  ('ถุงยางและสารหล่อลื่น', 'Condoms & Lubricants',  'condoms',         '❤️',(SELECT id FROM categories WHERE slug='health-beauty'),12,true);

-- ── c05: Babies & Toys (12 หมวดย่อย) ────────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('แม่และเด็ก',           'Mother & Baby',        'mother-baby',        '👶',(SELECT id FROM categories WHERE slug='babies-toys'),1,true),
  ('ผ้าอ้อมและกระโถน',     'Diapering & Potty',    'diapering',          '🚼',(SELECT id FROM categories WHERE slug='babies-toys'),2,true),
  ('นมผงและอาหารเด็ก',     'Milk Formula & Food',  'baby-food',          '🍼',(SELECT id FROM categories WHERE slug='babies-toys'),3,true),
  ('อุปกรณ์ให้อาหาร',      'Feeding Essentials',   'feeding',            '🥄',(SELECT id FROM categories WHERE slug='babies-toys'),4,true),
  ('รถเข็นและอุปกรณ์',     'Baby Gear',            'baby-gear',          '🛺',(SELECT id FROM categories WHERE slug='babies-toys'),5,true),
  ('ห้องเด็กอ่อน',         'Nursery',              'nursery',            '🛏️',(SELECT id FROM categories WHERE slug='babies-toys'),6,true),
  ('ของใช้ส่วนตัวเด็ก',    'Baby Personal Care',   'baby-personal-care', '🧸',(SELECT id FROM categories WHERE slug='babies-toys'),7,true),
  ('เสื้อผ้าเด็กอ่อน',     'Baby Fashion',         'baby-fashion',       '👕',(SELECT id FROM categories WHERE slug='babies-toys'),8,true),
  ('ของเล่นและเกม',         'Toys & Games',         'toys-games',         '🎲',(SELECT id FROM categories WHERE slug='babies-toys'),9,true),
  ('ของเล่นเด็กเล็ก',       'Baby Toys',            'baby-toys',          '🪀',(SELECT id FROM categories WHERE slug='babies-toys'),10,true),
  ('ของเล่นกีฬากลางแจ้ง',  'Sports Toys',          'sports-toys',        '⚽',(SELECT id FROM categories WHERE slug='babies-toys'),11,true),
  ('ของเล่นรีโมทคอนโทรล',  'RC & Electronic Toys', 'rc-toys',            '🚗',(SELECT id FROM categories WHERE slug='babies-toys'),12,true);

-- ── c06: Groceries & Pets (10 หมวดย่อย) ─────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('เครื่องดื่ม',          'Drinks',              'drinks',          '🥤',(SELECT id FROM categories WHERE slug='groceries-pets'),1,true),
  ('ซีเรียลและแยม',        'Breakfast & Spreads', 'breakfast',       '🥐',(SELECT id FROM categories WHERE slug='groceries-pets'),2,true),
  ('ของชำและเครื่องปรุง',  'Food Staples',        'food-staples',    '🛒',(SELECT id FROM categories WHERE slug='groceries-pets'),3,true),
  ('ผักและผลไม้',          'Fruit & Vegetables',  'fresh-produce',   '🥦',(SELECT id FROM categories WHERE slug='groceries-pets'),4,true),
  ('ขนมและช็อกโกแลต',      'Snacks & Sweets',     'snacks',          '🍫',(SELECT id FROM categories WHERE slug='groceries-pets'),5,true),
  ('ผลิตภัณฑ์ทำความสะอาด', 'Cleaning Supplies',   'cleaning',        '🧹',(SELECT id FROM categories WHERE slug='groceries-pets'),6,true),
  ('ผลิตภัณฑ์ซักผ้า',      'Laundry Supplies',    'laundry',         '🧺',(SELECT id FROM categories WHERE slug='groceries-pets'),7,true),
  ('อุปกรณ์สัตว์เลี้ยง',   'Pet Accessories',     'pet-accessories', '🐾',(SELECT id FROM categories WHERE slug='groceries-pets'),8,true),
  ('อาหารสัตว์เลี้ยง',     'Pet Food',            'pet-food',        '🦴',(SELECT id FROM categories WHERE slug='groceries-pets'),9,true),
  ('สุขภาพสัตว์เลี้ยง',    'Pet Healthcare',      'pet-healthcare',  '🩺',(SELECT id FROM categories WHERE slug='groceries-pets'),10,true);

-- ── c07: Home & Lifestyle + ต้นไม้ + ช่าง (23 หมวดย่อย) ─────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('เฟอร์นิเจอร์และจัดเก็บ','Furniture & Organization','furniture',        '🛋️',(SELECT id FROM categories WHERE slug='home-lifestyle'),1,true),
  ('โคมไฟและแสงสว่าง',      'Lighting',               'lighting',         '💡',(SELECT id FROM categories WHERE slug='home-lifestyle'),2,true),
  ('ของตกแต่งบ้าน',          'Home Décor',             'home-decor',       '🖼️',(SELECT id FROM categories WHERE slug='home-lifestyle'),3,true),
  ('ผ้าปูที่นอน',            'Bedding',                'bedding',          '🛏️',(SELECT id FROM categories WHERE slug='home-lifestyle'),4,true),
  ('ห้องน้ำ',                'Bath',                   'bath',             '🚿',(SELECT id FROM categories WHERE slug='home-lifestyle'),5,true),
  ('ครัวและรับประทานอาหาร',  'Kitchen & Dining',       'kitchen-dining',   '🍳',(SELECT id FROM categories WHERE slug='home-lifestyle'),6,true),
  ('เครื่องเขียนและออฟฟิศ',  'Stationery & Office',    'stationery',       '✏️',(SELECT id FROM categories WHERE slug='home-lifestyle'),7,true),
  ('ซักรีดและทำความสะอาด',   'Laundry & Cleaning',     'laundry-cleaning', '🧺',(SELECT id FROM categories WHERE slug='home-lifestyle'),8,true),
  ('กลางแจ้งและสวน',         'Outdoor & Garden',       'outdoor-garden',   '🌿',(SELECT id FROM categories WHERE slug='home-lifestyle'),9,true),
  ('ดนตรีและเครื่องดนตรี',   'Music & Instruments',    'music',            '🎸',(SELECT id FROM categories WHERE slug='home-lifestyle'),10,true),
  ('หนังสือ',                'Books',                  'books',            '📚',(SELECT id FROM categories WHERE slug='home-lifestyle'),11,true),
  -- 🌿 ต้นไม้และพืชสวน
  ('ต้นไม้และพืชสวน',       'Plants & Gardening',     'plants-gardening', '🪴',(SELECT id FROM categories WHERE slug='home-lifestyle'),12,true),
  ('ต้นไม้ในบ้าน',           'Indoor Plants',          'indoor-plants',    '🌱',(SELECT id FROM categories WHERE slug='home-lifestyle'),13,true),
  ('ต้นไม้กลางแจ้ง',         'Outdoor Plants',         'outdoor-plants',   '🌳',(SELECT id FROM categories WHERE slug='home-lifestyle'),14,true),
  ('เมล็ดพันธุ์',            'Seeds',                  'seeds',            '🌾',(SELECT id FROM categories WHERE slug='home-lifestyle'),15,true),
  ('ดินและปุ๋ย',              'Soil & Fertilizer',      'soil-fertilizer',  '🪣',(SELECT id FROM categories WHERE slug='home-lifestyle'),16,true),
  ('กระถางและภาชนะ',          'Pots & Planters',        'pots-planters',    '🪴',(SELECT id FROM categories WHERE slug='home-lifestyle'),17,true),
  -- 🔧 ช่างและวัสดุก่อสร้าง
  ('ช่างและวัสดุก่อสร้าง',   'Hardware & Building',    'hardware-building','🏗️',(SELECT id FROM categories WHERE slug='home-lifestyle'),18,true),
  ('วัสดุก่อสร้าง',           'Building Materials',     'building-materials','🧱',(SELECT id FROM categories WHERE slug='home-lifestyle'),19,true),
  ('สีและอุปกรณ์ทาสี',        'Paint & Tools',          'paint-tools',      '🎨',(SELECT id FROM categories WHERE slug='home-lifestyle'),20,true),
  ('ประปาและระบบน้ำ',          'Plumbing',               'plumbing',         '🚰',(SELECT id FROM categories WHERE slug='home-lifestyle'),21,true),
  ('ไฟฟ้าและสายไฟ',           'Electrical & Wiring',    'electrical',       '⚡',(SELECT id FROM categories WHERE slug='home-lifestyle'),22,true),
  ('เครื่องมือช่าง',           'Power Tools',            'power-tools',      '🔨',(SELECT id FROM categories WHERE slug='home-lifestyle'),23,true);

-- ── c08: Women's Fashion (8 หมวดย่อย) ───────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('เสื้อผ้าผู้หญิง',      'Women''s Clothing',    'womens-clothing',    '👗',(SELECT id FROM categories WHERE slug='womens-fashion'),1,true),
  ('รองเท้าผู้หญิง',       'Women''s Shoes',       'womens-shoes',       '👠',(SELECT id FROM categories WHERE slug='womens-fashion'),2,true),
  ('ชุดชั้นในและชุดนอน',   'Lingerie & Sleepwear', 'lingerie',           '🩱',(SELECT id FROM categories WHERE slug='womens-fashion'),3,true),
  ('ชุดว่ายน้ำ',            'Swimwear',             'swimwear',           '👙',(SELECT id FROM categories WHERE slug='womens-fashion'),4,true),
  ('เครื่องประดับผู้หญิง', 'Women''s Accessories', 'womens-accessories', '💍',(SELECT id FROM categories WHERE slug='womens-fashion'),5,true),
  ('กระเป๋าผู้หญิง',       'Women''s Bags',        'womens-bags',        '👜',(SELECT id FROM categories WHERE slug='womens-fashion'),6,true),
  ('แว่นตาผู้หญิง',        'Women''s Eyewear',     'womens-eyewear',     '🕶️',(SELECT id FROM categories WHERE slug='womens-fashion'),7,true),
  ('นาฬิกาผู้หญิง',        'Women''s Watches',     'womens-watches',     '⌚',(SELECT id FROM categories WHERE slug='womens-fashion'),8,true);

-- ── c09: Men's Fashion (7 หมวดย่อย) ─────────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('เสื้อผ้าผู้ชาย',      'Men''s Clothing',    'mens-clothing',    '👔',(SELECT id FROM categories WHERE slug='mens-fashion'),1,true),
  ('รองเท้าผู้ชาย',       'Men''s Shoes',       'mens-shoes',       '👞',(SELECT id FROM categories WHERE slug='mens-fashion'),2,true),
  ('ชุดชั้นในผู้ชาย',     'Men''s Underwear',   'mens-underwear',   '🩲',(SELECT id FROM categories WHERE slug='mens-fashion'),3,true),
  ('เครื่องประดับผู้ชาย', 'Men''s Accessories', 'mens-accessories', '⌚',(SELECT id FROM categories WHERE slug='mens-fashion'),4,true),
  ('กระเป๋าผู้ชาย',       'Men''s Bags',        'mens-bags',        '💼',(SELECT id FROM categories WHERE slug='mens-fashion'),5,true),
  ('แว่นตาผู้ชาย',        'Men''s Eyewear',     'mens-eyewear',     '🕶️',(SELECT id FROM categories WHERE slug='mens-fashion'),6,true),
  ('นาฬิกาผู้ชาย',        'Men''s Watches',     'mens-watches',     '⌚',(SELECT id FROM categories WHERE slug='mens-fashion'),7,true);

-- ── c10: Kid's Fashion (7 หมวดย่อย) ─────────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('เสื้อผ้าเด็กผู้ชาย', 'Boys'' Clothing',  'boys-clothing',  '👕',(SELECT id FROM categories WHERE slug='kids-fashion'),1,true),
  ('เสื้อผ้าเด็กผู้หญิง','Girls'' Clothing', 'girls-clothing', '👗',(SELECT id FROM categories WHERE slug='kids-fashion'),2,true),
  ('รองเท้าเด็กผู้ชาย',  'Boys'' Shoes',     'boys-shoes',     '👟',(SELECT id FROM categories WHERE slug='kids-fashion'),3,true),
  ('รองเท้าเด็กผู้หญิง', 'Girls'' Shoes',    'girls-shoes',    '👡',(SELECT id FROM categories WHERE slug='kids-fashion'),4,true),
  ('นาฬิกาเด็ก',          'Kids'' Watches',   'kids-watches',   '⌚',(SELECT id FROM categories WHERE slug='kids-fashion'),5,true),
  ('กระเป๋าเด็ก',         'Kids'' Bags',      'kids-bags',      '🎒',(SELECT id FROM categories WHERE slug='kids-fashion'),6,true),
  ('แว่นตาเด็ก',          'Kids'' Eyewear',   'kids-eyewear',   '🕶️',(SELECT id FROM categories WHERE slug='kids-fashion'),7,true);

-- ── c11: Sports & Travel (12 หมวดย่อย) ──────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('ออกกำลังกาย',         'Exercise & Fitness',      'exercise-fitness',    '🏋️',(SELECT id FROM categories WHERE slug='sports-travel'),1,true),
  ('กิจกรรมกลางแจ้ง',     'Outdoor Recreation',      'outdoor-recreation',  '🏕️',(SELECT id FROM categories WHERE slug='sports-travel'),2,true),
  ('เสื้อผ้ากีฬาผู้ชาย',  'Men''s Sports Apparel',   'mens-sports-apparel', '🏃',(SELECT id FROM categories WHERE slug='sports-travel'),3,true),
  ('รองเท้ากีฬาผู้ชาย',   'Men''s Sports Shoes',     'mens-sports-shoes',   '👟',(SELECT id FROM categories WHERE slug='sports-travel'),4,true),
  ('เสื้อผ้ากีฬาผู้หญิง', 'Women''s Sports Apparel', 'womens-sports-apparel','🤸',(SELECT id FROM categories WHERE slug='sports-travel'),5,true),
  ('รองเท้ากีฬาผู้หญิง',  'Women''s Sports Shoes',   'womens-sports-shoes', '👟',(SELECT id FROM categories WHERE slug='sports-travel'),6,true),
  ('จักรยาน',              'Cycling',                 'cycling',             '🚴',(SELECT id FROM categories WHERE slug='sports-travel'),7,true),
  ('กีฬาทางน้ำ',           'Water Sports',            'water-sports',        '🏊',(SELECT id FROM categories WHERE slug='sports-travel'),8,true),
  ('กีฬาทีม',              'Team Sports',             'team-sports',         '⚽',(SELECT id FROM categories WHERE slug='sports-travel'),9,true),
  ('แบดมินตันและเทนนิส',  'Racket Sports',            'racket-sports',       '🏸',(SELECT id FROM categories WHERE slug='sports-travel'),10,true),
  ('อุปกรณ์กีฬา',          'Sport Accessories',       'sport-accessories',   '🎽',(SELECT id FROM categories WHERE slug='sports-travel'),11,true),
  ('การเดินทาง',            'Travel',                  'travel',              '✈️',(SELECT id FROM categories WHERE slug='sports-travel'),12,true);

-- ── c12: Automotive (12 หมวดย่อย) ────────────────────────────
INSERT INTO categories (name_th,name_en,slug,icon,parent_id,sort_order,is_active) VALUES
  ('น้ำมันและของเหลว',   'Oils & Fluids',          'oils-fluids',        '🛢️',(SELECT id FROM categories WHERE slug='automotive'),1,true),
  ('ยานยนต์ทั่วไป',      'Automotive General',     'automotive-general', '🚘',(SELECT id FROM categories WHERE slug='automotive'),2,true),
  ('กล้องติดรถยนต์',     'Car Camera',             'car-camera',         '📹',(SELECT id FROM categories WHERE slug='automotive'),3,true),
  ('เครื่องเสียงรถยนต์', 'Car Audio',              'car-audio',          '🔊',(SELECT id FROM categories WHERE slug='automotive'),4,true),
  ('ยางและล้อรถ',         'Auto Tires & Wheels',    'auto-tires',         '🛞',(SELECT id FROM categories WHERE slug='automotive'),5,true),
  ('อะไหล่รถยนต์',       'Auto Parts & Spares',    'auto-parts',         '⚙️',(SELECT id FROM categories WHERE slug='automotive'),6,true),
  ('อุปกรณ์เสริมรถยนต์', 'Auto Accessories',       'auto-accessories',   '🪄',(SELECT id FROM categories WHERE slug='automotive'),7,true),
  ('ดูแลรักษารถ',         'Car Care',               'car-care',           '🧽',(SELECT id FROM categories WHERE slug='automotive'),8,true),
  ('มอเตอร์ไซค์',         'Motorcycle',             'motorcycle',         '🏍️',(SELECT id FROM categories WHERE slug='automotive'),9,true),
  ('ยางมอเตอร์ไซค์',      'Moto Tires & Wheels',    'moto-tires',         '🛞',(SELECT id FROM categories WHERE slug='automotive'),10,true),
  ('อะไหล่มอเตอร์ไซค์',   'Moto Parts',             'moto-parts',         '🔩',(SELECT id FROM categories WHERE slug='automotive'),11,true),
  ('ชุดขี่มอเตอร์ไซค์',   'Motorcycle Riding Gear', 'riding-gear',        '🪖',(SELECT id FROM categories WHERE slug='automotive'),12,true);

-- ══════════════════════════════════════════════════════════════
-- STEP 3 — อัปเดต product_count
-- ══════════════════════════════════════════════════════════════
UPDATE categories SET product_count = 0;

-- ══════════════════════════════════════════════════════════════
-- STEP 4 — ตรวจสอบผลลัพธ์
-- ══════════════════════════════════════════════════════════════
SELECT
  (SELECT COUNT(*) FROM categories WHERE parent_id IS NULL)  AS หมวดหลัก,
  (SELECT COUNT(*) FROM categories WHERE parent_id IS NOT NULL) AS หมวดย่อย,
  (SELECT COUNT(*) FROM categories) AS รวมทั้งหมด;

-- แสดงรายการจัดกลุ่ม
SELECT
  CASE WHEN parent_id IS NULL
    THEN icon || ' ' || name_th
    ELSE '    ' || icon || ' ' || name_th
  END AS หมวดหมู่,
  slug
FROM categories
ORDER BY COALESCE(parent_id::text, id::text), sort_order;
