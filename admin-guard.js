/* ============================================================================
 *  admin-guard.js — ตรวจสิทธิ์ก่อนเข้าหน้า admin / seller
 *
 *  ใส่ใน <head> ของหน้าที่ต้องป้องกัน:
 *      <script src="admin-guard.js"></script>
 *
 *  ค่าเริ่มต้นอนุญาตเฉพาะ role = 'admin'
 *  หน้าที่ seller ใช้ร่วม (เช่น admin-cms.html) ให้ตั้งค่าก่อนโหลดสคริปต์นี้:
 *      <script>window.GUARD_ROLES = ['admin','seller'];</script>
 *      <script src="admin-guard.js"></script>
 *
 *  หมายเหตุสำคัญ: นี่คือการป้องกันฝั่ง client (defense-in-depth / กัน UI หลุด)
 *  ความปลอดภัยจริงต้องพึ่ง RLS ใน Supabase (ดู security-rls-fix.sql) เสมอ
 *  เพราะค่าใน localStorage ปลอมได้ — guard นี้จึงตรวจจาก session จริงของ Supabase
 * ==========================================================================*/
(function () {
  'use strict';

  var SB_URL = 'https://qmgyimsptzewwyafvjzk.supabase.co';
  var SB_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtZ3lpbXNwdHpld3d5YWZ2anprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NjA4NDIsImV4cCI6MjA5MzAzNjg0Mn0.pcexjwmQndb_RhZHfKVZ6m2_21sn09iNAMyESjLOVJ0';
  var CDN    = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js';

  var allowed = (window.GUARD_ROLES && window.GUARD_ROLES.length) ? window.GUARD_ROLES : ['admin'];

  function deny(reason) {
    try { console.warn('[admin-guard] access denied:', reason); } catch (e) {}
    var here = location.pathname.split('/').pop() || '';
    location.replace('login.html?next=' + encodeURIComponent(here));
  }

  function check(client) {
    client.auth.getSession().then(function (res) {
      var session = res && res.data && res.data.session;
      if (!session || !session.user) { deny('no session'); return; }
      client.from('users').select('role').eq('id', session.user.id).single()
        .then(function (r) {
          var role = r && r.data && r.data.role;
          if (allowed.indexOf(role) === -1) { deny('role=' + role); }
        })
        .catch(function (e) { deny('role lookup failed'); });
    }).catch(function (e) { deny('session lookup failed'); });
  }

  function boot() {
    if (window.supabase && window.supabase.createClient) {
      check(window.supabase.createClient(SB_URL, SB_KEY));
      return;
    }
    var s = document.createElement('script');
    s.src = CDN;
    s.onload = function () {
      if (window.supabase && window.supabase.createClient) {
        check(window.supabase.createClient(SB_URL, SB_KEY));
      } else { deny('supabase-js failed to load'); }
    };
    s.onerror = function () { deny('cannot load supabase-js'); };
    document.head.appendChild(s);
  }

  boot();
})();
