insert into public.posts (
    id, author, category, title, body, status, like_count, created_at
)
values
    (
        '00000000-0000-4000-8000-000000000001',
        'Andreea M.',
        'Machiaj & Skincare',
        'Recomandare de blush lichid care să reziste chiar și 8 ore?',
        'Am încercat câteva variante din drugstore dar după 3 ore dispar complet de pe obraji. Vreau ceva cu aspect natural (dewy), nu foarte mat, buget până în 150 lei. Ce folosiți voi?',
        'published', 0, now() - interval '25 minutes'
    ),
    (
        '00000000-0000-4000-8000-000000000002',
        'Anonimă',
        'Idei de Cadouri',
        'Idee de cadou pentru iubitul meu (împlinim 2 ani) — nu vrea parfum sau ceas',
        'Fetelor, am nevoie de ajutor! Suntem împreună de 2 ani, îi place să gătească, îi plac jocurile pe PS5 și drumețiile. Vreau ceva memorabil, buget 400-500 lei. Orice idee e binevenită!',
        'published', 0, now() - interval '1 hour'
    ),
    (
        '00000000-0000-4000-8000-000000000003',
        'Ioana',
        'Fashion & Outfit',
        'Ce încălțăminte confortabilă pot purta la o nuntă de zi în aer liber?',
        'Nunta e într-o grădină cu iarbă și pietriș, deci tocurile stiletto ies din discuție. Port o rochie midi satinată verde salvie. Ce sandale sau pantofi cu toc gros ar arăta elegant?',
        'published', 0, now() - interval '3 hours'
    ),
    (
        '00000000-0000-4000-8000-000000000004',
        'Anonimă',
        'Relații & Sfaturi',
        'Cum îi spui unei prietene bune că noul ei iubit are niște red flag-uri evidente?',
        'E super îndrăgostită și nu vreau să pară că sunt invidioasă sau că mă bag unde nu-mi fierbe oala, dar tipul o izolează încet de grupul nostru. Ați trecut prin asta?',
        'published', 0, now() - interval '5 hours'
    ),
    (
        '00000000-0000-4000-8000-000000000005',
        'Clara',
        'Lifestyle & Productivitate',
        'Ce obicei mic de dimineață v-a schimbat complet starea de spirit?',
        'Încerc să nu mai stau pe TikTok imediat cum deschid ochii pentru că îmi strică toată energia. Voi ce faceți în primele 30 de minute după trezire?',
        'published', 0, now() - interval '1 day'
    )
on conflict (id) do nothing;

insert into public.comments (
    id, post_id, author, body, status, created_at
)
values
    (
        '10000000-0000-4000-8000-000000000001',
        '00000000-0000-4000-8000-000000000001',
        'Bianca',
        'Rare Beauty Soft Pinch în nuanța Hope! E puțin peste buget, dar un tub te ține literalmente doi ani pentru că e super pigmentat.',
        'published', now() - interval '18 minutes'
    ),
    (
        '10000000-0000-4000-8000-000000000002',
        '00000000-0000-4000-8000-000000000001',
        'Anonimă',
        'Dacă vrei ceva mai accesibil, NYX Sweet Cheeks sau Elf Camo Liquid Blush sunt geniale și rezistă foarte bine dacă le fixezi cu puțin blush pudră peste.',
        'published', now() - interval '10 minutes'
    ),
    (
        '10000000-0000-4000-8000-000000000003',
        '00000000-0000-4000-8000-000000000002',
        'Elena',
        'Un curs de gătit în doi (ex: sushi sau paste artizanale) + un cuțit japonez de bucătar gravat cu inițialele lui. Iubitul meu a fost super încântat!',
        'published', now() - interval '42 minutes'
    ),
    (
        '10000000-0000-4000-8000-000000000004',
        '00000000-0000-4000-8000-000000000002',
        'Maria C.',
        'Un rucsac tehnic Osprey pentru drumeții sau un weekend surpriză la o cabină A-frame la munte.',
        'published', now() - interval '15 minutes'
    ),
    (
        '10000000-0000-4000-8000-000000000005',
        '00000000-0000-4000-8000-000000000003',
        'Daria',
        'Sandale cu toc bloc de 5-6 cm aurii sau nude cu barete subțiri! Arată super feminin și nu te afunzi în iarbă.',
        'published', now() - interval '2 hours'
    ),
    (
        '10000000-0000-4000-8000-000000000006',
        '00000000-0000-4000-8000-000000000004',
        'Teodora',
        'Nu îl ataca direct pe el, pentru că o să-i ia apărarea. Întreab-o doar cum se simte ea în ultimul timp și asigur-o că ești mereu acolo pentru ea, indiferent de ce se întâmplă.',
        'published', now() - interval '4 hours'
    ),
    (
        '10000000-0000-4000-8000-000000000007',
        '00000000-0000-4000-8000-000000000004',
        'Sofia',
        'Exact ce a zis Teodora! Pune întrebări blânde de genul „Ți se pare că mai ai timp pentru tine în ultima vreme?”. Așa ajunge singură la concluzie.',
        'published', now() - interval '3 hours 50 minutes'
    ),
    (
        '10000000-0000-4000-8000-000000000008',
        '00000000-0000-4000-8000-000000000005',
        'Raluca',
        'Îmi las telefonul la încărcat în altă cameră și îmi cumpăr un ceas deșteptător clasic. Dimineața beau un pahar mare cu apă și ies 5 minute pe balcon la lumină naturală.',
        'published', now() - interval '1 day'
    )
on conflict (id) do nothing;
