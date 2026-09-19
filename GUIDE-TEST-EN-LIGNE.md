# Test en ligne — « Demander une analyse » (fiche A)

**Tes vingt-et-un gestes, tels qu'exécutés.** Le service tourne en
production depuis le 25/08/2026 (08h19) sous
**https://demande.cdatso.be**. Ce guide reste la référence de ces gestes —
utile pour un redéploiement à neuf ou un audit, pas pour une mise en ligne
restant à faire.
*Gestes ① à ⑫ : le service public. Gestes ⑬ à ⑯ : la page privée
d'administration, ajoutée le 18/09/2026 (BKL-CIN-096 lot 2). Gestes ⑰ à
㉑ : la huitième étape `publiee_pilote` et l'adresse de la page d'essai,
ajoutées le 19/09/2026 (BKL-CIN-098 lot S et lot S bis).*

**La borne, avant tout** : la clé de l'API Claude et la clé **secrète**
Supabase ne sortent **jamais** des variables d'environnement. Seule la clé
**publiable** entre dans `file.html` et dans `admin.html` : c'est son
rôle, et elle n'ouvre rien par elle-même — la table n'accorde aucun droit
au rôle `anon`.

**① Le dépôt.** Crée `cdatso/demander-une-analyse` sur GitHub (public),
puis depuis `C:\Users\cdats\Claude\SRV\demander-une-analyse` :
`git remote add origin <URL>` puis `git push -u origin master`.

**② L'autorisation GitHub → Netlify.** L'installation Netlify est limitée
aux dépôts choisis : un dépôt neuf n'est **pas** visible tant qu'il n'est
pas ajouté. GitHub → *Settings* → *Applications* → *Netlify* →
*Configure* → ajoute ce dépôt. À faire **avant** le geste ③, sinon il
n'apparaît pas dans la liste.

**③ Le site.** Netlify → *Add new site* → *Import an existing project* →
ce dépôt. **Aucune commande de build** ; `netlify.toml` déclare déjà `functions`, et Netlify installe `@anthropic-ai/sdk` d'après `package.json`.

**④ Le sous-domaine.** Branche-le (*Domain management*), puis **note
l'origine exacte** telle que le navigateur l'affiche, sans barre oblique
finale — forme `https://hote`. C'est la valeur du geste ⑤.

**⑤ Les variables** (*Site configuration* → *Environment variables*).
Cinq noms obligatoires, aucune valeur ici :

| Nom | Où la trouver |
|---|---|
| `QUALIFIER_ORIGINE` | l'origine notée au geste ④. **Absente, la function refuse tout** (fail-closed) |
| `ANTHROPIC_API_KEY` | la clé de l'atelier |
| `QUALIFIER_MODELE` | `claude-sonnet-5` |
| `SUPABASE_URL` | Supabase → *Project Settings* → *API* → *Project URL* |
| `SUPABASE_SECRET_KEY` | Supabase → *API keys* → la clé **secrète** (`sb_secret_…`) — jamais la publiable |

Facultatives : `QUALIFIER_REGISTRE_URL`, `QUALIFIER_BASE_PUBLIQUE` (leurs défauts pointent déjà le site public).

**⑥ La table.** Supabase → *SQL Editor* → colle
`supabase/01-table-demandes.sql` → *Run*. Le script est **rejouable** : il repart de zéro. Le linter signalera « *security definer view* » sur `demandes_publiques` : c'est **attendu**, ne le « corrige » pas — la vue serait vide, la table n'ayant aucune policy (motif en commentaire dans le script).

**⑦ Les deux emplacements de `file.html`.** En tête de son script :
`SUPABASE_URL` (geste ⑤) et `SUPABASE_CLE_PUBLIABLE` (Supabase →
*API keys* → clé **publiable**, `sb_publishable_…`). Commite, pousse,
attends le redéploiement. Emplacements laissés vides, la page affiche un
message clair — pas une page blanche.

**⑧ Première soumission : « Les Tontons flingueurs ».** Ouvre le
formulaire, titre `Les Tontons flingueurs`, réalisateur
`Georges Lautner`. **Attendu** : « ce film est déjà analysé » + le lien
vers la page. **Aucun appel de modèle, aucune ligne en base** — vérifie
les deux au geste ⑩.

**⑨ Seconde soumission : un film absent.** Par exemple `Le Salaire de la
peur`, `Henri-Georges Clouzot`, `1953`. **Attendu** : accusé
« enregistrée », puis la demande visible dans `file.html`, section
**Proposées**, avec sa qualification. Rien n'arrive ? Netlify →
*Functions* → `qualifier` → *Logs* : le journal dit à quelle étape ça
s'est arrêté.

**⑩ Les contrôles.** *SQL Editor* → `supabase/02-controles-demandes.sql`
→ *Run*. Un seul tableau, **vingt-cinq** lignes (douze jusqu'au 16/09/2026 ; treize au lot 0, contrôle n°12 ; dix-neuf au lot 2 du 18/09/2026, n°1 et n°12 amendés et n°13 à 18 neufs ; **vingt-cinq au lot S de BKL-CIN-098, le 19/09/2026** — n°4, 7, 12 et 14 amendés, n°19 à 24 neufs), colonnes *mesure* et *attendu* :
la table est certifiée quand chaque mesure satisfait son attendu. Le
contrôle 5 doit montrer **une** demande, pas deux — les Tontons ne
s'insèrent pas.

> **Deux lignes ne se jugent plus, elles se lisent** (décision d'AH du
> 19/09/2026) : le **n°6** « demandes du jour » et le **n°9** « lignes
> posées par l'IA hors proposée » portent désormais un attendu qui
> commence par **`informatif`**. Ils valaient **le jour du test** de la
> fiche A ; sur une base vivante, ils rougissaient par construction —
> un contrôle dont l'attendu a vieilli cesse d'être un détecteur. Leur
> **mesure reste affichée**. La borne du n°9 (« l'IA ne pose jamais un
> statut ») est tenue ailleurs, et mieux : par **structure**, dans
> `outils/controler-durcissement.mjs`. **Attendu du rendu : 25 lignes,
> 23 conformes + ces 2 informatives.**

**⑪ Le contrôle de confidentialité** — c'est la mesure que la session
préparatoire n'a **pas pu** faire. Avec la clé **publiable** :

```
curl -s "<URL-DU-PROJET>/rest/v1/demandes?select=*" -H "apikey: <CLE-PUBLIABLE>" -H "Authorization: Bearer <CLE-PUBLIABLE>"
```

**Attendu : une erreur de droit**, jamais une liste — corps JSON portant
`"code":"42501"` (« *permission denied for table demandes* »), statut
HTTP **401** (PostgREST : 42501 → « *if authenticated 403, else 401* »,
https://docs.postgrest.org/en/stable/references/errors.html, lu le
16/09/2026 ; Supabase note que ces erreurs sont « *often reported by
clients as 401 or 403* »,
https://supabase.com/docs/guides/troubleshooting/database-api-42501-errors,
lu le 16/09/2026 : **le code `42501` fait foi**, le statut peut être 403).
La table est close **par ses droits**, et non plus seulement par la RLS :
`supabase/03-droits-vue-publique.sql` retire à `anon` et `authenticated`
leurs droits par défaut (BKL-CIN-096 (b) lot 0). Avant ce script,
l'attendu était `[]`. Puis :

```
curl -s "<URL-DU-PROJET>/rest/v1/demandes_publiques?select=*" -H "apikey: <CLE-PUBLIABLE>" -H "Authorization: Bearer <CLE-PUBLIABLE>"
```

**Attendu** : les demandes, **sans `mail` ni `motif`**. Si le premier
rend des lignes **ou `[]`**, ou si le second est vide, **arrête-toi et
signale-le** : n'ouvre **pas** une policy de lecture sur la table pour
compenser — ce serait exposer l'adresse du demandeur et son texte libre.

**Puis la contre-lecture en ÉCRITURE** : ces deux lectures ne prouvent pas
que la clé publiable ne peut rien **modifier**. Joue la procédure
`PROCEDURE-CONTRE-LECTURE-ECRITURE-CIN-096-B-LOT0.md` (dossier de l'item,
`claude-config\mandats\CIN\BKL-CIN-096\`) : des tentatives d'écriture
construites pour ne toucher aucune ligne, dont l'attendu est une **erreur
de droit partout**.


**⑫ Arrêter le service.** Netlify → *Site configuration* → *Stop builds*
coupe les déploiements ; supprimer le site coupe tout. La table survit :
`drop view public.demandes_publiques; drop table public.demandes;` la
retire. *Voie non vérifiée en ligne par la session préparatoire — elle
n'avait aucun accès à Netlify ni à Supabase.*

---

## La page privée d'administration (BKL-CIN-096 lot 2, 18/09/2026)

*Gestes ⑬ à ⑯, ajoutés le 18/09/2026. La page vit à
`https://demande.cdatso.be/admin.html`, elle n'est **liée depuis aucune
autre page**, et elle est servie en `noindex, nofollow` **par en-tête**.
La sécurité ne repose pas là-dessus : c'est la **base** qui décide.*

**⑬ Les quatre gestes du tableau de bord, dans cet ordre.** Ils précèdent
le SQL, et deux d'entre eux ne se devinent pas :

1. *Authentication* → *Users* → **Add user** : un compte, à ton adresse.
2. *Authentication* → *Sign In / Providers* → **ferme les inscriptions**
   (« Allow new users to sign up » → off). C'est l'un des trois verrous ;
   `outils/controler-page-privee.mjs` le **mesure** (geste ⑯).
3. Relève ton **UID** (colonne *UID* de ton compte).
4. *Authentication* → *URL Configuration* → ajoute
   **`https://demande.cdatso.be/admin.html`** aux **« Redirect URLs »**.
   **Sans ce geste, le lien magique repart vers la « Site URL »**, en
   silence, et la connexion n'aboutit jamais sur la page.

**⑭ Le SQL de la posture.** *SQL Editor* → colle
`supabase/05-page-privee-w2.sql` → remplace les **quatre** occurrences du
paramètre d'UUID (`Ctrl+H`, *Replace all*) → *Run*.

> ⚠️ **Substitue dans l'ÉDITEUR, jamais dans le fichier du dépôt** — il est
> **public**. Travaille sur une copie placée **hors de tout dépôt**, et
> n'enregistre pas le fichier versionné. *(Le 18/09, un « Replace all » a
> écrit la valeur dans le fichier du dépôt : la consigne du script
> contenait alors la chaîne qu'elle faisait remplacer. Corrigé — mais le
> geste reste à ta main.)*

Attendu : quatre lignes — policies `3`, déclencheurs `3`,
`demandes_journal` `1 / true / 0`, UUID distincts `1`. Puis
`supabase/02-controles-demandes.sql` : **vingt-cinq** lignes depuis le
19/09/2026 (dix-neuf à la date du geste ⑭).

**⑮ Les DEUX épreuves du plafond — et il faut les deux.** Blocs optionnels
en bas de `02-controles-demandes.sql`, à jouer **séparément** :

| | Ce qu'elle prouve |
|---|---|
| **P-1** | le plafond **laisse passer** le rôle serveur — donc le formulaire public écrit toujours |
| **P-2** | le plafond **refuse** la onzième création de la page, en **onze instructions séparées** (cas A) **et** en **une seule instruction de onze lignes** (cas B) |

> ⚠️ **P-1 seul ne prouve rien.** Le 18/09, une garde fautive
> (`current_user` dans une fonction `security definer`) a rendu le plafond
> **inerte** : P-1 était vert, les dix-neuf contrôles étaient verts, et
> rien ne refusait quoi que ce soit. **Une garde se prouve des deux
> côtés.** P-2 porte un auto-contrôle (`select auth.uid() is not null`) :
> s'il rend `false`, **arrête-toi** — les insertions qui suivraient ne
> mesureraient rien.

**⑯ La recette de la page servie.** Sans jeton :

```
curl -I https://demande.cdatso.be/admin.html
curl -I https://demande.cdatso.be/admin
```

**Attendu : `x-robots-tag: noindex, nofollow` sur les DEUX adresses** —
Netlify sert aussi la page sans son extension. La mesure se fait sur
l'**en-tête**, pas sur la balise. Puis :

```
node outils/controler-page-privee.mjs
```

**Attendu : `exit 0`** — 8/8 refus de droit (`401 / 42501`) avec la clé
publiable seule, et `disable_signup = true`.

Enfin, **ton geste, celui qu'aucun outil ne fait à ta place** : ouvre la
page, demande un lien magique, révise **une** demande, et vérifie au
*Table Editor* que `demandes_journal` porte sa ligne (qui, quand, avant,
après).

> ### Lire la colonne `par` du journal — corrigé le 19/09/2026
>
> | `par` | Ce que cela veut dire |
> |---|---|
> | **non nul** | écriture par un compte **authentifié** — donc la **page privée** |
> | **nul** | écriture **sans compte authentifié**. **Deux** chemins, pas un : ① la clé **secrète** (`qualifier.mjs`, donc le **formulaire public**) ; ② le **tableau de bord Supabase** (*Table Editor*, *SQL Editor*), qui passe en rôle propriétaire — `auth.uid()` y est nul |
>
> ⚠️ **Jusqu'au 19/09/2026, `05-page-privee-w2.sql` et ce guide disaient
> que `par` nul signifiait « le formulaire public ».** C'était **faux par
> omission**, et le coût est réel : un geste que **tu** fais au tableau de
> bord se lisait comme la demande d'un visiteur. C'est arrivé le 19/09 sur
> la demande n°2. Le critère **E2** du bilan de promotion du pilote
> s'appuie sur ce journal — une provenance mal lue y devient un chiffre
> faux.
>
> **Le journal seul ne sépare pas ① de ②.** Aucune colonne ne le fait, et
> aucun script n'en ajoute. L'**indice** — pas la preuve — est ailleurs :
> une création par `qualifier.mjs` porte une `qualification` JSON et un
> `motif` ; un geste du tableau de bord, en général, ni l'un ni l'autre.

> Le courrier intégré de Supabase est **plafonné à quelques envois par
> heure** : ne redemande pas un lien en rafale. La session vit dans
> l'onglet et meurt avec lui.

> ⚠️ **Ne fais jamais ouvrir cette page par un agent qui pilote ton
> navigateur réel** : il agirait dans ta session ouverte et pourrait poser
> une étape « comme toi » (R-026).

---

## La huitième étape et l'adresse de la page d'essai (BKL-CIN-098, 19/09/2026)

*Gestes ⑰ à ㉑. **Chaque geste est nommé par son FICHIER ou par son
BOUTON, jamais par un numéro nu** — le 19/09, des gestes numérotés « 1, 2,
3 » à côté de fichiers `01, 02, 03` ont fait rejouer
`03-droits-vue-publique.sql` par méprise : page privée hors service dix
minutes.*

> ### ⛔ Deux règles à lire avant de cliquer
>
> **① `supabase/03-droits-vue-publique.sql` NE SE REJOUE JAMAIS SEUL.**
> Son `revoke all on public.demandes` emporte **aussi** les droits de
> **colonne** accordés par `supabase/05-page-privee-w2.sql` (section 6) et
> par `supabase/06-statut-publiee-pilote.sql` (section 6) — rien dans `03`
> ne les re-accorde, et la page privée tombe. *Mesuré le 19/09 : les sept
> paires perdues d'un coup (contrôle n°12 `0/0/7/false/true`, n°14 `0/0`,
> n°23 `0 | (aucune)`) ; surface publique jamais affectée ; aucune donnée
> touchée.* **Réparation** : rejouer les `grant` de `05` §6 et de `06` §6
> — **pas** `03`. L'avertissement daté est en fin de `03`.
>
> **② Ne laisse JAMAIS l'éditeur Supabase réécrire une épreuve.** Un bloc
> qui porte `create temporary table` fait afficher « *Potential issues
> detected* » et trois boutons. Clique **« Run without RLS »**, toujours.
> **« Run and enable RLS »** fait *ajouter* par Supabase un
> `alter table public.<nom> enable row level security` — préfixé
> `public.` alors que la table est **temporaire** : l'instruction ajoutée
> échoue en `42P01` et l'échec **ressemble à un défaut du bloc**. Une
> demi-heure y est passée le 19/09.

**⑰ `supabase/06-statut-publiee-pilote.sql` — déjà joué le 19/09/2026.**
Il a posé la huitième étape `publiee_pilote`, la colonne `page_pilote` et
ses deux bornes (forme et cohérence), la vue publique à **onze** colonnes,
le droit d'écrire l'adresse depuis la page privée, et il a **figé**
`demandes_journal` contre `update`, `delete` et `truncate`. **L'ordre des
gestes est écrit en tête du fichier, et il compte : les PAGES d'abord.**
Une demande à une étape que les pages servies ne connaissent pas ferait
afficher à la file publique « *Attention : N demande(s) portent une étape
inconnue* ».

**⑱ `supabase/02-controles-demandes.sql`** — tout sélectionner,
*Run without RLS* si l'éditeur le propose. **Attendu : 25 lignes**, chaque
`mesure` satisfaisant son `attendu`, **sauf** les n°6 et n°9 dont
l'attendu commence par `informatif` (voir le geste ⑩).

**⑲ Les trois épreuves du lot S**, blocs `P-3`, `P-4`, `P-5` en bas de
`supabase/02-controles-demandes.sql`, **un bloc à la fois** (sélectionner
le bloc décommenté, puis *Run without RLS*) :

| | Ce qu'elle prouve |
|---|---|
| **P-3 (a)** | l'**expression de forme** juge bien : 12 cas, dont 10 hostiles — et le dernier, une adresse valide **suivie d'un saut de ligne**, doit être **REFUSÉE** |
| **P-3 (b)** | la contrainte de forme est bien **attachée** à la colonne, et elle **refuse** |
| **P-4** | la borne de **cohérence** mord **des deux côtés** : 3 cas qui passent, 3 qui sont refusés |
| **P-5** | le journal est **figé** (`update`, `delete`, `truncate` refusés) **et il écrit encore** (l'`insert` passe — c'est la moitié qui compte) |

Chaque bloc vit dans une transaction terminée par `rollback`, et se
termine par un compte de restes : **attendu 0**. *(Que l'éditeur honore
bien un `begin; … rollback;` couvrant plusieurs instructions a été
**mesuré** le 19/09 : `1697 / 1697`, une seule transaction.)*

**⑳ La section `R-1` de `supabase/06-statut-publiee-pilote.sql`** — en
commentaire, **une seule fois**, et **après** que les pages portant
`publiee_pilote` sont déployées. Elle remet la demande n°2, *Le Château
ambulant*, de `traitee` à `publiee_pilote` et lui donne son adresse. Joue
ses blocs **(a)**, **(b)**, **(c)** dans l'ordre où elle les écrit, et
lis chaque sortie : `1 ligne / traitee / NUL`, puis `UPDATE 1`, puis
`1 ligne / publiee_pilote / l'adresse` et une ligne de journal à `par`
**nul** — ce qui est **attendu** (le tableau de bord n'est pas un compte
authentifié). C'est **ce geste, et lui seul**, qui fait apparaître le
premier lien sur la file publique.

**㉑ Ton geste courant, depuis `admin.html` — poser l'étape et l'adresse.**
Après chaque publication du pilote :

1. sur la carte de la demande, choisis **« Publiées à l'essai (non
   relues) »** puis **« Changer l'étape »** ;
2. la confirmation demande l'**adresse de la page d'essai** : colle-la.
   Forme admise, et **la page la vérifie avant d'envoyer** :
   `https://pilote.cdatso.be/films/<nom-du-film>.html` — minuscules,
   chiffres, tirets simples, `.html`, rien après. Hors forme, **rien ne
   part** ; et si elle partait, la base refuserait ;
3. **« Confirmer »**. Le message d'après-coup affiche l'adresse **telle
   que la base la rend**, et le lien apparaît sur `file.html` dans la
   rubrique « Publiées à l'essai (non relues) ».

**Ce qui change d'étape ensuite** : vers **« Traitées »**, c'est
l'**adoption** au site — l'adresse d'essai est **conservée**, la page
d'essai n'est jamais retouchée. Vers **« À traiter »** ou **« Mises de
côté »**, l'adresse est **remise à NUL dans le même geste** (la base
l'exige) et le lien disparaît de la file. Depuis **« Essai de publication
automatique »**, **« Traitées » n'est plus proposé** (décision d'AH du
19/09) : le chemin passe par « Publiées à l'essai », où **tu** constates.

> ⚠️ **L'interrupteur du pilote**
> (`claude-config\pilote\INTERRUPTEUR-PILOTE.txt`) et l'étape « Essai de
> publication automatique » vont ensemble : une demande à cette étape est
> **publiable** par la chaîne si l'interrupteur vaut `ACTIF`. Pour une
> demande d'essai que tu ne veux **pas** voir publiée, vérifie
> l'interrupteur **avant**.

---
---

*Le service alimente une table ; **tu** décides. Rien ne s'écrit jamais
dans `films-a-traiter.md`, et l'IA ne pose jamais un statut.*
