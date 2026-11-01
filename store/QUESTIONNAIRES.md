# إجابات استبيانات المتجرين — لبيب

اختر الإجابات كما هي هنا. أسماء الخيارات مكتوبة بالإنجليزية كما تظهر في لوحة التحكم.

---

# Google Play Console

## ١. App access (الوصول للتطبيق)
اختر: **All or some functionality is restricted** ثم أضف هذه التعليمات:
```
No login. The Parent Zone (settings, reports, purchase) is behind a parental gate:
a multiplication question written in Arabic words. Number words:
ثلاثة=3, أربعة=4, خمسة=5, ستة=6, سبعة=7, ثمانية=8, تسعة=9.
Example: "كم حاصل ضرب خمسة في سبعة؟" = 5 × 7 → type 35 and press ✓.
Open it from the "للأهل" button at the top of the child-picker screen.
```

## ٢. Ads (الإعلانات)
**Yes, my app contains ads.**

## ٣. Content rating (تصنيف المحتوى — استبيان IARC)
- Category: **All other app types** (أو Education إن ظهرت)
- Violence / Fear / Sexuality / Language / Controlled substances / Crude humor / Gambling: **No** لكل الأسئلة
- Does the app allow users to interact or exchange content? **No**
- Does the app share the user's current physical location? **No**
- Does the app allow users to purchase digital goods? **Yes**
- النتيجة المتوقعة: **Everyone / PEGI 3 / 3+**

## ٤. Target audience and content (الجمهور المستهدف)
- Target age groups: **5 and under**، **6–8**، **9–12**
- Appeal to children: سيعتبر التطبيق موجّهاً للأطفال تلقائياً → يدخل **برنامج العائلات (Families)**.
- Ads: نعم، عبر **Google AdMob** (شبكة معتمدة ذاتياً لبرنامج العائلات).
- Store presence: لا شيء خاص.

## ٥. Data safety (أمان البيانات)
التطبيق نفسه لا يجمع شيئاً، لكن مكتبة AdMob في نسخة أندرويد ترسل بيانات تقنية لعرض الإعلان. حسب دليل Google للإفصاح عن بيانات AdMob، أجب هكذا (المرجع الرسمي، راجعه عند التعبئة لأنه يتحدث مع كل إصدار: developers.google.com/admob/android/privacy/play-data-disclosure):

- Does your app collect or share any of the required user data types? **Yes**
- Is all of the user data collected by your app encrypted in transit? **Yes**
- Do you provide a way for users to request that their data is deleted? **No** (لا نحتفظ بأي بيانات لدينا؛ حذف الطفل من منطقة الآباء أو حذف التطبيق يمسح كل شيء من الجهاز)

البيانات (كلها **Collected**، وليست Shared، و**مطلوبة** وليست اختيارية):

| النوع | البند | الغرض |
|---|---|---|
| Location | **Approximate location** (من عنوان IP) | Advertising or marketing, Fraud prevention, security, and compliance |
| App activity | **App interactions** | Advertising or marketing, Analytics, Fraud prevention |
| App info and performance | **Crash logs**, **Diagnostics** | Analytics, Fraud prevention |
| Device or other IDs | **Device or other IDs** | Advertising or marketing, Fraud prevention |

**لا تختر**: الاسم، البريد، الصور، الرسائل، جهات الاتصال، الموقع الدقيق، معلومات مالية. التطبيق لا يجمع أياً منها.

## ٦. Families policy (سياسة العائلات)
- Do you comply with the Families Policy requirements? **Yes**
- Ads SDK: **Google AdMob** — mark that ad requests are tagged child-directed (TFCD) ✓
- Teacher Approved: اختياري، يمكن التقديم لاحقاً.

## ٧. أسئلة أخرى
- Government app: **No** — Financial features: **No** — Health: **No** — News app: **No**
- COVID-19 contact tracing: **No**
- Advertising ID: **No, my app does not use advertising ID** (أزلناه من التطبيق)

## ٨. Store settings
- App category: **Education**
- Tags: Education, Language learning, Kids
- Contact email: بريد الدعم
- Privacy policy: رابط صفحة الخصوصية

---

# App Store Connect (آيفون وآيباد)

## ١. التصنيف
- Primary category: **Education**
- **Made for Kids: Yes** → اختر فئة عمرية واحدة فقط (Apple لا تسمح بأكثر من واحدة):
  - **6–8** (أنصح بها: تغطي الصغار والأكبر قليلاً)
  - أو **5 and Under** إن كان أغلب جمهورك من الصغار
- Age rating: **4+** (جاوب No على كل أسئلة المحتوى الحساس)

## ٢. App Privacy (Privacy Nutrition Label)
- Do you or your third-party partners collect data from this app? **No** → النتيجة: **Data Not Collected**
  (نسخة آيفون بدون إعلانات وبدون أي أداة من جهات خارجية. الشراء تتولاه Apple ولا يُحسب جمعاً للبيانات.)

## ٣. In-App Purchase
- Type: **Non-Consumable** — Product ID: `unlock_all` — السعر: 4.99$
- Display name: فتح كل الدروس / Unlock all lessons
- Review screenshot: صورة شاشة منطقة الآباء (أجهّزها لك)

## ٤. App Review Information — Notes (انسخها كما هي)
```
Labeeb teaches English to Arab children (Kids Category). No login, no ads,
no third-party SDKs, no data collection; all progress is stored on device.

Parental gate: the Parent Zone (settings, report, and the "Unlock all"
purchase with Restore) opens from the "للأهل" button at the top of the
child-picker screen, and also when a child taps a locked unit (key icon).
The gate asks a multiplication written in Arabic words; type the number
and press ✓. Number words: ثلاثة=3, أربعة=4, خمسة=5, ستة=6, سبعة=7,
ثمانية=8, تسعة=9. Example: "كم حاصل ضرب خمسة في سبعة؟" = 5 × 7 = 35.

To try a lesson: create a child (any avatar, any age), then tap the
glowing stop on the map. The first 3 units are free; later units show a
key and are unlocked by the one-time "unlock_all" purchase.
```

## ٥. Export compliance
- Uses encryption? أضفنا الإعداد في التطبيق (`ITSAppUsesNonExemptEncryption = NO`)، فلن يُسأل هذا السؤال عند كل رفع.
