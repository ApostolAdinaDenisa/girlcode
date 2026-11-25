# GirlCode

GirlCode este o aplicație web statică. Fără setare Supabase, datele rămân local în browser pentru previzualizare. Cu Supabase configurat, postările, comentariile și fotografiile se salvează online și devin vizibile automat după verificarea limbajului.

## Publicare recomandată

Folosește **Supabase** pentru PostgreSQL și fotografii, apoi **Vercel** pentru site. Supabase aplică Row Level Security la citirea datelor, iar postările și comentariile sunt verificate automat atât în browser, cât și prin funcții SQL înainte de salvare.

1. Creează un proiect Supabase.
2. În Supabase, deschide **SQL Editor**, rulează tot conținutul din `supabase/schema.sql`.
3. Din **Project Settings → API**, copiază Project URL și cheia `publishable` (sau cheia legacy `anon`) în `config.js`.
   - Aceste valori sunt publice în browser și sunt protejate de politicile RLS din schema SQL.
   - Nu pune niciodată cheia `secret` sau `service_role` în `config.js`.
4. Încarcă proiectul într-un repository GitHub și importă-l în Vercel. Păstrează `index.html`, `config.js` și folderul `supabase/` în rădăcina proiectului.
5. Deschide site-ul Vercel și verifică publicarea unei întrebări de test.

```js
window.GIRLCODE_CONFIG = {
    supabaseUrl: 'https://PROJECT_REF.supabase.co',
    supabasePublishableKey: 'sb_publishable_...'
};
```

`config.js` este necesar ca site-ul public să se conecteze la baza online. Nu publica niciodată cheia `service_role`.

## Publicarea și moderarea conținutului

Postările și comentariile sunt publicate automat după verificarea limbajului, care rulează atât în browser, cât și pe server. Pentru un proiect Supabase deja configurat, rulează scriptul `supabase/auto-publish.sql` din **Supabase → SQL Editor**; acesta publică și conținutul mai vechi rămas `pending`. Pentru proiecte noi, `supabase/schema.sql` configurează publicarea automată.

Pentru a adăuga întrebările și sfaturile demonstrative din aplicație în baza de date, rulează `supabase/seed-content.sql` din **Supabase → SQL Editor**. Scriptul poate fi rulat din nou fără să dubleze conținutul.

Pentru un proiect Supabase deja creat, rulează `supabase/add-vacations-category.sql` din **Supabase → SQL Editor** ca să permită salvarea întrebărilor din categoria „Vacanțe”.

Filtrul blochează anumite cuvinte jignitoare, dar nu poate detecta orice conținut nepotrivit sau spam. Verifică periodic postările în **Supabase → Table Editor → posts** și comentariile în **comments**; poți schimba statusul unui element în `rejected`. RLS permite vizitatorilor să citească doar conținutul cu status `published` și nu le permite să modifice direct tabelele.

Fotografiile din bucketul public pot fi accesate de oricine are URL-ul. Pentru lansare publică, adaugă și protecție anti-spam (de exemplu CAPTCHA/Turnstile sau autentificare) și nu cere utilizatorilor să încarce fotografii private.
