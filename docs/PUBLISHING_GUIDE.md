# دليل نشر لبيب خطوة بخطوة

هذا الدليل لك أنت. كل خطوة مكتوب بجانبها **من يقوم بها**: أنت 👤 أو أنا 🤖.
الملفات الجاهزة كلها في مجلد `store/` في المشروع:
- `store/STORE_LISTING.md`: نصوص المتجر بالعربي والإنجليزي.
- `store/QUESTIONNAIRES.md`: إجابات كل الاستبيانات.
- `store/screenshots/`: صور المتجر لكل المقاسات.
- `store/play_icon_512.png` و`store/play_feature_graphic.png`: الأيقونة وصورة الغلاف.

**قاعدة ذهبية:** لا ترسل في المحادثة كلمات مرور، أو بيانات بطاقة، أو ملفات مفاتيح Apple (‎.p8).

---

## المرحلة أ: الحسابات (ابدأ بها الآن، لأن التحقق يأخذ أياماً)

### ١. Google Play Console 👤
1. افتح play.google.com/console وسجّل الدخول بحساب Google الذي تريده للتطبيق.
2. اختر **حساب شخصي (Personal)**، وادفع رسوم التسجيل (٢٥$ مرة واحدة).
3. أكمل **التحقق من الهوية**: صورة الهوية، وقد يطلب تأكيداً من جوال أندرويد حقيقي عبر تطبيق Play Console.
4. انتظر رسالة الموافقة (غالباً من يوم إلى عدة أيام).

### ٢. AdMob 👤
1. افتح admob.google.com بنفس حساب Google، وأكمل التسجيل (الدولة، المنطقة الزمنية، العملة).
2. **Payments**: أكمل بيانات الدفع والضرائب حتى تستلم الأرباح لاحقاً.
3. **Apps → Add app** ← Android ← «Is the app listed on a supported app store?» اختر **No** ← الاسم: `لبيب`.
4. داخل التطبيق: **Ad units → Add ad unit → Interstitial** ← الاسم: `after-lesson` ← Create.
5. **App settings**: ابحث عن **Max ad content rating** واختر **G**.
6. أرسل لي هنا معرّفين، وهما ليسا سرّيين:
   - **App ID**، ويشبه: `ca-app-pub-1234567890123456~1234567890`
   - **Ad unit ID**، ويشبه: `ca-app-pub-1234567890123456/1234567890`

### ٣. Apple Developer 👤
1. على آيفونك: الإعدادات ← اسمك ← تسجيل الدخول والأمان ← تأكد أن **المصادقة بخطوتين** مفعّلة.
2. نزّل تطبيق **Apple Developer** من App Store ← Account ← **Enroll Now** ← كفرد (Individual) ← ادفع ٩٩$ سنوياً.
3. بعد الموافقة: ادخل appstoreconnect.apple.com ← **Business** (أو Agreements) ← وقّع **Paid Apps Agreement** وأضف حسابك البنكي وبيانات الضريبة. هذا شرط حتى يعمل الشراء داخل التطبيق.

### ٤. بريد الدعم 👤
✅ تم: بريد الدعم `dev.awt1998@gmail.com` (في المتجر وصفحة الخصوصية).

### ٥. المختبِرون 👤
اجمع ١٥–٢٠ إيميل Gmail لأشخاص عندهم أجهزة أندرويد (الرسالة الجاهزة في المحادثة)، وأرسلها لي.

### ٦. Codemagic (لبناء نسخة الآيفون والأندرويد بدون Mac) 👤
1. افتح codemagic.io ← **Sign up with GitHub** ← اسمح له برؤية مستودع `-kids-english`.
2. **Add application** ← اختر المستودع ← نوع المشروع **Flutter** ← سيقرأ ملف `codemagic.yaml` الجاهز تلقائياً.
3. توقّف هنا. باقي إعدادات Codemagic نكملها معاً في المرحلة ج.

---

## المرحلة ب: ما أجهّزه أنا بعد وصول المعلومات 🤖
- أضع معرّفات AdMob الحقيقية في إعدادات البناء. لن تُكتب في الكود.
- أضع بريد الدعم في صفحة الخصوصية، وأنشرها على رابط عام.
- أنشئ **مفتاح التوقيع** (upload key) للأندرويد، وأرسله لك كملف مع كلمة مروره. **احفظه في مكانين آمنين**، فبدونه لا تستطيع تحديث التطبيق.

---

## المرحلة ج: Google Play، الاختبار المغلق ثم النشر

### ١. إنشاء التطبيق 👤
Play Console ← **Create app**:
- App name: `لبيب: إنجليزي للأطفال`
- Default language: **Arabic – ar**
- App or game: **App** — Free or paid: **Free**
- وافق على الإقرارات ← Create app

### ٢. محتوى التطبيق (App content) 👤
من القائمة الجانبية **Policy and programs → App content**، أكمل كل بند بالإجابات الموجودة في `store/QUESTIONNAIRES.md`:
Privacy policy، App access، Ads، Content rating، Target audience، Data safety، Government apps، Financial features، Health، Advertising ID.

### ٣. صفحة المتجر (Main store listing) 👤
- الأسماء والأوصاف: من `store/STORE_LISTING.md` (العربي، ثم **Add translation → English**).
- App icon: `store/play_icon_512.png`
- Feature graphic: `store/play_feature_graphic.png`
- Phone screenshots: `store/screenshots/play-phone/ar/` (وللإنجليزية: `.../en/`)
- 7-inch و10-inch tablet screenshots: `store/screenshots/play-tablet/ar/`
- Category: **Education** — Contact email: `dev.awt1998@gmail.com`.

### ٤. Codemagic: مفتاح التوقيع ومعرّفات الإعلانات 👤🤖
في Codemagic ← **Team settings**:
- **Code signing identities → Android keystores → Add keystore**: ارفع ملف المفتاح الذي أرسلته لك، واكتب كلمة المرور، واسم المرجع (Reference name): `labeeb_upload`.
- **Environment variables**: أنشئ مجموعة اسمها `admob` فيها:
  - `ADMOB_APP_ID` = الـApp ID
  - `ADMOB_INTERSTITIAL` = الـAd unit ID
- ثم **Start new build → android-release**. بعد ٥–١٥ دقيقة نزّل ملف `.aab` من صفحة البناء.

### ٥. الاختبار المغلق، والـ١٤ يوماً 👤
1. **Testing → Closed testing → Create track** (أو استخدم Alpha) ← **Testers**: أنشئ قائمة إيميلات وألصق إيميلات المختبِرين.
2. **Create new release** ← ارفع ملف `.aab` ← اكتب ملاحظة «نسخة تجريبية أولى» ← **Review release → Start rollout**.
3. انسخ **رابط الانضمام (opt-in link)** وأرسله للمختبِرين في القروب.
4. بعد رفع أول نسخة: **Monetize → Products → In-app products → Create product**:
   - Product ID: `remove_ads` (حرفياً) — الاسم: إزالة الإعلانات — السعر: 2.99$ ← **Activate**.
5. عدّاد الـ١٤ يوماً يبدأ حين يكتمل ١٢ مختبِراً مشتركاً. اطلب منهم فتح التطبيق كل كم يوم وإرسال ملاحظاتهم.

### ٦. طلب النشر العام 👤
بعد ١٤ يوماً: **Dashboard → Apply for production**. أجب عن أسئلة الاختبار (أساعدك في صياغتها). بعد الموافقة: **Production → Create release** ← نفس ملف `.aab` أو أحدث ← **Start rollout**.

---

## المرحلة د: App Store (آيفون وآيباد)

### ١. تسجيل معرّف التطبيق 👤
developer.apple.com ← **Certificates, IDs & Profiles → Identifiers → +** ← App IDs ← App ← Bundle ID (Explicit): `com.labeeb.english` ← فعّل **In-App Purchase** ← Register.

### ٢. إنشاء التطبيق 👤
appstoreconnect.apple.com ← **Apps → + → New App**:
- Platforms: iOS — Name: `لبيب: إنجليزي للأطفال` — Primary language: **Arabic**
- Bundle ID: `com.labeeb.english` — SKU: `labeeb-001`

### ٣. مفتاح الربط مع Codemagic 👤
App Store Connect ← **Users and Access → Integrations → App Store Connect API → +** ← الاسم: Codemagic ← الصلاحية **App Manager** ← Generate.
نزّل ملف `.p8` (يُنزّل **مرة واحدة فقط**)، وانسخ **Issuer ID** و**Key ID**.
ثم في Codemagic ← **Team settings → Integrations → App Store Connect → Add key**: الاسم `Labeeb ASC`، وارفع الملف واكتب المعرّفين.
**لا ترسل ملف .p8 في المحادثة.**

بعدها في Codemagic ← **Team settings → Code signing identities**:
- **iOS certificates → Generate certificate** ← النوع **Apple Distribution** ← اختر مفتاح `Labeeb ASC` ← احفظ.
- **iOS provisioning profiles → Fetch profiles** ← اختر ملف **App Store** الخاص بـ`com.labeeb.english`. إن لم يظهر، أنشئه من developer.apple.com ← Profiles ← App Store Connect، ثم أعد الجلب.

### ٤. البناء و TestFlight 👤
Codemagic ← **Start new build → ios-release**. يبني النسخة ويرفعها إلى TestFlight تلقائياً.
على آيفونك: نزّل تطبيق **TestFlight** ← ستظهر لك نسخة لبيب للتجربة.

### ٥. صفحة المتجر والمراجعة 👤
في App Store Connect داخل التطبيق:
- **App Information**: Category **Education** ← **Made for Kids** ← الفئة العمرية (راجع `store/QUESTIONNAIRES.md`) ← Age rating 4+.
- **App Privacy**: Data Not Collected ← رابط صفحة الخصوصية.
- **In-App Purchases → +** ← Non-Consumable ← Product ID: `unlock_all` ← السعر 4.99$.
- صفحة النسخة: النصوص من `store/STORE_LISTING.md`، والصور:
  - iPhone 6.9": `store/screenshots/ios-6.9/ar/`
  - iPad 13": `store/screenshots/ipad-13/ar/`
- **App Review Information**: انسخ الملاحظات الجاهزة من `store/QUESTIONNAIRES.md`، وبريدك ورقمك.
- اختر نسخة البناء من TestFlight ← أضف منتج الشراء للنسخة ← **Add for Review → Submit**.

المراجعة تأخذ عادة من ١ إلى ٣ أيام. إذا وصلت ملاحظات، أرسلها لي كما هي وأتولى الإصلاح.

---

## بعد النشر
- **أرباح AdMob:** تظهر في لوحة AdMob، والتحويل شهري بعد تجاوز الحد الأدنى للدفع.
- **التحديثات:** أي تعديل أبنيه أنا، وأنت تضغط Start new build في Codemagic ثم ترفع النسخة الجديدة.
- **التسويق في تيك توك:** وجّه الإعلانات للأهل فقط، ولا تضف أي أداة تتبّع داخل التطبيق.
