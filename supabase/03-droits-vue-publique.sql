-- 03-droits-vue-publique.sql
-- Retire a la clef PUBLIABLE (role anon) et au role authenticated tout
-- droit d'ECRITURE sur la vue publique demandes_publiques et tout droit
-- sur la table demandes. BKL-CIN-096 (b) lot 0, 16/09/2026.
--
-- !!! CE SCRIPT NE CONTIENT NI 'drop' NI 'create' : C'EST LUI, ET NON
-- !!! 01-table-demandes.sql, QUI SE JOUE SUR LA BASE EN PRODUCTION.
-- !!! 01 commence par 'drop view' puis 'drop table' : le rejouer en
-- !!! production DETRUIRAIT toutes les demandes.
--
-- Rejouable sans effet de bord : un 'revoke' d'un droit absent ne fait
-- rien, un 'grant' d'un droit deja detenu non plus.
--
-- ---------------------------------------------------------------------
-- POURQUOI (RISKLOG R-023 ; analyse CIN-096 (a) L2.0)
-- ---------------------------------------------------------------------
-- 1. La vue demandes_publiques est SIMPLE (une table, ni agregat ni
--    DISTINCT) : PostgreSQL la rend AUTOMATIQUEMENT MODIFIABLE -- un
--    INSERT, UPDATE ou DELETE sur la vue s'applique a la table, pourvu
--    que l'appelant detienne le privilege correspondant SUR LA VUE.
-- 2. Elle s'execute avec les droits de son PROPRIETAIRE (postgres), et
--    CONTOURNE donc la RLS de la table (voir 01, bloc de la vue).
-- 3. Supabase accorde PAR DEFAUT aux roles anon et authenticated des
--    droits d'ecriture sur les objets du schema public. 01 ne faisait
--    que 'grant select ... to anon' et ne RETIRAIT rien.
-- Consequence : quiconque detient la clef publiable -- en clair dans
-- file.html, par construction -- pouvait modifier statut, titre ou
-- decideur d'une demande PAR LA VUE. La borne "AH seul change une etape"
-- n'etait pas tenue par la base.
--
-- Mesure G-1 d'AH (16/09/2026, information_schema.role_table_grants) :
-- AVANT, anon et authenticated detenaient les sept privileges (SELECT,
-- INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER) sur la vue ET
-- sur la table. Le revoke de l'analyse L2.0 a ete joue par AH le meme
-- jour ; ce script le reprend, et retire en plus le SELECT
-- d'authenticated sur la vue (arbitrage AH, option 1, 16/09/2026).
--
-- Controle : 02-controles-demandes.sql, controle n.12.

-- ---------------------------------------------------------------------
-- 1. LA VUE : plus aucune ecriture, pour personne d'autre que postgres.
-- ---------------------------------------------------------------------
revoke insert, update, delete, truncate, references, trigger
    on public.demandes_publiques from anon, authenticated;

-- authenticated n'a aucun usage de la vue : file.html lit avec la clef
-- publiable, donc en anon. Moindre privilege (arbitrage AH, option 1).
-- Si le lot 2 (page privee, W2) en a besoin, il le reposera, a son gate.
revoke select on public.demandes_publiques from authenticated;

-- ---------------------------------------------------------------------
-- 2. LA TABLE : aucun droit, ni lecture ni ecriture, pour les deux roles.
-- ---------------------------------------------------------------------
-- Tant que la table n'a aucune policy, la RLS filtrait deja les LIGNES.
-- Le revoke ferme la COMMANDE elle-meme, et il reste vrai le jour ou une
-- policy apparait : la documentation Supabase avertit que "Adding
-- policies doesn't take those grants back".
-- qualifier.mjs n'est PAS concerne : il ecrit avec la clef SECRETE, role
-- service_role, que ce script ne touche pas.
revoke all on public.demandes from anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. LA LECTURE PUBLIQUE, rejouee : la file reste lisible quoi qu'il
--    arrive plus haut.
-- ---------------------------------------------------------------------
grant select on public.demandes_publiques to anon;

-- ---------------------------------------------------------------------
-- RETOUR ARRIERE -- en commentaire, a ne jouer que sur decision d'AH.
-- ---------------------------------------------------------------------
-- Il n'existe PAS de retour arriere qui rende une ecriture a anon ou a
-- authenticated : ce serait rouvrir R-023. Les seuls gestes reversibles
-- sont les LECTURES :
--
-- (a) La file publique est vide apres ce script (file.html affiche
--     "La file n'a pas pu etre lue", ou aucune demande) : rejouer le
--     grant de lecture seul --
--
-- grant select on public.demandes_publiques to anon;
--
-- (b) Annuler l'arbitrage "option 1" (rendre a authenticated la lecture
--     des dix colonnes publiques de la vue, sans aucune ecriture) --
--
-- grant select on public.demandes_publiques to authenticated;
--
-- Le revoke sur la TABLE ne se defait pas : la table n'a aucune policy,
-- un droit rendu n'ouvrirait aucune ligne aujourd'hui, et ouvrirait
-- tout le jour ou une policy apparaitrait.
--
-- Fichier destine a une MACHINE (colle dans l'editeur SQL de Supabase) :
-- UTF-8 SANS BOM, comme ses voisins.
