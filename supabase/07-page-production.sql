-- 07-page-production.sql
-- Ajoute la colonne d'ADRESSE DE PRODUCTION 'page_production' et ses deux
-- bornes EN BASE ; l'expose par la vue publique, en DOUZIEME et derniere
-- colonne ; accorde a la page privee le droit de l'ecrire ; et ouvre le
-- journal au geste 'adresse' -- un changement d'adresse (page_production
-- OU page_pilote) y laisse desormais sa ligne.
-- BKL-CIN-099, 26/09/2026.
--
-- !!! CE SCRIPT NE CONTIENT NI 'drop table' NI 'drop view' : C'EST LUI, ET
-- !!! NON 01-table-demandes.sql, QUI SE JOUE SUR LA BASE EN PRODUCTION.
-- !!! 01 commence par 'drop view' puis 'drop table' : le rejouer en
-- !!! production DETRUIRAIT toutes les demandes.
-- !!! Les seuls 'drop' ci-dessous portent sur des CONTRAINTES, aussitot
-- !!! reposees dans la meme transaction. La vue est remplacee par
-- !!! 'create or replace view' -- elle n'est PAS detruite, et aucun objet
-- !!! ne nait donc expose par les droits par defaut du schema public
-- !!! (R-023, pg_default_acl). Ses droits sont malgre tout RAPPELES plus
-- !!! bas : on les prouve par controle, on ne les suppose pas.
-- !!! ET 03-droits-vue-publique.sql NE SE REJOUE JAMAIS : son 'revoke all'
-- !!! emporterait aussi le droit de colonne que la section 5 accorde.
--
-- ---------------------------------------------------------------------
-- POURQUOI (BKL-CIN-099 ; cadrage du 21/09/2026, decisions d'AH au 4 bis)
-- ---------------------------------------------------------------------
-- La file publique range sous "Traitees" -- "Analysees et publiees" --
-- des demandes dont l'analyse est au site, et AUCUNE carte ne dit ou la
-- lire. Decision d'AH du 21/09/2026, verbatim : "A -- page_production" :
-- une colonne neuve, l'adresse ENTIERE, bornee en forme et en coherence,
-- sur le modele exact de 'page_pilote' (06-statut-publiee-pilote.sql).
--
-- QUI POSE L'ADRESSE : AH SEUL -- depuis la page privee au passage vers
-- 'traitee' (les deux chemins : depuis 'a_traiter' et depuis
-- 'publiee_pilote'), et, pour les demandes DEJA traitees, par le bloc R-2
-- en bas de ce fichier, joue UNE fois. 'traitee' reste une etape SANS
-- geste dans la page (decision d'AH n.2 du 21/09).
--
-- POURQUOI LA BORNE DE FORME EST EN BASE, ET NON DANS LA PAGE SEULE :
-- file.html AFFICHERA ce lien a un visiteur. Un lien affiche sur une page
-- publique ne doit jamais pouvoir etre arbitraire. Les deux pages rejouent
-- la MEME expression (defense en profondeur), mais c'est la base qui
-- REFUSE.
--
-- POURQUOI UNE COLONNE DEDIEE, ET NON 'slug_existant' : 'slug_existant'
-- veut dire "deja analyse EN PRODUCTION au moment de la demande" (06 le
-- dit deja pour page_pilote). Ici l'adresse est celle de la page PRODUITE
-- POUR la demande. Deux sens, deux colonnes.
--
-- ---------------------------------------------------------------------
-- LES ARBITRAGES D'AH DU 26/09/2026 QUE CE SCRIPT APPLIQUE
-- ---------------------------------------------------------------------
-- (E2) Etape ET adresse changees dans le MEME update : DEUX lignes au
--      journal -- une 'etape', puis une 'adresse' par colonne d'adresse
--      changee. Sans cela, l'adresse posee au passage vers 'traitee' ne
--      laisserait aucune trace de sa valeur.
-- (E3) Une ligne 'adresse' porte, dans 'avant' ET dans 'apres', le texte
--      '<colonne> : <valeur>', et '(nulle)' tient lieu de NUL. La ligne
--      dit donc seule QUELLE colonne a change, dans les deux sens, et
--      'apres' reste 'not null' (05 section 3) sans changer le schema.
-- (E1) Les controles de 02 que cette colonne rend rouges par
--      construction (n.4, 12, 14, 21, 23) sont AMENDES en place, dans le
--      meme lot que ce fichier (regle S-6 du PATRON).
--
-- ---------------------------------------------------------------------
-- ORDRE DES GESTES -- il compte : la BASE d'abord, les PAGES ensuite,
-- R-2 en dernier.
-- ---------------------------------------------------------------------
-- Les pages servies AUJOURD'HUI ignorent une colonne de plus : file.html
-- lit la vue par 'select=*', admin.html la table par 'select=*', et
-- aucune etape neuve n'apparait. A l'inverse, une page privee NEUVE
-- servie AVANT ce script enverrait un PATCH vers une colonne absente.
--
-- 0. DEJA FAIT le 26/09/2026 : la LECTURE du nom de la contrainte sur
--    demandes_journal.geste (05 l'a ecrite EN LIGNE : son nom ne se lit
--    pas au fichier). Requete jouee par AH, en lecture seule :
--      select conname, pg_get_constraintdef(oid) as definition
--        from pg_constraint
--       where conrelid = 'public.demandes_journal'::regclass
--         and contype = 'c'
--       order by conname;
--    Le nom RENDU est celui du 'drop constraint' de la section 6. Rendu
--    du 26/09/2026, 1 ligne : demandes_journal_geste_check |
--    CHECK ((geste = ANY (ARRAY['creation'::text, 'etape'::text]))).
-- 1. CE SCRIPT, par AH, dans le SQL Editor de Supabase (tout
--    selectionner, Run). Attendu : Success, puis le tableau de controle
--    immediat de la fin du fichier, a SIX lignes.
-- 2. PUIS 02-controles-demandes.sql EN ENTIER : trente-et-une lignes,
--    chacune conforme a son attendu, SAUF les trois dont l'attendu
--    commence par 'informatif' (n.6, n.9, n.30).
-- 3. PUIS, UN BLOC A LA FOIS, "Run without RLS" (JAMAIS "Run and enable
--    RLS") : les epreuves P-6 (a), P-6 (b), P-7, P-8 de 02, puis P-5
--    rejouee (le journal ouvert a 'adresse' doit rester fige). Chaque
--    bloc se termine par un compte de restes : attendu 0.
-- 4. PUIS les pages (file.html, admin.html) sont deployees et
--    constatees en ligne.
-- 5. PUIS, et seulement alors, le bloc R-2 ci-dessous, UNE fois.
-- 6. PUIS 02 une seconde fois : le controle n.30 doit rendre 0.
--
-- Si la contrainte de geste ne porte pas le nom ecrit en section 6, le
-- 'drop constraint' echoue, la transaction est annulee, et RIEN ne
-- change : on s'arrete et on le signale.
--
-- ---------------------------------------------------------------------
-- IDEMPOTENCE -- ce qui se rejoue, et ce qui ne se rejoue pas
-- ---------------------------------------------------------------------
-- Se rejouent sans effet de bord : la colonne ('if not exists'), les
-- deux contraintes de page_production ('drop ... if exists' puis 'add'),
-- la vue ('create or replace'), les revoke et les grant, la fonction
-- ('create or replace').
-- La section 6 se rejoue elle aussi : le 'drop constraint' vise le nom
-- que la section repose a l'identique. Le script entier est donc
-- rejouable -- ce qui n'est PAS une invitation a le rejouer.
--
-- Fichier destine a une MACHINE (colle dans l'editeur SQL de Supabase) :
-- UTF-8 SANS BOM, ASCII pur, comme ses voisins.

begin;

-- ---------------------------------------------------------------------
-- 1. LA COLONNE D'ADRESSE DE PRODUCTION.
-- ---------------------------------------------------------------------
-- 'text null' : une demande n'a d'adresse de production que si son
-- analyse est au site. NUL est l'etat normal de la quasi-totalite des
-- lignes -- et une 'traitee' PEUT rester sans adresse (voir section 3).
alter table public.demandes
    add column if not exists page_production text null;

comment on column public.demandes.page_production is
    'Adresse de la page de l analyse sur le site de production www.cdatso.be (BKL-CIN-099, 26/09/2026). Posee par AH SEUL -- page privee au passage vers traitee, ou bloc R-2 de 07. Bornee en FORME et en COHERENCE par deux contraintes. A ne pas confondre avec slug_existant ("deja analyse EN PRODUCTION au moment de la demande") ni avec page_pilote (la page d essai).';

-- ---------------------------------------------------------------------
-- 2. LA BORNE DE FORME -- l'adresse est nulle, ou elle est exactement
--    une page de films du site de production.
-- ---------------------------------------------------------------------
-- L'EXPRESSION EST LA MEME dans les TROIS endroits : ici, dans file.html
-- et dans admin.html. Si l'une des trois change, les trois changent --
-- sinon la page afficherait un lien que la base refuserait, ou
-- l'inverse. La passe D de outils/controler-proprete.mjs compare les
-- trois textes.
--
-- CE QU'ELLE EXIGE, morceau par morceau :
--   ^https://                schema en clair, et lui seul ('http://' est
--                            refuse)
--   www\.cdatso\.be          l'hote EXACT, AVEC 'www' -- le sitemap du
--                            site ecrit 'https://www.cdatso.be/' 59 fois
--                            et jamais sans 'www' (mesure du 21/09) ;
--                            points ECHAPPES : sans echappement, '.'
--                            apparierait n'importe quel caractere
--   /analyses-de-films/films/  le chemin, et lui seul
--   [a-z0-9]+(-[a-z0-9]+)*   le slug : la forme de TOUS les slugs du
--                            registre de production (49 sur 49 le
--                            26/09). Ni majuscule, ni point, ni barre
--                            oblique, ni chaine de requete -- donc '../'
--                            ne peut pas y entrer
--   \.html$                  l'extension, et FIN DE CHAINE
--
-- LE CAS QU'IL FAUT CONNAITRE : UN SAUT DE LIGNE FINAL. PostgreSQL, hors
-- mode "newline-sensitive", fait apparier '$' a la FIN DE CHAINE
-- seulement ; JavaScript sans l'indicateur 'm' de meme ; Python, lui,
-- tolere un saut de ligne terminal. ON NE LE SUPPOSE PAS : l'epreuve
-- P-6 de 02 le mesure ici, et la passe D le mesure en JavaScript.
alter table public.demandes
    drop constraint if exists demandes_page_production_forme_check;

alter table public.demandes
    add constraint demandes_page_production_forme_check check (
        page_production is null
        or page_production ~ '^https://www\.cdatso\.be/analyses-de-films/films/[a-z0-9]+(-[a-z0-9]+)*\.html$');

-- ---------------------------------------------------------------------
-- 3. LA BORNE DE COHERENCE -- SENS UNIQUE.
-- ---------------------------------------------------------------------
-- page_production NON NUL  =>  statut = 'traitee'.
-- Et PAS la reciproque : une 'traitee' PEUT etre sans adresse. C'est ce
-- qui laisse vivre, entre ce script et le bloc R-2, les demandes deja
-- traitees ; et c'est ce qui laisse a la PAGE, non a la base, le soin
-- d'exiger le champ au passage vers 'traitee' (decision d'AH du 26/09 :
-- champ obligatoire dans la page ; convention d'interface, comme la
-- table des transitions).
--
-- 'traitee' n'a aucune sortie dans la page privee : une adresse de
-- production ne s'y retire donc jamais par la page. Si une 'traitee'
-- devait changer d'etape au Table Editor, la base exigerait de remettre
-- l'adresse a NUL dans le meme geste -- c'est le sens de cette borne.
alter table public.demandes
    drop constraint if exists demandes_page_production_coherence_check;

alter table public.demandes
    add constraint demandes_page_production_coherence_check check (
        page_production is null or statut = 'traitee');

-- ---------------------------------------------------------------------
-- 4. LA VUE PUBLIQUE -- 'page_production' ajoutee EN DERNIER.
-- ---------------------------------------------------------------------
-- EN DERNIER, ET CE N'EST PAS UN GOUT : PostgreSQL n'accepte un
-- 'create or replace view' que si les colonnes EXISTANTES gardent leur
-- nom, leur type et leur ORDRE. Une colonne inseree ailleurs qu'a la fin
-- ferait echouer le remplacement -- et il faudrait alors un 'drop view'
-- puis un 'create view', qui, LUI, ferait naitre un objet neuf avec les
-- droits par defaut du schema public (R-023). On evite ce chemin.
--
-- SI LA BASE REFUSAIT MALGRE TOUT ce 'create or replace view' : NE PAS
-- le remplacer par un 'drop view' de sa propre initiative. La
-- transaction est annulee, rien ne change, on s'arrete et on le signale.
--
-- NI 'mail' NI 'motif' : le controle de confidentialite d'origine
-- (arbitrage n.3) est inchange. La vue passe de ONZE a DOUZE colonnes.
create or replace view public.demandes_publiques as
select id,
       created_at,
       titre,
       realisateur,
       annee,
       deja_analyse,
       slug_existant,
       qualification,
       statut,
       decideur,
       page_pilote,
       page_production
  from public.demandes;

-- LES DROITS DE LA VUE, RAPPELES (idempotents) -- les trois lignes de
-- 03-droits-vue-publique.sql, sans un mot de plus, comme en 06. Le
-- controle n.12 de 02 les mesure APRES coup, et le n.22 regarde les
-- droits de COLONNE sur la vue.
revoke insert, update, delete, truncate, references, trigger
    on public.demandes_publiques from anon, authenticated;
revoke select on public.demandes_publiques from authenticated;
grant select on public.demandes_publiques to anon;

-- ---------------------------------------------------------------------
-- 5. LE DROIT D'ECRIRE L'ADRESSE -- par COLONNE, au seul role
--    authenticated.
-- ---------------------------------------------------------------------
-- 06 accordait 'update (statut, page_pilote)'. Un droit de colonne ne
-- s'herite pas de la table : sans cette ligne, le PATCH de la page
-- privee vers 'traitee' -- l'etape ET l'adresse -- serait refuse en
-- entier (42501).
--
-- CE QUI N'EST PAS ACCORDE : ni titre, ni motif, ni mail, ni decideur,
-- ni slug_existant. "La page ne change QUE l'etape et les adresses" --
-- pas un champ de plus. Controles n.12, 14 et 23 de 02.
--
-- LA POLICY 'demandes_ah_etape' N'EST PAS TOUCHEE : elle borne deja les
-- LIGNES au seul compte d'AH. L'UUID d'AH n'apparait nulle part dans ce
-- fichier.
grant update (statut, page_pilote, page_production) on public.demandes to authenticated;

-- ---------------------------------------------------------------------
-- 6. LE JOURNAL, OUVERT AU GESTE 'adresse'.
-- ---------------------------------------------------------------------
-- (a) LA LISTE DE 'geste' ETAIT FERMEE : 05 l. 228 --
--     "geste text not null check (geste in ('creation', 'etape'))".
--     Une ligne 'adresse' y serait refusee, et le declencheur, en
--     echouant, ferait echouer l'update qui l'a appele : la page privee
--     ne pourrait plus rien poser. La liste s'ouvre donc, d'UNE valeur.
--
--     LE NOM DU 'drop' EST CELUI QUE LA BASE A RENDU a la lecture du
--     geste 0 (en tete de ce fichier). S'il ne correspond pas, le 'drop'
--     echoue et la transaction est annulee : rien ne change.
--
--     LA CONTRAINTE REPOSEE PORTE UN NOM ECRIT, et non plus un nom
--     engendre : la prochaine session le lira au fichier.
--
--     CE QUE CE GESTE NE TOUCHE PAS : les deux declencheurs qui FIGENT le
--     journal (06 section 7). Un 'alter table ... add constraint' verifie
--     les lignes existantes, il ne les modifie pas : ni update, ni delete,
--     ni truncate. Le journal reste en ecriture SEULE PAR AJOUT -- P-5,
--     rejouee apres ce script, le prouve.
alter table public.demandes_journal
    drop constraint demandes_journal_geste_check;

alter table public.demandes_journal
    add constraint demandes_journal_geste_check check (
        geste in ('creation', 'etape', 'adresse'));

-- (b) LA FONCTION DE JOURNALISATION -- la branche "adresse".
--
-- CE QUI NE CHANGE PAS : la ligne 'creation' a l'INSERT, et la ligne
-- 'etape' quand le statut change -- a l'identique de 05 section 4a. Le
-- plafond de creation (05 section 4b) ne compte que geste = 'creation' :
-- il n'est pas touche.
--
-- CE QUI S'AJOUTE : a l'UPDATE, une ligne 'adresse' PAR colonne d'adresse
-- qui change -- page_pilote, page_production -- que le statut change
-- aussi ou non (decision E2 d'AH : "Deux lignes").
--
-- CE QUE PORTENT 'avant' ET 'apres' (decision E3 d'AH) :
--     '<colonne> : <valeur>'   et '(nulle)' tient lieu de NUL.
-- 'apres' est 'not null' (05 l. 230) : une adresse remise a NUL s'y ecrit
-- donc '<colonne> : (nulle)', jamais NUL. 'avant' reste nullable par le
-- schema, mais il est rempli de la meme facon, pour que la ligne se lise
-- dans les deux sens.
--
-- 'is distinct from' et non '<>' : '<>' rend NUL -- donc "faux" -- quand
-- l'une des deux valeurs est NULLE, et le passage d'une adresse A NUL ou
-- DEPUIS NUL ne serait jamais trace.
--
-- MEMES PRECAUTIONS qu'en 05 : 'security definer' (le journal n'accorde
-- aucun droit, la fonction ecrit avec ceux de son proprietaire),
-- 'search_path' vide et tout qualifie, schema 'prive' non expose.
create or replace function prive.journaliser_demande()
    returns trigger
    language plpgsql
    security definer
    set search_path = ''
as $fn$
begin
    if tg_op = 'INSERT' then
        insert into public.demandes_journal (demande_id, geste, avant, apres, par)
        values (new.id, 'creation', null, new.statut, auth.uid());
    else
        if new.statut is distinct from old.statut then
            insert into public.demandes_journal (demande_id, geste, avant, apres, par)
            values (new.id, 'etape', old.statut, new.statut, auth.uid());
        end if;
        if new.page_pilote is distinct from old.page_pilote then
            insert into public.demandes_journal (demande_id, geste, avant, apres, par)
            values (new.id, 'adresse',
                    'page_pilote : ' || coalesce(old.page_pilote, '(nulle)'),
                    'page_pilote : ' || coalesce(new.page_pilote, '(nulle)'),
                    auth.uid());
        end if;
        if new.page_production is distinct from old.page_production then
            insert into public.demandes_journal (demande_id, geste, avant, apres, par)
            values (new.id, 'adresse',
                    'page_production : ' || coalesce(old.page_production, '(nulle)'),
                    'page_production : ' || coalesce(new.page_production, '(nulle)'),
                    auth.uid());
        end if;
    end if;
    return new;
end
$fn$;

-- 'create or replace' garde le proprietaire et les droits de la
-- fonction ; on ne le SUPPOSE pas -- les deux lignes de 05 l. 447 et
-- l. 450, rappelees, idempotentes. Le declencheur demandes_journal_trg
-- (05 section 5) n'est pas touche : il appelle la fonction par son nom.
revoke all on function prive.journaliser_demande() from public;
revoke all on function prive.journaliser_demande() from anon, authenticated;

commit;

-- ---------------------------------------------------------------------
-- CONTROLE IMMEDIAT (LECTURE SEULE) -- ce que la transaction a pose.
-- ---------------------------------------------------------------------
-- Attendu, dans l'ordre :
--   colonne page_production ........ text / YES
--   contraintes de page_production . 2 | demandes_page_production_coherence_check, demandes_page_production_forme_check
--   vue : colonnes / derniere ...... 12 / page_production
--   authenticated : UPDATE sur ..... 3 | page_pilote, page_production, statut
--   contrainte de geste ............ CHECK ((geste = ANY (ARRAY['creation'::text, 'etape'::text, 'adresse'::text])))
--   fonction de journal ............ true  (elle nomme 'adresse', les deux colonnes et '(nulle)')
--
-- La recette complete est 02-controles-demandes.sql (trente-et-une
-- lignes), et la PREUVE QUE LES BORNES MORDENT est dans ses blocs P-6,
-- P-7 et P-8. Sans eux, ces six lignes seraient vertes sur des bornes
-- mortes (lecon du 18/09/2026).
select 'colonne page_production : type / nullable' as controle,
       coalesce((select data_type || ' / ' || is_nullable
                   from information_schema.columns
                  where table_schema = 'public' and table_name = 'demandes'
                    and column_name = 'page_production'), '(absente)') as mesure,
       'text / YES' as attendu
union all
select 'contraintes de page_production',
       (select count(*)::text from pg_constraint
         where conrelid = 'public.demandes'::regclass
           and conname in ('demandes_page_production_forme_check',
                           'demandes_page_production_coherence_check'))
       || ' | ' ||
       coalesce((select string_agg(conname, ', ' order by conname)
                   from pg_constraint
                  where conrelid = 'public.demandes'::regclass
                    and conname in ('demandes_page_production_forme_check',
                                    'demandes_page_production_coherence_check')), '(aucune)'),
       '2 | demandes_page_production_coherence_check, demandes_page_production_forme_check'
union all
select 'vue publique : colonnes / derniere',
       (select count(*)::text from information_schema.columns
         where table_schema = 'public' and table_name = 'demandes_publiques')
       || ' / ' ||
       coalesce((select column_name from information_schema.columns
                  where table_schema = 'public' and table_name = 'demandes_publiques'
                  order by ordinal_position desc limit 1), '(aucune)'),
       '12 / page_production'
union all
select 'authenticated : UPDATE sur',
       (select count(*)::text
          from information_schema.columns c
         where c.table_schema = 'public' and c.table_name = 'demandes'
           and has_column_privilege('authenticated'::name, 'public.demandes',
                                    c.column_name::text, 'UPDATE'))
       || ' | ' ||
       coalesce((select string_agg(c.column_name::text, ', ' order by c.column_name)
                   from information_schema.columns c
                  where c.table_schema = 'public' and c.table_name = 'demandes'
                    and has_column_privilege('authenticated'::name, 'public.demandes',
                                             c.column_name::text, 'UPDATE')), '(aucune)'),
       '3 | page_pilote, page_production, statut'
union all
select 'contrainte de geste',
       coalesce((select pg_get_constraintdef(oid) from pg_constraint
                  where conrelid = 'public.demandes_journal'::regclass
                    and conname = 'demandes_journal_geste_check'), '(absente)'),
       'trois valeurs : creation, etape, adresse'
union all
select 'fonction de journal : branche adresse',
       coalesce((select (pg_get_functiondef(p.oid) like '%''adresse''%'
                         and pg_get_functiondef(p.oid) like '%page_production%'
                         and pg_get_functiondef(p.oid) like '%page_pilote%'
                         and pg_get_functiondef(p.oid) like '%(nulle)%')::text
                   from pg_proc p
                   join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'prive' and p.proname = 'journaliser_demande'), '(absente)'),
       'true';

-- ---------------------------------------------------------------------
-- R-2 -- GESTE UNIQUE DE REPRISE, en commentaire.
-- A jouer par AH APRES le reste (ordre des gestes, point 5), UNE SEULE
-- FOIS : les pages portant le lien de production sont deployees et
-- constatees en ligne.
-- ---------------------------------------------------------------------
-- POURQUOI. Quatre demandes sont DEJA en 'traitee' quand ce script est
-- joue ; 'traitee' n'a aucune sortie dans la page privee, donc la page
-- ne leur posera jamais d'adresse. Decision d'AH du 21/09/2026, verbatim :
-- "Bloc SQL R-2, une fois". La LISTE a ete re-mesuree le 26/09/2026 sur
-- la vue publique (4 lignes en 'traitee') et CONFIRMEE PAR AH, une
-- demande a la fois, avec chaque adresse :
--   n.2   Le Chateau ambulant          le-chateau-ambulant
--   n.3   Les Tontons-Flingueurs       les-tontons-flingueurs
--   n.5   Le bonheur est dans le pre   le-bonheur-est-dans-le-pre
--   n.37  Ballet mecanique             ballet-mecanique
-- Chaque page a rendu 200 le 26/09/2026. La n.37, passee en 'traitee' le
-- 21/09 au soir, n'etait pas au cadrage : elle est au mandat.
--
-- CE QU'IL LAISSERA AU JOURNAL, ET C'EST ATTENDU : QUATRE lignes
-- 'adresse', une par demande, 'avant' = 'page_production : (nulle)',
-- 'apres' = 'page_production : <l adresse>', avec 'par' A NUL -- le
-- tableau de bord Supabase n'est pas un compte authentifie (05, erratum
-- du 19/09). AUCUNE ligne 'etape' : le statut ne change pas.
--
-- LES FILTRES 'statut = traitee' ET 'page_production is null' NE SONT
-- PAS DECORATIFS : si une demande a bouge, ou a deja son adresse, elle
-- n'est PAS touchee -- et le bloc (b) le dit en rendant MOINS de quatre
-- lignes, au lieu d'ecraser un etat qu'on n'a pas sous les yeux.
-- UNE SEULE INSTRUCTION : les quatre passent ensemble, ou aucune (une
-- adresse hors forme ferait echouer le tout, par la contrainte de la
-- section 2).
--
-- (a) LECTURE prealable -- attendu : 4 lignes, statut 'traitee',
--     page_production a NUL partout (la n.2 porte encore sa page_pilote :
--     c'est la memoire de son essai, elle ne bouge pas).
--
-- select id, titre, statut, page_pilote, page_production
--   from public.demandes
--  where id in (2, 3, 5, 37)
--  order by id;
--
-- (b) Le geste lui-meme -- attendu : 4 lignes rendues par 'returning',
--     chacune avec SON adresse.
--
-- update public.demandes as d
--    set page_production = v.adresse
--   from (values
--     (2,  'https://www.cdatso.be/analyses-de-films/films/le-chateau-ambulant.html'),
--     (3,  'https://www.cdatso.be/analyses-de-films/films/les-tontons-flingueurs.html'),
--     (5,  'https://www.cdatso.be/analyses-de-films/films/le-bonheur-est-dans-le-pre.html'),
--     (37, 'https://www.cdatso.be/analyses-de-films/films/ballet-mecanique.html')
--   ) as v(id, adresse)
--  where d.id = v.id
--    and d.statut = 'traitee'
--    and d.page_production is null
-- returning d.id, d.titre, d.statut, d.page_production;
--
-- (c) LECTURE de constat -- attendu : 4 lignes, 'traitee', chacune avec
--     son adresse ; puis QUATRE lignes de journal 'adresse', 'par' NUL.
--     L'UUID ne s'affiche JAMAIS : on lit 'par is not null', pas 'par'.
--
-- select id, titre, statut, page_production
--   from public.demandes
--  where id in (2, 3, 5, 37)
--  order by id;
--
-- select id, demande_id, geste, avant, apres, par is not null as par_non_nul, a
--   from public.demandes_journal
--  where demande_id in (2, 3, 5, 37)
--    and geste = 'adresse'
--  order by id desc
--  limit 8;
--
-- ---------------------------------------------------------------------
-- RETOUR ARRIERE -- en commentaire, a ne jouer que sur decision d'AH.
-- ---------------------------------------------------------------------
-- CONDITION DE VALIDITE : aucune ligne ne porte d'adresse de production.
-- Sinon il faut d'abord qu'AH decide du sort de ces adresses (une remise
-- a NUL au Table Editor laisse, elle aussi, sa ligne 'adresse' au
-- journal).
--
-- (a) LECTURE prealable -- attendu : 0.
--
-- select count(*) as avec_adresse_de_production
--   from public.demandes
--  where page_production is not null;
--
-- (b) Le retour arriere lui-meme, si (a) rend 0.
--
-- CE QUI NE SE DEFAIT PAS : les lignes 'adresse' deja ecrites au journal.
-- Il est FIGE (06 section 7) : on ne les efface pas, et la contrainte de
-- 'geste' GARDE donc ses trois valeurs -- la reposer a deux valeurs
-- echouerait sur ces lignes (une contrainte se verifie sur TOUTES les
-- lignes). Elle ne se rend a deux valeurs que si le journal ne porte
-- AUCUNE ligne 'adresse' (lecture : select count(*) from
-- public.demandes_journal where geste = 'adresse' -- attendu 0).
--
-- LA VUE DOIT PERDRE UNE COLONNE, et 'create or replace view' NE SAIT
-- PAS en retirer une (PostgreSQL refuse : "cannot drop columns from
-- view"). Il faut donc ICI, et ici seulement, 'drop view' puis 'create
-- view' -- d'ou le RAPPEL des droits juste apres, sans lequel la vue
-- renaitrait exposee (R-023). C'est le seul 'drop view' de ce fichier,
-- et il est en commentaire.
--
-- begin;
--
-- -- La fonction, rendue a son texte de 05 section 4a.
-- create or replace function prive.journaliser_demande()
--     returns trigger
--     language plpgsql
--     security definer
--     set search_path = ''
-- as $fn$
-- begin
--     if tg_op = 'INSERT' then
--         insert into public.demandes_journal (demande_id, geste, avant, apres, par)
--         values (new.id, 'creation', null, new.statut, auth.uid());
--     elsif new.statut is distinct from old.statut then
--         insert into public.demandes_journal (demande_id, geste, avant, apres, par)
--         values (new.id, 'etape', old.statut, new.statut, auth.uid());
--     end if;
--     return new;
-- end
-- $fn$;
-- revoke all on function prive.journaliser_demande() from public;
-- revoke all on function prive.journaliser_demande() from anon, authenticated;
--
-- alter table public.demandes
--     drop constraint if exists demandes_page_production_coherence_check;
-- alter table public.demandes
--     drop constraint if exists demandes_page_production_forme_check;
--
-- drop view public.demandes_publiques;
-- create view public.demandes_publiques as
-- select id, created_at, titre, realisateur, annee, deja_analyse,
--        slug_existant, qualification, statut, decideur, page_pilote
--   from public.demandes;
-- revoke all on public.demandes_publiques from anon, authenticated;
-- grant select on public.demandes_publiques to anon;
--
-- alter table public.demandes drop column if exists page_production;
--
-- -- Le droit de colonne disparait AVEC la colonne ; ceux de 'statut' et
-- -- de 'page_pilote' sont reposes pour que la page privee continue.
-- grant update (statut, page_pilote) on public.demandes to authenticated;
--
-- commit;
--
-- Puis : rejouer 02 (attendu : le n.4 a '11 / 13' et les n.12, 14, 21,
-- 23, 25 a 30 ROUGES -- 02, file.html, admin.html,
-- outils/controler-proprete.mjs, le guide et le README se rendent a leur
-- etat du commit 8a57989, et le service se repousse par pull request).
-- Le linter Supabase signalera de nouveau "security definer view" sur la
-- vue recreee : c'est ATTENDU (PATRON regle D-3), ne pas le "corriger".
