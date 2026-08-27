# ย้ายโดเมน: www.thailandmarket.com → www.thailandmarket.ai

เว็บนี้ deploy ด้วย **GitHub Pages** (ดูได้จากไฟล์ `CNAME` ที่ root ของ repo)
การย้ายโดเมนมี 3 ส่วน: **ในโค้ด (repo)** → **ในหน้า Settings ของ GitHub** → **ที่ผู้ให้บริการโดเมน (DNS)**

ทั้ง `thailandmarket.com` และ `thailandmarket.ai` อยู่ที่ **GoDaddy** ทั้งคู่

## ลำดับการทำ (ห้ามสลับ)

| # | ทำอะไร | ที่ไหน | ดูหัวข้อ |
|---|---|---|---|
| 1 | Merge PR ที่เปลี่ยนไฟล์ `CNAME` | GitHub | §1 |
| 2 | ตั้ง DNS records ของ **`.ai`** | GoDaddy → thailandmarket.ai | §3 ขั้น 4 |
| 3 | ยืนยัน custom domain + รอ DNS check ผ่าน | GitHub Settings → Pages | §2 |
| 4 | ติ๊ก Enforce HTTPS (รอ cert ออกก่อน) | GitHub Settings → Pages | §3 ขั้น 7 |
| 5 | **เช็คว่า `https://www.thailandmarket.ai` เข้าได้จริง** | เบราว์เซอร์ | §3 ขั้น 6 |
| 6 | ลบ DNS เดิมของ **`.com`** + ตั้ง 301 forwarding | GoDaddy → thailandmarket.com | §4 |
| 7 | ตั้ง MX + สร้างกล่องเมล `admin@thailandmarket.ai` | GoDaddy → thailandmarket.ai | §5 |

> ข้อ 6 ต้องทำ **หลัง** ข้อ 5 ผ่านแล้วเท่านั้น ถ้ารื้อ `.com` ก่อนที่ `.ai` จะขึ้น
> จะไม่มีโดเมนไหนใช้งานได้เลยระหว่างรอ DNS propagate

---

## 1) ในโค้ด (ทำแล้วใน PR นี้)

| ไฟล์ | เปลี่ยนอะไร |
|---|---|
| `CNAME` | `www.thailandmarket.com` → `www.thailandmarket.ai` |
| `index.html`, `404.html`, `shop.html`, `storefront.html`, `site-map.html`, `seller.html`, `b2b.html`, `return.html` | `og:url`, `<link rel="canonical">`, `<title>` |
| `thamarket-app.html` | ค่าคงที่ `SITE` และข้อความที่แสดงชื่อโดเมน |

> ไฟล์ `CNAME` คือสิ่งที่บอก GitHub Pages ว่าเว็บนี้ใช้โดเมนอะไร — ต้องมีบรรทัดเดียว ไม่ต้องมี `https://`

---

## 2) ตั้งค่าใน GitHub (ทำหลัง merge)

1. ไปที่ repo → **Settings** → **Pages**
2. ช่อง **Custom domain** ใส่ `www.thailandmarket.ai` → **Save**
   (ถ้า merge PR นี้แล้ว ค่านี้จะอัปเดตตามไฟล์ `CNAME` ให้อัตโนมัติ)
3. รอจน GitHub ขึ้น **DNS check successful** (อาจใช้เวลาถึง ~24 ชม. รอ DNS propagate)
4. ติ๊ก **Enforce HTTPS** — ติ๊กได้ก็ต่อเมื่อ GitHub ออกใบ certificate ให้เสร็จแล้ว
   (ถ้ายังติ๊กไม่ได้ ให้ลบ custom domain แล้วใส่ใหม่ เพื่อสั่งออก cert รอบใหม่)

---

## 3) ตั้งค่า DNS ที่ผู้ให้บริการโดเมน — ทีละขั้น

> ส่วนนี้ทำใน GitHub ไม่ได้ ต้อง login เข้าที่ผู้ให้บริการโดเมนของ `thailandmarket.ai`

### ขั้น 0 — หาให้เจอก่อนว่า DNS อยู่ที่ไหน

โดเมนมี 2 ที่ที่อาจเกี่ยวข้อง และ**ต้องแก้ที่ "DNS host" ไม่ใช่ที่ registrar เสมอไป**

- **Registrar** = ที่ที่ซื้อโดเมน (Namecheap, GoDaddy, Porkbun, 101domain …)
- **DNS host** = ที่ที่ nameserver ชี้ไป (บางคนซื้อที่ GoDaddy แต่ย้าย NS ไป Cloudflare)

เช็คด้วยคำสั่งนี้ในเครื่องตัวเอง:

```bash
dig NS thailandmarket.ai +short
# หรือบน Windows
nslookup -type=NS thailandmarket.ai
```

- ได้ `xxx.ns.cloudflare.com` → ไปแก้ที่ **Cloudflare**
- ได้ `ns1.namecheaphosting.com` / `domaincontrol.com` (GoDaddy) / `ns1.porkbun.com` → แก้ที่ registrar นั้น
- ไม่ได้อะไรเลย → โดเมนอาจยังไม่ได้ตั้ง nameserver ให้ไปตั้งที่ registrar ก่อน

### ขั้น 1 — ลด TTL ก่อน (ถ้ามี record เดิมอยู่แล้ว)

ถ้า `thailandmarket.ai` เคยชี้ไปที่อื่นมาก่อน ให้แก้ TTL ของ record เดิมเป็น **300 วินาที (5 นาที)** แล้วรอ ~1 ชม.
ก่อนค่อยเปลี่ยนค่าจริง จะได้สลับเร็ว ถ้าเป็นโดเมนใหม่เอี่ยมยังไม่เคยตั้ง ข้ามขั้นนี้ได้

### ขั้น 2 — ลบ record เก่าที่ชนกัน

ในหน้า DNS ให้**ลบ**ของเดิมที่ชื่อ `www` และ `@` (root) ออกก่อน ถ้ามี:

- A / AAAA / CNAME ที่ชื่อ `www`
- A / AAAA / CNAME / ALIAS ที่ชื่อ `@`
- record ของ parking page ที่ registrar ใส่มาให้ตอนซื้อโดเมน (มักชี้ไป IP ของเขาเอง)

> ⚠️ ห้ามลบ MX, TXT (SPF/DKIM/verification) ถ้ามีใช้งานอยู่ — ลบเฉพาะที่ชนกับ 2 ชื่อข้างบน
> ชื่อ `www` กับ `@` จะมี CNAME **หรือ** A ได้อย่างใดอย่างหนึ่ง มีพร้อมกันไม่ได้

### ขั้น 3 — เพิ่ม record ของ GitHub Pages

**3.1 — `www` (โดเมนหลักตามไฟล์ CNAME):**

| Type | Name / Host | Value / Target | TTL |
|---|---|---|---|
| CNAME | `www` | `earthcarterior.github.io` | Auto / 300 |

- ค่า target ต้องเป็น `earthcarterior.github.io` **ไม่ใช่** ชื่อ repo และ **ไม่ใส่** `https://` หรือ path
- บาง UI ต้องใส่จุดปิดท้าย: `earthcarterior.github.io.`
- บาง UI (GoDaddy) ช่อง Host ให้กรอกแค่ `www` ไม่ต้องกรอกเต็มโดเมน

**3.2 — apex / root `thailandmarket.ai` (ให้เด้งเข้า www):**

เพิ่ม A record 4 ตัว ชื่อเดียวกันหมด (`@`):

| Type | Name | Value |
|---|---|---|
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |

เพิ่ม AAAA อีก 4 ตัวด้วยถ้ารองรับ IPv6 (ไม่บังคับ แต่แนะนำ):

| Type | Name | Value |
|---|---|---|
| AAAA | `@` | `2606:50c0:8000::153` |
| AAAA | `@` | `2606:50c0:8001::153` |
| AAAA | `@` | `2606:50c0:8002::153` |
| AAAA | `@` | `2606:50c0:8003::153` |

> GitHub จะ redirect `thailandmarket.ai` → `www.thailandmarket.ai` ให้เองอัตโนมัติ
> เพราะไฟล์ `CNAME` ในรีโประบุ `www` ไว้

### ขั้น 4 — GoDaddy: คลิกตรงไหนบ้าง (โดเมนใหม่ .ai)

1. เข้า godaddy.com → มุมขวาบนคลิกชื่อตัวเอง → **My Products**
2. หมวด **Domains** → หา `thailandmarket.ai` → คลิกปุ่ม **DNS**
   (บางบัญชีเป็น: คลิกชื่อโดเมน → แท็บ **DNS** → **DNS Records**)
3. ในตาราง **DNS Records** ให้จัดการของเดิมก่อน:
   - แถว **CNAME / Name = `www`** ที่ Value เป็น `@` → กดดินสอ **แก้เป็น** `earthcarterior.github.io`
     (GoDaddy ใส่ `www → @` มาให้ตอนซื้อโดเมนทุกครั้ง ตัวนี้ต้องแก้ ไม่ใช่เพิ่มใหม่)
   - แถว **A / Name = `@`** ที่ Value เป็น `Parked` หรือ IP แปลก ๆ → **ลบทิ้ง** (ถังขยะ)
   - แถว **CNAME `_domainconnect`** → ปล่อยไว้ ไม่ต้องยุ่ง
4. กด **Add New Record** เพิ่ม A record ทีละตัว รวม 4 ตัว:

   | Type | Name | Value | TTL |
   |---|---|---|---|
   | A | `@` | `185.199.108.153` | 1 Hour |
   | A | `@` | `185.199.109.153` | 1 Hour |
   | A | `@` | `185.199.110.153` | 1 Hour |
   | A | `@` | `185.199.111.153` | 1 Hour |

   GoDaddy ยอมให้มี A record ชื่อ `@` ซ้ำได้หลายตัว — เพิ่มให้ครบทั้ง 4
5. กด **Save** ทุกครั้งหลังเพิ่มแต่ละแถว

**ผลลัพธ์ที่ควรเห็นในตาราง GoDaddy:**

```
A       @      185.199.108.153
A       @      185.199.109.153
A       @      185.199.110.153
A       @      185.199.111.153
CNAME   www    earthcarterior.github.io
```

> **⚠️ ห้ามใช้ Domain Forwarding บนโดเมน `.ai`** — ถ้าตั้ง forwarding ไว้ GoDaddy จะเขียนทับ
> A record `@` ด้วย IP ของ GoDaddy เอง แล้ว GitHub Pages จะพัง หน้านี้ต้องเป็น DNS records ล้วน ๆ

**หมายเหตุสำหรับเจ้าอื่น** (เผื่อย้าย DNS ในอนาคต): Cloudflare ต้องตั้ง proxy เป็น
**DNS only (เมฆเทา)** ไม่งั้น GitHub ออก SSL cert ไม่ได้ · Namecheap ต้องลบ
"URL Redirect Record" และ CNAME `parkingpage.namecheap.com` ออกก่อน


### ขั้น 5 — เช็ค CAA record (ถ้ามี)

ถ้าโดเมนมี CAA record อยู่ ต้องอนุญาต Let's Encrypt ไม่งั้น GitHub ออก cert ไม่ได้:

```bash
dig CAA thailandmarket.ai +short
```

ถ้ามีผลลัพธ์ออกมาแต่ไม่มี `letsencrypt.org` ให้เพิ่ม:

| Type | Name | Value |
|---|---|---|
| CAA | `@` | `0 issue "letsencrypt.org"` |

ถ้าไม่มี CAA เลย = อนุญาตทุกเจ้า ไม่ต้องทำอะไร

### ขั้น 6 — รอ แล้วตรวจสอบ

DNS ใช้เวลา propagate ตั้งแต่ 5 นาที ถึง 24 ชม. ตรวจด้วย:

```bash
dig www.thailandmarket.ai +short
# ควรได้: earthcarterior.github.io. แล้วตามด้วย IP 185.199.1xx.153

dig thailandmarket.ai +short
# ควรได้ IP 185.199.1xx.153 ทั้ง 4 ตัว

curl -I https://www.thailandmarket.ai
# ควรได้ HTTP/2 200 และ header: server: GitHub.com
```

เช็คจากหลายประเทศได้ที่ https://dnschecker.org

### ขั้น 7 — กลับไปติ๊ก Enforce HTTPS

พอ Settings → Pages ขึ้น ✅ **DNS check successful** แล้ว รออีกสักพัก (10 นาที – 1 ชม.)
ให้ GitHub ออก certificate เสร็จ แล้วค่อยติ๊ก **Enforce HTTPS**

---

## 3.5) ตาราง Troubleshooting

| อาการ | สาเหตุที่พบบ่อย | วิธีแก้ |
|---|---|---|
| Pages ขึ้น "Domain does not resolve to the GitHub Pages server" | DNS ยังไม่ propagate / CNAME พิมพ์ผิด | รอ แล้ว `dig` เช็คค่าอีกครั้ง |
| ติ๊ก Enforce HTTPS ไม่ได้ (เป็นสีเทา) | cert ยังออกไม่เสร็จ หรือ Cloudflare proxy เปิดอยู่ | ปิด proxy เป็น DNS only → ลบ custom domain แล้วใส่ใหม่ |
| เข้าเว็บแล้วได้ 404 ของ GitHub | ไฟล์ `CNAME` ในรีโปไม่ตรงกับโดเมนที่เข้า | เช็คว่า `CNAME` = `www.thailandmarket.ai` บรรทัดเดียว |
| `ERR_TOO_MANY_REDIRECTS` | Cloudflare SSL mode = Flexible | เปลี่ยนเป็น Full (strict) |
| เว็บขึ้นแต่ CSS/รูปหาย | มีลิงก์ absolute ค้างอยู่ | สวีปแล้วในรีโปนี้ ไม่เหลือ — ถ้าเจอแจ้งได้ |
| custom domain ในรีโปหายเองหลัง push | มีคนลบไฟล์ `CNAME` ออก | ไฟล์ `CNAME` ต้องอยู่ใน branch ที่ Pages ใช้ deploy |

---

## 4) โดเมนเดิม `thailandmarket.com` ที่ GoDaddy

GitHub Pages ผูก custom domain ได้ **repo ละ 1 โดเมน** — ใส่ทั้ง `.com` และ `.ai` พร้อมกันไม่ได้
โดเมนเดิมจึงต้องเปลี่ยนบทบาทเป็น "ตัว redirect" แทน

### ⚠️ ลำดับสำคัญ — ทำผิดลำดับเว็บดับ

ทำ **หลัง** จาก `.ai` ใช้งานได้จริงแล้วเท่านั้น (เข้า `https://www.thailandmarket.ai` แล้วเห็นเว็บ)
ถ้ารื้อ `.com` ก่อน จะไม่มีโดเมนไหนใช้ได้เลยระหว่างรอ DNS

### 4.1 — ลบ record เก่าที่ชี้มาที่ GitHub ทิ้งก่อน

My Products → `thailandmarket.com` → **DNS** → ในตาราง DNS Records:

- ลบ **CNAME `www` → `earthcarterior.github.io`**
- ลบ **A `@` → 185.199.1xx.153** ทั้ง 4 ตัว (ถ้าเคยตั้งไว้)

> 🔒 **ขั้นนี้ห้ามข้าม** ถ้าปล่อย CNAME ชี้มาที่ `earthcarterior.github.io` ค้างไว้
> ทั้งที่ GitHub ไม่ได้ถือโดเมนนี้แล้ว คนอื่นเอาโดเมนคุณไปผูกกับ Pages ของเขาได้
> (subdomain takeover) แล้วปลอมเป็นเว็บคุณ

### 4.2 — ตั้ง Forwarding ที่ GoDaddy

ยังอยู่ที่หน้าโดเมน `thailandmarket.com` → เลื่อนหาหัวข้อ **Forwarding**
(อยู่ใต้ตาราง DNS Records หรือในแท็บ Domain Settings)

**ตัวที่ 1 — Domain (root):** กด **Add Forwarding**

| ช่อง | ค่าที่ใส่ |
|---|---|
| Forward to | `https://www.thailandmarket.ai` |
| Forward type | **Permanent (301)** |
| Settings | **Forward only** |

**ตัวที่ 2 — Subdomain `www`:** กด **Add Forwarding** อีกครั้ง เลือกหัวข้อ **Subdomain**

| ช่อง | ค่าที่ใส่ |
|---|---|
| Subdomain | `www` |
| Forward to | `https://www.thailandmarket.ai` |
| Forward type | **Permanent (301)** |
| Settings | **Forward only** |

- เลือก **301 Permanent** เท่านั้น — 302 ไม่ส่งค่า SEO ไปโดเมนใหม่
- เลือก **Forward only** ห้ามเลือก *Forward with masking* เพราะ masking จะครอบ URL เดิมไว้
  ทำให้ Google มองว่าเป็นเนื้อหาซ้ำ และ URL บนเบราว์เซอร์ไม่เปลี่ยน
- ตั้ง forwarding แล้ว GoDaddy จะสร้าง A record `@` ชี้ IP ของ GoDaddy ให้เอง — อันนี้ถูกต้องแล้ว
  สำหรับโดเมน `.com` (ต่างจากโดเมน `.ai` ที่ห้ามใช้ forwarding)

### 4.3 — ข้อจำกัดเรื่อง HTTPS ของ GoDaddy Forwarding

GoDaddy forwarding รองรับ `http://` ได้แน่นอน แต่ `https://www.thailandmarket.com`
อาจขึ้นเตือน certificate ถ้าโดเมนนั้นไม่มี SSL ผูกอยู่ — ลิงก์เก่าที่คนแชร์ไว้เป็น `https://`
จะเจอหน้าเตือนก่อนเด้ง ให้ทดสอบจริงหลังตั้งเสร็จ:

```bash
curl -I http://www.thailandmarket.com    # ควรได้ 301 → https://www.thailandmarket.ai
curl -I https://www.thailandmarket.com   # เช็คว่ามี cert error ไหม
```

ถ้าเจอ cert error และรับไม่ได้ ทางแก้ที่ฟรีและได้ผลชัวร์คือ **ย้าย nameserver ของ `.com`
ไป Cloudflare (แผนฟรี)** แล้วตั้ง Redirect Rule 301 ที่นั่นแทน — Cloudflare ออก SSL
ให้โดเมนฟรี ทำให้ `https://` ฝั่งเก่าใช้ได้ด้วย

### 4.4 — อย่าปล่อยโดเมนเดิมหมดอายุ

ต่ออายุ `thailandmarket.com` ไว้อย่างน้อย 1–2 ปีหลังย้าย เพื่อให้ 301 ทำงานต่อ
จนกว่า Google จะย้าย index มาที่ `.ai` ครบและลูกค้าจำโดเมนใหม่ได้

---


## 5) สิ่งที่ต้องตามเก็บหลังย้าย

- [ ] Google Search Console — เพิ่ม property ใหม่ `.ai` + ใช้ Change of Address จาก `.com`
- [ ] Supabase → Authentication → URL Configuration: อัปเดต Site URL และ Redirect URLs เป็น `.ai`
- [ ] อัปเดตลิงก์ในโซเชียล / LINE OA / โฆษณา
- [ ] **อีเมล `admin@thailandmarket.ai`** — ในโค้ดเปลี่ยนหมดแล้ว (จากเดิม `support@thailandmarket.com`
      และ `admin@thailandmarket.com`) แต่ **ที่อยู่นี้ยังใช้ไม่ได้จนกว่าจะตั้ง MX**

  MX เป็นคนละเรื่องกับ A/CNAME ของเว็บ — ตั้งที่ GoDaddy → `thailandmarket.ai` → DNS
  โดยใส่ค่าตามที่ผู้ให้บริการเมลบอก เช่น

  - **Google Workspace:** MX `@` → `smtp.google.com` (Priority 1)
  - **Microsoft 365:** MX `@` → `thailandmarket-ai.mail.protection.outlook.com` (Priority 0)
  - **Zoho Mail (มีแผนฟรี):** MX `@` → `mx.zoho.com` (10), `mx2.zoho.com` (20), `mx3.zoho.com` (50)

  พร้อมกับ TXT record สำหรับ SPF/DKIM ที่เจ้านั้นให้มา แล้วค่อยสร้างกล่อง `admin@`
  ในระบบเมล — MX อย่างเดียวไม่ได้สร้างกล่องให้

  แนะนำตั้ง forward จาก `support@thailandmarket.com` เดิมมาที่อยู่ใหม่ไว้ช่วงเปลี่ยนผ่านด้วย
  (GoDaddy → thailandmarket.com → Email → Forwarding) — ถ้ายกเลิกเมลของ `.com` ทันที
  ลูกค้าเก่าที่ส่งมาที่อยู่เดิมจะโดนตีกลับ
