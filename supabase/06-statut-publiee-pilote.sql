-- 06-statut-publiee-pilote.sql
-- Ajoute la HUITIEME valeur de statut, 'publiee_pilote', la colonne
-- d'ADRESSE de page 'page_pilote' et ses deux bornes EN BASE ; expose
-- l'adresse par la vue publique ; accorde a la page privee le droit de
-- l'ecrire ; et FIGE demandes_journal contre update, delete et truncate.
-- BKL-CIN-098 lot S, 19/09/2026.
--
-- !!! CE SCRIPT NE CONTIENT NI 'drop table' NI 'drop view' : C'EST LUI, ET
-- !!! NON 01-table-demandes.sql, QUI SE JOUE SUR LA BASE EN PRODUCTION.
-- !!! 01 commence par 'drop view' puis 'drop table' : le rejouer en
-- !!! production DETRUIRAIT toutes les demandes.
-- !!! Les seuls 'drop' ci-dessous portent sur des CONTRAINTES et des
-- !!! DECLENCHEURS, aussitot reposes dans la meme transaction. La vue est
-- !!! remplacee par 'create or replace view' -- elle n'est PAS detruite,
-- !!! et aucun objet ne nait donc expose par les droits par defaut du
-- !!! schema public (R-023, pg_default_acl). Ses droits sont malgre tout
-- !!! RAPPELES plus bas : on les prouve par controle, on ne les suppose
-- !!! pas (lecon de 05 section 1).
--
-- ---------------------------------------------------------------------
-- POURQUOI (BKL-CIN-098, cadrage du 19/09/2026 ; RISKLOG R-030)
-- ---------------------------------------------------------------------
-- Le 19/09/2026, la chaine pilote a publie sa premiere page. Deux
-- limites de conception sont apparues du cote du service :
--   (1) la rubrique "Traitees" de la file publique MENTAIT : une demande
--       publiee sur la surface PILOTE -- non relue, noindex, hors du
--       site -- y etait rangee faute d'une etape propre ;
--   (2) aucune carte ne portait de LIEN vers la page publiee.
-- Decision d'AH du 19/09/2026 : conception "A avec B" et "D". Ce script
-- est la part EN BASE de "A" : une huitieme etape, 'publiee_pilote', et
-- une adresse de page BORNEE.
--
-- CE QUE CE SCRIPT N'AUTORISE PAS. 'publiee_pilote' est une etape de
-- CONSTAT : elle dit "la chaine a publie, et AH l'a vu". Elle n'arme
-- rien, elle ne declenche rien, et elle ne vaut AUCUN gate de
-- production (R-009, R-010, R-011). L'etape qui ARME reste
-- 'publication_pilote' (04-etape-publication-pilote.sql).
--
-- QUI POSE L'ADRESSE : AH SEUL, depuis la page privee. La chaine pilote
-- ne detient qu'une clef de LECTURE et n'ecrit JAMAIS en base (critere
-- eliminatoire E1 de BKL-CIN-096). C'est donc AH qui decide quand le
-- lien apparait sur la file publique.
--
-- POURQUOI LA BORNE DE FORME EST EN BASE, ET NON DANS LA PAGE SEULE :
-- file.html AFFICHERA ce lien a un visiteur. Un lien affiche sur une
-- page publique ne doit jamais pouvoir etre arbitraire. La page rejoue
-- la MEME expression reguliere (defense en profondeur : la page ne fait
-- pas confiance a la base), mais c'est la base qui REFUSE.
--
-- POURQUOI UNE COLONNE DEDIEE, ET NON 'slug_existant' : 'slug_existant'
-- veut dire "deja analyse EN PRODUCTION au depot". Les deux corpus
-- restent disjoints ; reemployer la colonne les melangerait.
--
-- ---------------------------------------------------------------------
-- LES DEUX REPARATIONS GROUPEES ICI (constats du 19/09/2026)
-- ---------------------------------------------------------------------
-- Elles touchent les memes objets, elles voyagent donc dans le meme SQL.
--   (a) Le sens de demandes_journal.par NUL : il ne veut PAS dire "le
--       formulaire public" seul. Un geste fait au tableau de bord
--       Supabase (role proprietaire) rend 'par' NUL lui aussi. Cette
--       correction est ecrite dans les COMMENTAIRES de
--       05-page-privee-w2.sql et dans le guide -- aucune ligne de CODE
--       de 05 ne change.
--   (b) demandes_journal n'etait protege NI contre UPDATE, NI contre
--       DELETE : AH l'a modifie par erreur le 19/09, sans qu'aucune
--       trace n'en reste. La section 7 ci-dessous pose la parade.
--
-- ---------------------------------------------------------------------
-- ORDRE DES GESTES -- il compte
-- ---------------------------------------------------------------------
-- 1. file.html et admin.html portant l'etape 'publiee_pilote' sont
--    DEPLOYEES et constatees en ligne D'ABORD. Sans elles, une ligne a
--    cette etape ne serait pas affichee et la file montrerait
--    "Attention : N demande(s) portent une etape inconnue".
-- 2. PUIS ce script, par AH, dans le SQL Editor de Supabase (tout
--    selectionner, Run). Attendu : Success, puis le tableau de controle
--    immediat de la fin du fichier, a CINQ lignes.
-- 3. PUIS 02-controles-demandes.sql EN ENTIER : vingt-cinq lignes,
--    chacune conforme a son attendu.
-- 4. PUIS les epreuves P-3, P-4 et P-5 de 02, SEPAREMENT : elles
--    prouvent que les bornes MORDENT, et elles ne laissent RIEN en base.
-- 5. PUIS, et seulement alors, le bloc R-1 ci-dessous (geste unique de
--    reprise de la demande n.2).
-- 6. PUIS 02 une seconde fois : le controle 7 doit rester a 0, et la
--    demande n.2 doit avoir quitte 'traitee'.
--
-- Si la contrainte de statut ne porte pas le nom attendu, le
-- 'drop constraint' de la section 1 echoue, la transaction est annulee,
-- et RIEN ne change : on s'arrete et on le signale.
--
-- ---------------------------------------------------------------------
-- IDEMPOTENCE -- ce qui se rejoue, et ce qui ne se rejoue pas
-- ---------------------------------------------------------------------
-- Se rejouent sans effet de bord : la colonne ('if not exists'), les
-- deux contraintes de page_pilote ('drop ... if exists' puis 'add'), la
-- vue ('create or replace'), les revoke et les grant, la fonction
-- ('create or replace'), les deux declencheurs ('drop ... if exists'
-- puis 'create').
-- La section 1 se rejoue elle aussi : le 'drop constraint' trouve la
-- contrainte a huit valeurs et la repose identique. Le script entier est
-- donc rejouable -- ce qui n'est PAS une invitation a le rejouer.
--
-- Fichier destine a une MACHINE (colle dans l'editeur SQL de Supabase) :
-- UTF-8 SANS BOM, ASCII pur, comme ses voisins.

begin;

-- ---------------------------------------------------------------------
-- 1. LA HUITIEME VALEUR DE STATUT -- le geste de 04, a l'identique.
-- ---------------------------------------------------------------------
-- 'publiee_pilote' est placee JUSTE APRES 'publication_pilote' : l'ordre
-- de la liste est celui du cycle de vie d'une demande, et il se lit.
--
-- CYCLE DE VIE, tel que le cadrage du 19/09 le fixe :
--   proposee -> a_traiter -> publication_pilote  (AH arme ; la chaine
--                                                 publie)
--                         -> publiee_pilote      (AH constate et donne
--                                                 l'adresse)
--                         -> traitee             (si AH adopte la page
--                                                 au site)
-- Sinon la demande RESTE en 'publiee_pilote'. Le raccourci
-- 'publication_pilote' -> 'traitee' est RETIRE de la page privee
-- (decision d'AH du 19/09) : c'est une convention d'interface, pas une
-- borne de la base -- l'API accepterait encore ce passage.
alter table public.demandes
    drop constraint demandes_statut_check;

alter table public.demandes
    add constraint demandes_statut_check check (statut in (
        'proposee', 'a_traiter', 'publication_pilote', 'publiee_pilote',
        'scholar', 'candidat', 'mise_de_cote', 'traitee'));

-- ---------------------------------------------------------------------
-- 2. LA COLONNE D'ADRESSE.
-- ---------------------------------------------------------------------
-- 'text null' : une demande n'a d'adresse de page d'essai que si la
-- chaine en a publie une. NUL est l'etat normal de la quasi-totalite des
-- lignes.
alter table public.demandes
    add column if not exists page_pilote text null;

comment on column public.demandes.page_pilote is
    'Adresse de la page publiee sur la surface d essai pilote.cdatso.be (BKL-CIN-098 lot S, 19/09/2026). Posee par AH SEUL depuis la page privee ; la chaine pilote n ecrit jamais en base. Bornee en FORME et en COHERENCE par deux contraintes. A ne pas confondre avec slug_existant, qui veut dire "deja analyse EN PRODUCTION au depot".';

-- ---------------------------------------------------------------------
-- 3. LA BORNE DE FORME -- l'adresse est nulle, ou elle est exactement
--    une page de films de la surface d'essai.
-- ---------------------------------------------------------------------
-- L'EXPRESSION EST LA MEME dans les TROIS endroits : ici, dans file.html
-- et dans admin.html. Si l'une des trois change, les trois changent --
-- sinon la page afficherait un lien que la base refuserait, ou
-- l'inverse.
--
-- CE QU'ELLE EXIGE, morceau par morceau :
--   ^https://                schema en clair, et lui seul ('http://' est
--                            refuse : la surface d'essai est en HTTPS)
--   pilote\.cdatso\.be       l'hote EXACT, points ECHAPPES -- sans
--                            echappement, '.' apparierait n'importe quel
--                            caractere, et 'piloteXcdatsoYbe' passerait
--   /films/                  le chemin, et lui seul
--   [a-z0-9]+(-[a-z0-9]+)*   le slug : minuscules, chiffres, tirets
--                            SIMPLES entre groupes. Ni majuscule, ni
--                            point, ni barre oblique, ni chaine de
--                            requete -- donc '../' ne peut pas y entrer
--   \.html$                  l'extension, et FIN DE CHAINE
--
-- LE CAS QU'IL FAUT CONNAITRE : UN SAUT DE LIGNE FINAL. En Python, '$'
-- tolere un saut de ligne terminal -- une adresse valide SUIVIE d'un
-- saut de ligne y PASSE. PostgreSQL, hors mode "newline-sensitive", fait
-- apparier '$' a la FIN DE CHAINE seulement ; JavaScript sans
-- l'indicateur 'm' fait de meme. Les deux devraient donc REFUSER ce cas.
-- ON NE LE SUPPOSE PAS : l'epreuve P-3 de 02-controles-demandes.sql le
-- mesure ici, et la passe D de outils/controler-proprete.mjs le mesure
-- dans JavaScript, sur l'expression LUE aux deux pages servies.
alter table public.demandes
    drop constraint if exists demandes_page_pilote_forme_check;

alter table public.demandes
    add constraint demandes_page_pilote_forme_check check (
        page_pilote is null
        or page_pilote ~ '^https://pilote\.cdatso\.be/films/[a-z0-9]+(-[a-z0-9]+)*\.html$');

-- ---------------------------------------------------------------------
-- 4. LA BORNE DE COHERENCE -- l'etape et l'adresse ne se contredisent
--    jamais.
-- ---------------------------------------------------------------------
-- DEUX IMPLICATIONS, et il faut les deux :
--   (i)  statut = 'publiee_pilote'  =>  page_pilote NON NUL.
--        Une demande rangee dans la rubrique "Publiees a l'essai" sans
--        adresse serait une carte sans lien : la rubrique promettrait ce
--        qu'elle ne peut pas tenir.
--   (ii) page_pilote NON NUL  =>  statut dans ('publiee_pilote',
--        'traitee').
--        'traitee' est admis parce qu'une page ADOPTEE au site garde la
--        memoire de son adresse d'essai : la page pilote n'est jamais
--        retouchee et reste en ligne telle quelle (cadrage du 19/09,
--        chantier "D"). TOUTE AUTRE ETAPE remet l'adresse a NUL -- c'est
--        ce que la page privee fait dans le MEME 'PATCH' quand elle
--        quitte 'publiee_pilote' vers 'a_traiter' ou 'mise_de_cote'.
--
-- ECRITES EN UNE SEULE CONTRAINTE, et non deux : les deux implications
-- disent la meme chose -- "l'etape et l'adresse s'accordent" -- et un
-- refus doit nommer LA regle violee, pas la moitie. Le message d'erreur
-- cite le nom de la contrainte ; ce commentaire-ci en donne la lecture.
alter table public.demandes
    drop constraint if exists demandes_page_pilote_coherence_check;

alter table public.demandes
    add constraint demandes_page_pilote_coherence_check check (
        (statut <> 'publiee_pilote' or page_pilote is not null)
        and (page_pilote is null or statut in ('publiee_pilote', 'traitee')));

-- ---------------------------------------------------------------------
-- 5. LA VUE PUBLIQUE -- 'page_pilote' ajoutee EN DERNIER.
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
-- transaction est annulee, rien ne change, on s'arrete et on le signale
-- -- c'est un cas d'elicitation nomme au mandat (lot S, rubrique 5).
--
-- NI 'mail' NI 'motif' : le controle de confidentialite d'origine
-- (arbitrage n.3) est inchange. La vue passe de DIX a ONZE colonnes.
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
       page_pilote
  from public.demandes;

-- LES DROITS DE LA VUE, RAPPELES (idempotents). 'create or replace view'
-- ne detruit pas l'objet et devrait donc conserver son ACL -- mais la
-- lecon de 05 section 1 vaut ici : un objet recree ne garde pas
-- forcement ses droits, on ne le SUPPOSE pas. Ces trois lignes sont
-- celles de 03-droits-vue-publique.sql, sans un mot de plus, et le
-- controle n.12 de 02 les mesure APRES coup.
revoke insert, update, delete, truncate, references, trigger
    on public.demandes_publiques from anon, authenticated;
revoke select on public.demandes_publiques from authenticated;
grant select on public.demandes_publiques to anon;

-- ---------------------------------------------------------------------
-- 6. LE DROIT D'ECRIRE L'ADRESSE -- par COLONNE, au seul role
--    authenticated.
-- ---------------------------------------------------------------------
-- 05 accordait 'update (statut)'. La page privee doit desormais ecrire
-- DEUX colonnes dans un meme 'PATCH' : l'etape et l'adresse. Un droit de
-- colonne ne s'herite pas de la table : sans cette ligne, le 'PATCH' a
-- deux champs serait refuse (42501) et la page ne pourrait plus poser
-- 'publiee_pilote'.
--
-- CE QUI N'EST PAS ACCORDE, et c'est l'essentiel : ni titre, ni motif,
-- ni mail, ni decideur, ni slug_existant. La borne "la page ne change
-- QUE l'etape" devient "la page ne change QUE l'etape et l'adresse de la
-- page d'essai" -- pas un champ de plus. Controle n.23 de 02.
--
-- LA POLICY 'demandes_ah_etape' N'EST PAS TOUCHEE : elle borne deja les
-- LIGNES au seul compte d'AH, et elle continue de le faire pour cette
-- colonne comme pour l'autre. L'UUID d'AH n'apparait nulle part dans ce
-- fichier, et le marqueur du parametre d'UUID de 05 reste tel quel.
grant update (statut, page_pilote) on public.demandes to authenticated;

-- ---------------------------------------------------------------------
-- 7. LE JOURNAL, FIGE -- ni mise a jour, ni suppression, ni vidage.
-- ---------------------------------------------------------------------
-- CE QUE CETTE PARADE EST, ET CE QU'ELLE N'EST PAS.
-- Elle protege contre l'ERREUR, pas contre le proprietaire. Le 19/09, AH
-- a modifie une ligne de demandes_journal par erreur au tableau de bord,
-- et rien n'en a garde trace. Un declencheur arrete ce geste-la. Il
-- n'arrete PAS quelqu'un qui detient le role proprietaire et qui VEUT
-- passer outre : 'alter table ... disable trigger' suffit, et c'est
-- normal -- aucune parade en base ne tient contre son proprietaire. Ce
-- qui change, c'est qu'effacer une trace devient un geste DELIBERE et
-- NOMME, au lieu d'un clic.
--
-- CE QUI N'EST PAS GENE : l'INSERT. Le declencheur de journalisation
-- (prive.journaliser_demande, 05 section 4a) ecrit dans cette table a
-- chaque creation et a chaque changement d'etape. On ne fige que
-- 'update', 'delete' et 'truncate' : la table reste en ecriture SEULE
-- PAR AJOUT, ce qu'un journal doit etre. L'epreuve P-5 de 02 le prouve
-- des DEUX cotes -- l'insert passe, l'update et le delete sont refuses.
--
-- FONCTION DANS LE SCHEMA 'prive', comme ses trois soeurs : le schema
-- n'est pas expose a l'API (05 section 2), le 'search_path' est fixe a
-- la chaine vide et tout est qualifie, et les droits d'execution sont
-- retires. Memes raisons : une fonction 'security definer' au
-- 'search_path' mutable est la voie classique de l'elevation de
-- privilege.
--
-- DEUX DECLENCHEURS ET NON UN : PostgreSQL exige qu'un declencheur
-- 'truncate' soit de niveau INSTRUCTION ('for each statement') -- il n'y
-- a pas de ligne a lui montrer. 'update' et 'delete' sont de niveau
-- LIGNE, pour que le refus nomme le geste au moment ou il se produit.
create or replace function prive.refuser_modification_journal()
    returns trigger
    language plpgsql
    security definer
    set search_path = ''
as $fn$
begin
    raise exception
        'demandes_journal est une TRACE : elle ne se modifie pas, ne se supprime pas et ne se vide pas (geste refuse : %). Une correction se fait par une ligne DE PLUS, jamais en effacant.',
        tg_op
        using errcode = 'check_violation';
    return null;
end
$fn$;

-- PostgreSQL accorde EXECUTE a PUBLIC par defaut : on le retire, comme
-- pour les trois fonctions de 05 (l. 409-414). Le declencheur, lui,
-- s'execute hors de ce controle.
revoke all on function prive.refuser_modification_journal() from public;
revoke all on function prive.refuser_modification_journal() from anon, authenticated;

drop trigger if exists demandes_journal_fige_ligne_trg on public.demandes_journal;
create trigger demandes_journal_fige_ligne_trg
    before update or delete on public.demandes_journal
    for each row execute function prive.refuser_modification_journal();

drop trigger if exists demandes_journal_fige_instruction_trg on public.demandes_journal;
create trigger demandes_journal_fige_instruction_trg
    before truncate on public.demandes_journal
    for each statement execute function prive.refuser_modification_journal();

-- ---------------------------------------------------------------------
-- 7 bis. LE COMMENTAIRE DE LA TABLE, CORRIGE -- AJOUT DECLARE.
-- ---------------------------------------------------------------------
-- LE MANDAT NE DEMANDAIT PAS CETTE LIGNE : il demandait de corriger le
-- sens de 'par' NUL dans les COMMENTAIRES de 05 et dans le guide. Or il
-- existe un TROISIEME porteur de la meme phrase fausse, et c'est le
-- seul que ni 05 ni le guide ne peuvent atteindre : le commentaire
-- STOCKE EN BASE, pose par 05 l. 188-189 --
--   "par NON NUL = page privee ; par NUL = clef secrete, donc
--    qualifier.mjs, donc le formulaire public."
-- C'est ce texte-la que lit quiconque ouvre la table au tableau de
-- bord. Le laisser faux aurait laisse la correction a moitie faite.
--
-- Cette ligne ne touche AUCUNE ligne de code de 05 : 'comment on' ne
-- change ni structure, ni donnee, ni droit -- seulement l'etiquette. Si
-- AH prefere la retirer, il suffit de supprimer cette instruction : le
-- reste du script est intact.
comment on table public.demandes_journal is
    'Trace des gestes sur public.demandes (BKL-CIN-096 lot 2, 18/09/2026 ; commentaire corrige et table FIGEE le 19/09/2026, BKL-CIN-098 lot S). par NON NUL = ecriture par un compte AUTHENTIFIE, donc la page privee. par NUL = ecriture SANS compte authentifie : soit la clef secrete (qualifier.mjs, donc le formulaire public), soit le TABLEAU DE BORD Supabase (role proprietaire). Le journal seul ne separe pas ces deux cas. Table en ecriture SEULE PAR AJOUT : update, delete et truncate sont refuses par declencheur.';

commit;

-- ---------------------------------------------------------------------
-- CONTROLE IMMEDIAT (LECTURE SEULE) -- ce que la transaction a pose.
-- ---------------------------------------------------------------------
-- Attendu, dans l'ordre :
--   contrainte de statut ........ huit valeurs, publiee_pilote apres publication_pilote
--   colonne page_pilote ......... text / YES
--   contraintes de page_pilote .. 2 | demandes_page_pilote_coherence_check, demandes_page_pilote_forme_check
--   vue : colonnes / derniere ... 11 / page_pilote
--   declencheurs du journal ..... 2 | demandes_journal_fige_instruction_trg, demandes_journal_fige_ligne_trg
--
-- La recette complete est 02-controles-demandes.sql (vingt-cinq lignes),
-- et la PREUVE QUE LES BORNES MORDENT est dans ses blocs P-3, P-4 et
-- P-5. Sans eux, ces cinq lignes seraient vertes sur des bornes mortes
-- (lecon du 18/09/2026 : le plafond etait inerte, et tout etait vert).
select 'contrainte de statut' as controle,
       coalesce((select pg_get_constraintdef(oid) from pg_constraint
                  where conrelid = 'public.demandes'::regclass
                    and conname = 'demandes_statut_check'), '(absente)') as mesure,
       'huit valeurs, publiee_pilote apres publication_pilote' as attendu
union all
select 'colonne page_pilote : type / nullable',
       coalesce((select data_type || ' / ' || is_nullable
                   from information_schema.columns
                  where table_schema = 'public' and table_name = 'demandes'
                    and column_name = 'page_pilote'), '(absente)'),
       'text / YES'
union all
select 'contraintes de page_pilote',
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
select 'vue publique : colonnes / derniere',
       (select count(*)::text from information_schema.columns
         where table_schema = 'public' and table_name = 'demandes_publiques')
       || ' / ' ||
       coalesce((select column_name from information_schema.columns
                  where table_schema = 'public' and table_name = 'demandes_publiques'
                  order by ordinal_position desc limit 1), '(aucune)'),
       '11 / page_pilote'
union all
select 'declencheurs de demandes_journal',
       (select count(*)::text from pg_trigger
         where tgrelid = 'public.demandes_journal'::regclass and not tgisinternal)
       || ' | ' ||
       coalesce((select string_agg(tgname, ', ' order by tgname) from pg_trigger
                  where tgrelid = 'public.demandes_journal'::regclass
                    and not tgisinternal), '(aucun)'),
       '2 | demandes_journal_fige_instruction_trg, demandes_journal_fige_ligne_trg';

-- ---------------------------------------------------------------------
-- R-1 -- GESTE UNIQUE DE REPRISE, en commentaire.
-- A jouer par AH APRES le reste (ordre des gestes, point 5), UNE SEULE
-- FOIS.
-- ---------------------------------------------------------------------
-- POURQUOI. La demande n.2, "Le Chateau ambulant", est le PREMIER film
-- publie par la chaine pilote (19/09/2026). Elle a ete rangee en
-- 'traitee' le 19/09 a 08h01 FAUTE DE MIEUX -- le statut
-- 'publiee_pilote' n'existait pas encore. Ce bloc la remet a sa place et
-- lui donne son adresse. C'est ce geste, et lui seul, qui fera
-- apparaitre le premier lien dans la rubrique "Publiees a l'essai (non
-- relues)" de file.html.
--
-- CE QU'IL LAISSERA AU JOURNAL, ET C'EST ATTENDU : une ligne 'etape',
-- 'traitee' -> 'publiee_pilote', avec 'par' A NUL. 'par' NUL ne veut PAS
-- dire "le formulaire public" : il veut dire "ecriture sans compte
-- authentifie", ce qui recouvre AUSSI le tableau de bord Supabase, par
-- lequel ce bloc se joue. Voir la correction du 19/09 dans les
-- commentaires de 05-page-privee-w2.sql.
--
-- LE FILTRE 'and statut = traitee' N'EST PAS DECORATIF : si la demande a
-- deja bouge, la commande ne touche AUCUNE ligne et le dit (UPDATE 0) --
-- au lieu d'ecraser un etat qu'on n'a pas sous les yeux.
--
-- (a) LECTURE prealable -- attendu : 1 ligne, statut 'traitee',
--     page_pilote a NUL.
--
-- select id, titre, statut, page_pilote
--   from public.demandes
--  where id = 2;
--
-- (b) Le geste lui-meme -- attendu : UPDATE 1.
--
-- update public.demandes
--    set statut = 'publiee_pilote',
--        page_pilote = 'https://pilote.cdatso.be/films/le-chateau-ambulant.html'
--  where id = 2
--    and statut = 'traitee';
--
-- (c) LECTURE de constat -- attendu : 1 ligne, 'publiee_pilote', et
--     l'adresse ; puis la ligne de journal. L'UUID ne s'affiche JAMAIS :
--     on lit 'par is not null', pas 'par'.
--
-- select id, titre, statut, page_pilote
--   from public.demandes
--  where id = 2;
--
-- select id, demande_id, geste, avant, apres, par is not null as par_non_nul, a
--   from public.demandes_journal
--  where demande_id = 2
--  order by id desc
--  limit 3;
--
-- ---------------------------------------------------------------------
-- RETOUR ARRIERE -- en commentaire, a ne jouer que sur decision d'AH.
-- ---------------------------------------------------------------------
-- IL EST SYMETRIQUE, ET IL A UNE CONDITION DE VALIDITE : aucune ligne ne
-- doit porter la valeur 'publiee_pilote', ni une adresse. Sinon le
-- 'add constraint' de la contrainte a sept valeurs echoue (une
-- contrainte est verifiee sur TOUTES les lignes), la transaction est
-- annulee, et l'etat a huit valeurs reste en place : il faut d'abord
-- qu'AH decide du sort de ces demandes.
--
-- (a) LECTURE prealable -- attendu : 0 / 0.
--
-- select (select count(*) from public.demandes where statut = 'publiee_pilote') as a_l_etape,
--        (select count(*) from public.demandes where page_pilote is not null)   as avec_adresse;
--
-- (b) Le retour arriere lui-meme, si (a) rend 0 / 0.
--
-- begin;
--
-- drop trigger if exists demandes_journal_fige_ligne_trg on public.demandes_journal;
-- drop trigger if exists demandes_journal_fige_instruction_trg on public.demandes_journal;
-- drop function if exists prive.refuser_modification_journal();
--
-- -- Le commentaire de la table, rendu a son texte du 18/09/2026. Il
-- -- redeviendra faux sur le sens de 'par' NUL : c'est le prix du
-- -- retour arriere, et il se dit.
-- comment on table public.demandes_journal is
--     'Trace des gestes sur public.demandes (BKL-CIN-096 lot 2, 18/09/2026). par NON NUL = page privee ; par NUL = clef secrete, donc qualifier.mjs, donc le formulaire public.';
--
-- alter table public.demandes
--     drop constraint if exists demandes_page_pilote_coherence_check;
-- alter table public.demandes
--     drop constraint if exists demandes_page_pilote_forme_check;
--
-- -- LA VUE AVANT LA COLONNE : une vue qui lit une colonne empeche son
-- -- 'drop column'.
-- create or replace view public.demandes_publiques as
-- select id, created_at, titre, realisateur, annee, deja_analyse,
--        slug_existant, qualification, statut, decideur
--   from public.demandes;
--
-- revoke insert, update, delete, truncate, references, trigger
--     on public.demandes_publiques from anon, authenticated;
-- revoke select on public.demandes_publiques from authenticated;
-- grant select on public.demandes_publiques to anon;
--
-- alter table public.demandes drop column if exists page_pilote;
--
-- -- Le droit de colonne disparait AVEC la colonne ; celui de 'statut'
-- -- est repose pour que la page privee continue de fonctionner.
-- grant update (statut) on public.demandes to authenticated;
--
-- alter table public.demandes drop constraint demandes_statut_check;
-- alter table public.demandes
--     add constraint demandes_statut_check check (statut in (
--         'proposee', 'a_traiter', 'publication_pilote', 'scholar',
--         'candidat', 'mise_de_cote', 'traitee'));
--
-- commit;
--
-- Puis : rejouer le controle immediat ci-dessus (attendu : sept valeurs,
-- colonne absente, 0 contrainte de page_pilote, vue a dix colonnes,
-- 0 declencheur sur le journal), rendre 02-controles-demandes.sql,
-- file.html, admin.html, outils/controler-proprete.mjs, le guide et le
-- README a leur etat du commit dd0b41f, et repousser le service.
--
-- CE QUI NE SE DEFAIT PAS : les lignes deja ecrites dans
-- demandes_journal. C'est une trace, elle ne s'efface pas -- c'est
-- justement ce que la section 7 vient de rendre vrai.
