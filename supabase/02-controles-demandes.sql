-- 02-controles-demandes.sql
-- Recette de la table demandes et de la vue demandes_publiques, APRES
-- avoir joue 01-table-demandes.sql et soumis les deux demandes du
-- critere de sortie de la fiche A.
-- Prototype d'apprentissage BKL-FOR-006.
--
-- FORME CONSOLIDEE, reprise de FOR-003 (02-controles.sql, gate AH du
-- 20/08/2026) et de FOR-004 : le SQL Editor de Supabase n'affiche que le
-- resultat de la DERNIERE requete d'un script. Une requete par controle
-- n'afficherait donc que le dernier. Les VINGT-CINQ controles rendent ici
-- UN SEUL tableau -- colonnes ordre / controle / mesure / attendu -- et
-- chaque controle porte AUSSI son attendu en commentaire, juste au-dessus
-- de sa ligne, comme l'exige le mandat.
--
-- HISTORIQUE DU NOMBRE : douze jusqu'au 16/09/2026 ; treize au lot 0
-- (controle n.12, droits par defaut, R-023) ; DIX-NEUF au lot 2 du
-- 18/09/2026 -- le n.1 et le n.12 AMENDES par la posture W2, et SIX
-- controles neufs (n.13 a n.18) pour la page privee ; VINGT-CINQ au lot S
-- de BKL-CIN-098, le 19/09/2026 -- les n.4, n.7, n.12 et n.14 AMENDES par
-- la huitieme etape et la colonne page_pilote, et SIX controles neufs
-- (n.19 a n.24) pour l'adresse de page d'essai et pour le journal fige.
--
-- LES CONTROLES 19 A 24, ET LES AMENDEMENTS DES N.4, 7, 12 ET 14,
-- SUPPOSENT QUE 06-statut-publiee-pilote.sql A ETE JOUE. Avant lui, le
-- n.4 rend '10 / 12', le n.14 rend '6 / 0', et les n.19 a 24 sont rouges
-- ou vides : ce n'est pas une panne, c'est l'ordre des gestes.
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
       -- attendu : 11 / 13 -- AMENDE LE 19/09/2026 (BKL-CIN-098 lot S,
       -- script 06-statut-publiee-pilote.sql). L'attendu etait '10 / 12'
       -- depuis l'origine : douze champs a la table (fiche A), dix a la
       -- vue (mail et motif retires). La colonne 'page_pilote' ajoute UN
       -- champ des DEUX cotes -- la vue l'expose, en DERNIERE position
       -- (controle n.21). Sans cet amendement, ce controle serait devenu
       -- ROUGE PAR CONSTRUCTION le jour ou 06 est joue (regle S-6 du
       -- PATRON : un controle dont l'attendu a change reste rouge, et il
       -- cesse d'etre un detecteur).
       -- mail et motif restent hors de la vue : c'est le controle n.3.
       (select count(*)::text from information_schema.columns
         where table_schema = 'public' and table_name = 'demandes_publiques')
       || ' / ' ||
       (select count(*)::text from information_schema.columns
         where table_schema = 'public' and table_name = 'demandes'),
       '11 / 13'

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
       -- attendu : informatif -- AMENDE LE 19/09/2026 (BKL-CIN-098
       -- lot S bis, decision d'AH du jour, verbatim : "Les rendre
       -- informatifs" -- option marquee "Recommande" a l elicitation ;
       -- ecart n.151 du greffe).
       -- L'attendu etait 'au moins 1' depuis l'origine : "0 signifierait
       -- que l'insert n'a pas eu lieu, et l'accuse recu par le visiteur
       -- ne doit alors PAS avoir annonce un enregistrement". Il valait
       -- LE JOUR DU TEST de la fiche A, ou une demande venait d'etre
       -- soumise. Une base VIVANTE ne peut plus le satisfaire : un jour
       -- sans demande rend 0, et ce 0 est normal. Un controle qui rougit
       -- sur une base saine cesse d'etre un detecteur (regle S-6 du
       -- PATRON-SERVICE-SERVERLESS) -- et un rouge permanent finit par se
       -- lire comme un decor.
       -- LA MESURE RESTE AFFICHEE, et c'est tout l'objet : le nombre de
       -- demandes du jour se LIT, il ne se juge plus. Pour eprouver que
       -- l'insert du formulaire fonctionne, la mesure est ailleurs --
       -- epreuve P-1 (le plafond laisse passer le role serveur) et une
       -- soumission reelle.
       (select count(*)::text from public.demandes
         where created_at::date = current_date),
       'informatif -- controle du JOUR d un test'

union all
select 7,
       'statuts hors des huit valeurs',
       -- attendu : 0 -- la contrainte demandes_statut_check le garantit ;
       -- ce controle verifie qu'elle est bien en place et non desactivee.
       -- Sept valeurs depuis BKL-CIN-096 (b) lot 1 : publication_pilote
       -- (A10, Q2, 16/09/2026), jouee en production par
       -- 04-etape-publication-pilote.sql.
       -- HUIT depuis BKL-CIN-098 lot S (19/09/2026) : publiee_pilote,
       -- jouee par 06-statut-publiee-pilote.sql. C'est l'etape de
       -- CONSTAT ("la chaine a publie, AH l'a vu") ; celle qui ARME
       -- reste publication_pilote.
       -- LA LISTE CI-DESSOUS EST UNE RECOPIE de la contrainte : si la
       -- contrainte gagne une valeur et pas cette liste, ce controle
       -- rougit sur une base saine. C'est voulu -- il force la mise a
       -- jour. Le nombre de valeurs de la CONTRAINTE elle-meme se lit au
       -- controle immediat de 06.
       (select count(*)::text from public.demandes
         where statut not in ('proposee', 'a_traiter', 'publication_pilote',
                              'publiee_pilote', 'scholar', 'candidat',
                              'mise_de_cote', 'traitee')),
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
       -- attendu : informatif -- AMENDE LE 19/09/2026 (BKL-CIN-098
       -- lot S bis, decision d'AH du jour, verbatim : "Les rendre
       -- informatifs" -- option marquee "Recommande" a l elicitation ;
       -- ecart n.151 du greffe).
       -- L'attendu etait '0 avant tout arbitrage manuel d AH'. Sa propre
       -- note le disait deja : "ce controle se lit AVANT tout arbitrage
       -- manuel ; apres, il compte les deplacements d AH et cesse d etre
       -- un controle de borne". Nous y sommes : AH arbitre depuis le
       -- 25/08, et ce nombre compte desormais SES gestes -- 5 au
       -- 19/09/2026. Le garder a '0' serait tenir pour rouge le
       -- fonctionnement normal du service.
       -- LA BORNE ELLE-MEME N'EST PAS ABANDONNEE, elle est mesuree
       -- AILLEURS, et mieux : "l IA ne pose jamais un statut" est prouve
       -- par STRUCTURE dans outils/controler-durcissement.mjs -- le champ
       -- 'statut' est ABSENT du schema de sortie envoye au modele, et le
       -- controle le verifie sur le schema serialise. Une impossibilite
       -- mecanique vaut mieux qu'un comptage de lignes.
       -- LA MESURE RESTE AFFICHEE : elle dit combien de demandes ont
       -- quitte 'proposee', ce qui se lit d'un coup d oeil.
       (select count(*)::text from public.demandes
         where statut <> 'proposee'),
       'informatif -- la borne (l IA ne pose jamais un statut) est tenue par controler-durcissement'

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
       --       et les droits ACCORDES par 05, PUIS par 06 -- en trop et
       --       en moins confondus -> 0. Le detail nomme est au n.14.
       --       AMENDE LE 19/09/2026 (BKL-CIN-098 lot S) : la liste de
       --       reference passe de SIX a SEPT paires -- 06 ajoute
       --       'update (page_pilote)'. Sans cet amendement, (iii) aurait
       --       compte une paire "en trop" et ce controle serait devenu
       --       ROUGE PAR CONSTRUCTION (regle S-6 du PATRON).
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
                     ('decideur', 'INSERT'), ('statut', 'UPDATE'),
                     ('page_pilote', 'UPDATE'))) as en_trop)
          +
          (select count(*) from (
             (values ('titre', 'INSERT'), ('realisateur', 'INSERT'),
                     ('annee', 'INSERT'), ('statut', 'INSERT'),
                     ('decideur', 'INSERT'), ('statut', 'UPDATE'),
                     ('page_pilote', 'UPDATE'))
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
       'authenticated : les SEPT droits de colonne accordes, et rien d autre',
       -- attendu : 7 / 0 (BKL-CIN-096 (b) lot 2, 18/09/2026 -- controle
       -- NEUF ; AMENDE de 6 a 7 le 19/09/2026, BKL-CIN-098 lot S).
       -- C'est le "que" de la posture, rendu lisible :
       -- (i) avant la barre : combien des SEPT paires (colonne,
       --     privilege) accordees par 05 puis par 06 sont effectivement
       --     detenues -- insert sur titre, realisateur, annee, statut,
       --     decideur ; update sur statut ET sur page_pilote -> 7.
       --     Moins de sept, la page ne peut plus faire son travail : a
       --     six, elle poserait l etape mais PAS l adresse, et la borne
       --     de coherence refuserait le geste entier.
       -- (ii) apres la barre : combien de paires detenues EN TROP -> 0.
       --     Une seule paire en trop -- update (titre), par exemple -- et
       --     la borne "la page ne change QUE l etape et l adresse" tombe.
       -- Le n.12 (iii) agrege ces deux nombres ; celui-ci les separe, pour
       -- qu'un rouge dise TOUT DE SUITE de quel cote il penche.
       (select count(*)::text
          from (values ('titre', 'INSERT'), ('realisateur', 'INSERT'),
                       ('annee', 'INSERT'), ('statut', 'INSERT'),
                       ('decideur', 'INSERT'), ('statut', 'UPDATE'),
                       ('page_pilote', 'UPDATE')) as a(colonne, privilege)
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
                  ('decideur', 'INSERT'), ('statut', 'UPDATE'),
                  ('page_pilote', 'UPDATE'))) as en_trop),
       '7 / 0'

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
       'les TROIS declencheurs de demandes',
       -- attendu : 3 | demandes_journal_trg, demandes_plafond_instruction_trg,
       --               demandes_plafond_trg
       -- (BKL-CIN-096 (b) lot 2, 18/09/2026 -- controle NEUF, porte a TROIS
       -- le meme jour apres l'audit du greffe.)
       -- Sans le journal, aucune trace : le critere E2 du bilan de
       -- promotion du pilote devient improuvable.
       -- Sans le plafond de LIGNE, aucun refus -- et la page seule ne
       -- garde rien, puisque l API reste ouverte a la session d AH (R-026).
       -- Sans le declencheur d INSTRUCTION, le plafond est contournable
       -- par une insertion EN LOT : les declencheurs 'after' de niveau
       -- ligne ne jouant qu'a la FIN de l'instruction, toutes les lignes
       -- d'un meme POST liraient le meme compte. C'est lui qui remet a
       -- zero le compteur de l'instruction.
       -- Les NOMS sont affiches : un compte juste avec de mauvais noms
       -- serait un faux vert.
       (select count(*)::text from pg_trigger
         where tgrelid = 'public.demandes'::regclass and not tgisinternal)
       || ' | ' ||
       coalesce((select string_agg(tgname, ', ' order by tgname) from pg_trigger
                  where tgrelid = 'public.demandes'::regclass and not tgisinternal),
                '(aucun)'),
       '3 | demandes_journal_trg, demandes_plafond_instruction_trg, demandes_plafond_trg'

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
       -- CE QU IL MESURE, en TROIS points (le troisieme ajoute le
       -- 18/09/2026 apres l'audit du greffe) :
       --   (i)   la garde de sortie est la : "v_moi is null -> return new" ;
       --   (ii)  le texte ne contient PAS 'decideur' -- sinon le plafond
       --         compterait les demandes PUBLIQUES et plafonnerait le
       --         service en production (qualifier.mjs l. 790 ecrit
       --         decideur='AH' pour TOUTE demande du formulaire) ;
       --   (iii) le texte ne contient PAS 'current_user'. C EST LE
       --         CONTROLE QUI MANQUAIT. Dans une fonction
       --         'security definer', current_user vaut le PROPRIETAIRE de
       --         la fonction, jamais l appelant (documentation
       --         PostgreSQL, System Information Functions : "It also
       --         changes during the execution of functions with the
       --         attribute SECURITY DEFINER"). Une garde
       --         "current_user <> 'authenticated' -> return new" est donc
       --         VRAIE A CHAQUE APPEL : la fonction sort avant de
       --         compter, le plafond ne refuse RIEN, et tous les autres
       --         controles restent VERTS sur un plafond mort. C est
       --         exactement ce qui s est produit le 18/09.
       --
       -- C est un controle de MENTION, pas de VALEUR : il lit le TEXTE de
       -- la fonction, il ne la fait pas jouer. 02 est un script de
       -- LECTURE, et il le reste.
       -- LES MESURES DE VALEUR sont les deux blocs optionnels du bas :
       --   P-1 -- le plafond LAISSE PASSER le role serveur ;
       --   P-2 -- le plafond REFUSE la onzieme creation de la page, dans
       --          les DEUX formes (onze instructions, et une instruction
       --          de onze lignes).
       -- P-1 SEUL NE SUFFIT PAS : un plafond mort le passe haut la main.
       -- C est P-2 qui prouve qu il mord.
       (select (pg_get_functiondef(p.oid) like '%v_moi is null%'
                and pg_get_functiondef(p.oid) not like '%decideur%'
                and pg_get_functiondef(p.oid) not like '%current_user%')::text
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'prive' and p.proname = 'plafond_creation_page'),
       'true'

union all
select 19,
       'colonne page_pilote : existe / type / nullable',
       -- attendu : 1 / text / YES (BKL-CIN-098 lot S, 19/09/2026 --
       -- controle NEUF). C'est l'adresse de la page publiee sur la
       -- surface d essai. 'text' et non 'varchar(n)' : une longueur
       -- arbitraire ne borne rien d utile ici -- c'est la FORME qui
       -- borne (controle n.20), pas la taille. 'YES' (nullable) parce
       -- que NUL est l etat normal de la quasi-totalite des lignes :
       -- une demande n a d adresse que si la chaine a publie.
       -- NE PAS CONFONDRE avec slug_existant, qui veut dire "deja
       -- analyse EN PRODUCTION au depot" : les deux corpus restent
       -- disjoints, et c est pourquoi la colonne est DEDIEE.
       coalesce((select '1 / ' || data_type || ' / ' || is_nullable
                   from information_schema.columns
                  where table_schema = 'public' and table_name = 'demandes'
                    and column_name = 'page_pilote'), '0 / (absente) / (absente)'),
       '1 / text / YES'

union all
select 20,
       'les DEUX contraintes de page_pilote',
       -- attendu : 2 | demandes_page_pilote_coherence_check,
       --               demandes_page_pilote_forme_check
       -- (BKL-CIN-098 lot S, 19/09/2026 -- controle NEUF.)
       -- FORME : l adresse est nulle, ou elle appartient exactement a
       -- https://pilote.cdatso.be/films/<slug>.html. Un lien affiche sur
       -- une page PUBLIQUE ne doit jamais pouvoir etre arbitraire.
       -- COHERENCE : publiee_pilote => adresse non nulle ; adresse non
       -- nulle => publiee_pilote ou traitee.
       -- LES NOMS SONT AFFICHES : un compte juste avec de mauvais noms
       -- serait un faux vert -- et le message d erreur que la page
       -- montrera a AH cite le NOM de la contrainte.
       -- CE CONTROLE EST UN CONTROLE D EXISTENCE. Il ne prouve pas que
       -- les contraintes MORDENT : c est ce que font les epreuves P-3 et
       -- P-4, en bas de ce fichier. Une contrainte presente mais
       -- declaree 'not valid', ou une expression fautive, passerait
       -- cette ligne. Une garde se prouve des DEUX cotes.
       (select count(*)::text from pg_constraint
         where conrelid = 'public.demandes'::regclass
           and conname in ('demandes_page_pilote_forme_check',
                           'demandes_page_pilote_coherence_check'))
       || ' | ' ||
       coalesce((select string_agg(conname, ', ' order by conname)
                   from pg_constraint
                  where conrelid = 'public.demandes'::regclass
                    and conname in ('demandes_page_pilote_forme_check',
                                    'demandes_page_pilote_coherence_check')), '(aucune)'),
       '2 | demandes_page_pilote_coherence_check, demandes_page_pilote_forme_check'

union all
select 21,
       'la vue expose page_pilote, et EN DERNIER',
       -- attendu : 11 / page_pilote (BKL-CIN-098 lot S, 19/09/2026 --
       -- controle NEUF).
       -- EXPOSEE : sans elle dans la vue, file.html -- qui lit la vue
       -- avec la clef publiable -- ne connaitrait pas l adresse et ne
       -- pourrait poser aucun lien.
       -- EN DERNIER, et ce n est pas un gout : PostgreSQL n accepte un
       -- 'create or replace view' que si les colonnes EXISTANTES gardent
       -- nom, type et ORDRE. La position de page_pilote est donc la
       -- preuve que la vue a ete REMPLACEE et non DETRUITE puis recreee
       -- -- et un objet recree naitrait avec les droits par defaut du
       -- schema public (R-023). Cette ligne mesure cela aussi.
       (select count(*)::text from information_schema.columns
         where table_schema = 'public' and table_name = 'demandes_publiques')
       || ' / ' ||
       coalesce((select column_name from information_schema.columns
                  where table_schema = 'public' and table_name = 'demandes_publiques'
                  order by ordinal_position desc limit 1), '(aucune)'),
       '11 / page_pilote'

union all
select 22,
       'anon : SELECT sur la vue, et RIEN d autre -- apres remplacement',
       -- attendu : true / 0 / 0 (BKL-CIN-098 lot S, 19/09/2026 --
       -- controle NEUF).
       -- POURQUOI CE CONTROLE EN PLUS DES N.12 ET 13. Le n.12 mesure les
       -- droits de TABLE, le n.13 les droits de COLONNE d anon SUR LA
       -- TABLE. Aucun des deux ne regarde les droits de COLONNE d anon
       -- SUR LA VUE -- et c est precisement l objet que 06 remplace.
       -- has_table_privilege ne voit PAS un droit de colonne : un
       -- 'grant update (statut) on demandes_publiques to anon' aurait
       -- laisse les n.12 et 13 verts. Ce controle ferme ce trou-la.
       -- (i)   anon garde SELECT sur la vue -> true (sans lui, la file
       --       publique est vide) ;
       -- (ii)  droits de TABLE d ecriture sur la vue -> 0 ;
       -- (iii) droits de COLONNE d ecriture sur la vue -> 0.
       has_table_privilege('anon'::name, 'public.demandes_publiques', 'SELECT')::text
       || ' / ' ||
       (select count(*)::text
          from (values ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'),
                       ('REFERENCES'), ('TRIGGER')) as p(privilege)
         where has_table_privilege('anon'::name, 'public.demandes_publiques',
                                   p.privilege))
       || ' / ' ||
       (select count(*)::text
          from information_schema.columns c
         cross join (values ('INSERT'), ('UPDATE'), ('REFERENCES')) as p(privilege)
         where c.table_schema = 'public' and c.table_name = 'demandes_publiques'
           and has_column_privilege('anon'::name, 'public.demandes_publiques',
                                    c.column_name::text, p.privilege)),
       'true / 0 / 0'

union all
select 23,
       'authenticated : UPDATE sur statut ET page_pilote, et sur rien d autre',
       -- attendu : 2 | page_pilote, statut (BKL-CIN-098 lot S,
       -- 19/09/2026 -- controle NEUF).
       -- CE QU IL AJOUTE AU N.14 : les NOMS. Le n.14 compte des paires
       -- et rend deux nombres ; celui-ci NOMME les colonnes que la page
       -- privee peut ecrire. Un rouge y dit TOUT DE SUITE laquelle est
       -- de trop, ou laquelle manque -- au lieu d un "7 / 1" a instruire.
       -- DEUX, ET PAS TROIS : la page pose l etape et l adresse dans un
       -- meme 'PATCH'. Elle ne touche ni le titre, ni le motif, ni le
       -- mail, ni le decideur, ni slug_existant. Une colonne de plus
       -- ici, et la borne "la page ne change QUE l etape et l adresse"
       -- tombe -- sans qu aucun autre controle ne le dise.
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
       '2 | page_pilote, statut'

union all
select 24,
       'demandes_journal FIGE : les DEUX declencheurs',
       -- attendu : 2 | demandes_journal_fige_instruction_trg,
       --               demandes_journal_fige_ligne_trg
       -- (BKL-CIN-098 lot S, 19/09/2026 -- controle NEUF.)
       -- POURQUOI. Le 19/09, AH a modifie une ligne de ce journal par
       -- erreur au tableau de bord, et rien n en a garde trace. Un
       -- journal qu on peut reecrire sans laisser de trace n est pas un
       -- journal -- et le critere E2 du bilan de promotion du pilote
       -- repose sur lui.
       -- DEUX ET NON UN : PostgreSQL exige qu un declencheur 'truncate'
       -- soit de niveau INSTRUCTION (il n y a pas de ligne a lui
       -- montrer) ; 'update' et 'delete' sont de niveau LIGNE.
       -- CE QUE CETTE PARADE N EST PAS : une protection contre le
       -- PROPRIETAIRE. Un 'alter table ... disable trigger' la leve. Ce
       -- qui change, c est qu effacer une trace devient un geste
       -- DELIBERE et NOMME, au lieu d un clic.
       -- L INSERT N EST PAS GENE : c est ce que prouve l epreuve P-5, et
       -- c est la moitie qui compte -- une garde qui refuserait AUSSI
       -- l insert tuerait la journalisation en silence.
       (select count(*)::text from pg_trigger
         where tgrelid = 'public.demandes_journal'::regclass and not tgisinternal)
       || ' | ' ||
       coalesce((select string_agg(tgname, ', ' order by tgname) from pg_trigger
                  where tgrelid = 'public.demandes_journal'::regclass
                    and not tgisinternal), '(aucun)'),
       '2 | demandes_journal_fige_instruction_trg, demandes_journal_fige_ligne_trg'

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
--
-- ---------------------------------------------------------------------
-- P-2 -- LA MESURE DU REFUS. BKL-CIN-096 (b) lot 2, 18/09/2026, apres
-- l'audit du greffe. A jouer SEPAREMENT par AH, et EN DEUX FOIS.
--
-- POURQUOI P-1 NE SUFFIT PAS -- et c'est toute la lecon du jour.
-- P-1 prouve que le plafond LAISSE PASSER le role serveur. Un plafond
-- MORT passe cette epreuve haut la main. Le 18/09, une garde fautive
-- ('current_user' dans une fonction 'security definer') a rendu le
-- plafond inerte : P-1 etait vert, le controle n.18 etait vert, les
-- dix-neuf lignes etaient vertes, et RIEN ne refusait quoi que ce soit.
-- Une garde se prouve des DEUX cotes : ce qu'elle laisse passer, ET ce
-- qu'elle refuse. P-2 est le second cote.
--
-- CE QUE P-2 FAIT : il se place dans le ROLE et le JETON de la page
-- privee, puis tente onze creations. La onzieme doit etre REFUSEE.
-- Tout est dans une transaction terminee par 'rollback' : ni les lignes
-- ni leur journal ne restent (le compteur d'instruction non plus, il est
-- local a la transaction).
--
-- !!! SUBSTITUTION : la chaine a remplacer est formee du caractere '<',
-- !!! puis de UUID-DE-AH, puis du caractere '>' -- ecrite ici en
-- !!! morceaux EXPRES pour que la consigne ne soit pas appariee. Elle
-- !!! apparait TROIS fois dans les blocs ci-dessous. Substitue dans
-- !!! l'EDITEUR, et N'ENREGISTRE PAS ce fichier : le depot est PUBLIC.
--
-- !!! JOUE LE CAS A, PUIS LE CAS B, SEPAREMENT. L'erreur attendue avorte
-- !!! la transaction : tout ce qui suivrait dans le meme envoi echouerait
-- !!! pour cette raison-la, et non pour la bonne.
--
-- =====================================================================
-- CAS A -- ONZE INSTRUCTIONS SEPAREES (le cas de la page, qui insere une
-- ligne a la fois). Attendu : les dix premieres passent, la ONZIEME leve
-- 'Plafond atteint : 10 creations par jour depuis la page privee (10
-- deja journalisee(s), 0 dans cette instruction)...' (check_violation).
-- =====================================================================
--
-- begin;
-- set local role authenticated;
-- select set_config('request.jwt.claims',
--                   '{"sub":"<UUID-DE-AH>","role":"authenticated"}', true);
--
-- -- (0) AUTO-CONTROLE, a lire AVANT d'aller plus loin.
-- --     auth.uid() lit 'request.jwt.claim.sub' d'abord, puis
-- --     'request.jwt.claims'::jsonb->>'sub' (definition Supabase,
-- --     verifiee le 18/09/2026). La forme ci-dessus couvre le second
-- --     chemin. SI jeton_lu EST false, ARRETE-TOI : les insertions qui
-- --     suivent s'executeraient avec auth.uid() NUL, le plafond sortirait
-- --     par sa garde, les onze passeraient -- et P-2 ne prouverait RIEN.
-- --     Un controle qui peut passer sans rien mesurer est pire que pas
-- --     de controle. Attendu : true | authenticated.
-- select auth.uid() is not null as jeton_lu, current_user as role_courant;
--
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 01', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 02', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 03', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 04', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 05', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 06', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 07', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 08', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 09', 'proposee', 'AH');
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 10', 'proposee', 'AH');
-- -- LA ONZIEME : c'est ELLE qui doit echouer.
-- insert into public.demandes (titre, statut, decideur) values ('P-2 refus -- A ROLLBACK 11', 'proposee', 'AH');
--
-- rollback;
--
-- =====================================================================
-- CAS B -- UNE SEULE INSTRUCTION DE ONZE LIGNES (le cas que la page ne
-- produit JAMAIS, mais qu'un seul POST de PostgREST avec le jeton d'AH
-- produirait -- c'est-a-dire le cas meme que ce plafond vise, R-026).
-- Attendu : la MEME erreur 'Plafond atteint', levee a la onzieme ligne
-- de l'instruction, et AUCUNE des onze n'entre.
-- Sans le declencheur de NIVEAU INSTRUCTION, les onze passeraient : les
-- declencheurs 'after' de niveau ligne ne jouent qu'a la FIN de
-- l'instruction, donc le journal serait encore vide pour toutes.
-- =====================================================================
--
-- begin;
-- set local role authenticated;
-- select set_config('request.jwt.claims',
--                   '{"sub":"<UUID-DE-AH>","role":"authenticated"}', true);
-- select auth.uid() is not null as jeton_lu, current_user as role_courant;
--
-- insert into public.demandes (titre, statut, decideur) values
--   ('P-2 lot -- A ROLLBACK 01', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 02', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 03', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 04', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 05', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 06', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 07', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 08', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 09', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 10', 'proposee', 'AH'),
--   ('P-2 lot -- A ROLLBACK 11', 'proposee', 'AH');
--
-- rollback;
--
-- =====================================================================
-- APRES LES DEUX CAS -- verifier qu'il ne reste RIEN. Attendu : 0.
-- =====================================================================
--
-- select count(*) as restes
--   from public.demandes
--  where titre like 'P-2 %A ROLLBACK%';
--
-- SI LES ONZE PASSENT dans l'un ou l'autre cas : le plafond est inerte
-- pour cette forme-la. ARRET, et on le signale -- on ne "reessaie" pas.
-- ---------------------------------------------------------------------

-- =====================================================================
-- P-3, P-4, P-5 -- LES EPREUVES DU LOT S. BKL-CIN-098, 19/09/2026.
-- A jouer SEPAREMENT par AH, UN BLOC A LA FOIS : selectionner le bloc
-- decommente, puis Run.
-- =====================================================================
--
-- POURQUOI TROIS EPREUVES DE PLUS. Les controles n.19 a 24 sont des
-- controles d'EXISTENCE : ils lisent le catalogue. Une contrainte
-- presente mais a l'expression fautive, un declencheur pose mais
-- desactive, une borne qui n'interdit rien -- tout cela les laisse
-- VERTS. C'est exactement ce qui s'est produit le 18/09 avec le plafond
-- inerte : dix-neuf lignes vertes, et rien ne refusait quoi que ce soit.
-- UNE GARDE SE PROUVE DES DEUX COTES : ce qu'elle laisse passer, ET ce
-- qu'elle refuse.
--
-- CE QUI REND CES BLOCS SANS DANGER : chacun vit dans une transaction
-- terminee par 'rollback'. Les lignes creees, leurs lignes de journal et
-- les tables temporaires disparaissent toutes. Seule la SEQUENCE des
-- identifiants avance -- c'est normal et sans consequence. Chaque bloc
-- se termine par un compte de restes, a jouer APRES le rollback :
-- attendu 0.
--
-- !!! ET CE N'EST PLUS UN POSTULAT. Que l'editeur SQL de Supabase honore
-- !!! bien un 'begin; ... rollback;' couvrant PLUSIEURS instructions
-- !!! d'un meme envoi n'avait JAMAIS ete mesure -- ni au lot 2, ou P-1
-- !!! et P-2 reposent pourtant entierement dessus. Mesure du 19/09/2026
-- !!! 16h15 (BKL-CIN-098 lot S), par une sonde qui ne cree rien :
-- !!!     begin;
-- !!!     select set_config('zz.sonde_txid', txid_current()::text, true);
-- !!!     select current_setting('zz.sonde_txid', true), txid_current();
-- !!!     rollback;
-- !!! -> meme valeur des deux cotes (1697 / 1697) : UNE SEULE
-- !!! transaction. Le 'rollback' protege. La sonde se rejoue en dix
-- !!! secondes le jour ou l'on en doute.
--
-- =====================================================================
-- !!! LE DIALOGUE DE SUPABASE -- LIRE AVANT DE CLIQUER.
-- =====================================================================
-- Un bloc qui porte 'create temporary table' fait afficher a l'editeur
-- "Potential issues detected ... This query creates a table without
-- enabling Row Level Security", avec trois boutons.
--
--   * "Run without RLS"      <- C'EST CELUI-LA, TOUJOURS.
--   * "Run and enable RLS"   <- JAMAIS. Supabase AJOUTE alors a ta
--                               requete un 'alter table public.<nom>
--                               enable row level security'. Il prefixe
--                               'public.' -- or la table est
--                               TEMPORAIRE, donc elle n'est pas dans
--                               public. L'instruction ajoutee echoue en
--                               42P01 "relation ... does not exist", et
--                               l'echec ressemble a un defaut du bloc.
--                               C'est arrive le 19/09/2026 a 16h13, et
--                               une demi-heure y est passee.
--   * "Cancel"               <- si tu n'es pas sur.
--
-- L'AVERTISSEMENT EST SANS OBJET ICI : une table TEMPORAIRE vit dans le
-- schema temporaire de TA session, aucun autre role ne peut l'atteindre,
-- et elle meurt avec la connexion. Le linter voit 'create table' et ne
-- distingue pas.
--
-- LA REGLE GENERALE, qui vaut au-dela de ce cas : ON NE LAISSE JAMAIS
-- L'EDITEUR REECRIRE UNE EPREUVE. Une mesure dont le texte a ete modifie
-- par l'outil ne mesure plus ce qu'elle annonce.
-- =====================================================================
--
-- POURQUOI UN BLOC 'do' ET UNE TABLE TEMPORAIRE, plutot qu'une suite de
-- commandes : une erreur de contrainte AVORTE la transaction, et tout ce
-- qui suivrait echouerait pour CETTE raison-la, et non pour la bonne
-- (c'est la lecon de P-2, qui doit se jouer en deux fois). Un bloc
-- 'begin ... exception' ouvre une SOUS-transaction : l'erreur attendue y
-- est rattrapee, consignee, et la suite continue. Les resultats
-- s'accumulent dans une table temporaire, et UN SEUL tableau les rend.
--
-- L'EDITEUR SQL JOUE EN TANT QUE 'postgres' : auth.uid() y est NUL, le
-- plafond de creation sort par sa garde (fail-open), et les policies ne
-- s'appliquent pas au proprietaire. Ces epreuves mesurent donc les
-- CONTRAINTES et les DECLENCHEURS, pas les policies -- celles-ci sont
-- mesurees par les controles n.1, 12 a 14, 17, 22, 23 et par la
-- contre-lecture hostile (outils/controler-page-privee.mjs).
--
-- ---------------------------------------------------------------------
-- P-3 (a) -- L'EXPRESSION DE FORME, LUE. Bloc de LECTURE PURE : aucune
-- transaction, rien n'est ecrit. Il eprouve l'EXPRESSION elle-meme, sur
-- douze cas dont dix hostiles.
-- ---------------------------------------------------------------------
-- ATTENDU : douze lignes, colonne 'jugement' a 'OK' partout.
--
-- LE CAS QUI COMPTE LE PLUS EST LE DERNIER : une adresse VALIDE SUIVIE
-- D'UN SAUT DE LIGNE. En Python, '$' tolere un saut de ligne terminal et
-- ce cas PASSE ; le greffe l'a mesure le 19/09/2026 en eprouvant
-- l'expression sur 49 slugs reels (0 hors forme) et 10 cas hostiles.
-- PostgreSQL, hors mode "newline-sensitive", fait apparier '$' a la FIN
-- DE CHAINE seulement : il devrait donc REFUSER. C'est ce que cette
-- ligne mesure -- on ne le suppose pas. JavaScript est mesure a part,
-- par la passe D de outils/controler-proprete.mjs.
--
-- select cas,
--        case when valeur ~ '^https://pilote\.cdatso\.be/films/[a-z0-9]+(-[a-z0-9]+)*\.html$'
--             then 'ACCEPTEE' else 'REFUSEE' end as verdict,
--        attendu,
--        case when (case when valeur ~ '^https://pilote\.cdatso\.be/films/[a-z0-9]+(-[a-z0-9]+)*\.html$'
--                        then 'ACCEPTEE' else 'REFUSEE' end) = attendu
--             then 'OK' else '>>> ECART <<<' end as jugement,
--        length(valeur) as longueur
--   from (values
--     ('01 adresse valide, slug compose', 'https://pilote.cdatso.be/films/le-chateau-ambulant.html', 'ACCEPTEE'),
--     ('02 adresse valide, slug simple',  'https://pilote.cdatso.be/films/rose.html',                'ACCEPTEE'),
--     ('03 autre domaine',                'https://www.cdatso.be/films/le-chateau-ambulant.html',    'REFUSEE'),
--     ('04 domaine-leurre en suffixe',    'https://pilote.cdatso.be.evil.be/films/rose.html',        'REFUSEE'),
--     ('05 domaine-leurre en prefixe',    'https://evil.be/pilote.cdatso.be/films/rose.html',        'REFUSEE'),
--     ('06 http en clair',                'http://pilote.cdatso.be/films/rose.html',                 'REFUSEE'),
--     ('07 chemin hors films/',           'https://pilote.cdatso.be/docs/journal-pilote.html',       'REFUSEE'),
--     ('08 remontee de chemin',           'https://pilote.cdatso.be/films/../docs/secret.html',      'REFUSEE'),
--     ('09 chaine de requete',            'https://pilote.cdatso.be/films/rose.html?x=1',            'REFUSEE'),
--     ('10 majuscules dans le slug',      'https://pilote.cdatso.be/films/Le-Chateau.html',          'REFUSEE'),
--     ('11 schema javascript',            'javascript:alert(1)',                                     'REFUSEE'),
--     ('12 valide + SAUT DE LIGNE final', 'https://pilote.cdatso.be/films/rose.html' || chr(10),      'REFUSEE')
--   ) as t(cas, valeur, attendu)
--  order by cas;
--
-- ---------------------------------------------------------------------
-- P-3 (b) -- LA CONTRAINTE DE FORME MORD. Transaction, puis rollback.
-- ---------------------------------------------------------------------
-- (a) prouve que l'EXPRESSION juge bien. (b) prouve qu'elle est
-- effectivement ATTACHEE a la colonne et qu'elle REFUSE -- une
-- contrainte declaree 'not valid', ou absente, laisserait (a) vert et
-- (b) rouge.
--
-- ATTENDU : douze lignes, 'jugement' a 'OK' partout. Puis, apres le
-- rollback, le compte de restes a 0.
--
-- begin;
--
-- create temporary table p3_resultats (
--     cas text, verdict text, attendu text) on commit drop;
--
-- do $p3$
-- declare
--     v_id bigint;
--     r    record;
-- begin
--     -- Une ligne d'appui, en 'traitee' : la borne de COHERENCE admet
--     -- une adresse a cette etape, ce qui isole la borne de FORME.
--     insert into public.demandes (titre, statut, decideur)
--     values ('P-3 forme -- A ROLLBACK', 'traitee', 'AH')
--     returning id into v_id;
--
--     for r in
--         select * from (values
--           ('01 adresse valide, slug compose', 'https://pilote.cdatso.be/films/le-chateau-ambulant.html', 'ACCEPTEE'),
--           ('02 adresse valide, slug simple',  'https://pilote.cdatso.be/films/rose.html',                'ACCEPTEE'),
--           ('03 autre domaine',                'https://www.cdatso.be/films/le-chateau-ambulant.html',    'REFUSEE'),
--           ('04 domaine-leurre en suffixe',    'https://pilote.cdatso.be.evil.be/films/rose.html',        'REFUSEE'),
--           ('05 domaine-leurre en prefixe',    'https://evil.be/pilote.cdatso.be/films/rose.html',        'REFUSEE'),
--           ('06 http en clair',                'http://pilote.cdatso.be/films/rose.html',                 'REFUSEE'),
--           ('07 chemin hors films/',           'https://pilote.cdatso.be/docs/journal-pilote.html',       'REFUSEE'),
--           ('08 remontee de chemin',           'https://pilote.cdatso.be/films/../docs/secret.html',      'REFUSEE'),
--           ('09 chaine de requete',            'https://pilote.cdatso.be/films/rose.html?x=1',            'REFUSEE'),
--           ('10 majuscules dans le slug',      'https://pilote.cdatso.be/films/Le-Chateau.html',          'REFUSEE'),
--           ('11 schema javascript',            'javascript:alert(1)',                                     'REFUSEE'),
--           ('12 valide + SAUT DE LIGNE final', 'https://pilote.cdatso.be/films/rose.html' || chr(10),      'REFUSEE')
--         ) as t(cas, valeur, attendu)
--     loop
--         begin
--             update public.demandes set page_pilote = r.valeur where id = v_id;
--             insert into p3_resultats values (r.cas, 'ACCEPTEE', r.attendu);
--         exception when check_violation then
--             insert into p3_resultats values (r.cas, 'REFUSEE', r.attendu);
--         end;
--     end loop;
-- end
-- $p3$;
--
-- select cas, verdict, attendu,
--        case when verdict = attendu then 'OK' else '>>> ECART <<<' end as jugement
--   from p3_resultats
--  order by cas;
--
-- rollback;
--
-- APRES le rollback -- attendu : 0.
--
-- select count(*) as restes
--   from public.demandes
--  where titre like 'P-3 %A ROLLBACK%';
--
-- ---------------------------------------------------------------------
-- P-4 -- LA BORNE DE COHERENCE MORD, DES DEUX COTES.
-- ---------------------------------------------------------------------
-- Elle dit deux choses, et il faut prouver les deux dans les deux sens :
--   publiee_pilote  => adresse NON NULLE ;
--   adresse non nulle => publiee_pilote ou traitee.
-- Six cas : trois qui doivent PASSER, trois qui doivent etre REFUSES. Un
-- controle qui n'eprouverait que les refus ne dirait pas si la borne
-- laisse encore travailler la page privee.
--
-- ATTENDU : six lignes, 'jugement' a 'OK' partout. Puis, apres le
-- rollback, le compte de restes a 0.
--
-- begin;
--
-- create temporary table p4_resultats (
--     cas text, verdict text, attendu text) on commit drop;
--
-- do $p4$
-- declare
--     v_id  bigint;
--     v_url text := 'https://pilote.cdatso.be/films/le-chateau-ambulant.html';
-- begin
--     insert into public.demandes (titre, statut, decideur)
--     values ('P-4 coherence -- A ROLLBACK', 'a_traiter', 'AH')
--     returning id into v_id;
--
--     -- (1) DOIT PASSER : publiee_pilote AVEC son adresse, pose dans le
--     --     meme geste -- c'est exactement le 'PATCH' a deux champs de
--     --     la page privee.
--     begin
--         update public.demandes
--            set statut = 'publiee_pilote', page_pilote = v_url
--          where id = v_id;
--         insert into p4_resultats values ('1 publiee_pilote AVEC adresse', 'ACCEPTE', 'ACCEPTE');
--     exception when check_violation then
--         insert into p4_resultats values ('1 publiee_pilote AVEC adresse', 'REFUSE', 'ACCEPTE');
--     end;
--
--     -- (2) DOIT PASSER : adoption -- vers traitee, l'adresse RESTE.
--     --     Une page adoptee garde la memoire de son adresse d'essai.
--     begin
--         update public.demandes set statut = 'traitee' where id = v_id;
--         insert into p4_resultats values ('2 vers traitee, adresse gardee', 'ACCEPTE', 'ACCEPTE');
--     exception when check_violation then
--         insert into p4_resultats values ('2 vers traitee, adresse gardee', 'REFUSE', 'ACCEPTE');
--     end;
--
--     -- (3) DOIT PASSER : retour a publiee_pilote, adresse toujours la.
--     begin
--         update public.demandes set statut = 'publiee_pilote' where id = v_id;
--         insert into p4_resultats values ('3 retour a publiee_pilote', 'ACCEPTE', 'ACCEPTE');
--     exception when check_violation then
--         insert into p4_resultats values ('3 retour a publiee_pilote', 'REFUSE', 'ACCEPTE');
--     end;
--
--     -- (4) DOIT ETRE REFUSE : quitter publiee_pilote vers mise_de_cote
--     --     SANS remettre l'adresse a NUL. C'est l'erreur que la page
--     --     privee evite en posant 'page_pilote: null' dans le MEME
--     --     PATCH -- et que la base doit refuser si la page l'oubliait.
--     begin
--         update public.demandes set statut = 'mise_de_cote' where id = v_id;
--         insert into p4_resultats values ('4 quitter SANS vider l adresse', 'ACCEPTE', 'REFUSE');
--     exception when check_violation then
--         insert into p4_resultats values ('4 quitter SANS vider l adresse', 'REFUSE', 'REFUSE');
--     end;
--
--     -- (5) DOIT ETRE REFUSE : publiee_pilote SANS adresse. Une carte de
--     --     la rubrique "Publiees a l'essai" sans lien promettrait ce
--     --     qu'elle ne peut pas tenir.
--     begin
--         update public.demandes
--            set statut = 'publiee_pilote', page_pilote = null
--          where id = v_id;
--         insert into p4_resultats values ('5 publiee_pilote SANS adresse', 'ACCEPTE', 'REFUSE');
--     exception when check_violation then
--         insert into p4_resultats values ('5 publiee_pilote SANS adresse', 'REFUSE', 'REFUSE');
--     end;
--
--     -- (6) DOIT ETRE REFUSE : une adresse sur une demande 'a_traiter'.
--     --     Seules publiee_pilote et traitee en portent une.
--     begin
--         update public.demandes
--            set statut = 'a_traiter', page_pilote = v_url
--          where id = v_id;
--         insert into p4_resultats values ('6 adresse sur a_traiter', 'ACCEPTE', 'REFUSE');
--     exception when check_violation then
--         insert into p4_resultats values ('6 adresse sur a_traiter', 'REFUSE', 'REFUSE');
--     end;
-- end
-- $p4$;
--
-- select cas, verdict, attendu,
--        case when verdict = attendu then 'OK' else '>>> ECART <<<' end as jugement
--   from p4_resultats
--  order by cas;
--
-- rollback;
--
-- APRES le rollback -- attendu : 0.
--
-- select count(*) as restes
--   from public.demandes
--  where titre like 'P-4 %A ROLLBACK%';
--
-- ---------------------------------------------------------------------
-- P-5 -- LE JOURNAL EST FIGE, MAIS IL ECRIT ENCORE.
-- ---------------------------------------------------------------------
-- LES DEUX COTES, et le premier est le plus important : une garde qui
-- refuserait AUSSI l'insert tuerait la journalisation EN SILENCE, et
-- tous les controles resteraient verts sur un journal muet.
--   (1) une creation et un changement d'etape ECRIVENT bien deux lignes ;
--   (2) 'update' sur une ligne du journal est REFUSE ;
--   (3) 'delete' sur une ligne du journal est REFUSE ;
--   (4) 'truncate' de la table est REFUSE.
--
-- LE CAS (4) EST DANS LE BLOC 'do' A DESSEIN : il n'existe AUCUNE ligne
-- 'truncate' isolee dans ce fichier qu'un humain pourrait selectionner
-- et jouer seule. TRUNCATE est transactionnel dans PostgreSQL -- le
-- rollback le defait -- mais on ne laisse pas trainer l'occasion.
--
-- ATTENDU : cinq lignes, 'jugement' a 'OK' partout. Puis, apres le
-- rollback, DEUX comptes de restes a 0.
--
-- begin;
--
-- create temporary table p5_resultats (
--     cas text, verdict text, attendu text) on commit drop;
--
-- do $p5$
-- declare
--     v_id     bigint;
--     v_jid    bigint;
--     v_avant  integer;
--     v_apres  integer;
-- begin
--     select count(*) into v_avant from public.demandes_journal;
--
--     insert into public.demandes (titre, statut, decideur)
--     values ('P-5 journal -- A ROLLBACK', 'proposee', 'AH')
--     returning id into v_id;
--
--     update public.demandes set statut = 'a_traiter' where id = v_id;
--
--     select count(*) into v_apres from public.demandes_journal;
--
--     -- (1) L'INSERT PASSE : une ligne 'creation' et une ligne 'etape'.
--     insert into p5_resultats
--     values ('1 lignes de journal ecrites', (v_apres - v_avant)::text, '2');
--
--     select id into v_jid
--       from public.demandes_journal
--      where demande_id = v_id
--      order by id
--      limit 1;
--
--     -- (2) UPDATE : refuse.
--     begin
--         update public.demandes_journal set apres = 'falsifie' where id = v_jid;
--         insert into p5_resultats values ('2 update d une ligne', 'ACCEPTE', 'REFUSE');
--     exception when check_violation then
--         insert into p5_resultats values ('2 update d une ligne', 'REFUSE', 'REFUSE');
--     end;
--
--     -- (3) DELETE : refuse.
--     begin
--         delete from public.demandes_journal where id = v_jid;
--         insert into p5_resultats values ('3 delete d une ligne', 'ACCEPTE', 'REFUSE');
--     exception when check_violation then
--         insert into p5_resultats values ('3 delete d une ligne', 'REFUSE', 'REFUSE');
--     end;
--
--     -- (4) TRUNCATE : refuse.
--     begin
--         truncate table public.demandes_journal;
--         insert into p5_resultats values ('4 truncate de la table', 'ACCEPTE', 'REFUSE');
--     exception when check_violation then
--         insert into p5_resultats values ('4 truncate de la table', 'REFUSE', 'REFUSE');
--     end;
--
--     -- (5) RIEN N'A DISPARU : le compte est celui d'avant les trois
--     --     tentatives. Si le truncate etait passe, ce nombre serait 0.
--     insert into p5_resultats
--     values ('5 lignes de journal encore la',
--             (select count(*) from public.demandes_journal)::text,
--             (v_apres)::text);
-- end
-- $p5$;
--
-- select cas, verdict, attendu,
--        case when verdict = attendu then 'OK' else '>>> ECART <<<' end as jugement
--   from p5_resultats
--  order by cas;
--
-- rollback;
--
-- APRES le rollback -- attendu : 0 et 0.
--
-- select (select count(*) from public.demandes
--          where titre like 'P-5 %A ROLLBACK%') as demandes_restantes,
--        (select count(*) from public.demandes_journal j
--           join public.demandes d on d.id = j.demande_id
--          where d.titre like 'P-5 %A ROLLBACK%')  as journal_restant;
--
-- SI UNE SEULE LIGNE DE P-3, P-4 OU P-5 REND '>>> ECART <<<' : la borne
-- correspondante ne fait pas ce qu'elle annonce. ARRET, et on le signale
-- -- on ne "reessaie" pas, et on ne passe pas a la suite.
-- ---------------------------------------------------------------------
