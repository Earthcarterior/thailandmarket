# 🇹🇭 Thailand Market — Deployment Guide
**General Marketplace Platform · 54 HTML Pages · 2026**

---

## 📊 สรุปโปรเจกต์

| รายการ | จำนวน |
|--------|-------|
| หน้า HTML ทั้งหมด | 54 หน้า |
| หมวด Buyer Journey | 14 หน้า |
| หมวด Account | 5 หน้า |
| หมวด Seller Center | 11 หน้า |
| หมวด Admin Panel | 10 หน้า |
| หมวด Promotions | 9 หน้า |
| Tech Docs | 3 หน้า |
| Database Schema | 1 ไฟล์ SQL |

---

## 🚀 วิธี Deploy (Static HTML — ไม่ต้อง Backend)

### ✅ วิธีที่ 1 — Netlify (แนะนำ · ง่ายที่สุด · ฟรี)

1. ไปที่ **https://app.netlify.com/drop**
2. Zip โฟลเดอร์ทั้งหมด หรือ drag & drop โฟลเดอร์ลงในหน้า
3. ได้ URL ทันที เช่น `https://thailand-market-abc123.netlify.app`
4. (Optional) Settings → Domain → เพิ่ม Custom Domain

```
เวลา: 2 นาที | ค่าใช้จ่าย: ฟรี | CDN: ทั่วโลก
```

---

### ✅ วิธีที่ 2 — GitHub Pages (ฟรี · เหมาะกับ dev)

```bash
# 1. สร้าง repo บน github.com
git init
git add .
git commit -m "Thailand Market v1.0"
git branch -M main
git remote add origin https://github.com/USERNAME/thailand-market.git
git push -u origin main

# 2. GitHub → Settings → Pages → Source: Deploy from branch → main
# URL: https://USERNAME.github.io/thailand-market/
```

---

### ✅ วิธีที่ 3 — Vercel (เร็วมาก · ฟรี)

```bash
npm install -g vercel
cd thailand-market/
vercel
# ตอบ: Project name, Framework = Other
# URL: https://thailand-market.vercel.app
```

---

### ✅ วิธีที่ 4 — Cloudflare Pages (เร็วสุด · CDN ไทย)

1. https://pages.cloudflare.com → Create a project
2. Upload files โดยตรง หรือ Connect GitHub repo
3. Build command: (ว่าง) · Output directory: `/`
4. URL: `https://thailand-market.pages.dev`

---

### ✅ วิธีที่ 5 — Firebase Hosting

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Public directory: . (current)
# Single-page app: No
firebase deploy
```

---

## 🌐 การตั้งค่า Custom Domain

```
ตัวอย่าง Domain: thailandmarket.co.th / tm-shop.co.th

Netlify:   Site settings → Domain management → Add custom domain
Vercel:    Project → Settings → Domains → Add
GitHub:    Settings → Pages → Custom domain
CF Pages:  Pages → Custom domains → Set up a custom domain
```

**DNS Settings ที่ต้องตั้ง:**
```
Type: CNAME
Name: www (หรือ @)
Value: (URL จากแพลตฟอร์มที่เลือก)
TTL: Auto
```

---

## 📁 โครงสร้างไฟล์

```
thailand-market/
├── index.html              ← Entry Point (หน้าแรก)
│
├── ── BUYER JOURNEY ──
├── login.html              ← เข้าสู่ระบบ / สมัครสมาชิก
├── forgot-password.html    ← ลืมรหัสผ่าน (OTP 3 ขั้นตอน)
├── category.html           ← หมวดหมู่สินค้า 8 หมวด
├── search.html             ← ค้นหา + Filter
├── product.html            ← หน้าสินค้า + รีวิว + Q&A
├── compare.html            ← เปรียบเทียบสินค้า
├── checkout.html           ← ตะกร้า + ชำระเงิน
├── payment-result.html     ← ผลการชำระเงิน
├── tracking.html           ← ติดตามพัสดุ
├── order-history.html      ← ประวัติคำสั่งซื้อ
├── order-detail.html       ← รายละเอียดออเดอร์
├── returns.html            ← คืนสินค้า / เงิน
├── review-write.html       ← เขียนรีวิว
│
├── ── ACCOUNT ──
├── profile.html            ← โปรไฟล์ + Loyalty Points
├── address-book.html       ← จัดการที่อยู่
├── wishlist.html           ← รายการโปรด + Collections
├── notification-center.html← การแจ้งเตือน
├── chat.html               ← แชทกับร้านค้า
│
├── ── PROMOTIONS ──
├── flash-sale.html         ← Flash Sale Hub
├── live-shopping.html      ← Live Shopping
├── brand-day.html          ← Brand Day Campaign
├── coupon-hub.html         ← ศูนย์คูปอง
├── loyalty-catalog.html    ← แลกของรางวัล
├── gift-card.html          ← Gift Card
├── subscription.html       ← TM Plus Membership
├── referral.html           ← แนะนำเพื่อน
├── b2b-portal.html         ← B2B Portal
│
├── ── SELLER CENTER ──
├── seller-portal.html      ← Seller Dashboard
├── seller-products.html    ← จัดการสินค้า
├── seller-orders.html      ← ออเดอร์
├── seller-reviews.html     ← รีวิว
├── seller-coupons.html     ← คูปองร้านค้า
├── seller-ads.html         ← Sponsored Ads
├── seller-analytics.html   ← Analytics
├── seller-finance.html     ← การเงิน / Payout
├── seller-live.html        ← Live Shopping Setup
├── seller-onboarding.html  ← Seller Onboarding
├── onboarding.html         ← สมัครขายของ
│
├── ── ADMIN PANEL ──
├── admin-dashboard.html    ← Admin Overview
├── admin-users.html        ← จัดการผู้ใช้
├── admin-sellers.html      ← จัดการร้านค้า
├── admin-orders.html       ← ออเดอร์ทั้งระบบ
├── admin-products.html     ← อนุมัติสินค้า
├── admin-coupons.html      ← จัดการคูปอง
├── admin-payouts.html      ← Payout ผู้ขาย
├── flash-sale-admin.html   ← Flash Sale Admin
├── analytics-report.html  ← รายงาน Analytics
├── campaign-calendar.html  ← Campaign Calendar
│
├── ── MISC ──
├── help-center.html        ← Help Center + FAQ
├── sitemap.html            ← Site Map (ทุกหน้า)
├── storefront.html         ← Alternative Storefront
│
├── ── TECH DOCS ──
├── api-docs.html           ← REST API Reference
├── microservices-arch.html ← System Architecture
└── database-schema.sql     ← PostgreSQL Schema
```

---

## ⚡ ขั้นตอนถัดไป — Production Backend

เมื่อต้องการทำให้เป็นระบบจริง:

### Phase 1: Backend API (เดือน 1-2)
```
Framework:  NestJS (Node.js) หรือ FastAPI (Python)
Database:   PostgreSQL (ดู database-schema.sql)
Cache:      Redis
Auth:       JWT + Refresh Token
File:       AWS S3 / Cloudflare R2
```

### Phase 2: Integration (เดือน 2-3)
```
Payment:    Omise (omise.co) หรือ 2C2P
Logistics:  Kerry API + Flash Express API
Notify:     Firebase FCM + LINE Messaging API
Search:     Elasticsearch หรือ Algolia
```

### Phase 3: Scale (เดือน 3-6)
```
CDN:        Cloudflare (รูปภาพ + Cache)
Infra:      AWS Bangkok Region (ap-southeast-1)
Container:  Docker + Kubernetes
Monitor:    Datadog / New Relic
```

### ราคาประมาณ (Hosting เริ่มต้น):
| แพลตฟอร์ม | ราคา | เหมาะกับ |
|-----------|------|---------|
| Netlify Free | ฟรี | Demo / Prototype |
| Vercel Pro | $20/เดือน | Production frontend |
| AWS EC2 t3.medium | ~$30/เดือน | Backend API |
| RDS PostgreSQL | ~$25/เดือน | Database |
| **รวมเริ่มต้น** | **~$55/เดือน** | MVP ที่ใช้งานได้จริง |

---

## 🔧 Tech Stack ที่แนะนำ (Full Production)

```
Frontend:   Next.js 14 + TypeScript + Tailwind CSS
Backend:    NestJS + PostgreSQL + Redis + Elasticsearch  
Mobile:     React Native (iOS + Android)
Payment:    Omise + 2C2P + PromptPay QR
Logistics:  Kerry + Flash Express + J&T API
Auth:       NextAuth.js + LINE Login + Google OAuth
CDN:        Cloudflare + AWS CloudFront
Deploy:     AWS ECS + RDS + ElastiCache
```

---

## ✅ Checklist ก่อน Launch

- [ ] ทดสอบทุก flow บน Mobile (Chrome DevTools)
- [ ] เชื่อมต่อ Payment Gateway จริง (Omise sandbox)
- [ ] ตั้งค่า Google Analytics / Mixpanel
- [ ] ตั้งค่า Facebook Pixel
- [ ] SSL Certificate (อัตโนมัติกับ Netlify/Vercel)
- [ ] Favicon + Apple Touch Icon
- [ ] robots.txt + sitemap.xml
- [ ] Open Graph Meta Tags (Social sharing)
- [ ] ทดสอบ PageSpeed Insights > 80
- [ ] เชื่อมต่อ LINE OA สำหรับ notification

---

*สร้างโดย Thailand Market Team · 2026 · 54 pages ready to deploy*
