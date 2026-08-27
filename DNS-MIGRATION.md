# ย้ายโดเมน: www.thailandmarket.com → www.thailandmarket.ai

เว็บนี้ deploy ด้วย **GitHub Pages** (ดูได้จากไฟล์ `CNAME` ที่ root ของ repo)
การย้ายโดเมนมี 3 ส่วน: **ในโค้ด (repo)** → **ในหน้า Settings ของ GitHub** → **ที่ผู้ให้บริการโดเมน (DNS)**

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

### ขั้น 4 — จุดที่แต่ละเจ้าต่างกัน

**Cloudflare**
- ไปที่ DNS → Records → Add record
- ตั้ง **Proxy status = DNS only (เมฆสีเทา)** ทั้ง `www` และ `@`
  ถ้าเปิด proxy (เมฆส้ม) ไว้ **GitHub จะออก SSL cert ไม่ได้** ค้างที่ "certificate provisioning" ตลอด
- ถ้าอยากเปิด proxy ทีหลัง ให้รอจน GitHub ติ๊ก Enforce HTTPS ได้ก่อน แล้วค่อยเปิด
  และต้องตั้ง SSL/TLS mode = **Full (strict)** ไม่ใช่ Flexible (Flexible จะทำให้ redirect loop)
- Cloudflare รองรับ CNAME flattening ที่ apex ได้ — จะใช้ `CNAME @ → earthcarterior.github.io` แทน A record 4 ตัวก็ได้

**GoDaddy**
- My Products → Domain → DNS → Manage Zones
- GoDaddy จะมี A record `@` ชี้ไป `Parked` มาให้ ต้องแก้/ลบทิ้ง
- GoDaddy ให้ A record ชื่อซ้ำหลายตัวได้ กด "Add More Records"

**Namecheap**
- Domain List → Manage → Advanced DNS
- ลบ "URL Redirect Record" และ CNAME `www` → `parkingpage.namecheap.com` ที่ติดมาตอนซื้อ
- CNAME ใช้ Type = `CNAME Record`, Host = `www`

**Porkbun**
- Domain Management → DNS → ลบ A record ของ parking ออกก่อน

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

## 4) จัดการโดเมนเดิม (thailandmarket.com)

GitHub Pages ใช้ custom domain ได้ **repo ละ 1 โดเมน** — ใส่ทั้ง `.com` และ `.ai` พร้อมกันไม่ได้
ถ้าอยากให้คนที่พิมพ์ `.com` เด้งไป `.ai` เลือกอย่างใดอย่างหนึ่ง:

- **ง่ายสุด:** ใช้ฟีเจอร์ *Domain Forwarding / URL Redirect* ของ registrar ที่ถือ `.com` อยู่
  ตั้ง 301 redirect `www.thailandmarket.com` → `https://www.thailandmarket.ai`
- **ผ่าน Cloudflare:** ใช้ Redirect Rule (301) ที่ zone ของ `.com`
- **ผ่าน GitHub:** สร้าง repo ใหม่แยกอีกอัน ใส่ `CNAME` = `www.thailandmarket.com`
  และ `index.html` ที่มี `<meta http-equiv="refresh" content="0; url=https://www.thailandmarket.ai/">`
  (วิธีนี้เป็น redirect ฝั่ง client ไม่ใช่ 301 จริง — SEO ด้อยกว่า 2 วิธีบน)

**อย่าปล่อย DNS ของ `.com` ชี้ไปที่ GitHub Pages ทิ้งไว้เฉย ๆ** หลังถอด custom domain
เพราะเสี่ยงโดน subdomain takeover

---

## 5) สิ่งที่ต้องตามเก็บหลังย้าย

- [ ] Google Search Console — เพิ่ม property ใหม่ `.ai` + ใช้ Change of Address จาก `.com`
- [ ] Supabase → Authentication → URL Configuration: อัปเดต Site URL และ Redirect URLs เป็น `.ai`
- [ ] อัปเดตลิงก์ในโซเชียล / LINE OA / โฆษณา
- [ ] **อีเมล:** ในโค้ดเปลี่ยนเป็น `admin@thailandmarket.ai` หมดแล้ว (จากเดิม `support@thailandmarket.com`
      และ `admin@thailandmarket.com`) — ต้องตั้ง **MX record** ของ `thailandmarket.ai` ที่ registrar
      และสร้างกล่องเมล `admin@thailandmarket.ai` ให้เรียบร้อย ไม่งั้นเมลที่ส่งมาจะตีกลับ
      แนะนำตั้ง forward จาก `support@thailandmarket.com` เดิมมาที่อยู่ใหม่ไว้ช่วงเปลี่ยนผ่าน
