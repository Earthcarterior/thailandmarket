@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ==================================================
echo    ดึงรูปจากโพสต์ Facebook ลงคอม
echo ==================================================
echo.

set PY=python
where python >nul 2>nul
if not errorlevel 1 goto GOTPY
set PY=py
where py >nul 2>nul
if not errorlevel 1 goto GOTPY

echo [!] ไม่พบ Python บนเครื่องนี้
echo.
echo     ติดตั้งก่อนที่ https://www.python.org/downloads/
echo     ตอนติดตั้ง ให้ติ๊กช่อง "Add Python to PATH" ด้วย
echo     ติดตั้งเสร็จแล้วปิดหน้าต่างนี้ แล้วเปิดไฟล์นี้ใหม่
echo.
pause
exit /b 1

:GOTPY
echo เลือกวิธี:
echo.
echo   [1] เซฟหน้าเว็บไว้แล้ว  (ลากไฟล์ .html มาวาง - ไม่ต้องล็อกอิน)
echo   [2] ใส่ลิงก์โพสต์       (ต้องมี gallery-dl + ล็อกอินในเบราว์เซอร์)
echo.
set /p MODE=พิมพ์ 1 หรือ 2 แล้วกด Enter:

if "%MODE%"=="1" goto FROMHTML
if "%MODE%"=="2" goto FROMURL
echo.
echo [!] ต้องพิมพ์ 1 หรือ 2 เท่านั้น
echo.
pause
exit /b 1

:FROMHTML
echo.
echo วิธีเซฟหน้าเว็บ: เปิดโพสต์ใน Chrome ^> เลื่อนลงจนสุด ^> Ctrl+S ^> เลือก "Webpage, Complete"
echo.
set /p TARGET=ลากไฟล์ .html มาวางตรงนี้ แล้วกด Enter:
if "%TARGET%"=="" goto NOINPUT
echo.
%PY% fb_images.py --from-html %TARGET% -o fb-images
goto DONE

:FROMURL
echo.
set /p TARGET=วางลิงก์โพสต์ Facebook แล้วกด Enter:
if "%TARGET%"=="" goto NOINPUT
echo.
set /p BROWSER=ใช้เบราว์เซอร์อะไรอยู่ (chrome / firefox / edge / brave):
if "%BROWSER%"=="" set BROWSER=chrome
echo.
echo กำลังตรวจสอบ gallery-dl...
%PY% -m pip install --quiet --upgrade gallery-dl
echo.
%PY% fb_images.py %TARGET% --browser %BROWSER% -o fb-images
goto DONE

:NOINPUT
echo.
echo [!] ไม่ได้ใส่อะไรมา ยกเลิก
echo.
pause
exit /b 1

:DONE
echo.
echo ==================================================
rem fb-images ถูกสร้างเสมอแม้ไม่ได้รูป จึงต้องเช็คว่ามีไฟล์ข้างในจริง
dir /b fb-images 2>nul | findstr . >nul
if errorlevel 1 (
  echo  ไม่ได้รูปเลย - ลองอ่าน README.md ส่วน "ปัญหาที่เจอบ่อย"
  echo ==================================================
) else (
  echo  เสร็จแล้ว - รูปอยู่ในโฟลเดอร์ fb-images
  echo ==================================================
  start "" "fb-images"
)
echo.
pause
