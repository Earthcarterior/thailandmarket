-- ============================================================================
--  SECURITY / RLS HARDENING — thailandmarket
--  รันไฟล์นี้ใน Supabase → SQL Editor (รันซ้ำได้ ปลอดภัย / idempotent)
--
--  แก้ช่องโหว่:
--   1. [CRITICAL] auth_manage_users FOR ALL USING(true)
--        → ผู้ใช้ล็อกอินคนใดก็ได้สามารถยกระดับตัวเองเป็น admin / อ่าน-แก้-ลบ
--          ข้อมูลผู้ใช้ทุกคนได้ผ่าน anon key
--   2. [MEDIUM] auth_insert_products WITH CHECK(true)  → ใครก็ลงสินค้าได้
--   3. [MEDIUM] auth_insert_reviews  WITH CHECK(true)  → รีวิวปลอมในชื่อคนอื่นได้
--
--  อ้างอิง schema: users.id = auth.uid(), reviews.user_id → users.id,
--                  products.created_by → users.id
-- ============================================================================

-- ── Helper functions ────────────────────────────────────────────────────────
-- SECURITY DEFINER เพื่ออ่าน role ของตัวเองโดยไม่ trigger RLS ซ้ำ (กัน recursion)
CREATE OR REPLACE FUNCTION public.current_user_role()
  RETURNS TEXT
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
  RETURNS BOOLEAN
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT COALESCE(public.current_user_role() = 'admin', false);
$$;

-- ── USERS : ปิดช่องโหว่ privilege escalation ────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS auth_manage_users     ON public.users;
DROP POLICY IF EXISTS users_select_self      ON public.users;
DROP POLICY IF EXISTS users_insert_self      ON public.users;
DROP POLICY IF EXISTS users_update_self      ON public.users;
DROP POLICY IF EXISTS users_admin_all        ON public.users;

-- อ่านได้เฉพาะแถวของตัวเอง (admin อ่านได้ทุกแถว)
CREATE POLICY users_select_self ON public.users
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_admin());

-- สมัครสมาชิก: เพิ่มได้เฉพาะแถวที่ id = auth uid ของตัวเอง
CREATE POLICY users_insert_self ON public.users
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- แก้ไขได้เฉพาะแถวของตัวเอง (การเปลี่ยน role/สิทธิ์ ถูกบล็อกด้วย trigger ด้านล่าง)
CREATE POLICY users_update_self ON public.users
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- admin จัดการได้ทุกแถว ทุก operation
CREATE POLICY users_admin_all ON public.users
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- กันไม่ให้ผู้ใช้ทั่วไปแก้คอลัมน์ที่เป็นสิทธิ์ของตัวเอง (role, is_active, seller_id, loyalty_pts)
CREATE OR REPLACE FUNCTION public.prevent_privilege_escalation()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  -- admin แก้ได้ทุกอย่าง
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;
  IF NEW.role        IS DISTINCT FROM OLD.role        THEN
    RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน role ด้วยตัวเอง';
  END IF;
  IF NEW.is_active   IS DISTINCT FROM OLD.is_active   THEN
    RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน is_active ด้วยตัวเอง';
  END IF;
  IF NEW.seller_id   IS DISTINCT FROM OLD.seller_id   THEN
    RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน seller_id ด้วยตัวเอง';
  END IF;
  IF NEW.loyalty_pts IS DISTINCT FROM OLD.loyalty_pts THEN
    RAISE EXCEPTION 'ไม่อนุญาตให้เปลี่ยน loyalty_pts ด้วยตัวเอง';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_priv_esc ON public.users;
CREATE TRIGGER trg_prevent_priv_esc
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.prevent_privilege_escalation();

-- ── PRODUCTS : เฉพาะ seller/admin เท่านั้นที่ลงสินค้าได้ ─────────────────────
DROP POLICY IF EXISTS auth_insert_products    ON public.products;
DROP POLICY IF EXISTS sellers_insert_products ON public.products;

CREATE POLICY sellers_insert_products ON public.products
  FOR INSERT TO authenticated
  WITH CHECK (
    public.current_user_role() IN ('seller','admin')
    AND (created_by = auth.uid() OR created_by IS NULL)
  );

-- ── REVIEWS : เขียนรีวิวได้เฉพาะในชื่อตัวเอง ─────────────────────────────────
DROP POLICY IF EXISTS auth_insert_reviews     ON public.reviews;
DROP POLICY IF EXISTS auth_insert_own_reviews ON public.reviews;

CREATE POLICY auth_insert_own_reviews ON public.reviews
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- หมายเหตุ: การยืนยันว่า "ซื้อสินค้าจริงก่อนรีวิว" ควรบังคับเพิ่มด้วยการเช็ค
-- order_id ที่เป็นของ user คนนั้น (เปิดใช้เมื่อพร้อม):
-- WITH CHECK (
--   user_id = auth.uid()
--   AND order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
-- );
