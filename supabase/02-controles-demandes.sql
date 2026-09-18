-- 02-controles-demandes.sql
-- Recette de la table demandes et de la vue demandes_publiques, APRES
-- avoir joue 01-table-demandes.sql et soumis les deux demandes du
-- critere de sortie de la fiche A.
-- Prototype d'apprentissage BKL-FOR-006.
--
-- FORME CONSOLIDEE, reprise de FOR-003 (02-controles.sql, gate AH du
-- 20/08/2026) et de FOR-004 : le SQL Editor de Supabase n'affiche que le
-- resultat de la DERNIERE requete d'un script. Une requete par controle
-- n'afficherait donc que le dernier. Les DIX-NEUF controles rendent ici UN
-- SEUL tableau -- colonnes ordre / controle / mesure / attendu -- et
-- chaque controle porte AUSSI son attendu en commentaire, juste au-dessus
-- de sa ligne, comme l'exige le mandat.
--
-- HISTORIQUE DU NOMBRE : douze jusqu'au 16/09/2026 ; treize au lot 0
-- (controle n.12, droits par defaut, R-023) ; DIX-NEUF au lot 2 du
-- 18/09/2026 -- le n.1 et le n.12 AMENDES par la posture W2, et SIX
-- controles neufs (n.13 a n.18) pour la page privee.
--
-- REGLE DE LECTURE : un controle est vert quand la MESURE satisfait
-- l'ATTENDU de la meme ligne. Un controle sans attendu ne controle rien.
--
-- A jouer TEL QUEL (tout selectionner, Run). Joue sur une table vide, il
-- rend des zeros aux controles de contenu : c'est correct et cela se lit
-- -- le controle 5 a 0 ligne signifie "aucune demande recue", pas
-- "panne". Les controles 0 a 4, 10, et 12 a 18, eux, sont vrais des la
-- creation -- ceux de la posture ne dependent d'aucune donnee.
--
-- LES CONTROLES 1 ET 12 A 18 SUPPOSENT QUE 05-page-privee-w2.sql A ETE
-- JOUE. Avant lui, le n.1 rend '0' (et non '3'), et les n.13 a 18 sont
-- rouges ou vides : ce n'est pas une panne, c'est l'ordre des gestes.
--
-- CE QUE CE SCRIPT NE PROUVE PAS, et qui se prouve ailleurs : que la
-- clef PUBLIABLE lit bien la vue et ne lit PAS la table. Cette mesure
-- passe par l'API, pas par l'editeur SQL (qui emprunte une voie
-- privilegiee et voit tout) : c'est le geste 11 du GUIDE-TEST-EN-LIGNE.
--
-- Fichier destine a une MACHINE (colle dans l'editeur SQL) : UTF-8 SANS
-- BOM, derogation nommee du mandat rubrique 6.

select 0 as ordre,
       'RLS activee sur public.demandes' as controle,
       -- attendu : true -- la table porte mail et motif, elle reste close
       (select relrowsecurity::text from pg_class
         where oid = 'public.demandes'::regclass) as mesure,
       'true' as attendu

union all
select 1,
       'nombre de policies sur demandes',
       -- attendu : 3 -- AMENDE LE 18/09/2026 (BKL-CIN-096 (b) lot 2,
       -- posture W2, script 05-page-privee-w2.sql). L'attendu etait '0'
       -- depuis l'origine : "AUCUNE policy, pas une seule", parce que
       -- l'ecriture venait de la clef secrete SEULE et la lecture de la
       -- vue. La page privee ouvre un SECOND chemin d'ecriture, celui
       -- d'AH authentifie, et ce chemin est borne par TROIS policies
       -- NOMINATIVES : demandes_ah_lecture, demandes_ah_etape,
       -- demandes_ah_creation. Trois, pas une de plus : le controle n.17
       -- verifie en outre qu'elles ne nomment qu'UN SEUL UUID.
       -- La regle D-1 du PATRON-SERVICE-SERVERLESS ("RLS activee, aucune
       -- policy") cesse de decrire ce service le jour ou 05 est joue ;
       -- son amendement est un geste du greffe, pas de ce fichier.
       (select count(*)::text from pg_policies
         where schemaname = 'public' and tablename = 'demandes'),
       '3'

union all
select 2,
       'la vue demandes_publiques existe',
       -- attendu : 1 -- sans elle, file.html n'a rien a lire
       (select count(*)::text from information_schema.views
         where table_schema = 'public' and table_name = 'demandes_publiques'),
       '1'

union all
select 3,
       'colonnes mail ou motif exposees par la vue',
       -- attendu : 0 -- LE CONTROLE DE CONFIDENTIALITE cote schema
       -- (arbitrage n.3) : la vue ne montre ni l'adresse du demandeur,
       -- ni son texte libre
       (select count(*)::text from information_schema.columns
         where table_schema = 'public'
           and table_name = 'demandes_publiques'
           and column_name in ('mail', 'motif')),
       '0'

union all
select 4,
       'colonnes de la vue / de la table',
       -- attendu : 10 / 12 -- douze champs a la table (fiche A), dix a la
       -- vue : mail et motif retires
       (select count(*)::text from information_schema.columns
         where table_schema = 'public' and table_name = 'demandes_publiques')
       || ' / ' ||
       (select count(*)::text from information_schema.columns
         where table_schema = 'public' and table_name = 'demandes'),
       '10 / 12'

union all
select 5,
       'nombre de demandes',
       -- attendu : au moins 1 apres le critere de sortie -- la demande du
       -- film ABSENT est inseree ; celle des Tontons flingueurs NE DOIT
       -- PAS l'etre (deja analysee : aucun appel, aucun insert)
       (select count(*)::text from public.demandes),
       'au moins 1'

union all
select 6,
       'demandes du jour',
       -- attendu : au moins 1 le jour du test -- 0 signifierait que
       -- l'insert n'a pas eu lieu, et l'accuse recu par le visiteur ne
       -- doit alors PAS avoir annonce un enregistrement
       (select count(*)::text from public.demandes
         where created_at::date = current_date),
       'au moins 1'

union all
select 7,
       'statuts hors des sept valeurs',
       -- attendu : 0 -- la contrainte demandes_statut_check le garantit ;
       -- ce controle verifie qu'elle est bien en place et non desactivee.
       -- Sept valeurs depuis BKL-CIN-096 (b) lot 1 : publication_pilote
       -- (A10, Q2, 16/09/2026), jouee en production par
       -- 04-etape-publication-pilote.sql.
       (select count(*)::text from public.demandes
         where statut not in ('proposee', 'a_traiter', 'publication_pilote',
                              'scholar', 'candidat', 'mise_de_cote',
                              'traitee')),
       '0'

union all
select 8,
       'contrainte de statut presente',
       -- attendu : 1 -- sans elle, n'importe quelle chaine entrerait,
       -- y compris un statut invente
       (select count(*)::text from pg_constraint
         where conrelid = 'public.demandes'::regclass
           and conname = 'demandes_statut_check'),
       '1'

union all
select 9,
       'lignes posees par l IA hors proposee',
       -- attendu : 0 -- BORNE : l'IA ne propose JAMAIS de statut ; toute
       -- ligne dont le decideur est AH et le statut autre que proposee a
       -- ete deplacee A LA MAIN par AH, ce qui est la regle. Ce controle
       -- se lit donc AVANT tout arbitrage manuel ; apres, il compte les
       -- deplacements d AH et cesse d etre un controle de borne.
       (select count(*)::text from public.demandes
         where statut <> 'proposee'),
       '0 avant tout arbitrage manuel d AH'

union all
select 10,
       'doublons (titre normalise + annee)',
       -- attendu : 0 sur un test propre -- mais un doublon n'est PAS un
       -- defaut du service : le meme film demande deux fois donne DEUX
       -- lignes, et la deduplication est un geste d AH (cas limite
       -- tranche par le mandat). Ce controle MESURE, il n'accuse pas.
       (select coalesce(sum(n - 1), 0)::text
          from (select count(*) as n
                  from public.demandes
                 group by lower(btrim(titre)), annee
                having count(*) > 1) as d),
       '0 sur un test propre'

union all
select 11,
       'derniere demande (relecture)',
       -- attendu : la demande du film ABSENT, statut proposee, decideur
       -- AH, deja_analyse false, et une qualification JSON non vide
       -- portant volet / genreBase / sources_probables / difficulte.
       -- '(vide)' a la place d un champ signale un champ NULL CONSERVE,
       -- ce qui est la regle (aucune donnee devinee) et non un defaut.
       (select coalesce(titre, '?')
               || ' | ' || coalesce(realisateur, '(vide)')
               || ' | ' || coalesce(annee::text, '(vide)')
               || ' | statut=' || statut
               || ' | decideur=' || decideur
               || ' | deja_analyse=' || deja_analyse::text
               || ' | qualification=' || coalesce(qualification::text, '(vide)')
          from public.demandes
         order by created_at desc
         limit 1),
       'le film absent, proposee, AH, false, qualification renseignee'

union all
select 12,
       'droits d anon et d authenticated (vue d ensemble)',
       -- attendu : 0 / 0 / 0 / true / true
       --
       -- AMENDE LE 18/09/2026 (BKL-CIN-096 (b) lot 2, posture W2). Sa
       -- version du lot 0 attendait 0 SELECT d'authenticated sur la
       -- TABLE : le script 05 le lui ACCORDE, et ce controle serait donc
       -- devenu ROUGE PAR CONSTRUCTION. Il s'annoncait lui-meme, l. 188 de
       -- sa version precedente. Le voici reecrit.
       --
       -- (i)   anon : nombre de privileges de TABLE detenus sur demandes
       --       OU sur demandes_publiques, hors son SELECT sur la vue -> 0.
       --       anon est la clef publiable, en clair dans file.html : il ne
       --       doit RIEN pouvoir d'autre que lire la vue.
       -- (ii)  authenticated : privileges de TABLE qu'il ne doit PAS
       --       detenir -- DELETE, TRUNCATE, TRIGGER sur la table, et les
       --       SEPT sur la vue (arbitrage "option 1" du lot 0 : la page
       --       privee lit la TABLE, pas la vue) -> 0.
       -- (iii) authenticated : ecarts entre les droits de COLONNE detenus
       --       et les droits ACCORDES par 05 -- en trop et en moins
       --       confondus -> 0. Le detail nomme est au controle n.14.
       -- (iv)  authenticated detient SELECT sur la table -> true (sans
       --       lui, la page privee n'affiche rien).
       -- (v)   anon garde SELECT sur la vue -> true (sans lui, file.html
       --       ne lit plus rien et la file publique est vide).
       --
       -- MESURE : has_table_privilege pour les droits de TABLE (il compte
       -- AUSSI les droits herites d'un role et ceux accordes a PUBLIC),
       -- has_column_privilege pour les droits de COLONNE. Les deux sont
       -- necessaires : has_table_privilege ne voit PAS un grant de
       -- colonne, et c'est precisement la forme que prend W2.
       -- information_schema.role_table_grants (requete G-1, bloc optionnel
       -- plus bas) ne voit que les droits DIRECTS : G-1 reste la lecture
       -- croisee, pas le controle.
       (select count(*)::text
          from (values ('public.demandes'), ('public.demandes_publiques')) as o(objet)
         cross join (values ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'),
                            ('REFERENCES'), ('TRIGGER'), ('SELECT')) as p(privilege)
         where has_table_privilege('anon'::name, o.objet, p.privilege)
           and not (p.privilege = 'SELECT' and o.objet = 'public.demandes_publiques'))
       || ' / ' ||
       (select count(*)::text
          from (values ('public.demandes', 'DELETE'),
                       ('public.demandes', 'TRUNCATE'),
                       ('public.demandes', 'TRIGGER'),
                       ('public.demandes_publiques', 'SELECT'),
                       ('public.demandes_publiques', 'INSERT'),
                       ('public.demandes_publiques', 'UPDATE'),
                       ('public.demandes_publiques', 'DELETE'),
                       ('public.demandes_publiques', 'TRUNCATE'),
                       ('public.demandes_publiques', 'REFERENCES'),
                       ('public.demandes_publiques', 'TRIGGER')) as x(objet, privilege)
         where has_table_privilege('authenticated'::name, x.objet, x.privilege))
       || ' / ' ||
       (select (
          (select count(*) from (
             (select c.column_name::text, p.privilege::text
                from information_schema.columns c
               cross join (values ('INSERT'), ('UPDATE'), ('REFERENCES')) as p(privilege)
               where c.table_schema = 'public' and c.table_name = 'demandes'
                 and has_column_privilege('authenticated'::name, 'public.demandes',
                                          c.column_name::text, p.privilege))
             except
             (values ('titre', 'INSERT'), ('realisateur', 'INSERT'),
                     ('annee', 'INSERT'), ('statut', 'INSERT'),
                     ('decideur', 'INSERT'), ('statut', 'UPDATE'))) as en_trop)
          +
          (select count(*) from (
             (values ('titre', 'INSERT'), ('realisateur', 'INSERT'),
                     ('annee', 'INSERT'), ('statut', 'INSERT'),
                     ('decideur', 'INSERT'), ('statut', 'UPDATE'))
             except
             (select c.column_name::text, p.privilege::text
                from information_schema.columns c
               cross join (values ('INSERT'), ('UPDATE'), ('REFERENCES')) as p(privilege)
               where c.table_schema = 'public' and c.table_name = 'demandes'
                 and has_column_privilege('authenticated'::name, 'public.demandes',
                                          c.column_name::text, p.privilege))) as en_moins)
       )::text)
       || ' / ' ||
       has_table_privilege('authenticated'::name, 'public.demandes', 'SELECT')::text
       || ' / ' ||
       has_table_privilege('anon'::name, 'public.demandes_publiques', 'SELECT')::text,
       '0 / 0 / 0 / true / true'

union all
select 13,
       'anon : droits de COLONNE sur demandes',
       -- attendu : 0 (BKL-CIN-096 (b) lot 2, 18/09/2026 -- controle NEUF).
       -- Le controle n.12 mesure les droits de TABLE. Un grant de COLONNE
       -- a anon ne s'y verrait PAS : has_table_privilege ne regarde que
       -- l'etage table. Ce controle ferme ce trou-la, colonne par colonne,
       -- pour les quatre privileges qui s'accordent par colonne.
       -- Un seul de ces droits, et la clef publiable ecrit dans la table.
       (select count(*)::text
          from information_schema.columns c
         cross join (values ('SELECT'), ('INSERT'), ('UPDATE'),
                            ('REFERENCES')) as p(privilege)
         where c.table_schema = 'public' and c.table_name = 'demandes'
           and has_column_privilege('anon'::name, 'public.demandes',
                                    c.column_name::text, p.privilege)),
       '0'

union all
select 14,
       'authenticated : les SIX droits de colonne accordes, et rien d autre',
       -- attendu : 6 / 0 (BKL-CIN-096 (b) lot 2, 18/09/2026 -- controle
       -- NEUF). C'est le "que" de la posture, rendu lisible :
       -- (i) avant la barre : combien des SIX paires (colonne, privilege)
       --     accordees par 05 sont effectivement detenues --
       --     insert sur titre, realisateur, annee, statut, decideur ;
       --     update sur statut -> 6. Moins de six, la page ne peut plus
       --     faire son travail.
       -- (ii) apres la barre : combien de paires detenues EN TROP -> 0.
       --     Une seule paire en trop -- update (titre), par exemple -- et
       --     la borne "la page ne change QUE l etape" tombe.
       -- Le n.12 (iii) agrege ces deux nombres ; celui-ci les separe, pour
       -- qu'un rouge dise TOUT DE SUITE de quel cote il penche.
       (select count(*)::text
          from (values ('titre', 'INSERT'), ('realisateur', 'INSERT'),
                       ('annee', 'INSERT'), ('statut', 'INSERT'),
                       ('decideur', 'INSERT'), ('statut', 'UPDATE')) as a(colonne, privilege)
         where has_column_privilege('authenticated'::name, 'public.demandes',
                                    a.colonne, a.privilege))
       || ' / ' ||
       (select count(*)::text from (
          (select c.column_name::text, p.privilege::text
             from information_schema.columns c
            cross join (values ('INSERT'), ('UPDATE'), ('REFERENCES')) as p(privilege)
            where c.table_schema = 'public' and c.table_name = 'demandes'
              and has_column_privilege('authenticated'::name, 'public.demandes',
                                       c.column_name::text, p.privilege))
          except
          (values ('titre', 'INSERT'), ('realisateur', 'INSERT'),
                  ('annee', 'INSERT'), ('statut', 'INSERT'),
                  ('decideur', 'INSERT'), ('statut', 'UPDATE'))) as en_trop),
       '6 / 0'

union all
select 15,
       'demandes_journal : existe / RLS / policies / droits publics',
       -- attendu : 1 / true / 0 / 0 (BKL-CIN-096 (b) lot 2, 18/09/2026 --
       -- controle NEUF). Le journal est la TRACE : qui a change quoi,
       -- quand, depuis quelle valeur. Il est ferme DEUX FOIS --
       -- (i) la table existe -> 1 ;
       -- (ii) la RLS est activee -> true ;
       -- (iii) aucune policy -> 0 : personne ne le lit par l API ;
       -- (iv) aucun droit pour anon ni authenticated -> 0 : la commande
       --      elle-meme est close, pas seulement les lignes. Un objet neuf
       --      du schema public peut naitre avec les droits par defaut de
       --      la plateforme (R-023) : ce controle le verifie APRES coup.
       -- AH lit ce journal au Table Editor (voie privilegiee). Ne rien y
       -- voir par l API n'est pas une panne.
       (select count(*)::text from pg_class
         where oid = to_regclass('public.demandes_journal'))
       || ' / ' ||
       coalesce((select relrowsecurity::text from pg_class
                  where oid = to_regclass('public.demandes_journal')), '(absente)')
       || ' / ' ||
       (select count(*)::text from pg_policies
         where schemaname = 'public' and tablename = 'demandes_journal')
       || ' / ' ||
       -- MESURE PAR L ACL DE LA RELATION, et non par has_table_privilege :
       -- has_table_privilege('...', 'public.demandes_journal', ...) LEVE
       -- UNE ERREUR si la table n'existe pas encore, et ferait echouer le
       -- SCRIPT ENTIER au lieu de rendre ce controle rouge. Un controle
       -- qui casse la recette au lieu de rougir n'est pas un controle.
       -- aclexplode sur pg_class n'a pas ce defaut : table absente = zero
       -- ligne. Il voit aussi les droits accordes a PUBLIC (grantee 0).
       (select count(*)::text
          from pg_class c
         cross join lateral aclexplode(coalesce(c.relacl, '{}'::aclitem[])) a
         where c.oid = to_regclass('public.demandes_journal')
           and (a.grantee = 0
                or pg_get_userbyid(a.grantee) in ('anon', 'authenticated'))),
       '1 / true / 0 / 0'

union all
select 16,
       'les DEUX declencheurs de demandes',
       -- attendu : 2 | demandes_journal_trg, demandes_plafond_trg
       -- (BKL-CIN-096 (b) lot 2, 18/09/2026 -- controle NEUF).
       -- Sans le premier, aucune trace : le critere E2 du bilan de
       -- promotion du pilote devient improuvable. Sans le second, le
       -- plafond de creation n'existe plus -- et la page seule ne garde
       -- rien, puisque l API reste ouverte a la session d AH (R-026).
       -- Les NOMS sont affiches : un compte juste avec de mauvais noms
       -- serait un faux vert.
       (select count(*)::text from pg_trigger
         where tgrelid = 'public.demandes'::regclass and not tgisinternal)
       || ' | ' ||
       coalesce((select string_agg(tgname, ', ' order by tgname) from pg_trigger
                  where tgrelid = 'public.demandes'::regclass and not tgisinternal),
                '(aucun)'),
       '2 | demandes_journal_trg, demandes_plafond_trg'

union all
select 17,
       'UUID distincts nommes dans les policies de demandes',
       -- attendu : 1 (BKL-CIN-096 (b) lot 2, 18/09/2026 -- controle NEUF).
       -- Les trois policies sont NOMINATIVES : chacune nomme l UUID d AH.
       -- Ce controle compte les UUID DISTINCTS qu'elles nomment, et n en
       -- AFFICHE AUCUN : le depot est PUBLIC, la valeur ne doit entrer
       -- dans aucune piece versionnee. 1 = un seul compte au monde
       -- satisfait ces policies. 0 = la substitution n a pas eu lieu (ou
       -- les policies ne nomment plus personne : elles vaudraient alors
       -- pour TOUT compte authentifie). 2 ou plus = un second compte a ete
       -- ouvert quelque part, et il faut savoir lequel.
       (select count(distinct m[1])::text
          from pg_policies p,
               lateral regexp_matches(
                   coalesce(p.qual, '') || ' ' || coalesce(p.with_check, ''),
                   '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
                   'g') as m
         where p.schemaname = 'public' and p.tablename = 'demandes'),
       '1'

union all
select 18,
       'plafond : la garde qui laisse passer le role serveur',
       -- attendu : true (BKL-CIN-096 (b) lot 2, 18/09/2026 -- controle
       -- NEUF). LIRE LA LIMITE DE CE CONTROLE AVANT DE LE CROIRE.
       --
       -- CE QU IL MESURE : que la fonction du plafond porte bien sa garde
       -- de sortie -- "auth.uid() is null -> return new". C est un
       -- controle de MENTION, pas de VALEUR : il lit le texte de la
       -- fonction, il ne la fait pas jouer.
       -- POURQUOI PAS MIEUX ICI : 02 est un script de LECTURE. Eprouver
       -- le plafond pour de vrai demande une INSERTION, et ce fichier
       -- n ecrit rien -- c est sa nature et elle ne change pas.
       -- OU EST LA MESURE DE VALEUR : au bloc optionnel "P-1" en bas de
       -- ce fichier, a jouer SEPAREMENT par AH. Il insere puis ROLLBACK :
       -- rien ne reste.
       -- CE QUE LA GARDE PROTEGE : qualifier.mjs ecrit decideur='AH' pour
       -- TOUTE demande du formulaire public (l. 790). Un plafond qui
       -- compterait cette colonne refuserait la onzieme demande PUBLIQUE
       -- du jour et plafonnerait le SERVICE en production. La garde est
       -- ce qui rend cela impossible : sans compte authentifie, on sort
       -- avant de compter quoi que ce soit.
       (select (pg_get_functiondef(p.oid) like '%v_moi is null%'
                and pg_get_functiondef(p.oid) not like '%decideur%')::text
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'prive' and p.proname = 'plafond_creation_page'),
       'true'

order by ordre;

-- ---------------------------------------------------------------------
-- DETAIL OPTIONNEL -- a executer SEPAREMENT (selectionner le bloc puis
-- Run ; lance avec tout le script, seul son resultat s'afficherait).
--
-- Les demandes du jour, telles que la file publique les montre :
--
-- select id, created_at, titre, realisateur, annee, statut, qualification
-- from public.demandes_publiques
-- where created_at::date = current_date
-- order by id;
--
-- Les deux colonnes NON publiables, pour lecture par AH seul (l editeur
-- SQL emprunte une voie privilegiee -- la vue, elle, ne les montre pas) :
--
-- select id, titre, mail, motif
-- from public.demandes
-- order by id desc
-- limit 10;
--
-- Le detail d une qualification, axe par axe :
--
-- select id, titre,
--        qualification->>'volet'    as volet,
--        qualification->>'genreBase' as genre_base,
--        qualification->>'difficulte' as difficulte,
--        qualification->'sources_probables' as sources
-- from public.demandes
-- order by id desc
-- limit 10;
--
-- G-1 -- LECTURE CROISEE du controle 12 (analyse CIN-096 (a) L2.0) :
-- les droits DIRECTS d'anon et d'authenticated sur la vue et la table.
-- Attendu : une seule ligne, demandes_publiques | anon | SELECT. Toute
-- autre ligne se signale. (Ne voit ni les droits herites ni ceux de
-- PUBLIC : c'est le controle 12 qui les compte.)
--
-- select table_name, grantee, privilege_type
--   from information_schema.role_table_grants
--  where table_schema = 'public'
--    and table_name in ('demandes_publiques', 'demandes')
--    and grantee in ('anon', 'authenticated')
--  order by table_name, grantee, privilege_type;
--
-- Les droits accordes PAR DEFAUT aux objets FUTURS du schema public
-- (pg_default_acl). type_objet : r = tables ET vues, S = sequences,
-- f = fonctions, T = types. Une entree qui donne a anon ou a
-- authenticated des lettres d'ecriture (a = INSERT, w = UPDATE,
-- d = DELETE, D = TRUNCATE, x = REFERENCES, t = TRIGGER) signifie qu'un
-- drop puis create de la vue ou de la table RETABLIRAIT l'exposition :
-- il faudrait alors rejouer 03-droits-vue-publique.sql apres tout
-- create. Ce script MESURE ; il ne modifie aucun droit par defaut.
--
-- select pg_get_userbyid(d.defaclrole) as proprietaire,
--        coalesce(n.nspname, '(tous schemas)') as schema,
--        d.defaclobjtype as type_objet,
--        d.defaclacl as droits
--   from pg_default_acl d
--   left join pg_namespace n on n.oid = d.defaclnamespace
--  where n.nspname = 'public' or d.defaclnamespace = 0
--  order by proprietaire, schema, type_objet;
--
-- ---------------------------------------------------------------------
-- P-1 -- LA MESURE DE VALEUR DU PLAFOND (controle n.18), a jouer
-- SEPAREMENT par AH : selectionner le bloc decommente, puis Run.
-- BKL-CIN-096 (b) lot 2, 18/09/2026.
--
-- CE QU IL PROUVE, pour de vrai : que le declencheur de plafond LAISSE
-- PASSER une insertion faite sans compte authentifie -- c est-a-dire
-- celle de la clef secrete, celle de qualifier.mjs, celle du formulaire
-- public. Le controle n.18 ne lit que le TEXTE de la fonction ; celui-ci
-- la fait JOUER.
--
-- POURQUOI C EST SANS DANGER : tout est dans une transaction terminee
-- par ROLLBACK. La ligne inseree et sa ligne de journal disparaissent
-- toutes les deux. Rien ne reste, pas meme l id consomme (la sequence,
-- elle, avance -- c est normal et sans consequence).
-- L editeur SQL joue en tant que 'postgres' : auth.uid() y est NUL, ce
-- qui est exactement le cas a eprouver.
--
-- ATTENDU : la transaction va jusqu'au bout sans erreur, et la ligne de
-- controle rend 'insertion acceptee sans compte authentifie'. Si le
-- declencheur levait "Plafond atteint", la prescription serait FAUSSE et
-- le service en production serait plafonne : ARRET, et on le signale.
--
-- begin;
--
-- insert into public.demandes (titre, statut, decideur)
-- values ('P-1 controle du plafond -- A ROLLBACK', 'proposee', 'AH');
--
-- select 'insertion acceptee sans compte authentifie' as resultat,
--        auth.uid() is null as auth_uid_nul,
--        current_user as role_courant;
--
-- rollback;
--
-- Puis, APRES le rollback, verifier qu il ne reste rien -- attendu : 0.
--
-- select count(*) as restes
--   from public.demandes
--  where titre = 'P-1 controle du plafond -- A ROLLBACK';
-- ---------------------------------------------------------------------
