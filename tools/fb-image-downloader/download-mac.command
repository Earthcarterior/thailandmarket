#!/bin/bash
# ดับเบิลคลิกไฟล์นี้เพื่อดึงรูปจากโพสต์ Facebook
# ครั้งแรกถ้าเปิดไม่ได้ ให้คลิกขวา > Open แล้วกด Open อีกที

cd "$(dirname "$0")" || exit 1

echo "=================================================="
echo "   ดึงรูปจากโพสต์ Facebook ลงคอม"
echo "=================================================="
echo

if command -v python3 >/dev/null 2>&1; then
    PY=python3
elif command -v python >/dev/null 2>&1; then
    PY=python
else
    echo "[!] ไม่พบ Python บนเครื่องนี้"
    echo
    echo "    ติดตั้งก่อนที่ https://www.python.org/downloads/"
    echo "    หรือเปิด Terminal แล้วพิมพ์:  brew install python3"
    echo
    read -r -p "กด Enter เพื่อปิด"
    exit 1
fi

echo "เลือกวิธี:"
echo
echo "  [1] เซฟหน้าเว็บไว้แล้ว  (ลากไฟล์ .html มาวาง - ไม่ต้องล็อกอิน)"
echo "  [2] ใส่ลิงก์โพสต์       (ต้องมี gallery-dl + ล็อกอินในเบราว์เซอร์)"
echo
read -r -p "พิมพ์ 1 หรือ 2 แล้วกด Enter: " MODE
echo

# ลากไฟล์มาวางใน Terminal จะได้ path ที่ escape ช่องว่างไว้ ต้องแกะออกก่อน
unescape() {
    printf '%s' "$1" | sed -e "s/^['\"]//" -e "s/['\"]$//" -e 's/\\ / /g'
}

case "$MODE" in
    1)
        echo "วิธีเซฟหน้าเว็บ: เปิดโพสต์ใน Chrome > เลื่อนลงจนสุด > Cmd+S > เลือก \"Webpage, Complete\""
        echo
        read -r -p "ลากไฟล์ .html มาวางตรงนี้ แล้วกด Enter: " RAW
        TARGET="$(unescape "$RAW")"
        [ -z "$TARGET" ] && { echo; echo "[!] ไม่ได้ใส่อะไรมา ยกเลิก"; read -r -p "กด Enter เพื่อปิด"; exit 1; }
        echo
        "$PY" fb_images.py --from-html "$TARGET" -o fb-images
        ;;
    2)
        read -r -p "วางลิงก์โพสต์ Facebook แล้วกด Enter: " RAW
        TARGET="$(unescape "$RAW")"
        [ -z "$TARGET" ] && { echo; echo "[!] ไม่ได้ใส่อะไรมา ยกเลิก"; read -r -p "กด Enter เพื่อปิด"; exit 1; }
        echo
        read -r -p "ใช้เบราว์เซอร์อะไรอยู่ (chrome / firefox / safari / edge / brave): " BROWSER
        [ -z "$BROWSER" ] && BROWSER=chrome
        echo
        echo "กำลังตรวจสอบ gallery-dl..."
        "$PY" -m pip install --quiet --upgrade gallery-dl 2>/dev/null
        echo
        "$PY" fb_images.py "$TARGET" --browser "$BROWSER" -o fb-images
        ;;
    *)
        echo "[!] ต้องพิมพ์ 1 หรือ 2 เท่านั้น"
        read -r -p "กด Enter เพื่อปิด"
        exit 1
        ;;
esac

echo
echo "=================================================="
if [ -d fb-images ] && [ -n "$(ls -A fb-images 2>/dev/null)" ]; then
    echo " เสร็จแล้ว - รูปอยู่ในโฟลเดอร์ fb-images"
    echo "=================================================="
    open fb-images
else
    echo " ไม่ได้รูปเลย - ลองอ่าน README.md ส่วน \"ปัญหาที่เจอบ่อย\""
    echo "=================================================="
fi
echo
read -r -p "กด Enter เพื่อปิด"
