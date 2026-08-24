# Thailand Market — สรุปหมวดหมู่ & ฟิลเตอร์

เอกสารสรุปโครงสร้าง **หมวดหมู่สินค้า (Categories)** และ **ระบบฟิลเตอร์ (Filters)**
ของเว็บ Thailand Market — ดึงจากไฟล์จริงในโปรเจกต์ (SQL + `category.html`)

| หัวข้อ | ค่า |
|--------|-----|
| หมวดหลัก (Level 1) | **12 หมวด** |
| หมวดย่อย (Level 2) | **132 หมวด** |
| รวมทั้งหมด | **144 แถวในตาราง `categories`** |
| ความลึกสูงสุด | 2 ระดับ (parent → child) |
| ไฟล์ต้นทางหลัก | `supabase-categories-full.sql` |
| หน้าใช้งานฟิลเตอร์ | `category.html` (หน้าหลักของ list + search) |

---

## 1. ตาราง `categories` (Supabase)

จาก `supabase-setup.sql` / `SETUP-ALL.sql`:

| คอลัมน์ | ชนิด | หมายเหตุ |
|---------|------|----------|
| `id` | UUID PK | `uuid_generate_v4()` |
| `name_th` | TEXT NOT NULL | ชื่อไทย — ใช้แสดงผลหลัก |
| `name_en` | TEXT | ชื่ออังกฤษ |
| `slug` | TEXT UNIQUE NOT NULL | ใช้ใน URL `category.html?slug=...` |
| `icon` | TEXT | emoji |
| `image_url` | TEXT | รูปแบนเนอร์หมวด |
| `parent_id` | UUID FK → categories(id) | `NULL` = หมวดหลัก |
| `sort_order` | INTEGER | ลำดับแสดงผล |
| `is_active` | BOOLEAN | ซ่อน/แสดง |
| `product_count` | INTEGER | จำนวนสินค้า (แสดงข้างชื่อในฟิลเตอร์) |
| `created_at` | TIMESTAMPTZ | |

> `database-schema.sql` เป็นสคีมารุ่นเก่า (มี `commission_rate`, `color_hex`, `level` และ seed 8 หมวด) — **ไม่ใช่ตัวที่ระบบใช้อยู่จริง** ยึดตาม `supabase-setup.sql`

### ไฟล์ SQL ของหมวดหมู่ — ใช้ตัวไหน

| ไฟล์ | เนื้อหา | ใช้เมื่อ |
|------|---------|----------|
| **`supabase-categories-full.sql`** | 12 หลัก + 132 ย่อย, resolve `parent_id` ด้วย slug lookup (ไม่ hardcode UUID) | ✅ ตัวหลัก — รันตัวนี้ |
| `lazada-categories.sql` | เวอร์ชันก่อนหน้า (12 หลัก + 121 ย่อย) | อ้างอิงเท่านั้น |
| `CATEGORIES-FIX.sql` | ตั้ง RLS ให้ anon อ่าน `categories` ได้ + seed หมวดด้วย UUID แบบ fix | ใช้เมื่อหมวดไม่โผล่ใน seller-portal / add-product |

**ลำดับการรัน:** `SETUP-ALL.sql` (หรือ `supabase-setup.sql`) → `supabase-categories-full.sql` → ถ้าหมวดไม่แสดง ค่อยรัน `CATEGORIES-FIX.sql`

---

## 2. แผนผังหมวดหมู่ทั้งหมด (12 หลัก / 132 ย่อย)

| # | หมวดหลัก | slug | หมวดย่อย |
|---|----------|------|----------|
| 1 | 📱 อุปกรณ์อิเล็กทรอนิกส์ | `electronic-devices` | 12 |
| 2 | 🔌 อุปกรณ์เสริมอิเล็กทรอนิกส์ | `electronic-accessories` | 10 |
| 3 | 📺 ทีวีและเครื่องใช้ไฟฟ้า | `tv-home-appliances` | 7 |
| 4 | 💄 สุขภาพและความงาม | `health-beauty` | 12 |
| 5 | 🍼 แม่และเด็ก / ของเล่น | `babies-toys` | 12 |
| 6 | 🛒 ของชำและสัตว์เลี้ยง | `groceries-pets` | 10 |
| 7 | 🏠 บ้านและไลฟ์สไตล์ | `home-lifestyle` | 23 |
| 8 | 👗 แฟชั่นผู้หญิง | `womens-fashion` | 8 |
| 9 | 👔 แฟชั่นผู้ชาย | `mens-fashion` | 7 |
| 10 | 👧 แฟชั่นเด็ก | `kids-fashion` | 7 |
| 11 | 🏋️ กีฬาและการเดินทาง | `sports-travel` | 12 |
| 12 | 🚗 ยานยนต์ | `automotive` | 12 |

---

## 3. รายละเอียดหมวดย่อยรายหมวด

### 1. 📱 อุปกรณ์อิเล็กทรอนิกส์ — Electronic Devices
`electronic-devices` · หมวดย่อย 12 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 📱 โทรศัพท์มือถือ | Mobiles | `mobiles` |
| 2 | 📟 แท็บเล็ต | Tablets | `tablets` |
| 3 | 💻 โน้ตบุ๊ก | Laptops | `laptops` |
| 4 | 🖥️ คอมพิวเตอร์ตั้งโต๊ะ | Desktops | `desktops` |
| 5 | 📷 กล้อง DSLR | DSLR Cameras | `dslr` |
| 6 | 📸 กล้อง Mirrorless | Mirrorless Cameras | `mirrorless` |
| 7 | 📷 กล้อง Point & Shoot | Point & Shoot | `point-shoot` |
| 8 | 🖼️ กล้อง Instant | Instant Camera | `instant-camera` |
| 9 | 🎥 กล้องวิดีโอ / Action | Action Cameras | `action-cameras` |
| 10 | 🛸 โดรน | Drones | `drones` |
| 11 | 📹 กล้องวงจรปิด | Security Cameras | `security-cameras` |
| 12 | 🎮 เครื่องเล่นเกม Console | Console Gaming | `console-gaming` |

### 2. 🔌 อุปกรณ์เสริมอิเล็กทรอนิกส์ — Electronic Accessories
`electronic-accessories` · หมวดย่อย 10 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 📱 อุปกรณ์เสริมมือถือ | Mobile Accessories | `mobile-accessories` |
| 2 | 🎧 เครื่องเสียง | Audio | `audio` |
| 3 | ⌚ Wearables | Wearables | `wearables` |
| 4 | 🔧 Gadgets | Gadgets | `gadgets` |
| 5 | 💾 อุปกรณ์จัดเก็บข้อมูล | Data Storage | `data-storage` |
| 6 | 🖱️ อุปกรณ์เสริม PC | PC Accessories | `pc-accessories` |
| 7 | 🔩 ชิ้นส่วนคอมพิวเตอร์ | Computer Components | `computer-components` |
| 8 | 📡 อุปกรณ์เครือข่าย | Network Components | `network-components` |
| 9 | 🎮 อุปกรณ์เสริม Console | Console Accessories | `console-accessories` |
| 10 | 🎞️ อุปกรณ์เสริมกล้อง | Camera Accessories | `camera-accessories` |

### 3. 📺 ทีวีและเครื่องใช้ไฟฟ้า — TV & Home Appliances
`tv-home-appliances` · หมวดย่อย 7 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 📺 ทีวีและอุปกรณ์วิดีโอ | TVs & Video | `tvs-video` |
| 2 | 🫙 เครื่องใช้ไฟฟ้าขนาดใหญ่ | Large Appliances | `large-appliances` |
| 3 | ☕ เครื่องครัวขนาดเล็ก | Small Kitchen Appliances | `small-kitchen` |
| 4 | ❄️ เครื่องปรับอากาศ | Air Treatment | `air-treatment` |
| 5 | 🔌 เครื่องใช้ไฟฟ้าในบ้าน | Household Appliances | `household-appliances` |
| 6 | 💆 เครื่องดูแลร่างกาย | Personal Care Appliances | `personal-care-appliances` |
| 7 | 🔧 อะไหล่และอุปกรณ์เสริม | Parts & Accessories | `appliance-parts` |

### 4. 💄 สุขภาพและความงาม — Health & Beauty
`health-beauty` · หมวดย่อย 12 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | ✨ ดูแลผิวหน้า | Skincare | `skincare` |
| 2 | 💄 เครื่องสำอาง | Make-Up | `makeup` |
| 3 | 💇 ดูแลเส้นผม | Hair Care | `hair-care` |
| 4 | 🛁 ดูแลร่างกาย | Bath & Body | `bath-body` |
| 5 | 🪥 ของใช้ส่วนตัว | Personal Care | `personal-care` |
| 6 | 🌸 น้ำหอม | Fragrances | `fragrances` |
| 7 | 💅 เครื่องมือความงาม | Beauty Tools | `beauty-tools` |
| 8 | 🧴 ผลิตภัณฑ์ผู้ชาย | Men's Care | `mens-care` |
| 9 | 💊 วิตามินและอาหารเสริม | Vitamins & Supplements | `vitamins` |
| 10 | 🏥 อุปกรณ์ทางการแพทย์ | Medical Supplies | `medical-supplies` |
| 11 | 🩲 ผ้าอ้อมผู้ใหญ่ | Adult Diapers | `adult-diapers` |
| 12 | ❤️ ถุงยางและสารหล่อลื่น | Condoms & Lubricants | `condoms` |

### 5. 🍼 แม่และเด็ก / ของเล่น — Babies & Toys
`babies-toys` · หมวดย่อย 12 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 👶 แม่และเด็ก | Mother & Baby | `mother-baby` |
| 2 | 🚼 ผ้าอ้อมและกระโถน | Diapering & Potty | `diapering` |
| 3 | 🍼 นมผงและอาหารเด็ก | Milk Formula & Food | `baby-food` |
| 4 | 🥄 อุปกรณ์ให้อาหาร | Feeding Essentials | `feeding` |
| 5 | 🛺 รถเข็นและอุปกรณ์ | Baby Gear | `baby-gear` |
| 6 | 🛏️ ห้องเด็กอ่อน | Nursery | `nursery` |
| 7 | 🧸 ของใช้ส่วนตัวเด็ก | Baby Personal Care | `baby-personal-care` |
| 8 | 👕 เสื้อผ้าเด็กอ่อน | Baby Fashion | `baby-fashion` |
| 9 | 🎲 ของเล่นและเกม | Toys & Games | `toys-games` |
| 10 | 🪀 ของเล่นเด็กเล็ก | Baby Toys | `baby-toys` |
| 11 | ⚽ ของเล่นกีฬากลางแจ้ง | Sports Toys | `sports-toys` |
| 12 | 🚗 ของเล่นรีโมทคอนโทรล | RC & Electronic Toys | `rc-toys` |

### 6. 🛒 ของชำและสัตว์เลี้ยง — Groceries & Pets
`groceries-pets` · หมวดย่อย 10 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 🥤 เครื่องดื่ม | Drinks | `drinks` |
| 2 | 🥐 ซีเรียลและแยม | Breakfast & Spreads | `breakfast` |
| 3 | 🛒 ของชำและเครื่องปรุง | Food Staples | `food-staples` |
| 4 | 🥦 ผักและผลไม้ | Fruit & Vegetables | `fresh-produce` |
| 5 | 🍫 ขนมและช็อกโกแลต | Snacks & Sweets | `snacks` |
| 6 | 🧹 ผลิตภัณฑ์ทำความสะอาด | Cleaning Supplies | `cleaning` |
| 7 | 🧺 ผลิตภัณฑ์ซักผ้า | Laundry Supplies | `laundry` |
| 8 | 🐾 อุปกรณ์สัตว์เลี้ยง | Pet Accessories | `pet-accessories` |
| 9 | 🦴 อาหารสัตว์เลี้ยง | Pet Food | `pet-food` |
| 10 | 🩺 สุขภาพสัตว์เลี้ยง | Pet Healthcare | `pet-healthcare` |

### 7. 🏠 บ้านและไลฟ์สไตล์ — Home & Lifestyle
`home-lifestyle` · หมวดย่อย 23 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 🛋️ เฟอร์นิเจอร์และจัดเก็บ | Furniture & Organization | `furniture` |
| 2 | 💡 โคมไฟและแสงสว่าง | Lighting | `lighting` |
| 3 | 🖼️ ของตกแต่งบ้าน | Home Décor | `home-decor` |
| 4 | 🛏️ ผ้าปูที่นอน | Bedding | `bedding` |
| 5 | 🚿 ห้องน้ำ | Bath | `bath` |
| 6 | 🍳 ครัวและรับประทานอาหาร | Kitchen & Dining | `kitchen-dining` |
| 7 | ✏️ เครื่องเขียนและออฟฟิศ | Stationery & Office | `stationery` |
| 8 | 🧺 ซักรีดและทำความสะอาด | Laundry & Cleaning | `laundry-cleaning` |
| 9 | 🌿 กลางแจ้งและสวน | Outdoor & Garden | `outdoor-garden` |
| 10 | 🎸 ดนตรีและเครื่องดนตรี | Music & Instruments | `music` |
| 11 | 📚 หนังสือ | Books | `books` |
| 12 | 🪴 ต้นไม้และพืชสวน | Plants & Gardening | `plants-gardening` |
| 13 | 🌱 ต้นไม้ในบ้าน | Indoor Plants | `indoor-plants` |
| 14 | 🌳 ต้นไม้กลางแจ้ง | Outdoor Plants | `outdoor-plants` |
| 15 | 🌾 เมล็ดพันธุ์ | Seeds | `seeds` |
| 16 | 🪣 ดินและปุ๋ย | Soil & Fertilizer | `soil-fertilizer` |
| 17 | 🪴 กระถางและภาชนะ | Pots & Planters | `pots-planters` |
| 18 | 🏗️ ช่างและวัสดุก่อสร้าง | Hardware & Building | `hardware-building` |
| 19 | 🧱 วัสดุก่อสร้าง | Building Materials | `building-materials` |
| 20 | 🎨 สีและอุปกรณ์ทาสี | Paint & Tools | `paint-tools` |
| 21 | 🚰 ประปาและระบบน้ำ | Plumbing | `plumbing` |
| 22 | ⚡ ไฟฟ้าและสายไฟ | Electrical & Wiring | `electrical` |
| 23 | 🔨 เครื่องมือช่าง | Power Tools | `power-tools` |

### 8. 👗 แฟชั่นผู้หญิง — Women's Fashion
`womens-fashion` · หมวดย่อย 8 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 👗 เสื้อผ้าผู้หญิง | Women's Clothing | `womens-clothing` |
| 2 | 👠 รองเท้าผู้หญิง | Women's Shoes | `womens-shoes` |
| 3 | 🩱 ชุดชั้นในและชุดนอน | Lingerie & Sleepwear | `lingerie` |
| 4 | 👙 ชุดว่ายน้ำ | Swimwear | `swimwear` |
| 5 | 💍 เครื่องประดับผู้หญิง | Women's Accessories | `womens-accessories` |
| 6 | 👜 กระเป๋าผู้หญิง | Women's Bags | `womens-bags` |
| 7 | 🕶️ แว่นตาผู้หญิง | Women's Eyewear | `womens-eyewear` |
| 8 | ⌚ นาฬิกาผู้หญิง | Women's Watches | `womens-watches` |

### 9. 👔 แฟชั่นผู้ชาย — Men's Fashion
`mens-fashion` · หมวดย่อย 7 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 👔 เสื้อผ้าผู้ชาย | Men's Clothing | `mens-clothing` |
| 2 | 👞 รองเท้าผู้ชาย | Men's Shoes | `mens-shoes` |
| 3 | 🩲 ชุดชั้นในผู้ชาย | Men's Underwear | `mens-underwear` |
| 4 | ⌚ เครื่องประดับผู้ชาย | Men's Accessories | `mens-accessories` |
| 5 | 💼 กระเป๋าผู้ชาย | Men's Bags | `mens-bags` |
| 6 | 🕶️ แว่นตาผู้ชาย | Men's Eyewear | `mens-eyewear` |
| 7 | ⌚ นาฬิกาผู้ชาย | Men's Watches | `mens-watches` |

### 10. 👧 แฟชั่นเด็ก — Kid's Fashion
`kids-fashion` · หมวดย่อย 7 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 👕 เสื้อผ้าเด็กผู้ชาย | Boys' Clothing | `boys-clothing` |
| 2 | 👗 เสื้อผ้าเด็กผู้หญิง | Girls' Clothing | `girls-clothing` |
| 3 | 👟 รองเท้าเด็กผู้ชาย | Boys' Shoes | `boys-shoes` |
| 4 | 👡 รองเท้าเด็กผู้หญิง | Girls' Shoes | `girls-shoes` |
| 5 | ⌚ นาฬิกาเด็ก | Kids' Watches | `kids-watches` |
| 6 | 🎒 กระเป๋าเด็ก | Kids' Bags | `kids-bags` |
| 7 | 🕶️ แว่นตาเด็ก | Kids' Eyewear | `kids-eyewear` |

### 11. 🏋️ กีฬาและการเดินทาง — Sports & Travel
`sports-travel` · หมวดย่อย 12 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 🏋️ ออกกำลังกาย | Exercise & Fitness | `exercise-fitness` |
| 2 | 🏕️ กิจกรรมกลางแจ้ง | Outdoor Recreation | `outdoor-recreation` |
| 3 | 🏃 เสื้อผ้ากีฬาผู้ชาย | Men's Sports Apparel | `mens-sports-apparel` |
| 4 | 👟 รองเท้ากีฬาผู้ชาย | Men's Sports Shoes | `mens-sports-shoes` |
| 5 | 🤸 เสื้อผ้ากีฬาผู้หญิง | Women's Sports Apparel | `womens-sports-apparel` |
| 6 | 👟 รองเท้ากีฬาผู้หญิง | Women's Sports Shoes | `womens-sports-shoes` |
| 7 | 🚴 จักรยาน | Cycling | `cycling` |
| 8 | 🏊 กีฬาทางน้ำ | Water Sports | `water-sports` |
| 9 | ⚽ กีฬาทีม | Team Sports | `team-sports` |
| 10 | 🏸 แบดมินตันและเทนนิส | Racket Sports | `racket-sports` |
| 11 | 🎽 อุปกรณ์กีฬา | Sport Accessories | `sport-accessories` |
| 12 | ✈️ การเดินทาง | Travel | `travel` |

### 12. 🚗 ยานยนต์ — Automotive & Motorcycles
`automotive` · หมวดย่อย 12 หมวด

| # | ไทย | อังกฤษ | slug |
|---|-----|--------|------|
| 1 | 🛢️ น้ำมันและของเหลว | Oils & Fluids | `oils-fluids` |
| 2 | 🚘 ยานยนต์ทั่วไป | Automotive General | `automotive-general` |
| 3 | 📹 กล้องติดรถยนต์ | Car Camera | `car-camera` |
| 4 | 🔊 เครื่องเสียงรถยนต์ | Car Audio | `car-audio` |
| 5 | 🛞 ยางและล้อรถ | Auto Tires & Wheels | `auto-tires` |
| 6 | ⚙️ อะไหล่รถยนต์ | Auto Parts & Spares | `auto-parts` |
| 7 | 🪄 อุปกรณ์เสริมรถยนต์ | Auto Accessories | `auto-accessories` |
| 8 | 🧽 ดูแลรักษารถ | Car Care | `car-care` |
| 9 | 🏍️ มอเตอร์ไซค์ | Motorcycle | `motorcycle` |
| 10 | 🛞 ยางมอเตอร์ไซค์ | Moto Tires & Wheels | `moto-tires` |
| 11 | 🔩 อะไหล่มอเตอร์ไซค์ | Moto Parts | `moto-parts` |
| 12 | 🪖 ชุดขี่มอเตอร์ไซค์ | Motorcycle Riding Gear | `riding-gear` |
---

## 4. ระบบฟิลเตอร์ (`category.html`)

Sidebar `#filters-sidebar` — บนมือถือเปิดผ่านปุ่มลอย `#filter-fab` ("🎛 ตัวกรอง")

### 4.1 เรียงลำดับ (Sort)

| ปุ่ม | ค่า `currentSort` | Query |
|------|-------------------|-------|
| ใหม่สุด *(ค่าเริ่มต้น)* | `created_at-desc` | `.order('created_at', desc)` |
| ขายดี | `pop` | `.order('sold_count', desc)` |
| ราคา ↑ | `price-asc` | `.order('price', asc)` |
| ราคา ↓ | `price-desc` | `.order('price', desc)` |
| ★ คะแนน | `rating` | `.order('rating_avg', desc)` |

### 4.2 ฟิลเตอร์ทั้ง 6 กลุ่ม

| กลุ่ม | ชนิด | ตัวเลือก | ตัวแปร | Query ที่ยิงจริง |
|-------|------|----------|--------|------------------|
| **หมวดหมู่** | checkbox tree (หลัก + ย่อย, มี product_count) | 144 หมวด | `currentCat` | `.in('category_id', [หมวด, ...หมวดย่อยทั้งหมด])` |
| **ช่วงราคา** | input min/max + chip | ต่ำกว่า ฿500 · ฿500–1K · ฿1K–5K · ฿5K+ | `#min-price` / `#max-price` | `.gte('price',min)` `.lte('price',max)` |
| **แบรนด์** | checkbox (โหลดจากตาราง `brands`) | ตามข้อมูลจริง | `selectedBrands` (Set) | ⚠️ ยังไม่ผูกกับ query |
| **ส่วนลด** | pill เลือกได้ 1 | 10%+ · 20%+ · 30%+ · 50%+ | `currentDiscount` | `.gte('discount_percent', n)` |
| **บริการ** | pill เลือกได้หลายอัน | 🚚 ส่งฟรี · ⚡ Flash Sale · ⭐ สินค้าแนะนำ · ✅ ร้านค้ายืนยัน | `currentServices` (Set) | `flash` → `.eq('is_flash_sale',true)` · `featured` → `.eq('is_featured',true)` |
| **คะแนนรีวิว** | pill เลือกได้ 1 | 5 ดาว · 4+ ดาว · 3+ ดาว | `currentRating` | `.gte('rating_avg', n)` |

นอกจากนี้ ช่องค้นหา (`#search-inp`, debounce 400ms) ยิง
`.or('name_th.ilike.%q%, description.ilike.%q%')`

### 4.3 ช่องว่างที่ยังไม่ได้ทำ (ควรรู้ก่อนใช้งานจริง)

1. **แบรนด์** — เลือกได้ ขึ้น active tag ได้ แต่ `selectedBrands` ไม่ถูกใส่ใน query ของ `loadProds()` → ผลลัพธ์ไม่เปลี่ยน
2. **ส่งฟรี (`free_ship`)** — มีปุ่มแต่ไม่มีเงื่อนไขใน query (ยังไม่มีคอลัมน์รองรับใน `products`)
3. **ร้านค้ายืนยัน (`verified`)** — มีปุ่ม แต่ไม่มีทั้ง query และป้าย active tag (`labels` ใน `updateActiveTags()` ไม่มีคีย์นี้)

### 4.4 พฤติกรรมประกอบ

- **Active tags** — แถบป้ายด้านบน (`#active-filters`) แสดงฟิลเตอร์ที่เปิดอยู่ กด ✕ เพื่อลบทีละอัน
- **ล้างทั้งหมด** — `resetAllFilters()` เคลียร์ทุกตัวแปร + กลับหน้า 1
- **แบ่งหน้า** — `PAGE_MAX = 72` ชิ้น/หน้า (โหลด 3 chunk รวดเดียว) แล้วขึ้นเลขหน้า
- **มุมมอง** — สลับ grid / list ผ่าน `currentView`
- **ฟิลเตอร์ทุกตัวทำงานที่ฝั่ง Supabase** (ยกเว้นแบรนด์/ส่งฟรี/ร้านยืนยันที่ยังไม่ผูก) — เปลี่ยนค่าแล้วเรียก `loadProds()` ใหม่ทุกครั้ง

---

## 5. URL Parameters ของ `category.html`

| พารามิเตอร์ | ตัวอย่าง | ความหมาย |
|-------------|----------|----------|
| `slug` | `?slug=mobiles` | เปิดหมวดตาม slug (แนะนำให้ใช้ตัวนี้) |
| `cat` | `?cat=electronic-devices` หรือ UUID | รองรับทั้ง slug และ UUID (backward-compat), `?cat=all` = ทั้งหมด |
| `q` / `search` | `?q=หูฟัง` | คำค้นหา |
| `brand` / `brand_name` | `?brand=<uuid>` | กรองตามแบรนด์จากลิงก์ |
| `collection` | `?collection=...` | คอลเลกชัน/แคมเปญ |

`search.html` เป็นหน้า redirect เฉย ๆ → ส่งต่อไป `category.html?q=...`

---

## 6. จุดอื่นในระบบที่อ่านตาราง `categories`

| ไฟล์ | ใช้ทำอะไร |
|------|-----------|
| `category.html` | แถบหมวดด้านบน + checkbox tree ในฟิลเตอร์ |
| `index.html` | แถวหมวดหมู่หน้าแรก |
| `storefront.html` | หมวดในร้านค้า |
| `wishlist.html` | จัดกลุ่ม/กรองรายการที่ถูกใจ |
| `seller-products.html` / `seller-portal.html` | dropdown เลือกหมวดตอนลงสินค้า |
| `admin-categories.html` | หน้าจัดการหมวดหมู่ฝั่งแอดมิน |

---

*สรุปจากซอร์สในรีโป ณ วันที่ 24 ส.ค. 2026*
