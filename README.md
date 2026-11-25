# GirlCode

GirlCode este o aplicație web statică. Fără setare Supabase, datele rămân local în browser pentru previzualizare. Cu Supabase configurat, postările, comentariile și fotografiile se salvează online și devin vizibile automat după verificarea limbajului și CAPTCHA.

## Publicare recomandată

Folosește **Supabase** pentru PostgreSQL și fotografii, apoi **Vercel** pentru site. Supabase aplică Row Level Security la citirea datelor, iar postările și comentariile sunt verificate automat atât în browser, cât și prin funcții SQL înainte de salvare.

1. Creează un proiect Supabase.
2. În Supabase, deschide **SQL Editor**, rulează tot conținutul din `supabase/schema.sql`. Pentru instalările existente, rulează din nou scriptul după actualizări; acesta revocă accesul direct la scriere și mută publicarea prin Edge Function.
3. Creează un widget Cloudflare Turnstile pentru domeniul site-ului.
4. Din **Project Settings → API**, copiază Project URL și cheia `publishable` (sau cheia legacy `anon`) în `config.js`. Adaugă cheia publică Turnstile în `turnstileSiteKey`.
   - Aceste valori sunt publice în browser și sunt protejate de politicile RLS din schema SQL.
   - Nu pune niciodată cheia `secret` sau `service_role` în `config.js`.
5. În **Supabase → Edge Functions → Secrets**, setează `TURNSTILE_SECRET_KEY` și `ALLOWED_ORIGINS` (origin-urile exacte permise, separate prin virgulă; de exemplu `https://girlcode.example`). Funcția folosește `SUPABASE_URL` și `SUPABASE_SERVICE_ROLE_KEY` din mediul Supabase; nu le copia în codul browserului.
6. Rulează `supabase login`, conectează proiectul cu `supabase link --project-ref PROJECT_REF`, apoi deployează cu `supabase functions deploy submit-community-content`. `supabase/config.toml` setează `verify_jwt = false` doar pentru această funcție, care verifică originea și tokenul Turnstile pe server înainte de a apela funcțiile SQL.
7. În **Authentication → Settings**, dezactivează **Allow new users to sign up** în proiectul găzduit; aplicația nu folosește autentificare. `supabase/config.toml` dezactivează înregistrările și pentru dezvoltarea locală.
8. Încarcă proiectul în Vercel și verifică publicarea unei întrebări și a unui comentariu. `vercel.json` setează CSP, `X-Frame-Options: DENY` și alte headere.

```js
window.GIRLCODE_CONFIG = {
    supabaseUrl: 'https://PROJECT_REF.supabase.co',
    supabasePublishableKey: 'sb_publishable_...',
    turnstileSiteKey: 'TURNSTILE_SITE_KEY'
};
```

`config.js` este necesar ca site-ul public să se conecteze la baza online. Nu publica niciodată cheia `service_role`.

## Protecția conținutului și publicării

RLS este activă pentru `posts`, `comments` și `post_likes`. Rolurile `anon` și `authenticated` pot citi doar postări și comentarii publicate; nu au acces direct la inserare, modificare sau ștergere. Aprecierile pot fi schimbate numai prin funcția controlată `toggle_post_like`. Postările și comentariile trec prin Edge Function, care verifică Turnstile server-side; funcțiile SQL validează în continuare lungimea, categoria și limbajul.

Widgetul Turnstile trebuie configurat înainte de publicare. Dacă cheia publică lipsește, trimiterea online eșuează în mod închis. `verify_jwt = false` este limitat la această funcție publică, care verifică Turnstile și origin-urile permise înainte de orice operație privilegiată.

Politica CSP păstrează temporar `unsafe-inline` și `unsafe-eval` pentru scripturile inline și Tailwind Play CDN folosite de pagina statică. Pentru o politică CSP mai strictă, mută JavaScript/CSS inline în fișiere externe și înlocuiește Play CDN cu CSS compilat. Dacă schimbi proiectul Supabase, actualizează origin-ul său în `img-src` și `connect-src` din `vercel.json`.

## Publicarea și moderarea conținutului

Postările și comentariile sunt publicate automat după verificarea limbajului, care rulează atât în browser, cât și pe server. Pentru un proiect Supabase deja configurat, rulează scriptul `supabase/auto-publish.sql` din **Supabase → SQL Editor**; acesta publică și conținutul mai vechi rămas `pending`. Pentru proiecte noi, `supabase/schema.sql` configurează publicarea automată.

Pentru a adăuga întrebările și sfaturile demonstrative din aplicație în baza de date, rulează `supabase/seed-content.sql` din **Supabase → SQL Editor**. Scriptul poate fi rulat din nou fără să dubleze conținutul.

Pentru un proiect Supabase deja creat, rulează `supabase/add-vacations-category.sql` din **Supabase → SQL Editor** ca să permită salvarea întrebărilor din categoria „Vacanțe”.

Filtrul blochează anumite cuvinte jignitoare, dar nu poate detecta orice conținut nepotrivit sau spam. Verifică periodic postările în **Supabase → Table Editor → posts** și comentariile în **comments**; poți schimba statusul unui element în `rejected`. RLS permite vizitatorilor să citească doar conținutul cu status `published` și nu le permite să modifice direct tabelele.

Fotografiile din bucketul public pot fi accesate de oricine are URL-ul. Încărcarea fotografiilor este făcută de Edge Function după verificarea Turnstile; nu cere utilizatorilor să încarce fotografii private.
