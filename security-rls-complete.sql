-- ============================================================================
--  SECURITY / RLS — COMPLETE HARDENING (thailandmarket)
--  รันใน Supabase → SQL Editor (รันซ้ำได้ ปลอดภัย / idempotent)
--
--  ไฟล์นี้ครอบ "ส่วนที่ขาด" ทั้งหมดต่อจาก security-rls-fix.sql:
--  ฐานข้อมูลยังมี policy `FOR ALL TO authenticated USING(true)` หลงเหลือบนหลาย
--  ตาราง (auth_all_users, auth_all_sellers, auth_all_coupons, auth_all_banners,
--  auth_all_categories, auth_all_products, ฯลฯ) + นโยบายอ่าน orders/order_items
--  แบบ USING(true) ทั้งหมดนี้เปิดช่องให้ผู้ใช้ล็อกอินคนใดก็ได้:
--    • ยกระดับตัวเองเป็น admin / แก้ผู้ใช้คนอื่น (auth_all_users)
--    • แก้ร้าน/สินค้า/คูปอง/แบนเนอร์ ของคนอื่น
--    • อ่านออเดอร์ + ที่อยู่ของลูกค้าทุกคน
--
--  กลยุทธ์: ลบ policy เดิมทั้งหมดบนตารางที่เกี่ยวข้อง (กันชื่อซ้ำ/ไม่รู้จากหลายไฟล์)
--  แล้วสร้างชุด policy มาตรฐานที่ scope ถูกต้อง
--
--  ownership: users.id = auth.uid(); sellers/orders/addresses/notifications/
--  wishlist.user_id → users.id ; products.created_by → users.id ;
--  order_items.order_id → orders ; product_variants.product_id → products
-- ============================================================================

-- ── Helper functions (SECURITY DEFINER → bypass RLS, กัน recursion) ──────────
CREATE OR REPLACE FUNCTION public.current_user_role()
  RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT role FROM public.users WHERE id = auth.uid(); $$;

CREATE OR REPLACE FUNCTION public.is_admin()
  RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT COALESCE(public.current_user_role() = 'admin', false); $$;

CREATE OR REPLACE FUNCTION public.is_seller_or_admin()
  RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT COALESCE(public.current_user_role() IN ('seller','admin'), false); $$;

-- ── ลบ policy เดิมทั้งหมดบนตารางเป้าหมาย (idempotent, ไม่สนชื่อ) ─────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('users','sellers','products','product_variants',
        'categories','brands','banners','coupons','flash_sale_events',
        'site_settings','orders','order_items','reviews','wishlist',
        'addresses','notifications')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I',
                   r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- เปิด RLS ให้ครบ
ALTER TABLE public.users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sellers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flash_sale_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications    ENABLE ROW LEVEL SECURITY;

-- ════════════════════════════════════════════════════════════════════════════
--  USERS — อ่าน/แก้เฉพาะของตัวเอง, admin จัดการทั้งหมด, กันยกระดับ role
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY users_select_self ON public.users FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_admin());
CREATE POLICY users_insert_self ON public.users FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());
CREATE POLICY users_update_self ON public.users FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY users_admin_all ON public.users FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE OR REPLACE FUNCTION public.prevent_privilege_escalation()
  RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF public.is_admin() THEN RETURN NEW; END IF;
  IF NEW.role        IS DISTINCT FROM OLD.role        THEN RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน role ด้วยตัวเอง'; END IF;
  IF NEW.is_active   IS DISTINCT FROM OLD.is_active   THEN RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน is_active ด้วยตัวเอง'; END IF;
  IF NEW.seller_id   IS DISTINCT FROM OLD.seller_id   THEN RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน seller_id ด้วยตัวเอง'; END IF;
  IF NEW.loyalty_pts IS DISTINCT FROM OLD.loyalty_pts THEN RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน loyalty_pts ด้วยตัวเอง'; END IF;
  RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS trg_prevent_priv_esc ON public.users;
CREATE TRIGGER trg_prevent_priv_esc BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.prevent_privilege_escalation();

-- ════════════════════════════════════════════════════════════════════════════
--  SELLERS — สาธารณะอ่านร้าน active, เจ้าของจัดการร้านตัวเอง, admin ทั้งหมด
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY sellers_public_read ON public.sellers FOR SELECT
  USING (status = 'active' OR user_id = auth.uid() OR public.is_admin());
CREATE POLICY sellers_insert_own ON public.sellers FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
CREATE POLICY sellers_update_own ON public.sellers FOR UPDATE TO authenticated
  USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY sellers_admin_all ON public.sellers FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ════════════════════════════════════════════════════════════════════════════
--  PRODUCTS — สาธารณะอ่าน active, seller ลง/แก้ของตัวเอง, admin ทั้งหมด
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY products_public_read ON public.products FOR SELECT
  USING (status = 'active' OR created_by = auth.uid() OR public.is_admin());
CREATE POLICY products_seller_insert ON public.products FOR INSERT TO authenticated
  WITH CHECK (public.is_seller_or_admin() AND (created_by = auth.uid() OR created_by IS NULL));
CREATE POLICY products_seller_update ON public.products FOR UPDATE TO authenticated
  USING (created_by = auth.uid() OR public.is_admin())
  WITH CHECK (created_by = auth.uid() OR public.is_admin());
CREATE POLICY products_admin_all ON public.products FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ── product_variants — อ่านสาธารณะ, เขียนโดยเจ้าของสินค้า/admin ──────────────
CREATE POLICY variants_public_read ON public.product_variants FOR SELECT USING (true);
CREATE POLICY variants_owner_write ON public.product_variants FOR ALL TO authenticated
  USING (public.is_admin() OR EXISTS (
    SELECT 1 FROM public.products p WHERE p.id = product_variants.product_id AND p.created_by = auth.uid()))
  WITH CHECK (public.is_admin() OR EXISTS (
    SELECT 1 FROM public.products p WHERE p.id = product_variants.product_id AND p.created_by = auth.uid()));

-- ════════════════════════════════════════════════════════════════════════════
--  CATALOG ที่ admin จัดการ — อ่านสาธารณะ, เขียนเฉพาะ admin
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY categories_public_read ON public.categories FOR SELECT USING (is_active = true OR public.is_admin());
CREATE POLICY categories_admin_all   ON public.categories FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY brands_public_read ON public.brands FOR SELECT USING (is_active = true OR public.is_admin());
CREATE POLICY brands_admin_all   ON public.brands FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY banners_public_read ON public.banners FOR SELECT USING (is_active = true OR public.is_admin());
CREATE POLICY banners_admin_all   ON public.banners FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY coupons_public_read ON public.coupons FOR SELECT USING (is_active = true OR public.is_admin());
CREATE POLICY coupons_admin_all   ON public.coupons FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY flash_public_read ON public.flash_sale_events FOR SELECT USING (is_active = true OR public.is_admin());
CREATE POLICY flash_admin_all   ON public.flash_sale_events FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY settings_public_read ON public.site_settings FOR SELECT USING (true);
CREATE POLICY settings_admin_all   ON public.site_settings FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ════════════════════════════════════════════════════════════════════════════
--  ORDERS — เจ้าของ + seller ที่มีสินค้าในออเดอร์ + admin
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY orders_select ON public.orders FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_admin()
    OR EXISTS (SELECT 1 FROM public.order_items oi
               JOIN public.products p ON p.id = oi.product_id
               WHERE oi.order_id = orders.id AND p.created_by = auth.uid())
  );
CREATE POLICY orders_insert_own ON public.orders FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() OR public.is_admin());
CREATE POLICY orders_update ON public.orders FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_admin()
    OR EXISTS (SELECT 1 FROM public.order_items oi
               JOIN public.products p ON p.id = oi.product_id
               WHERE oi.order_id = orders.id AND p.created_by = auth.uid())
  );

-- ── order_items — ผูกกับสิทธิ์ของ orders ─────────────────────────────────────
CREATE POLICY oi_select ON public.order_items FOR SELECT TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_items.order_id AND o.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.products p WHERE p.id = order_items.product_id AND p.created_by = auth.uid())
  );
CREATE POLICY oi_insert ON public.order_items FOR INSERT TO authenticated
  WITH CHECK (
    public.is_admin()
    OR EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_items.order_id AND o.user_id = auth.uid())
  );

-- ════════════════════════════════════════════════════════════════════════════
--  REVIEWS — อ่านสาธารณะ, เขียน/แก้/ลบ เฉพาะของตัวเอง, admin ทั้งหมด
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY reviews_public_read ON public.reviews FOR SELECT USING (true);
CREATE POLICY reviews_insert_own ON public.reviews FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());
CREATE POLICY reviews_update_own ON public.reviews FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY reviews_delete_own ON public.reviews FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY reviews_admin_all ON public.reviews FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ════════════════════════════════════════════════════════════════════════════
--  ข้อมูลส่วนตัว — เฉพาะเจ้าของ (admin อ่านได้)
-- ════════════════════════════════════════════════════════════════════════════
CREATE POLICY wishlist_own ON public.wishlist FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY addresses_own ON public.addresses FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY notifications_select_own ON public.notifications FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());
CREATE POLICY notifications_update_own ON public.notifications FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY notifications_admin_all ON public.notifications FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());
