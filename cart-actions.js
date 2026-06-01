/* ============================================================================
 *  cart-actions.js — จัดการปุ่ม "เพิ่มลงตะกร้า / ซื้อเลย" แบบปลอดภัย (กัน XSS)
 *
 *  แทนการฝังชื่อสินค้าเป็น JS string ใน onclick (`quickAddCart('${name}',...)`)
 *  ซึ่งเปิดช่อง XSS เมื่อชื่อมี ' หรือ " ให้ใช้ data-* attribute แทน:
 *
 *    <button data-act="cart" data-id="..." data-name="..."
 *            data-price="..." data-img="...">เพิ่มลงตะกร้า</button>
 *    <button data-act="buy"  data-id="..." data-name="..."
 *            data-price="...">ซื้อเลย</button>
 *
 *  ค่าใน dataset เป็นสตริงล้วน ไม่เคยถูก eval → ฝัง markup แล้วไม่ทำงาน
 *
 *  ใช้ capture phase เพื่อให้ทำงานก่อน onclick ของการ์ด (openProduct) แล้ว
 *  stopPropagation กันไม่ให้การ์ดนำทางเมื่อกดปุ่ม
 *  เรียกฟังก์ชัน cart เดิมของแต่ละหน้า: quickAddCart / addCart / addToCart
 * ==========================================================================*/
(function () {
  'use strict';
  function handler(e) {
    var btn = e.target.closest && e.target.closest('[data-act="cart"],[data-act="buy"]');
    if (!btn) return;
    e.stopPropagation();
    var id    = btn.dataset.id || '';
    var name  = btn.dataset.name || '';
    var price = Number(btn.dataset.price || 0);
    var img   = btn.dataset.img || '';
    var add = window.quickAddCart || window.addCart || window.addToCart;
    if (typeof add !== 'function') { try { console.warn('[cart-actions] no cart function on page'); } catch (x) {} return; }
    if (btn.getAttribute('data-act') === 'buy') {
      add(id, name, price, '');
      location.href = 'checkout.html';
    } else {
      add(id, name, price, img);
    }
  }
  document.addEventListener('click', handler, true);
})();
