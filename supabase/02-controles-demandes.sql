-- 02-controles-demandes.sql
-- Recette de la table demandes et de la vue demandes_publiques, APRES
-- avoir joue 01-table-demandes.sql et soumis les deux demandes du
-- critere de sortie de la fiche A.
-- Prototype d'apprentissage BKL-FOR-006.
--
-- FORME CONSOLIDEE, reprise de FOR-003 (02-controles.sql, gate AH du
-- 20/08/2026) et de FOR-004 : le SQL Editor de Supabase n'affiche que le
-- resultat de la DERNIERE requete d'un script. Une requete par controle
-- n'afficherait donc que le dernier. Les DOUZE controles rendent ici UN
-- SEUL tableau -- colonnes ordre / controle / mesure / attendu -- et
-- chaque controle porte AUSSI son attendu en commentaire, juste au-dessus
-- de sa ligne, comme l'exige le mandat.
--
-- REGLE DE LECTURE : un controle est vert quand la MESURE satisfait
-- l'ATTENDU de la meme ligne. Un controle sans attendu ne controle rien.
--
-- A jouer TEL QUEL (tout selectionner, Run). Joue sur une table vide, il
-- rend des zeros aux controles de contenu : c'est correct et cela se lit
-- -- le controle 5 a 0 ligne signifie "aucune demande recue", pas
-- "panne". Les controles 0 a 4 et 10, eux, sont vrais des la creation.
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
       -- attendu : 0 -- AUCUNE policy, pas une seule : l'ecriture passe
       -- par la clef secrete, la lecture par la vue
       (select count(*)::text from pg_policies
         where schemaname = 'public' and tablename = 'demandes'),
       '0'

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
       'statuts hors des six valeurs',
       -- attendu : 0 -- la contrainte demandes_statut_check le garantit ;
       -- ce controle verifie qu'elle est bien en place et non desactivee
       (select count(*)::text from public.demandes
         where statut not in ('proposee', 'a_traiter', 'scholar',
                              'candidat', 'mise_de_cote', 'traitee')),
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
-- ---------------------------------------------------------------------
