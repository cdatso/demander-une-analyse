-- 08-etape-archivee.sql
-- Ajoute la NEUVIEME valeur de statut, 'archivee', et sa borne EN BASE
-- (une demande archivee n'a aucune adresse) ; RETIRE de la vue publique
-- les lignes a cette etape. La ligne reste dans la table, et sa trace au
-- journal : on ne supprime rien.
-- BKL-CIN-092 lot "etape archivee" (reste R8 de BKL-CIN-099), 26/09/2026.
--
-- !!! CE SCRIPT NE CONTIENT NI 'drop table', NI 'drop view', NI AUCUN
-- !!! 'drop' SUR LA TABLE : C'EST LUI, ET NON 01-table-demandes.sql, QUI
-- !!! SE JOUE SUR LA BASE EN PRODUCTION. 01 commence par 'drop view' puis
-- !!! 'drop table' : le rejouer en production DETRUIRAIT toutes les
-- !!! demandes.
-- !!! Les seuls 'drop' ci-dessous portent sur des CONTRAINTES, aussitot
-- !!! reposees dans la meme transaction. La vue est remplacee par
-- !!! 'create or replace view' -- elle n'est PAS detruite, et aucun objet
-- !!! ne nait donc expose par les droits par defaut du schema public
-- !!! (R-023, pg_default_acl). Ses droits sont malgre tout RAPPELES plus
-- !!! bas : on les prouve par controle, on ne les suppose pas.
-- !!! ET 03-droits-vue-publique.sql NE SE REJOUE JAMAIS : son 'revoke all'
-- !!! sur la table emporterait les droits de colonne que 05, 06 et 07
-- !!! accordent a la page privee.
--
-- ---------------------------------------------------------------------
-- POURQUOI (BKL-CIN-092 ; note de preparation du greffe, 26/09/2026)
-- ---------------------------------------------------------------------
-- Une demande indesirable ou d'essai n'avait que deux sorts : rester en
-- 'mise_de_cote' -- VISIBLE sur la file publique, la vue n'ayant aucun
-- 'where' -- ou etre SUPPRIMEE par SQL, la page privee n'ayant, par
-- conception, aucun droit de suppression. Le 26/09/2026, deux demandes
-- d'essai ont du etre supprimees ainsi. 'archivee' est la troisieme voie :
-- la ligne et sa trace restent, la file publique ne la montre plus.
--
-- ---------------------------------------------------------------------
-- LES DECISIONS D'AH QUE CE SCRIPT APPLIQUE
-- ---------------------------------------------------------------------
-- Du 26/09/2026, au gate du mandat -- elles ne se rouvrent pas :
--   (1) l'etape existe et s'appelle 'archivee' ;
--   (2) AUCUN archivage depuis 'traitee' ("Traitees" reste sans sortie) ;
--   (3) l'archivage se fait depuis 'mise_de_cote' SEULEMENT.
-- (2) et (3) sont des CONVENTIONS D'INTERFACE, tenues par la table des
-- transitions de admin.html (decision d'AH du 18/09/2026 : les
-- transitions vivent dans la page, pas en base). La base, elle, garde ce
-- qui doit l'etre quel que soit le chemin : l'etape existe, une archivee
-- n'a pas d'adresse, et la vue ne la montre pas.
--
-- Du 26/09/2026, a l'execution (elicitation, option recommandee) :
--   (4) la vue est REMPLACEE par 'create or replace view', et non
--       detruite puis recreee. Ajouter un 'where' ne change ni le nom, ni
--       le type, ni l'ORDRE des douze colonnes : PostgreSQL l'accepte, et
--       c'est la doctrine de 06 et de 07 (R-023).
--   (5) le controle n.7 de 02 est AMENDE en place (neuf valeurs).
--
-- ---------------------------------------------------------------------
-- ORDRE DES GESTES -- il compte : la BASE d'abord, les PAGES ensuite.
-- ---------------------------------------------------------------------
-- Les pages servies AUJOURD'HUI ne connaissent pas 'archivee' ; aucune
-- ligne ne la porte tant que la page privee ne l'a pas posee, et la vue
-- ne la rendra jamais a file.html. A l'inverse, une page privee NEUVE
-- servie AVANT ce script proposerait "Archivees" et la base REFUSERAIT le
-- PATCH (contrainte de statut) : sans dommage, mais sans effet.
--
-- 1. CE SCRIPT, par AH, dans le SQL Editor de Supabase (tout
--    selectionner, Run). Attendu : Success, puis le tableau de controle
--    immediat de la fin du fichier, a SEPT lignes.
-- 2. PUIS 02-controles-demandes.sql EN ENTIER : trente-six lignes (n.0 a
--    35), chacune conforme a son attendu, SAUF celles dont l'attendu
--    commence par 'informatif' (n.6, n.9, n.30, n.35) -- et le n.11, en
--    ecart connu (E9 de BKL-CIN-099, hors de ce lot).
-- 3. PUIS, UN BLOC A LA FOIS, "Run without RLS" (JAMAIS "Run and enable
--    RLS") : les epreuves P-9 (a), P-9 (b), P-9 (c) de 02. Chaque bloc
--    se termine par un compte de restes : attendu 0.
-- 4. PUIS la page privee (admin.html) est deployee et constatee en ligne.
--    file.html ne change pas : c'est la vue qui fait le travail.
--
-- Si la contrainte de statut ne porte pas le nom ecrit en section 1, le
-- 'drop constraint' echoue, la transaction est annulee, et RIEN ne
-- change : on s'arrete et on le signale.
-- SI LA BASE REFUSAIT le 'create or replace view' de la section 3 : NE
-- PAS le remplacer par un 'drop view' de sa propre initiative. La
-- transaction est annulee, rien ne change, on s'arrete et on le signale.
--
-- ---------------------------------------------------------------------
-- IDEMPOTENCE
-- ---------------------------------------------------------------------
-- Se rejouent sans effet de bord : la contrainte de statut ('drop' puis
-- 'add', a l'identique), la contrainte "sans adresse" ('drop ... if
-- exists' puis 'add'), la vue ('create or replace'), les revoke et le
-- grant. Le script entier est donc rejouable -- ce qui n'est PAS une
-- invitation a le rejouer.
--
-- Fichier destine a une MACHINE (colle dans l'editeur SQL de Supabase) :
-- UTF-8 SANS BOM, ASCII pur, comme ses voisins.

begin;

-- ---------------------------------------------------------------------
-- 1. LA NEUVIEME VALEUR DE STATUT -- le geste de 06, a l'identique.
-- ---------------------------------------------------------------------
-- Les HUIT valeurs de 06 l. 129-131 sont conservees, dans leur ordre ;
-- 'archivee' vient en NEUVIEME et derniere : c'est la fin de vie d'une
-- demande non retenue, apres 'mise_de_cote'.
--
-- CYCLE DE VIE AJOUTE (convention de la page privee, pas borne de la
-- base) :
--   ... -> mise_de_cote -> archivee   (sans sortie depuis la page)
-- Le retour, s'il le faut, se fait au Table Editor -- comme pour
-- 'traitee'.
alter table public.demandes
    drop constraint demandes_statut_check;

alter table public.demandes
    add constraint demandes_statut_check check (statut in (
        'proposee', 'a_traiter', 'publication_pilote', 'publiee_pilote',
        'scholar', 'candidat', 'mise_de_cote', 'traitee', 'archivee'));

-- ---------------------------------------------------------------------
-- 2. LA BORNE "SANS ADRESSE" -- une archivee n'a ni page d'essai, ni
--    page de production.
-- ---------------------------------------------------------------------
-- CE QU'ELLE AJOUTE, ET CE QU'ELLE N'AJOUTE PAS. Les bornes de coherence
-- de 06 (page_pilote non nulle => publiee_pilote ou traitee) et de 07
-- (page_production non nulle => traitee) interdisent DEJA une adresse a
-- une archivee. Celle-ci le dit EN UN NOM, du cote de l'etape : un refus
-- cite 'demandes_archivee_sans_adresse_check', et la regle survit si
-- l'une des deux autres venait a s'elargir un jour. C'est une borne de
-- plus sur la meme verite, pas une verite neuve -- et l'epreuve P-9 (a)
-- de 02 mesure qu'elle MORD.
--
-- POURQUOI C'EST VRAI DES LA POSE : aucune ligne ne porte 'archivee'
-- avant ce script ; l'ajout verifie toutes les lignes, et n'en trouve
-- aucune a refuser.
alter table public.demandes
    drop constraint if exists demandes_archivee_sans_adresse_check;

alter table public.demandes
    add constraint demandes_archivee_sans_adresse_check check (
        statut <> 'archivee'
        or (page_pilote is null and page_production is null));

-- ---------------------------------------------------------------------
-- 3. LA VUE PUBLIQUE -- les archivees n'y sont plus.
-- ---------------------------------------------------------------------
-- LES DOUZE COLONNES DE 07 l. 207-220, DANS LE MEME ORDRE, SANS UNE DE
-- PLUS : seule la clause 'where' est neuve. C'est ce qui permet le
-- 'create or replace' (decision (4) ci-dessus) : PostgreSQL remplace la
-- requete d'une vue pourvu que ses colonnes gardent nom, type et ordre.
--
-- 'statut <> ...' ET NON 'statut is distinct from ...' : 'statut' est
-- 'not null' (01 l. 113), les deux ecritures rendent les memes lignes ;
-- la plus simple se lit mieux au controle n.32 de 02.
--
-- CE QUE CE 'where' FAIT A file.html : une demande archivee disparait de
-- la file publique -- elle ne tombe PAS dans "etape inconnue", puisque la
-- page ne la recoit plus. file.html ne change pas d'un octet.
--
-- NI 'mail' NI 'motif' : le controle de confidentialite d'origine
-- (arbitrage n.3) est inchange.
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
  from public.demandes
 where statut <> 'archivee';

-- LES DROITS DE LA VUE, RAPPELES (idempotents) -- les trois lignes de
-- 07 l. 226-229, a l'octet, comme 07 les tenait de 06 et de 03. Les
-- controles n.12 et n.22 de 02 les mesurent APRES coup.
revoke insert, update, delete, truncate, references, trigger
    on public.demandes_publiques from anon, authenticated;
revoke select on public.demandes_publiques from authenticated;
grant select on public.demandes_publiques to anon;

-- ---------------------------------------------------------------------
-- CE QUE CE SCRIPT NE TOUCHE PAS -- et pourquoi il n'en a pas besoin.
-- ---------------------------------------------------------------------
-- * LES DROITS DE LA PAGE PRIVEE : 07 accorde deja 'update (statut,
--   page_pilote, page_production)'. Le PATCH vers 'archivee' n'ecrit que
--   ces trois colonnes. Aucun 'delete' n'est accorde, ni ici ni ailleurs.
-- * LES POLICIES : elles bornent le COMPTE (l'UUID d'AH), pas l'etape.
--   L'UUID d'AH n'apparait nulle part dans ce fichier.
-- * LE JOURNAL : prive.journaliser_demande() (07 section 6) ecrit deja
--   une ligne 'etape' a tout changement de statut -- donc
--   'mise_de_cote -> archivee' -- et une ligne 'adresse' SEULEMENT si une
--   adresse change. Une demande en 'mise_de_cote' n'en porte aucune : le
--   PATCH d'archivage, qui les pose a NUL, n'ecrit donc qu'UNE ligne,
--   'etape'. L'epreuve P-9 (c) le mesure.

commit;

-- ---------------------------------------------------------------------
-- CONTROLE IMMEDIAT (LECTURE SEULE) -- ce que la transaction a pose.
-- ---------------------------------------------------------------------
-- Attendu, dans l'ordre :
--   contrainte de statut ............ neuf valeurs, archivee en dernier
--   contrainte "sans adresse" ....... 1 | demandes_archivee_sans_adresse_check
--   vue : colonnes / derniere ....... 12 / page_production
--   vue : la clause qui retire ...... true
--   vue : lignes archivee rendues ... 0
--   anon sur la vue ................. true / 0   (SELECT ; ecritures)
--   authenticated : SELECT sur vue .. false
--
-- La recette complete est 02-controles-demandes.sql (trente-six lignes),
-- et la PREUVE QUE LES BORNES MORDENT est dans ses blocs P-9 (a), (b) et
-- (c). Sans eux, ces sept lignes seraient vertes sur des bornes mortes
-- (lecon du 18/09/2026).
select 'contrainte de statut' as controle,
       coalesce((select pg_get_constraintdef(oid) from pg_constraint
                  where conrelid = 'public.demandes'::regclass
                    and conname = 'demandes_statut_check'), '(absente)') as mesure,
       'neuf valeurs, archivee en dernier' as attendu
union all
select 'contrainte archivee sans adresse',
       (select count(*)::text from pg_constraint
         where conrelid = 'public.demandes'::regclass
           and conname = 'demandes_archivee_sans_adresse_check')
       || ' | ' ||
       coalesce((select conname::text from pg_constraint
                  where conrelid = 'public.demandes'::regclass
                    and conname = 'demandes_archivee_sans_adresse_check'), '(aucune)'),
       '1 | demandes_archivee_sans_adresse_check'
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
select 'vue publique : la clause qui retire les archivees',
       (pg_get_viewdef('public.demandes_publiques'::regclass) like '%<> ''archivee''%')::text,
       'true'
union all
select 'vue publique : lignes archivee rendues',
       (select count(*)::text from public.demandes_publiques where statut = 'archivee'),
       '0'
union all
select 'anon sur la vue : SELECT / ecritures',
       has_table_privilege('anon'::name, 'public.demandes_publiques', 'SELECT')::text
       || ' / ' ||
       (select count(*)::text
          from (values ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'),
                       ('REFERENCES'), ('TRIGGER')) as p(privilege)
         where has_table_privilege('anon'::name, 'public.demandes_publiques',
                                   p.privilege)),
       'true / 0'
union all
select 'authenticated : SELECT sur la vue',
       has_table_privilege('authenticated'::name, 'public.demandes_publiques', 'SELECT')::text,
       'false';

-- ---------------------------------------------------------------------
-- RETOUR ARRIERE -- en commentaire, a ne jouer que sur decision d'AH.
-- ---------------------------------------------------------------------
-- CONDITION DE VALIDITE : aucune ligne ne porte 'archivee'. Sinon le
-- 'add constraint' a huit valeurs echoue (une contrainte se verifie sur
-- TOUTES les lignes), la transaction est annulee, et l'etat a neuf
-- valeurs reste en place : il faut d'abord qu'AH decide du sort de ces
-- demandes (au Table Editor ; chaque changement d'etape y laisse sa
-- ligne 'etape' au journal).
--
-- (a) LECTURE prealable -- attendu : 0.
--
-- select count(*) as archivees
--   from public.demandes
--  where statut = 'archivee';
--
-- (b) Le retour arriere lui-meme, si (a) rend 0.
--
-- CE QUI NE SE DEFAIT PAS : les lignes 'etape' deja ecrites au journal
-- (vers ou depuis 'archivee'). Il est FIGE (06 section 7) : on ne les
-- efface pas. Elles ne genent aucune contrainte : 'avant' et 'apres' ne
-- sont bornes a aucune liste d'etapes.
--
-- LA VUE, rendue a sa requete de 07 -- sans 'where' -- par 'create or
-- replace' : les douze colonnes ne changent pas, la vue n'est pas
-- detruite, et ses droits sont rappeles a l'identique.
--
-- begin;
--
-- create or replace view public.demandes_publiques as
-- select id, created_at, titre, realisateur, annee, deja_analyse,
--        slug_existant, qualification, statut, decideur, page_pilote,
--        page_production
--   from public.demandes;
-- revoke insert, update, delete, truncate, references, trigger
--     on public.demandes_publiques from anon, authenticated;
-- revoke select on public.demandes_publiques from authenticated;
-- grant select on public.demandes_publiques to anon;
--
-- alter table public.demandes
--     drop constraint if exists demandes_archivee_sans_adresse_check;
--
-- alter table public.demandes drop constraint demandes_statut_check;
-- alter table public.demandes
--     add constraint demandes_statut_check check (statut in (
--         'proposee', 'a_traiter', 'publication_pilote', 'publiee_pilote',
--         'scholar', 'candidat', 'mise_de_cote', 'traitee'));
--
-- commit;
--
-- Puis : rejouer le controle immediat ci-dessus (attendu : huit valeurs,
-- 0 contrainte "sans adresse", 12 / page_production, false, 0, true / 0,
-- false), rendre 02-controles-demandes.sql, admin.html,
-- outils/controler-proprete.mjs, le guide et le README a leur etat du
-- commit aaf4956, et repousser le service par pull request. Le rejeu de
-- 02 rend alors les n.31 a 33 ROUGES par construction.
