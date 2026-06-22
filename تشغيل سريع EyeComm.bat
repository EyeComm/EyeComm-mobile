@echo off
title EyeComm - تشغيل سريع
color 0A
echo ========================================
echo     ⚡ تشغيل EyeComm (سريع)
echo ========================================
echo.
echo 🔥 جاري تشغيل السيرفر...
cd /d "C:\Users\Amir\Desktop\EYE AMIR\EyeComm_Complete"
start "EyeComm Server" cmd /k "python server.py"

echo.
echo ⏳ انتظر 2 ثانية...
timeout /t 2 /nobreak > nul

echo.
echo 📱 جاري تشغيل التطبيق...
start "" "C:\Users\Amir\Desktop\EYE AMIR\EyeComm_Complete\build\windows\x64\runner\Release\ers.exe"

echo.
echo ✅ تم التشغيل!
pause