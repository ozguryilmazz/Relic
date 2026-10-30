# Relic

Türk mitolojisi temalı mobil kule savunma + tıklama oyunu. Godot 4.5.1, yatay ekran, Android.

## Oynanış özeti

- Sağdaki düşman kalesinden 100 dalga asker gelir; oyuncu sadece savunur.
- Kaynaklar yol kenarındaki bölgelere dokunarak toplanır (en fazla 2 parmak):
  orman → odun, kayalık → taş, çalılık → diken (%60) / şifa (%40), çöl → kemik.
- Düşman önce **diken bölgesinden**, sonra **barikattan** geçer, en son **kaleye** ulaşır.
  - Diken bölgesi, barikat ve kaleye dokununca kaynak eklemek için mini pencere açılır.
  - Barikat hasar vermez; düşmanı diken bölgesinin içinde tutar.
  - Kaleye ulaşan düşman kalan canı kadar vurur ve yok olur.
- Öldürülen her düşman **korku** puanı verir; korkuyla köle alınır, köleler otomatik toplar.
- Bekleyen ultiye dokunmak **şifalı bitki** yedirir ve kalan süreyi kısaltır.

Bütün denge sayıları `scripts/balance.gd` içinde.

## Klasörler

| Yol | İçerik |
|---|---|
| `scripts/balance.gd` | Oyun matematiği ve kahraman tanımları |
| `scripts/game.gd` | Harita, dalgalar, düşmanlar, ultiler |
| `scripts/hud.gd` | Oyun içi arayüz |
| `scripts/menu.gd` | Ana menü, kahraman kartları, skor tablosu |
| `scripts/firebase.gd` | Sürüm kontrolü ve skorlar (Realtime Database REST) |
| `firebase/database.rules.json` | Realtime Database kuralları |
| `tools/sim_test.tscn` | Otomatik oyuncuyla denge testi |

## Denge testi

```
godot --headless --path . --fixed-fps 60 res://tools/sim_test.tscn -- 5 0
```
İlk sayı saniyedeki tık, ikincisi kahraman (0 Tepegöz, 1 Şahmeran, 2 Alkarası).

## Derleme

`main` dalına her push'ta GitHub Actions APK derler, Release oluşturur ve
(secret tanımlıysa) son sürüm bilgisini Firebase'e yazar. Gerekli secret'lar:

| Secret | Açıklama |
|---|---|
| `KEYSTORE_BASE64` | İmza anahtarının base64 hali |
| `KEYSTORE_PASSWORD` | Anahtar şifresi |
| `KEYSTORE_ALIAS` | Anahtar adı |
| `FIREBASE_DB_SECRET` | Realtime Database secret'ı (sürüm bilgisini yazmak için) |
