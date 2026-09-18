-- 05-page-privee-w2.sql
-- POSTURE W2 de la page privee d'administration (admin.html) :
--   * droits MINIMAUX, par colonne, au seul role authenticated ;
--   * TROIS policies NOMINATIVES sur public.demandes (lecture, etape,
--     creation), chacune portant l'UUID d'AH ;
--   * table public.demandes_journal : la trace EN BASE de chaque geste ;
--   * declencheur de JOURNALISATION (after insert or update) ;
--   * declencheur de PLAFOND de creation (before insert).
-- BKL-CIN-096 (b) lot 2, 18/09/2026, gate AH "go paire CIN-096 lot 2".
--
-- !!! CE SCRIPT NE CONTIENT NI 'drop table' NI 'drop view' : C'EST LUI, ET
-- !!! NON 01-table-demandes.sql, QUI SE JOUE SUR LA BASE EN PRODUCTION.
-- !!! 01 commence par 'drop view' puis 'drop table' : le rejouer en
-- !!! production DETRUIRAIT toutes les demandes.
-- !!! Les seuls 'drop' ci-dessous portent sur des POLICIES et des
-- !!! DECLENCHEURS, aussitot reposes dans la meme transaction. La table
-- !!! demandes_journal est creee par 'create table if not exists' : un
-- !!! rejeu NE DETRUIT PAS la trace deja ecrite (D-4 tenue sans perte).
--
-- =====================================================================
-- !!! AVANT DE JOUER -- UN SEUL GESTE DE SUBSTITUTION
-- =====================================================================
-- Remplace les CINQ occurrences de la chaine
--
--     <UUID-DE-AH>
--
-- par ton UUID (Supabase -> Authentication -> Users -> ton compte ->
-- colonne "UID"). Ctrl+H dans le SQL Editor, "Replace all".
--
-- CINQ, et non quatre : QUATRE sont dans le code (une a la policy de
-- lecture, DEUX a celle d'etape -- 'using' et 'with check' --, une a
-- celle de creation), la CINQUIEME est celle de la presente consigne.
-- Cette derniere est un COMMENTAIRE : la remplacer est sans effet, et
-- "Replace all" vaut mieux qu'un compte a la main. Le controle qui fait
-- foi n'est pas ce nombre, c'est le controle n.17 de
-- 02-controles-demandes.sql : "UUID distincts nommes dans les policies
-- de demandes" = 1.
--
-- NE COMMITE JAMAIS LA VALEUR. Ce depot est PUBLIC : le fichier
-- versionne garde le PARAMETRE, et la substitution vit dans l'editeur
-- SQL seul (mandat lot 2, borne L-2).
--
-- FAIL-CLOSED SI TU OUBLIES : la chaine ci-dessus n'est pas un UUID
-- valide, la conversion ::uuid leve "invalid input syntax for type
-- uuid", la transaction est ANNULEE, et RIEN ne change. Un oubli ne
-- laisse pas la base a moitie ouverte.
-- =====================================================================
--
-- ---------------------------------------------------------------------
-- CE QUI CHANGE, ET POURQUOI C'EST UN CHANGEMENT DE POSTURE
-- ---------------------------------------------------------------------
-- Jusqu'ici : "RLS activee, AUCUNE policy" (PATRON-SERVICE-SERVERLESS
-- regle D-1). L'ecriture venait du SERVEUR seul, par la clef SECRETE
-- (role service_role), qui contourne la RLS de par son role.
-- A partir d'ici : "RLS activee, POLICIES NOMINATIVES". Un second
-- chemin d'ecriture existe -- celui d'AH, authentifie par lien magique,
-- depuis admin.html. Il est borne par TROIS verrous superposes :
--   (1) les DROITS : authenticated ne recoit que select sur la table,
--       update de la SEULE colonne statut, insert de CINQ colonnes
--       nommees. Aucun delete, jamais.
--   (2) les POLICIES : chacune exige auth.uid() = l'UUID d'AH. Un autre
--       compte authentifie -- s'il en naissait un -- ne verrait rien et
--       n'ecrirait rien.
--   (3) les INSCRIPTIONS FERMEES au tableau de bord (geste d'AH) : aucun
--       autre compte ne peut naitre.
-- Le verrou (2) est le seul qui tienne si (3) cede : c'est pourquoi il
-- est NOMINATIF et non "to authenticated" tout court.
--
-- Supabase avertit que "Adding policies doesn't take those grants back" :
-- les revoke du lot 0 sont donc RAPPELES en tete ci-dessous, et ils sont
-- idempotents (un revoke d'un droit absent ne fait rien).
--
-- ---------------------------------------------------------------------
-- ECRITS QUI DEVIENNENT FAUX LE JOUR OU CE SCRIPT EST JOUE
-- ---------------------------------------------------------------------
-- * 02-controles-demandes.sql, controle n.1 (attendu '0' policy) et
--   controle n.12 : AMENDES dans le meme commit que ce fichier.
-- * 01-table-demandes.sql l. 11, l. 100-103, l. 146 : note datee posee en
--   tete de ce fichier-la, sans reecriture.
-- * 03-droits-vue-publique.sql l. 54 et l. 86 : note datee en tete.
-- * file.html l. 16 : note datee (exception nommee du mandat).
-- * PATRON-SERVICE-SERVERLESS.md regle D-1 : amendement du GREFFE, pas
--   d'ici. Ce script ne touche aucune norme.
--
-- ---------------------------------------------------------------------
-- PROVENANCE D'UNE CREATION -- resolue SANS colonne nouvelle
-- ---------------------------------------------------------------------
-- demandes_journal.par NON NUL  = ligne creee depuis la PAGE PRIVEE (AH
--                                 authentifie ; auth.uid() rend son UUID).
-- demandes_journal.par NUL      = ligne creee par la clef SECRETE, donc
--                                 par qualifier.mjs, donc par le
--                                 formulaire public.
-- La colonne 'decideur' NE DIT RIEN de la provenance : qualifier.mjs
-- l. 790 ecrit decideur='AH' pour TOUTE demande publique, et c'est aussi
-- le DEFAUT de la colonne (01-table-demandes.sql l. 90).
--
-- Fichier destine a une MACHINE (colle dans l'editeur SQL de Supabase) :
-- UTF-8 SANS BOM, ASCII pur, comme ses voisins.

begin;

-- ---------------------------------------------------------------------
-- 1. PREALABLE -- les revoke du lot 0, RAPPELES (idempotents).
-- ---------------------------------------------------------------------
-- Sans effet s'ils ont deja joue (03-droits-vue-publique.sql, 16/09).
-- Ils sont ici parce qu'une policy ne reprend AUCUN droit : la section 6
-- ci-dessous ACCORDE a authenticated, et elle doit accorder sur une
-- ardoise propre, pas par-dessus les droits par defaut de la plateforme
-- (R-023).
revoke insert, update, delete, truncate, references, trigger
    on public.demandes_publiques from anon, authenticated;
revoke select on public.demandes_publiques from authenticated;
revoke all on public.demandes from anon, authenticated;

-- La file publique reste lisible quoi qu'il arrive plus haut.
grant select on public.demandes_publiques to anon;

-- NOTE : authenticated ne recoit PAS la vue. La page privee lit la
-- TABLE -- elle a besoin de motif et de mail, que la vue ne montre pas,
-- et c'est meme sa raison d'etre cote lecture (section 6). L'arbitrage
-- "option 1" du lot 0 (03-droits-vue-publique.sql l. 46-49) reste donc
-- entier : authenticated n'a aucun usage de la VUE.

-- ---------------------------------------------------------------------
-- 2. UN SCHEMA NON EXPOSE pour les fonctions de declencheur.
-- ---------------------------------------------------------------------
-- POURQUOI. Les deux fonctions ci-dessous sont en SECURITY DEFINER :
-- elles s'executent avec les droits de leur proprietaire (postgres), ce
-- qu'exige leur travail (ecrire dans demandes_journal, que personne
-- d'autre ne peut ecrire). Supabase avertit qu'une fonction security
-- definer "in an exposed schema is callable over the Data API with the
-- creator's privileges".
--
-- DOUBLE CEINTURE, et l'ordre compte :
--   (a) PostgreSQL REFUSE l'appel direct d'une fonction de declencheur.
--       Une fonction 'returns trigger' n'est invocable que par le
--       mecanisme de declenchement : le gestionnaire du langage
--       procedural (plpgsql) verifie le contexte et leve une erreur
--       sinon. Verifie le 18/09/2026 sur la documentation PostgreSQL
--       (41.10 Trigger Functions : "A trigger function is created with
--       the CREATE FUNCTION command, declaring it as a function with no
--       arguments and a return type of trigger", et "When a PL/pgSQL
--       function is called as a trigger, several special variables are
--       created automatically") et sur la liste pgsql-hackers (message
--       6946.1250174217@sss.pgh.pa.us, Tom Lane : le controle est fait
--       par les langages proceduraux eux-memes, et non par le
--       gestionnaire de fonctions, pour ne pas ralentir tous les appels).
--   (b) MAIS la documentation PostgREST, elle, N'ENONCE PAS que les
--       fonctions 'returns trigger' sont exclues de /rpc : elle dit
--       "Every function in the exposed schema and accessible by the
--       active database role is executable under the /rpc prefix", et ne
--       nomme comme exclusion que les "Stored Procedures"
--       (docs.postgrest.org, references/api/stored_procedures, lu le
--       18/09/2026). LE DOUTE SUBSISTE DU COTE DE L'API.
-- Le mandat tranche ce cas d'avance : doute -> schema non expose. C'est
-- ce que fait cette section. La garantie (a) rendrait l'appel inoffensif ;
-- la parade (b) le rend introuvable. On pose les deux, et on ne parie
-- sur aucune des deux seule.
--
-- !!! NE JAMAIS AJOUTER 'prive' A LA LISTE DES SCHEMAS EXPOSES
-- !!! (Supabase -> Project Settings -> API -> "Exposed schemas").
-- !!! Cette liste vaut 'public, graphql_public' et doit le rester.
create schema if not exists prive;

-- Personne d'autre que le proprietaire n'entre dans ce schema.
revoke all on schema prive from public;
revoke all on schema prive from anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. LE JOURNAL -- la trace EN BASE de chaque geste.
-- ---------------------------------------------------------------------
-- C'est la piece qui manquait : aujourd'hui, le Table Editor change une
-- etape sans laisser ni date, ni auteur, ni valeur precedente. Le
-- critere E2 du bilan de promotion du pilote ("0 publication d'une
-- demande non posee en publication_pilote") ne peut pas se prouver sans
-- cette table.
--
-- 'if not exists' et NON 'drop table' : un rejeu du script NE DETRUIT
-- PAS la trace. Un journal qu'on efface en rejouant un script n'est pas
-- un journal.
create table if not exists public.demandes_journal (
    id          bigint generated by default as identity primary key,
    demande_id  bigint not null,
    geste       text   not null check (geste in ('creation', 'etape')),
    avant       text,
    apres       text   not null,
    par         uuid,
    a           timestamptz not null default now()
);

comment on table public.demandes_journal is
    'Trace des gestes sur public.demandes (BKL-CIN-096 lot 2, 18/09/2026). par NON NUL = page privee ; par NUL = clef secrete, donc qualifier.mjs, donc le formulaire public.';

create index if not exists demandes_journal_a_idx
    on public.demandes_journal (a desc);

-- RLS activee et AUCUNE policy : personne ne lit ce journal par l'API.
-- AH le lit au Table Editor (voie privilegiee). Ce n'est pas une panne.
alter table public.demandes_journal enable row level security;

-- Et, par-dessus la RLS, AUCUN DROIT : un objet neuf du schema public
-- peut naitre avec les droits par defaut de la plateforme (R-023,
-- pg_default_acl). La RLS filtre les LIGNES ; le revoke ferme la
-- COMMANDE. On pose les deux.
revoke all on public.demandes_journal from anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. LES DEUX FONCTIONS DE DECLENCHEUR (schema prive, section 2).
-- ---------------------------------------------------------------------
-- ECART DECLARE par rapport au SQL candidat de l'analyse L2.3, dans le
-- sens du durcissement : le candidat portait "set search_path = public",
-- on pose "set search_path = ''" et on qualifie TOUT. Une fonction
-- security definer dont le search_path est mutable est la voie classique
-- de l'elevation de privilege.

-- 4a. JOURNALISATION -- after insert or update.
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
    elsif new.statut is distinct from old.statut then
        insert into public.demandes_journal (demande_id, geste, avant, apres, par)
        values (new.id, 'etape', old.statut, new.statut, auth.uid());
    end if;
    return new;
end
$fn$;

-- 4b. PLAFOND DE CREATION -- before insert.
--
-- !!! LIRE CE BLOC AVANT DE TOUCHER A CETTE FONCTION. !!!
--
-- CE QU'ELLE COMPTE : les CREATIONS FAITES PAR LA PAGE PRIVEE, du jour
-- civil, par le compte qui insere -- c'est-a-dire les lignes de
-- demandes_journal ou geste = 'creation' ET par = auth.uid().
--
-- CE QU'ELLE NE COMPTE JAMAIS : les lignes ou decideur = 'AH'.
-- qualifier.mjs l. 790 ecrit decideur='AH' pour TOUTE demande venue du
-- formulaire PUBLIC, et 01-table-demandes.sql l. 90 en fait le DEFAUT de
-- la colonne. Une fonction qui compterait decideur='AH' refuserait la
-- ONZIEME DEMANDE PUBLIQUE DU JOUR : elle plafonnerait le SERVICE EN
-- PRODUCTION a dix demandes par jour, silencieusement, et aucune
-- verification de la recette ne l'aurait vu. (Prescription corrigee le
-- 18/09/2026 AVANT tout jeu ; ecart n.130.)
--
-- FAIL-OPEN, et voici la raison (PATRON regle C-4) : toute insertion qui
-- n'est PAS celle de la page privee ressort immediatement, sans rien
-- compter. Cette garde protege un CONFORT d'usage de la page privee --
-- pas une depense, pas une donnee. Elle ne doit JAMAIS pouvoir refuser
-- la demande d'un visiteur. En cas de doute sur l'appelant : laisser
-- passer.
--
-- LE PLAFOND EST EN BASE, ET NON DANS LA PAGE (decision d'AH du
-- 18/09/2026) : un plafond porte par la page seule ne garde rien --
-- l'API reste ouverte a la session d'AH, et c'est precisement ce jeton
-- qu'un outil pilotant son navigateur reel pourrait emprunter (R-026).
-- La page AFFICHE le refus ; la base seule REFUSE.
--
-- JOUR CIVIL = le jour d'AH, Europe/Brussels, recalcule a chaque appel
-- (PATRON regle C-1 : on ne code jamais un decalage en dur, et on ne
-- touche a rien aux changements d'heure).
create or replace function prive.plafond_creation_page()
    returns trigger
    language plpgsql
    security definer
    set search_path = ''
as $fn$
declare
    v_moi   uuid;
    v_debut timestamptz;
    v_n     integer;
begin
    v_moi := auth.uid();

    -- Garde 1 : aucun compte authentifie = clef secrete (service_role)
    -- ou voie privilegiee. On ne compte rien, on laisse passer.
    if v_moi is null then
        return new;
    end if;

    -- Garde 2 : ceinture et bretelles -- seul le role authenticated est
    -- plafonne. Tout autre appelant passe.
    if current_user <> 'authenticated' then
        return new;
    end if;

    v_debut := date_trunc('day', now() at time zone 'Europe/Brussels')
               at time zone 'Europe/Brussels';

    select count(*) into v_n
      from public.demandes_journal
     where geste = 'creation'
       and par   = v_moi
       and a    >= v_debut;

    if v_n >= 10 then
        raise exception
            'Plafond atteint : 10 creations par jour depuis la page privee. Le compteur repart a zero au jour suivant.'
            using errcode = 'check_violation';
    end if;

    return new;
end
$fn$;

-- Les fonctions ne s'executent pour PERSONNE d'autre que leur
-- proprietaire : PostgreSQL accorde EXECUTE a PUBLIC par defaut, on le
-- retire. Leurs declencheurs, eux, s'executent hors de ce controle.
revoke all on function prive.journaliser_demande() from public;
revoke all on function prive.plafond_creation_page() from public;
revoke all on function prive.journaliser_demande() from anon, authenticated;
revoke all on function prive.plafond_creation_page() from anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. LES DEUX DECLENCHEURS sur public.demandes.
-- ---------------------------------------------------------------------
-- L'ordre de vie compte : le PLAFOND est 'before insert' (il refuse
-- avant que la ligne existe), la JOURNALISATION est 'after insert or
-- update' (elle ecrit ce qui a bien eu lieu). La onzieme creation du
-- jour est donc refusee en lisant les DIX lignes deja journalisees.
drop trigger if exists demandes_plafond_trg on public.demandes;
create trigger demandes_plafond_trg
    before insert on public.demandes
    for each row execute function prive.plafond_creation_page();

drop trigger if exists demandes_journal_trg on public.demandes;
create trigger demandes_journal_trg
    after insert or update on public.demandes
    for each row execute function prive.journaliser_demande();

-- ---------------------------------------------------------------------
-- 6. LES DROITS, PAR COLONNE, AU SEUL ROLE authenticated.
-- ---------------------------------------------------------------------
-- La page lit TOUT : elle montre a AH motif et mail, que la vue publique
-- ne porte pas -- c'est sa raison d'etre cote lecture.
grant select on public.demandes to authenticated;

-- Elle ne change QUE l'etape. Pas le titre, pas le motif, pas le mail,
-- pas le decideur d'une demande recue.
grant update (statut) on public.demandes to authenticated;

-- Elle ne cree qu'avec CINQ colonnes. id et created_at viennent de leurs
-- defauts ; motif, mail, slug_existant et qualification restent nuls ;
-- deja_analyse prend son defaut (false).
grant insert (titre, realisateur, annee, statut, decideur)
    on public.demandes to authenticated;

-- AUCUN delete, JAMAIS. Une demande indesirable passe en 'mise_de_cote' ;
-- la suppression reste un geste du Table Editor, hors de la page.

-- ---------------------------------------------------------------------
-- 7. LES TROIS POLICIES NOMINATIVES.
-- ---------------------------------------------------------------------
-- 'to authenticated' NE SUFFIRAIT PAS : il nomme un ROLE, que tout
-- compte partagerait. Chaque policy nomme l'UUID -- un seul compte au
-- monde la satisfait. C'est le verrou qui tient meme si les inscriptions
-- se rouvraient par accident.
--
-- Rejouables : drop if exists, puis create.
drop policy if exists demandes_ah_lecture  on public.demandes;
drop policy if exists demandes_ah_etape    on public.demandes;
drop policy if exists demandes_ah_creation on public.demandes;

-- (i) LIRE -- toute la file, motif et mail compris.
create policy demandes_ah_lecture on public.demandes
    for select to authenticated
    using (auth.uid() = '<UUID-DE-AH>'::uuid);

-- (ii) CHANGER L'ETAPE -- 'using' choisit les lignes visibles a la mise
-- a jour, 'with check' interdit de faire sortir la ligne de sa portee.
-- Les DEUX sont necessaires : 'using' seul laisserait ecrire une ligne
-- puis la rendre inatteignable.
--
-- LA TABLE DES TRANSITIONS ADMISES N'EST PAS ICI -- decision d'AH du
-- 18/09/2026 : elle est portee par LA PAGE seule. C'est donc une
-- CONVENTION D'INTERFACE, et non un verrou de la base : "traitee n'a
-- aucune sortie" vaut pour la page, PAS pour l'API. Ecrit noir sur blanc
-- pour qu'aucune lecture ulterieure ne prenne la page pour une garantie
-- de la base.
create policy demandes_ah_etape on public.demandes
    for update to authenticated
    using (auth.uid() = '<UUID-DE-AH>'::uuid)
    with check (auth.uid() = '<UUID-DE-AH>'::uuid);

-- (iii) CREER -- et 'decideur' ne peut valoir que 'AH'. Une creation par
-- la page est, par definition, une decision d'AH.
create policy demandes_ah_creation on public.demandes
    for insert to authenticated
    with check (auth.uid() = '<UUID-DE-AH>'::uuid and decideur = 'AH');

commit;

-- ---------------------------------------------------------------------
-- CONTROLE IMMEDIAT (LECTURE SEULE) -- ce que la transaction a pose.
-- ---------------------------------------------------------------------
-- Attendu, dans l'ordre :
--   policies sur demandes ............... 3
--   declencheurs sur demandes ........... 2
--   demandes_journal / RLS / policies ... 1 / true / 0
--   UUID distincts nommes ............... 1  (la VALEUR n'est pas affichee)
-- La recette complete est 02-controles-demandes.sql (controles 1 et 12 a 18).
select 'policies sur demandes' as controle,
       (select count(*)::text from pg_policies
         where schemaname = 'public' and tablename = 'demandes') as mesure,
       '3' as attendu
union all
select 'declencheurs sur demandes',
       (select count(*)::text from pg_trigger
         where tgrelid = 'public.demandes'::regclass and not tgisinternal),
       '2'
union all
select 'demandes_journal : table / RLS / policies',
       (select count(*)::text from pg_class
         where oid = to_regclass('public.demandes_journal'))
       || ' / ' ||
       coalesce((select relrowsecurity::text from pg_class
                  where oid = to_regclass('public.demandes_journal')), '(absente)')
       || ' / ' ||
       (select count(*)::text from pg_policies
         where schemaname = 'public' and tablename = 'demandes_journal'),
       '1 / true / 0'
union all
select 'UUID distincts nommes dans les policies de demandes',
       (select count(distinct m[1])::text
          from pg_policies p,
               lateral regexp_matches(
                   coalesce(p.qual, '') || ' ' || coalesce(p.with_check, ''),
                   '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
                   'g') as m
         where p.schemaname = 'public' and p.tablename = 'demandes'),
       '1';

-- ---------------------------------------------------------------------
-- RETOUR ARRIERE -- en commentaire, a ne jouer que sur decision d'AH.
-- ---------------------------------------------------------------------
-- Il rend la table a sa posture D-1 ("RLS activee, aucune policy"). Le
-- JOURNAL, lui, ne se detruit pas : c'est une piece. Si AH veut vraiment
-- s'en defaire, c'est un geste separe et explicite (deux dernieres
-- lignes, laissees commentees elles aussi).
--
-- begin;
--
-- drop trigger if exists demandes_journal_trg on public.demandes;
-- drop trigger if exists demandes_plafond_trg on public.demandes;
-- drop function if exists prive.journaliser_demande();
-- drop function if exists prive.plafond_creation_page();
--
-- drop policy if exists demandes_ah_lecture  on public.demandes;
-- drop policy if exists demandes_ah_etape    on public.demandes;
-- drop policy if exists demandes_ah_creation on public.demandes;
--
-- revoke all on public.demandes from authenticated;
--
-- commit;
--
-- Puis : rendre 02-controles-demandes.sql a son etat du commit e48be92
-- (controle n.1 attendu '0', controle n.12 d'origine), retirer admin.html
-- et la section [[headers]] de netlify.toml, et repousser le service.
-- La regle D-1 du PATRON redevient vraie sans amendement.
--
-- Et, SEULEMENT si AH le demande explicitement :
-- drop table if exists public.demandes_journal;
-- drop schema if exists prive;
