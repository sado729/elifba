# Android Signing Key

Bu qovluqda Android app-in imzalanması üçün keystore faylı saxlanmalıdır.

## Setup:
1. `elifba.jks` faylını bu qovluğa əlavə edin
2. Environment variables təyin edin:
   - `STORE_PASSWORD`: keystore parolunuz
   - `KEY_PASSWORD`: key parolunuz

## Əgər keystore yoxdursa:
```bash
keytool -genkey -v -keystore elifba.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mrsadiq
```
