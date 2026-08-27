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

## 3) ตั้งค่า DNS ที่ผู้ให้บริการโดเมน (ส่วนนี้ทำใน GitHub ไม่ได้)

ต้องเข้าไปที่ registrar / DNS provider ของ `thailandmarket.ai`
(เช่น Cloudflare, GoDaddy, Namecheap, Porkbun) แล้วสร้าง record:

**สำหรับ `www` (โดเมนหลักตาม CNAME):**

| Type | Name | Value |
|---|---|---|
| CNAME | `www` | `earthcarterior.github.io` |

**สำหรับ apex/root `thailandmarket.ai` (ให้ redirect เข้า www):**

| Type | Name | Value |
|---|---|---|
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |

(หรือใช้ AAAA สำหรับ IPv6: `2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`)

> ถ้าใช้ Cloudflare: ตั้ง proxy status เป็น **DNS only** (เมฆสีเทา) ตอนแรก
> เพื่อให้ GitHub ออก certificate ได้ แล้วค่อยเปิด proxy ทีหลังถ้าต้องการ

ตรวจสอบ:
```bash
dig www.thailandmarket.ai +short
curl -I https://www.thailandmarket.ai
```

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
