-- 04-etape-publication-pilote.sql
-- Ajoute la SEPTIEME valeur de statut, 'publication_pilote', a la
-- contrainte demandes_statut_check de la table demandes.
-- BKL-CIN-096 (b) lot 1, 17/09/2026.
--
-- !!! CE SCRIPT NE CONTIENT NI 'drop' NI 'create' D'OBJET : C'EST LUI, ET
-- !!! NON 01-table-demandes.sql, QUI SE JOUE SUR LA BASE EN PRODUCTION.
-- !!! 01 commence par 'drop view' puis 'drop table' : le rejouer en
-- !!! production DETRUIRAIT toutes les demandes.
-- !!! Le seul 'drop' ci-dessous est celui d'une CONTRAINTE, aussitot
-- !!! reposee dans la meme transaction : aucune table, vue, fonction ni
-- !!! declencheur n'est cree ou recree, donc aucun objet ne nait expose
-- !!! par les droits par defaut du schema public (R-023, pg_default_acl).
-- !!! La vue demandes_publiques expose deja 'statut' sans filtre : elle
-- !!! ne change pas.
--
-- ---------------------------------------------------------------------
-- POURQUOI (A10, Q2 ; analyse CIN-096 (a) L3)
-- ---------------------------------------------------------------------
-- A10 (arbitrage AH, 16/09/2026) : "une etape dediee" -- une valeur de
-- statut distingue l'accord de TRAITEMENT (a_traiter) de l'accord de
-- PUBLICATION automatique.
-- Q2 (arbitrage AH, 16/09/2026) : son nom est 'publication_pilote' ; une
-- demande publiee par le pilote RESTE a cette valeur (pas de huitieme).
-- Place : juste apres 'a_traiter'.
--
-- ---------------------------------------------------------------------
-- PORTEE DE L'ETAPE -- en toutes lettres (analyse CIN-096 (a) L3.1)
-- ---------------------------------------------------------------------
-- Posee par AH SEUL, l'etape 'publication_pilote' vaut accord de
-- traitement ET autorisation de publication automatique NON RELUE SUR LA
-- SURFACE PILOTE SEULEMENT.
-- En PRODUCTION (www.cdatso.be), la publication reste un GATE PRONONCE
-- EN FENETRE par AH (charte regle 6). Un statut en base ne devient
-- JAMAIS un gate de production (R-009, R-010, R-011) : cette etape ne
-- leve la borne "un statut n'est pas un gate" que pour le pilote, par
-- decision d'AH, et N'AUTORISE RIEN D'AUTRE. Ni 'a_traiter' ni
-- 'publication_pilote' ne valent gate de merge sur le depot de
-- production.
-- Cette portee suppose qu'AH seul puisse poser l'etape : c'est ce que
-- tient 03-droits-vue-publique.sql (controle n.12 de 02 a 0 / true).
--
-- CE SCRIPT NE PASSE AUCUNE LIGNE a 'publication_pilote'. La valeur
-- n'existera sur une demande que par un geste d'AH, film par film. Tant
-- que la skill pilote n'existe pas, elle n'arme rien.
--
-- ---------------------------------------------------------------------
-- ORDRE DES GESTES (analyse CIN-096 (a) L3.4)
-- ---------------------------------------------------------------------
-- 1. file.html portant la section 'publication_pilote' est DEPLOYEE et
--    constatee en ligne D'ABORD. Sans elle, une ligne a cette etape ne
--    serait pas affichee et la page montrerait "Attention : N demande(s)
--    portent une etape inconnue".
-- 2. PUIS ce script, par AH, dans le SQL Editor de Supabase (tout
--    selectionner, Run). Attendu : Success, et une ligne de resultat --
--    la definition de la contrainte a SEPT valeurs (voir plus bas).
-- 3. PUIS 02-controles-demandes.sql : treize lignes ; controle 7 = 0 ;
--    controle 8 = 1 ; controle 12 = 0 / true, inchange.
--
-- Si la contrainte ne porte pas le nom attendu, le 'drop constraint'
-- echoue, la transaction est annulee, et RIEN ne change : on s'arrete et
-- on le signale.

begin;

alter table public.demandes
    drop constraint demandes_statut_check;

alter table public.demandes
    add constraint demandes_statut_check check (statut in (
        'proposee', 'a_traiter', 'publication_pilote', 'scholar',
        'candidat', 'mise_de_cote', 'traitee'));

commit;

-- Controle immediat (LECTURE) : la contrainte porte bien sept valeurs,
-- 'publication_pilote' juste apres 'a_traiter'.
select pg_get_constraintdef(oid)
  from pg_constraint
 where conrelid = 'public.demandes'::regclass
   and conname = 'demandes_statut_check';

-- ---------------------------------------------------------------------
-- RETOUR ARRIERE "contrainte a six valeurs" -- en commentaire, a ne jouer
-- que sur decision d'AH.
-- ---------------------------------------------------------------------
-- VALABLE SEULEMENT SI AUCUNE LIGNE NE PORTE 'publication_pilote'. Sinon
-- le 'add constraint' echoue (la contrainte est verifiee sur toutes les
-- lignes), la transaction est annulee, et la contrainte a sept valeurs
-- reste en place : il faut d'abord qu'AH decide du sort de ces demandes.
--
-- (a) LECTURE prealable -- attendu : 0.
--
-- select count(*) as demandes_publication_pilote
--   from public.demandes
--  where statut = 'publication_pilote';
--
-- (b) Le retour arriere lui-meme, si (a) rend 0.
--
-- begin;
--
-- alter table public.demandes
--     drop constraint demandes_statut_check;
--
-- alter table public.demandes
--     add constraint demandes_statut_check check (statut in (
--         'proposee', 'a_traiter', 'scholar',
--         'candidat', 'mise_de_cote', 'traitee'));
--
-- commit;
--
-- Puis rejouer le controle de lecture ci-dessus (attendu : six valeurs)
-- et remettre file.html, 01 et 02 a leur etat du commit 840e91c.
--
-- Fichier destine a une MACHINE (colle dans l'editeur SQL de Supabase) :
-- UTF-8 SANS BOM, comme ses voisins.
