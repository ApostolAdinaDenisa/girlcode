# GirlCode

GirlCode este o aplicație web statică. Fără setare Supabase, datele rămân local în browser pentru previzualizare. Cu Supabase configurat, postările, comentariile și fotografiile se salvează online și pot fi văzute de toți vizitatorii după aprobare.

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

## Moderarea conținutului

Postările și comentariile noi au implicit statusul `pending`. Ele nu apar în feed până când moderatorul le aprobă din **Supabase → Table Editor**, schimbând statusul în `published`; conținutul nepotrivit poate fi marcat `rejected`. RLS nu permite vizitatorilor să citească postări în așteptare sau să modifice direct tabelele.

Fotografiile din bucketul public pot fi accesate de oricine are URL-ul. Pentru lansare publică, adaugă și protecție anti-spam (de exemplu CAPTCHA/Turnstile sau autentificare) și nu cere utilizatorilor să încarce fotografii private.

Pentru aprobare prin SQL:

```sql
update public.posts set status = 'published' where id = 'ID_POSTARE';
update public.comments set status = 'published' where id = 'ID_COMENTARIU';
```
