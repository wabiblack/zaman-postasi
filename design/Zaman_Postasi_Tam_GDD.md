# Zaman Postası | Tam Oyun Tasarım Dokümanı

**Sürüm:** 1.0 · **Platform:** iOS / Android · **Ekran:** dikey, tek elle · **Motor:** Godot 4.x · **Oyun süresi hedefi:** 3–5 saat · **Çevrimdışı**

## 1. Oyun fikri ve vizyon

2026 yılında kayıp bir Anadolu kasabası olan **İğdeyaka**'nın yıkıntıları arasında bulunan eski posta kutusu, 1925–1929 yıllarına mektup gönderir. Oyuncu felaketlerin sebeplerini araştırıp geçmişte yaşayan insanlara seçilmiş cümle parçalarından oluşan mektuplar yollar. Gelecek haritası her gönderimin ardından değişir. **Bir felaketi önlemek başka bir kayba yol açabilir.** Oyunun özü; delil bul, çıkarım yap, sınırlı pulla müdahale et, beklenmedik sonucu incele ve yeni karar ver döngüsüdür.

**Tasarım ilkeleri:** Her mektup görünür iz bırakır; olumlu sonuçların anlaşılır bir bedeli olabilir; kararlar rastgele değil deterministik sonuç verir; sistem küçük ekibin üretebileceği katmanlı 2D görüntüler kullanır.

## 2. Hikâye, mekân ve zaman kuralları

İğdeyaka'da fırın, değirmen, telgraf binası, taş köprü, menfez, kuyu, okul arsası, mezarlık ve istasyon yolu bulunur. 1925 yangınında canlar ve kayıtlar kaybedilir. 1926 selinde eski altyapı çöker. 1927 salgınında kirli su ve sağlık altyapısı etkili olur. 1928'de değirmen borç ve üretim kayıpları nedeniyle kapanma noktasına gelir. 1929'da aileler göç eder; kasaba adı idari kayıtlardan silinir. Ana gizem bir kötüyü bulmak değil, **felaketler zincirinin kökünü anlamaktır.**

Oyuncu geçmişe gitmez. Posta kutusu yalnız beş sabit tarih penceresine çalışır. Bir bölümde her alıcıya bir kez mektup gider. O bölümdeki mektupların etkileri toplu hesaplanır; gönderim sırası nihai tarihi değiştirmez. Araştırma defteri ve posta kutusu değişen tarihten etkilenmez. Geçmiş bölümü değiştirmek sonraki bölüm seçimlerinin tekrar oynanmasını gerektirir.

## 3. Oynanış döngüsü

1. 2026 haritasındaki ipucu noktalarına dokun: yıkık fırın, mezar, gazete, köprü, telgraf penceresi.
2. Otomatik araştırma defterindeki bağlantıları gör. Bulunmamış ipuçları için kademeli rehber al.
3. Alt çekmecede **Kime? / Ne hakkında? / Ne yapsın?** alanlarını doldur. Sistem yalnızca anlamlı, önceden yazılmış cümle kombinasyonlarını açar.
4. Bir pul kullanarak gönder. Kâğıt, pul ve posta kutusu animasyonu 1–2 saniye sürer.
5. Haritada yerel çizim katmanları değişir; değişim kısa vurgulanır. Zaman çizelgesine kanıtlanmış sebep–sonuç kartları eklenir.
6. Alıcıdan yanıt gelebilir. Şüphe ve söylenti değişebilir. Kalan pullarla devam et ya da bölümü kapat.

**Kullanılabilirlik:** 720×1280 sanal tasarım; güvenli alanlar; 44pt/48dp civarı dokunma alanları; alt yüzde 60'ta temel kontroller; büyük metin seçeneği; hareket azaltma; yalnız renge bağlı bildirim yok; klavye ve iki parmak hareketi gerekmez.

## 4. Ekranlar

**Ana harita:** Sabit sepya 2D mekân ve yaklaşık 10 dokunulabilir nokta. Üstte bölüm ve pul sayacı, altta İpucu / Mektup / Zaman / Defter menüsü.

**Mektup kurucu:** Alıcı portresi, konu seçimi, öğüt seçimi, tam mektup önizlemesi ve büyük Gönder butonu. Açılmamış önerilerin üzerinde gerekli kanıt yazılıdır.

**Zaman çizelgesi:** Mektup → kısa vadeli olay → güncel harita etkisi. Henüz ispatlanmayan gelecek bağlantıları soru işaretiyle gösterilir.

**Araştırma defteri:** İpucu koleksiyonu, önce/sonra karşılaştırması, kısa karakter biyografileri ve açılan belgeler.

**Bölüm sonu:** Can kayıpları, korunan yapılar, bilinmeyen bedeller ve sonraki bölüme taşınan koşullar. Puan yerine nedensellik özetlenir.

## 5. Temel sistemler

### Kelebek etkisi

Mektuplar sayısal etkiler ve kalıcı durum etiketleri taşır. Örnek: fırını kapatmak yangını hafifletir ama geliri kesip Feride'yi göçe zorlayabilir; kömürü menfeze taşımak yangın riskini azaltır ama gelecek yılki seli ağırlaştırır. Dünya, her olasılık için ayrı tam resim yerine **konum bazlı sprite katmanları** ile çizilir.

### Şüphe

Karakter başına 0–4 şüphe puanı vardır. 0–1 normal, 2 şüpheci, 3–4 yeni mektupları önemsemiyor. Açıklanamaz ölçüde kesin olay bilgisi daha çok şüphe üretir. Şüphe seviyesi yüksek alıcıya gönderimden önce risk uyarısı verilir. Yeni bölüm, ilerleme kilidi oluşmaması için en az iki geçerli alıcı sunar.

### Pul ve kayıt sistemi

Bölüm pulları: B1 3, B2 3, B3 4, B4 3, B5 4. Pul satın alınmaz veya gerçek zamanla yenilenmez. Bölüm başı kontrol noktasına dönülebilir. Otomatik kayıt cihazda yereldir; mektup geçmişinden tüm durum yeniden üretilebilir.

## 6. Beş bölüm

| Bölüm | Tarih | Karakter | Pul | Mektup | Temel çatışma |
|---|---|---:|---:|---:|---|
| Külün Kokusu | 1925 | 4 | 3 | 12 | Yangını küçültmek, fırın ve okulun geleceğini korumak |
| Suyun Yolu | 1926 | 4 | 3 | 12 | Sel tahliyesi, köprü ve kuyunun güvenliği |
| Sessiz Ateş | 1927 | 4 | 4 | 12 | Su kirliliği, salgın, tedavi ve toplumsal güven |
| Çark Durduğunda | 1928 | 5 | 3 | 15 | Değirmenin borcu, işçi güvenliği ve gelir |
| Son Tren | 1929 | 5 | 4 | 15 | İdari kayıtlar, kalma ve güvenli göç |

**B2 karakterleri:** Nermin (telgraf), İhsan (köprü bekçisi), Sabri (su yolu işçisi), Fatma (ebe). Kararlar menfezi açmak, köprüyü kapatmak, haneleri boşaltmak ve kuyuyu korumak arasında çatışır. B1'in menfez ve köprü etkileri bu bölümde görülür.

**B3 karakterleri:** Fatma, Dr. Lütfi, Zeki ve kasabada kalmışsa Feride; Feride gittiyse Mahir. Oyuncu kuyuyu kapatma, ilaç talebi, geçici sağlık bölgesi ve erzak dağıtımı arasında seçim yapar.

**B4 karakterleri:** Cemil, değirmen sahibi Rana, Sabri, Nermin, Hasan ya da vekili Mahir. Üretim, borç, işçilerin güvenliği ve soruşturma çatışır.

**B5 karakterleri:** Muhtar Ali, Nermin, Rana, İhsan, Feride ya da Mahir. Kasabayı kurtarmak için herkesin kalması gerektiği varsayımı sorgulanır. Güvenli göç bile bir erdem olabilir.

## 7. İlk 10 dakika: ayrıntılı örnek akış

| Zaman | Eylem | Öğretilen sistem |
|---|---|---|
| 00:00–00:45 | Soluk İğdeyaka haritası ve eski posta kutusu görünür. | Dokunma ve gizem |
| 00:45–01:45 | 1925 yangınında dört kişi öldüğünü söyleyen gazete bulunur. | İpuçları ve geçmiş |
| 01:45–03:00 | Yıkık fırın, mezarlar ve gaz lambası izi incelenir. | Harita/defter |
| 03:00–04:15 | Hasan'a **H1** mektubu gönderilir: fırını kapat. | Mektup kurma, 3→2 pul |
| 04:15–05:30 | Yangın 5→3'e iner, kayıplar 4→1 olur; fırın kapalı kalır. | Harita değişimi |
| 05:30–06:45 | Feride gelir kaybıyla göç eder, okulun hiç açılmadığı anlaşılır. | Beklenmedik bedel |
| 06:45–08:00 | Nermin'e **N2** gönderilir, kayıtlar korunur. | 2→1 pul, delil |
| 08:00–09:10 | Yeni bakım kaydı açılır; Nermin yanıtında mektuplardan kuşkulandığını yazar. | Yanıt ve şüphe |
| 09:10–10:00 | Oyuncu Feride'ye F1 gönderme kararını değerlendirir. | Son pul ve ahlaki tercih |

Oyuncu F1'i gönderirse H1+N2+F1 sonucunda yangın H=2'ye iner; Feride kalır, okul açılır, fırın kapalı ve 1 yangın kaybı vardır.

## 8. Birinci bölüm karakterleri

| Ad | Motivasyon | Bilgi ve sır | Rol |
|---|---|---|---|
| Hasan Usta, 46 | Geçimini sürdürmek ve kızını korumak | Fırın kapanırsa Feride'nin ayrılması olası | Yangın/fırın |
| Feride, 19 | Çocuklar için okul kurmak | Şehirde sağlık eğitimi şansı var | Okul/gelecek |
| Nermin, 28 | Doğru kayıt tutmak, gerçeği öğrenmek | Teslim defterinde eksik bildirim var | Kanıt/şüphe |
| Cemil Usta, 41 | Değirmeni ve çalışanları korumak | Lambaların bakımına bütçe ayrılmamış | Borç/yangın |

### B1: bütün geçerli mektuplar

| ID | Alıcı | Konu | Tavsiye | ΔH | Sonuç ve bedel |
|---|---|---|---|---:|---|
| H1 | Hasan Usta | Gaz lambası | Ocakları söndür, fırını üç gün kapat. | -2 | Fırın kurtulabilir, gelir kaybı Feride’yi göçe zorlayabilir. |
| H2 | Hasan Usta | Kömür çuvalları | Kömür çuvallarını dere menfezine taşı. | -1 | Yangın riski azalır, menfez tıkanır. |
| H3 | Hasan Usta | Komşuların yardımı | Mahalleliyi kum kovalarıyla nöbete çağır. | -1 | Bir yangın kaybı önlenir, söylenti büyür. |
| F1 | Feride | Fırın gecesi | İki komşuyla gece nöbeti kur. | -1 | Alevler erken görülür, Feride kalır ve şüphelenir. |
| F2 | Feride | Sağlık eğitimi | İstanbul’daki sıhhiye kursuna git. | +0 | Feride gider; okul açılmaz, sağlık bağlantısı kurulur. |
| F3 | Feride | Ders defterleri | Defterleri değirmenin ambarına taşı. | +0 | Okul umudu ve defterler korunur; değirmen aksar. |
| N1 | Nermin | Gece uyarısı | Gece yarısı yangın çanını çal. | +0 | İki ölüm önlenebilir, köprüde izdiham olur. |
| N2 | Nermin | Telgraf kayıtları | Kayıtların kopyasını gizli bir yere sakla. | +0 | Kanıt korunur, söylentiler artar. |
| N3 | Nermin | Geciken telgraf | Acil uyarıyı Cemil Usta’ya ulaştır. | -1 | Yangın azalır, üretim ve gelir kaybı olur. |
| C1 | Cemil Usta | Eski lambalar | Bütün eski lambaları yenileriyle değiştir. | -2 | Alev riski düşer, borç doğar ve eski lamba kaybolur. |
| C2 | Cemil Usta | Kömür deposu | Kömürü menfezin kıyısına boşalt. | -1 | Yangın azalır, menfez tıkanır ve dere kirlenir. |
| C3 | Cemil Usta | Bakım defteri | Eksik imzalı defteri muhtara teslim et. | +0 | İhmal belgelenir, soruşturma üretimi aksatır. |

### B1 kesin hesap kuralları

**Yangın:** `H=max(0, 5 + tüm ΔH toplamı)`. H=0–1 önlendi, H=2–3 kontrol altında, H=4–5 büyük yangın. İlk can kaybı sırasıyla 0, 1 ve 4; H3 varsa 1, N1 varsa 2 azaltılır (alt sınır 0). **Hasan** H<4 veya H3 varsa hayatta kalır. **Feride** F2 varsa gider; ayrıca H1 gönderilmişse veya Hasan ölmüşse F1/F3 koruması yoksa gider. **Okul**, Feride kalıp H<=1 olursa; veya H=2–3 ve F1/F3 varsa açılır. **Fırın** H>=4 ise yıkık, H1 varsa kapalı, H>=2 ise hasarlı, aksi durumda açıktır.

**İleri bölümlere etkiler:** `menfez=H2(1)+C2(2)`, `köprü_baskısı=N1(1)`, `su_kirliliği=C2(1)`, `sağlık_bağlantısı=F2(1)`, `değirmen_borcu=F3+N3+C1+C3`, `söylenti=H3+N2+C3`. N2 veya C3 kanıtı korur; daha düşük yangın ve atılmamış eski lamba da kanıt sağlayabilir.

**İletişim/cevap tonu:** Hasan H1'e “Üç gün ekmek çıkarmazsam bizi kim doyuracak?” diye yazar; F1 gönderildiğinde Feride “O saatte ne olacağını nasıl bildin?” diye sorar; N2 ardından Nermin “Böyle bir şeyi önceden bilmen tuhaf.” der. Yanıtsız mektuplar da bulunur. Cevaplar yeni bilgiye ve şüpheye göre değişebilir.

**Bütün kombinasyonlar:** 0 mektup (1), 1 mektup (12), 2 farklı alıcı (54), 3 farklı alıcı (108): toplam **175** geçerli durum. Test verileri ekte JSON'dur. Oyuncu en az bir mektup gönderdikten sonra bölümü bitirebilir.

## 9. Sonlar

Oyun sonunda `household_retention` 0–100 arası hesaplanır; açık köprü, temiz kuyu, okul ve çalışan değirmen dört kamusal yapıdır.

- **İğdeyaka Yaşıyor:** Tutunma >=70, en az 3 yapı ve resmî kayıt var.
- **Başka Bir İğdeyaka:** Önceki koşul yok, tutunma >=50 ve en az 2 yapı var.
- **İzler Kaldı:** Tutunma >=25; birkaç aile ve hatıra kalır.
- **Silinenler:** Tutunma <25; kasaba ismi silinir ama kişisel kurtuluşlar epilogda görünür.

Her finalde Hasan, Feride, Nermin, işçilerin ve kasabanın kaderiyle ilgili kişisel epilog varyantları eklenir. B2–B5'in tam tutunma ağırlıkları, bölüm verileri yazılırken dengelenir.

## 10. Görsel ve ses varlıkları

| Grup | Miktar | Açıklama |
|---|---:|---|
| Ana harita | 1 | Katmanlı, sabit sepya 2D resim |
| Mekân sürümleri | ~32 | 10 yerde yıkık/kapalı/açık/hasarlı varyantlar |
| Portreler | 24 | 12 karakter × 2 ifade |
| İpucu çizimleri | ~18 | Gazete, lamba, telgraf, defter vb. |
| Mektup varlıkları | 8–12 | Zarf, pul, damga, kâğıt, kapak |
| UI panelleri | ~15 | Defter, mektup, zaman, seçenek, final |
| İkonlar | ~20 | Pul, geri, şüphe, araştırma, ses |
| Bölüm başlıkları | 5 | Dönem ve olay atmosferi |
| Final görüntüleri | 4 | Farklı 2026 kasabaları |
| Müzik | 7 | Menü, 5 bölüm, final. Sakin piyano/gramofon |
| Ambiyans | 4 | Dere, rüzgâr, gece, kasaba |
| SFX | ~18 | Kâğıt, pul, posta kutusu, dönüşüm, uyarı |

Palet: kâğıt `#E8D6B8`, sepya `#8A6046`, mürekkep `#2E2927`, pas `#AD6447`. Çizim kaynakları katmanlı; oyuna PNG/WebP sprite olarak aktarılır. Ağır animasyon yoktur. Konuşmalar seslendirilmez; tüm bilgi metinle anlaşılır.

## 11. Teknik mimari

**Öneri:** Godot 4.x, GDScript, 2D Compatibility. Dikey mobil Canvas/Control tabanlı arayüz. `Main` sahnesinde `MapBase`, `LocationLayers`, `Hotspots`, `LetterComposer`, `Timeline`, `Journal`, `ReplyPopup`, `ChangeOverlay` düğümleri. Autoload sınıfları: `GameState`, `ChapterDatabase`, `StoryResolver`, `SaveManager`, `AudioManager`.

**Veri:** Bölüm, karakter, mektup, koşul, ipucu ve harita varyantları JSON'da. Her mektupta ID, alıcı, konu, öğüt, önkoşul, puan etkisi, bayrak, şüphe ve cevap alanları tutulur. Tüm durum, mektup geçmişinden deterministik hesaplanır. `user://` içine atomik yazmaya yakın geçici-dosya→yeniden adlandırma akışıyla otomatik kayıt tutulur; üç profil önerilir.

**İşleyici:** Bölümün gönderilmiş mektupları okunur; alıcıya ikinci mektup ve pul aşımı reddedilir; şüphe eşiği geçerliyse mektup etkisiz kalabilir; sayısal etkiler toplanır ve öncelik kuralları uygulanır; tek sonuç nesnesinden hem harita hem zaman çizelgesi güncellenir. Gönderim sırası son sonucu etkilemez. Eski bölüme geri sarma, sonraki sonuçların yeniden hesaplanmasını gerektirir.

**Mobil derleme:** Android için APK test, AAB mağaza; iOS için macOS + Xcode ve uygun imzalama gereklidir. Ağ, reklam ve üyelik bulunmaz. Büyük metin, hareket azaltma, tüm sesi kapatma ve safe area testleri yapılır.

## 12. Üretim planı ve kabul kriterleri

| Faz | Tahmini süre | Çıktı | Tamamlanma koşulu |
|---|---:|---|---|
| Ön üretim | 1–2 hafta | GDD, kroki, veri şeması | 5 kişilik kâğıt testi, nedensellik anlaşılır |
| Prototip | 3–4 hafta | 5–10 dk Godot oynanışı | Mektup→harita değişimi→kayıt→yeniden açma çalışır |
| B1 vertical slice | 5–7 hafta | Tam ilk bölüm, 4 karakter, 12 mektup | 175 durum testi, mobil arayüz ve sesler geçer |
| B2–B5 | 10–14 hafta | 54 ek mektup, bütün bölümler | 4 final ulaşılabilir, sonuçlar çelişmez |
| Son QA/yayın | 3–4 hafta | Mobil yayın adayları | Kritik hata yok, tüm oyun çevrimdışı tamamlanır |

**Toplam ekip tahmini:** 22–31 hafta. Roller: 1 programcı, 1 2D sanatçı/UI tasarımcısı, 1 yazar/oyun tasarımcısı, yarı zamanlı ses tasarımcısı ve test oyuncuları.

**İlk sprint:** Proje kurulumu; 720×1280 UI; B1 veri yükleme; dört portre kartı; 12 mektup; fırın/okul/mezarlık katmanları; 175 sonuç testi; harita geçişi; otomatik kayıt; Android ve iOS dokunma testi.

**Riskler:** Dallanma patlaması (sprite katmanıyla önle); nedensel çelişkiler (veri testi); metin yorgunluğu (kısa kartlar); şüphe kaynaklı kilitlenme (vekâlet rolü); küçük ekranda taşma (safe area/test); kayıt kaybı (yedek ve migration).

## 13. Varsayımlar

1. İğdeyaka, olaylar ve kişiler kurgusaldır.
2. Oyuncu 2026'da kalır; posta kutusu 1925–1929 arasındaki sabit pencerelere gider.
3. Posta kutusu ve defter geçmiş değişimlerinden etkilenmez.
4. Bölüm pulları 3/3/4/3/4; bir alıcıya bölümde en fazla bir mektup gider.
5. İlk bölümde dört ana kişi, 12 mektup, 175 geçerli kombinasyon tasarlanmıştır.
6. Toplam 66 sabit mektup seçeneği planlanır; B2–B5'in tüm metinleri ileriki içerik fazında yazılacaktır.
7. Türkçe, internetsiz, reklamsız ve mikro ödemesiz bir premium oyun varsayılmıştır.
8. Bu belge **tasarım ve B1 karar verisi** teslimidir; çalışan APK/IPA değildir.
