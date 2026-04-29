-- ══════════════════════════════════════════════════════════
-- Thailand Market — Categories (Lazada Structure)
-- Run ใน Supabase SQL Editor
-- ══════════════════════════════════════════════════════════

-- ลบหมวดหมู่เดิมออกก่อน (ถ้ามี)
DELETE FROM categories WHERE parent_id IS NOT NULL;
DELETE FROM categories WHERE parent_id IS NULL;

-- ── หมวดหลัก 12 หมวด ─────────────────────────────────────
INSERT INTO categories (id, name_th, name_en, slug, icon, sort_order, is_active) VALUES
  ('c01', 'อุปกรณ์อิเล็กทรอนิกส์', 'Electronic Devices',      'electronic-devices',     '📱', 1,  true),
  ('c02', 'อุปกรณ์เสริมอิเล็กทรอนิกส์', 'Electronic Accessories', 'electronic-accessories', '🔌', 2,  true),
  ('c03', 'ทีวีและเครื่องใช้ไฟฟ้า',  'TV & Home Appliances',   'tv-home-appliances',     '📺', 3,  true),
  ('c04', 'สุขภาพและความงาม',        'Health & Beauty',        'health-beauty',          '💄', 4,  true),
  ('c05', 'แม่และเด็ก / ของเล่น',    'Babies & Toys',          'babies-toys',            '🍼', 5,  true),
  ('c06', 'ของชำและสัตว์เลี้ยง',     'Groceries & Pets',       'groceries-pets',         '🛒', 6,  true),
  ('c07', 'บ้านและไลฟ์สไตล์',        'Home & Lifestyle',       'home-lifestyle',         '🏠', 7,  true),
  ('c08', 'แฟชั่นผู้หญิง',           'Women''s Fashion',       'womens-fashion',         '👗', 8,  true),
  ('c09', 'แฟชั่นผู้ชาย',            'Men''s Fashion',         'mens-fashion',           '👔', 9,  true),
  ('c10', 'แฟชั่นเด็ก',              'Kid''s Fashion',         'kids-fashion',           '👧', 10, true),
  ('c11', 'กีฬาและการเดินทาง',       'Sports & Travel',        'sports-travel',          '🏋️', 11, true),
  ('c12', 'ยานยนต์',                 'Automotive & Motorcycles','automotive',             '🚗', 12, true);

-- ── หมวดย่อย: Electronic Devices ─────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('โทรศัพท์มือถือ',        'Mobiles',               'mobiles',               'c01', 1, true),
  ('แท็บเล็ต',              'Tablets',               'tablets',               'c01', 2, true),
  ('โน้ตบุ๊ก',              'Laptops',               'laptops',               'c01', 3, true),
  ('คอมพิวเตอร์ตั้งโต๊ะ',  'Desktops',              'desktops',              'c01', 4, true),
  ('กล้อง DSLR',            'DSLR Cameras',          'dslr',                  'c01', 5, true),
  ('กล้อง Mirrorless',      'Mirrorless Cameras',    'mirrorless',            'c01', 6, true),
  ('กล้อง Point & Shoot',   'Point & Shoot',         'point-shoot',           'c01', 7, true),
  ('กล้อง Instant',         'Instant Camera',        'instant-camera',        'c01', 8, true),
  ('กล้องวิดีโอ / Action',  'Action/Video Cameras',  'action-cameras',        'c01', 9, true),
  ('โดรน',                  'Drones',                'drones',                'c01', 10, true),
  ('กล้องวงจรปิด',          'Security Cameras',      'security-cameras',      'c01', 11, true),
  ('เครื่องเล่นเกม Console', 'Console Gaming',        'console-gaming',        'c01', 12, true);

-- ── หมวดย่อย: Electronic Accessories ─────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('อุปกรณ์เสริมมือถือ',   'Mobile Accessories',     'mobile-accessories',    'c02', 1, true),
  ('เครื่องเสียง',          'Audio',                  'audio',                 'c02', 2, true),
  ('Wearables',             'Wearables',              'wearables',             'c02', 3, true),
  ('Gadgets',               'Gadgets',                'gadgets',               'c02', 4, true),
  ('อุปกรณ์จัดเก็บข้อมูล', 'Data Storage',           'data-storage',          'c02', 5, true),
  ('อุปกรณ์เสริม PC',       'PC Accessories',         'pc-accessories',        'c02', 6, true),
  ('ชิ้นส่วนคอมพิวเตอร์',  'Computer Components',    'computer-components',   'c02', 7, true),
  ('อุปกรณ์เครือข่าย',      'Network Components',     'network-components',    'c02', 8, true),
  ('อุปกรณ์เสริม Console',  'Console Accessories',    'console-accessories',   'c02', 9, true),
  ('อุปกรณ์เสริมกล้อง',     'Camera Accessories',     'camera-accessories',    'c02', 10, true);

-- ── หมวดย่อย: TV & Home Appliances ───────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('ทีวีและอุปกรณ์วิดีโอ',  'TVs & Video Devices',    'tvs-video',             'c03', 1, true),
  ('เครื่องใช้ไฟฟ้าขนาดใหญ่','Large Appliances',       'large-appliances',      'c03', 2, true),
  ('เครื่องครัวขนาดเล็ก',   'Small Kitchen Appliances','small-kitchen',         'c03', 3, true),
  ('เครื่องปรับอากาศขนาดเล็ก','Air Treatment',          'air-treatment',         'c03', 4, true),
  ('เครื่องใช้ไฟฟ้าในบ้าน', 'Household Appliances',   'household-appliances',  'c03', 5, true),
  ('เครื่องดูแลร่างกาย',    'Personal Care Appliances','personal-care-appliances','c03', 6, true),
  ('อะไหล่และอุปกรณ์เสริม', 'Parts & Accessories',    'appliance-parts',       'c03', 7, true);

-- ── หมวดย่อย: Health & Beauty ────────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('ดูแลผิวหน้า',           'Skincare',               'skincare',              'c04', 1, true),
  ('เครื่องสำอาง',          'Make-Up',                'makeup',                'c04', 2, true),
  ('ดูแลเส้นผม',            'Hair Care',              'hair-care',             'c04', 3, true),
  ('ดูแลร่างกาย',           'Bath & Body',            'bath-body',             'c04', 4, true),
  ('ของใช้ส่วนตัว',         'Personal Care',          'personal-care',         'c04', 5, true),
  ('น้ำหอม',                'Fragrances',             'fragrances',            'c04', 6, true),
  ('เครื่องมือความงาม',     'Beauty Tools',           'beauty-tools',          'c04', 7, true),
  ('ผลิตภัณฑ์ผู้ชาย',       'Men''s Care',            'mens-care',             'c04', 8, true),
  ('วิตามินและอาหารเสริม',  'Vitamins & Supplements', 'vitamins',              'c04', 9, true),
  ('อุปกรณ์ทางการแพทย์',    'Medical Supplies',       'medical-supplies',      'c04', 10, true),
  ('ผ้าอ้อมผู้ใหญ่',        'Adult Diapers',          'adult-diapers',         'c04', 11, true),
  ('ถุงยางและสารหล่อลื่น',  'Condoms & Lubricants',   'condoms',               'c04', 12, true);

-- ── หมวดย่อย: Babies & Toys ──────────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('แม่และเด็ก',            'Mother & Baby',          'mother-baby',           'c05', 1, true),
  ('ผ้าอ้อมและกระโถน',      'Diapering & Potty',      'diapering',             'c05', 2, true),
  ('นมผงและอาหารเด็ก',      'Milk Formula & Baby Food','baby-food',             'c05', 3, true),
  ('อุปกรณ์ให้อาหาร',       'Feeding Essentials',     'feeding',               'c05', 4, true),
  ('รถเข็นและอุปกรณ์',      'Baby Gear',              'baby-gear',             'c05', 5, true),
  ('ห้องเด็กอ่อน',          'Nursery',                'nursery',               'c05', 6, true),
  ('ของใช้ส่วนตัวเด็ก',     'Baby Personal Care',     'baby-personal-care',    'c05', 7, true),
  ('เสื้อผ้าเด็กอ่อน',      'Baby Fashion',           'baby-fashion',          'c05', 8, true),
  ('ของเล่นและเกม',          'Toys & Games',           'toys-games',            'c05', 9, true),
  ('ของเล่นเด็กเล็ก',        'Baby Toys',              'baby-toys',             'c05', 10, true),
  ('ของเล่นกีฬากลางแจ้ง',   'Sports Toys',            'sports-toys',           'c05', 11, true),
  ('ของเล่นรีโมทคอนโทรล',   'RC & Electronic Toys',   'rc-toys',               'c05', 12, true);

-- ── หมวดย่อย: Groceries & Pets ───────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('เครื่องดื่ม',           'Drinks',                 'drinks',                'c06', 1, true),
  ('ซีเรียลและแยม',         'Breakfast & Spreads',    'breakfast',             'c06', 2, true),
  ('ของชำและเครื่องปรุง',   'Food Staples',           'food-staples',          'c06', 3, true),
  ('ผักและผลไม้',           'Fruit & Vegetables',     'fresh-produce',         'c06', 4, true),
  ('ขนมและช็อกโกแลต',       'Snacks & Sweets',        'snacks',                'c06', 5, true),
  ('ผลิตภัณฑ์ทำความสะอาด',  'Cleaning Supplies',      'cleaning',              'c06', 6, true),
  ('ผลิตภัณฑ์ซักผ้า',       'Laundry Supplies',       'laundry',               'c06', 7, true),
  ('อุปกรณ์สัตว์เลี้ยง',    'Pet Accessories',        'pet-accessories',       'c06', 8, true),
  ('อาหารสัตว์เลี้ยง',      'Pet Food',               'pet-food',              'c06', 9, true),
  ('สุขภาพสัตว์เลี้ยง',     'Pet Healthcare',         'pet-healthcare',        'c06', 10, true);

-- ── หมวดย่อย: Home & Lifestyle ───────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('เฟอร์นิเจอร์และจัดเก็บ', 'Furniture & Organization','furniture',            'c07', 1, true),
  ('โคมไฟและแสงสว่าง',       'Lighting',              'lighting',              'c07', 2, true),
  ('ของตกแต่งบ้าน',          'Home Décor',             'home-decor',            'c07', 3, true),
  ('ผ้าปูที่นอน',            'Bedding',                'bedding',               'c07', 4, true),
  ('ห้องน้ำ',                'Bath',                   'bath',                  'c07', 5, true),
  ('ครัวและรับประทานอาหาร',  'Kitchen & Dining',       'kitchen-dining',        'c07', 6, true),
  ('เครื่องเขียนและออฟฟิศ',  'Stationery & Office',    'stationery',            'c07', 7, true),
  ('ซักรีดและทำความสะอาด',   'Laundry & Cleaning',     'laundry-cleaning',      'c07', 8, true),
  ('เครื่องมือและซ่อมบ้าน',  'Tools & Home Improvement','tools',                'c07', 9, true),
  ('กลางแจ้งและสวน',         'Outdoor & Garden',       'outdoor-garden',        'c07', 10, true),
  ('ดนตรีและเครื่องดนตรี',   'Music & Instruments',    'music',                 'c07', 11, true),
  ('หนังสือ',                'Books',                  'books',                 'c07', 12, true);

-- ── หมวดย่อย: Women's Fashion ────────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('เสื้อผ้าผู้หญิง',        'Women''s Clothing',      'womens-clothing',       'c08', 1, true),
  ('รองเท้าผู้หญิง',         'Women''s Shoes',         'womens-shoes',          'c08', 2, true),
  ('ชุดชั้นในและชุดนอน',     'Lingerie & Sleepwear',   'lingerie',              'c08', 3, true),
  ('ชุดว่ายน้ำ',             'Swimwear',               'swimwear',              'c08', 4, true),
  ('เครื่องประดับผู้หญิง',   'Women''s Accessories',   'womens-accessories',    'c08', 5, true),
  ('กระเป๋าผู้หญิง',         'Women''s Bags',          'womens-bags',           'c08', 6, true),
  ('แว่นตาผู้หญิง',          'Women''s Eyewear',       'womens-eyewear',        'c08', 7, true),
  ('นาฬิกาผู้หญิง',          'Women''s Watches',       'womens-watches',        'c08', 8, true);

-- ── หมวดย่อย: Men's Fashion ──────────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('เสื้อผ้าผู้ชาย',         'Men''s Clothing',        'mens-clothing',         'c09', 1, true),
  ('รองเท้าผู้ชาย',          'Men''s Shoes',           'mens-shoes',            'c09', 2, true),
  ('ชุดชั้นในผู้ชาย',        'Men''s Underwear',       'mens-underwear',        'c09', 3, true),
  ('เครื่องประดับผู้ชาย',    'Men''s Accessories',     'mens-accessories',      'c09', 4, true),
  ('กระเป๋าผู้ชาย',          'Men''s Bags',            'mens-bags',             'c09', 5, true),
  ('แว่นตาผู้ชาย',           'Men''s Eyewear',         'mens-eyewear',          'c09', 6, true),
  ('นาฬิกาผู้ชาย',           'Men''s Watches',         'mens-watches',          'c09', 7, true);

-- ── หมวดย่อย: Kid's Fashion ──────────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('เสื้อผ้าเด็กผู้ชาย',     'Boys'' Clothing',        'boys-clothing',         'c10', 1, true),
  ('เสื้อผ้าเด็กผู้หญิง',    'Girls'' Clothing',       'girls-clothing',        'c10', 2, true),
  ('รองเท้าเด็กผู้ชาย',      'Boys'' Shoes',           'boys-shoes',            'c10', 3, true),
  ('รองเท้าเด็กผู้หญิง',     'Girls'' Shoes',          'girls-shoes',           'c10', 4, true),
  ('นาฬิกาเด็ก',             'Kids'' Watches',         'kids-watches',          'c10', 5, true),
  ('กระเป๋าเด็ก',            'Kids'' Bags',            'kids-bags',             'c10', 6, true),
  ('แว่นตาเด็ก',             'Kids'' Eyewear',         'kids-eyewear',          'c10', 7, true);

-- ── หมวดย่อย: Sports & Travel ────────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('ออกกำลังกาย',            'Exercise & Fitness',     'exercise-fitness',      'c11', 1, true),
  ('กิจกรรมกลางแจ้ง',        'Outdoor Recreation',     'outdoor-recreation',    'c11', 2, true),
  ('เสื้อผ้ากีฬาผู้ชาย',     'Men''s Sports Apparel',  'mens-sports-apparel',   'c11', 3, true),
  ('รองเท้ากีฬาผู้ชาย',      'Men''s Sports Shoes',    'mens-sports-shoes',     'c11', 4, true),
  ('เสื้อผ้ากีฬาผู้หญิง',    'Women''s Sports Apparel','womens-sports-apparel', 'c11', 5, true),
  ('รองเท้ากีฬาผู้หญิง',     'Women''s Sports Shoes',  'womens-sports-shoes',   'c11', 6, true),
  ('จักรยาน',                'Cycling',                'cycling',               'c11', 7, true),
  ('กีฬาทางน้ำ',             'Water Sports',           'water-sports',          'c11', 8, true),
  ('กีฬาทีม',                'Team Sports',            'team-sports',           'c11', 9, true),
  ('แบดมินตันและเทนนิส',     'Racket Sports',          'racket-sports',         'c11', 10, true),
  ('อุปกรณ์กีฬา',            'Sport Accessories',      'sport-accessories',     'c11', 11, true),
  ('การเดินทาง',              'Travel',                 'travel',                'c11', 12, true);

-- ── หมวดย่อย: Automotive ─────────────────────────────────
INSERT INTO categories (name_th, name_en, slug, parent_id, sort_order, is_active) VALUES
  ('น้ำมันและของเหลว',       'Oils & Fluids',          'oils-fluids',           'c12', 1, true),
  ('ยานยนต์ทั่วไป',          'Automotive',             'automotive-general',    'c12', 2, true),
  ('กล้องติดรถยนต์',         'Car Camera',             'car-camera',            'c12', 3, true),
  ('เครื่องเสียงรถยนต์',     'Car Audio',              'car-audio',             'c12', 4, true),
  ('ยางและล้อรถ',            'Auto Tires & Wheels',    'auto-tires',            'c12', 5, true),
  ('อะไหล่รถยนต์',           'Auto Parts & Spares',    'auto-parts',            'c12', 6, true),
  ('อุปกรณ์เสริมรถยนต์',    'Auto Accessories',        'auto-accessories',      'c12', 7, true),
  ('ดูแลรักษารถ',            'Car Care',               'car-care',              'c12', 8, true),
  ('มอเตอร์ไซค์',            'Motorcycle',             'motorcycle',            'c12', 9, true),
  ('ยางมอเตอร์ไซค์',         'Moto Tires & Wheels',    'moto-tires',            'c12', 10, true),
  ('อะไหล่มอเตอร์ไซค์',      'Moto Parts',             'moto-parts',            'c12', 11, true),
  ('ชุดขี่มอเตอร์ไซค์',      'Motorcycle Riding Gear', 'riding-gear',           'c12', 12, true);

-- อัปเดต product_count
UPDATE categories SET product_count = 0;

-- แสดงผลลัพธ์
SELECT 
  CASE WHEN parent_id IS NULL THEN name_th ELSE '  └─ ' || name_th END as หมวดหมู่,
  slug,
  sort_order
FROM categories 
ORDER BY 
  COALESCE(parent_id, id),
  sort_order;
