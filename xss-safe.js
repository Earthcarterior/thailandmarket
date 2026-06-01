/* ============================================================================
 *  xss-safe.js — ตัว escape HTML กลางสำหรับกัน stored XSS
 *
 *  ใส่ใน <head> ก่อนสคริปต์อื่นที่ render ข้อมูล:
 *      <script src="xss-safe.js"></script>
 *
 *  ใช้ครอบทุกค่าที่มาจากผู้ใช้/seller ก่อนยัดลง innerHTML / template literal:
 *      el.innerHTML = `<div>${esc(product.name_th)}</div>`;
 *
 *  มี alias esc / escQ / escHtml / escapeHtml ให้ตรงกับชื่อที่หน้าเดิมใช้อยู่
 *  (จะไม่ทับของเดิมถ้าหน้านั้นนิยามฟังก์ชันชื่อเดียวกันไว้ก่อนแล้ว)
 * ==========================================================================*/
(function (g) {
  'use strict';
  function esc(v) {
    if (v === null || v === undefined) return '';
    return String(v)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
  g.esc = esc;
  if (typeof g.escQ        !== 'function') g.escQ        = esc;
  if (typeof g.escHtml     !== 'function') g.escHtml     = esc;
  if (typeof g.escapeHtml  !== 'function') g.escapeHtml  = esc;
})(window);
