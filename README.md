# Demander une analyse

Un formulaire public : un visiteur propose un film, le service vérifie
s'il est **déjà analysé**, qualifie la demande dans des vocabulaires
imposés, l'inscrit dans une table, et une page publique affiche la file.
**AH arbitre ensuite**, comme aujourd'hui — mais avec une file visible.

**Statut : service du site, EN PRODUCTION depuis le 25/08/2026 (08h19)**,
sous l'adresse canonique `https://demande.cdatso.be`. Provenance :
prototype d'apprentissage BKL-FOR-006, préparé pour l'atelier AI-Shift du
26 août 2026 (fiche A), passé en production sous l'item BKL-CIN-092.

## La chaîne

```
index.html  --POST-->  netlify/functions/qualifier.mjs
                            |
                            |-- 1. garde de méthode et d'origine (CORS, une seule origine)
                            |-- 2. validation d'entrée + pot de miel
                            |-- 3. fetch du registre public (données, jamais évaluées)
                            |-- 4. test « déjà analysé » (slug ET titre normalisés)
                            |        trouvé -> accusé + lien, FIN (aucun appel, aucun insert)
                            |-- 5. appel Claude, sortie structurée, vocabulaires imposés
                            |-- 6. insert dans Supabase (clé secrète, statut = proposee)
                            '-- 7. accusé au visiteur

file.html  --GET-->  vue public.demandes_publiques (clé publiable, lecture seule)
```

## Les bornes — elles ne sont pas décoratives

- **L'IA qualifie, elle ne rédige pas, et elle ne pose jamais un
  `statut`.** Le champ n'est pas dans son schéma de sortie : ce n'est pas
  une consigne, c'est une impossibilité mécanique. Le code écrit
  `proposee` ; **AH seul** change une étape, à la main dans Supabase.
- **Le service n'écrit jamais dans `films-a-traiter.md`**, ni dans aucun
  canal de la file d'attente, ni dans le dépôt de production du site. Il
  alimente une table ; la mise en file reste un geste humain. La function
  n'importe aucune primitive d'écriture de fichier.
- **Le registre distant est une donnée, jamais du code.** Il est lu par
  `fetch` puis **analysé textuellement**. Ni `eval`, ni `new Function`,
  ni `import()` sur son contenu — un `fetch` suivi d'un `eval` est une
  exécution de code arbitraire.
- **Le champ « pourquoi ce film » est du texte libre écrit par un
  inconnu.** Il vit dans un bloc de données délimité et échappé, jamais
  dans la section d'instructions du prompt, qui énonce la règle 11 de la
  charte en toutes lettres.
- **La clé publiable ne peut rien écrire, ni par la vue ni par la
  table.** Depuis le 16/09/2026 (BKL-CIN-096 (b) lot 0, risque R-023),
  la base retire aux rôles `anon` et `authenticated` les droits
  d'écriture que Supabase leur accorde par défaut : la vue
  `demandes_publiques`, simple donc modifiable et exécutée avec les droits
  de son propriétaire, ne garde que `SELECT` pour `anon` ; la table
  `demandes` ne leur accorde plus rien. Script de production :
  `supabase/03-droits-vue-publique.sql` (ni `drop` ni `create` — **jamais**
  `01`, qui détruit la table) ; preuve : contrôle n°12 de
  `supabase/02-controles-demandes.sql`. C'est la condition de la première
  borne : sans elle, quiconque lit la clé dans `file.html` pourrait
  changer une étape, et « AH seul » ne serait qu'une intention.
- **Aucune clé dans ce dépôt.** Tout par variables d'environnement
  Netlify. Les deux emplacements de `file.html` sont livrés **vides** :
  c'est l'attendu, et le contrôle de propreté le vérifie.
- **Le champ « adresse électronique » est stocké et inutilisé.** Aucun
  message n'est envoyé à personne. La vue publique ne l'expose pas — pas
  plus que le motif.
- **Depuis le 19/09/2026, la file publique porte un lien vers du contenu
  NON RELU — et c'est AH qui décide quand.** La huitième étape
  `publiee_pilote` et la colonne `page_pilote` (script
  `supabase/06-statut-publiee-pilote.sql`, BKL-CIN-098 lot S) ouvrent la
  rubrique « Publiées à l'essai (non relues) », dont chaque carte renvoie
  à une page de `pilote.cdatso.be`. Trois bornes, et il faut les trois :
  l'adresse est **posée par AH seul** depuis la page privée — la chaîne
  pilote n'a qu'une clé de lecture et **n'écrit jamais en base** ; elle
  est **bornée en base** en forme (une page de films de la surface
  d'essai, rien d'autre) et en cohérence (l'étape et l'adresse ne se
  contredisent jamais) ; et `file.html` **rejoue la même expression**
  avant de créer le lien, parce qu'un lien affiché sur une page publique
  ne doit jamais pouvoir être arbitraire. Le risque assumé est nommé au
  **RISKLOG R-030** ; l'arbitrage A6 (« surface pilote non liée ») est
  **amendé** par la décision d'AH du 19/09.
- **Depuis le 26/09/2026, chaque carte « Traitées » peut porter le lien
  vers son analyse au site — « Lire l'analyse ».** La colonne
  `page_production` (script `supabase/07-page-production.sql`,
  BKL-CIN-099) suit exactement le modèle de `page_pilote` : l'adresse est
  **posée par AH seul** — depuis la page privée au passage vers
  « Traitées », où le champ est **obligatoire**, ou, pour les demandes déjà
  traitées, par le bloc `R-2` joué une fois ; elle est **bornée en base**
  en forme (une page de films de
  `https://www.cdatso.be/analyses-de-films/films/`, avec `www`, rien
  d'autre) et en cohérence (une adresse n'existe que sur une `traitee`) ;
  et `file.html` **rejoue la même expression** avant de créer le lien. Le
  **journal** trace désormais aussi chaque changement d'adresse (geste
  `adresse`, pour `page_production` comme pour `page_pilote`).
- **Depuis le 26/09/2026, une demande non retenue peut quitter la file publique sans être supprimée** : l'étape `archivee` (script `supabase/08-etape-archivee.sql`, BKL-CIN-092), posée par AH depuis la page privée **depuis « Mises de côté » seulement**, sans sortie, est retirée de la vue publique par un `where` ; la ligne reste en table, et sa trace au journal.

### Ce qui n'est PAS dans le périmètre, et qui est déclaré

**La limitation de débit (*rate limiting*) côté code est posée, mais NON
PROUVÉE ACTIVE** sur ce compte/plan à la date du 25/08/2026. Une règle
Netlify `rateLimit` est déclarée dans le `config` exporté de
`qualifier.mjs` (10 requêtes par 60 secondes, agrégées par IP et domaine,
`path` requis par la doc Netlify — voir le commentaire d'en-tête du
fichier) — mais elle ne produit aucun effet mesuré : le tableau de bord
Netlify (*Web security*) affiche « Rate Limiting : Not set / No active
rules », et une recette en ligne de 23 requêtes rapides n'a produit aucun
statut 429. **La borne réelle et vérifiée** est le **plafond de dépense
mensuel côté console Anthropic** (déjà posé par AH, hors de ce dépôt) :
au-delà, l'API refuse (HTTP 400), et la fonction se dégrade proprement
(502 « qualification indisponible »), sans jamais casser le service.
L'anti-abus complémentaire reste en place : **validation stricte**
(plafonds de taille sur le corps et sur chaque champ) plus un **pot de
miel**.

Hors périmètre également : toute page d'administration, et le lien depuis
le site de production vers ce service.

> **Erratum daté du 19/09/2026.** Les deux phrases ci-dessus valaient au
> 25/08/2026 et ne sont plus vraies de la première : la **page privée
> d'administration** `admin.html` existe depuis le 18/09/2026
> (BKL-CIN-096 lot 2, policies nominatives, journal en base), et elle a
> reçu le 19/09 la pose de l'étape `publiee_pilote` avec son adresse. La
> seconde tient toujours : **le lien depuis le site de production** vers
> ce service, ou vers la surface d'essai, reste **hors de ce dépôt** —
> c'est le chantier « porte » de BKL-CIN-098, non exécuté à ce jour.
> De même, « les deux emplacements de `file.html` sont livrés vides » vaut
> pour la livraison d'origine : depuis le 25/08 ils portent l'adresse du
> projet et la clé **publiable**, ce qui est correct (une clé publiable
> est publique par construction) et ce que le contrôle de propreté vérifie
> désormais — préfixe `sb_publishable_` exigé, tout autre préfixe rouge.

## Fraîcheur du registre

Le registre est **fetché sur le site public à chaque requête** — pas de
copie embarquée qui ferait foi. Une analyse publiée est donc connue du
service dès qu'elle est en ligne, sans redéploiement.

`fixtures/films-data-2026-08-24.js` est une **capture datée** du registre
publié (37 890 octets, 46 entrées, 848 lignes, LF). Elle sert
**uniquement** au rejeu hors ligne : **elle ne fait pas foi**, et elle
vieillira.

⚠️ Les vocabulaires (`volet`, `genreBase`) sont **recopiés** en tête de
`qualifier.mjs`, relevés le 24/08/2026 dans le fichier de référence du
dépôt de production. Ajouter un terme au vocabulaire là-bas ne le rend
pas admissible ici : il faut le reporter dans ce fichier.

## Jouer les contrôles hors ligne

```
node outils/run-bouchonne.mjs            # rejoue la chaîne, aucun réseau
node outils/controler-durcissement.mjs   # injection, schéma, bornes du code
node outils/controler-proprete.mjs       # zéro secret, emplacements, passe D
```

Aucun de ces trois n'appelle l'API, n'écrit en base, ni ne touche le
réseau. Leur **code de sortie** est le résultat : `0` vert, `1` rouge.
*(Un quatrième, `outils/controler-page-privee.mjs`, est le seul du dépôt à
faire des appels réseau : contre-lecture hostile **en écriture** avec la
clé publiable seule — attendu, refus de droit partout.)*

La **passe D** de `controler-proprete.mjs` (19/09/2026, BKL-CIN-098 lot S
bis) mesure l'ajout du jour, parce que les passes A à C n'en voyaient
rien : l'expression de forme est-elle **identique caractère pour
caractère** dans le SQL, dans `file.html` et dans `admin.html` ; juge-t-elle
bien les douze cas de l'épreuve P-3 (a), **saut de ligne final compris** ;
le lien est-il créé sous **double garde** ; `traitee` est-il bien **retiré**
des sorties de `publication_pilote` ; reste-t-il **zéro** `innerHTML`. Elle
a été **prouvée capable d'être rouge** dans une copie jetable — un
caractère ôté à l'expression, un `innerHTML` glissé, une classe de slug
ouverte aux majuscules : trois fois `exit 1`.

Le 26/09/2026 (BKL-CIN-099), la passe D a été **étendue à l'adresse de
production** (D-7 à D-10) : même expression **aux trois endroits**
(`07`, `file.html`, `admin.html`) ; les **quatorze** cas de l'épreuve P-6
(a) jugés en JavaScript ; lien « Lire l'analyse » créé sous **double
garde** ; champ de la page privée posé **depuis les deux chemins** vers
« Traitées », refusé **vide**, éprouvé **avant l'envoi** — et `traitee`
toujours **sans sortie**. Le contrôle D-3 attend désormais **deux** liens
gardés dans la file, et non plus un. Prouvée capable d'être rouge dans
des copies jetables : six mutations, six `exit 1` — dont une classe de
slug ouverte aux majuscules **aux trois endroits à la fois**, que seul le
jugement en comportement (D-8) voit.

## Coût, chiffré après les bornes

Un appel par demande, sur une entrée bornée (corps ≤ 8 000 caractères,
motif ≤ 2 000) et une sortie schématisée courte (`max_tokens` 1024,
réflexion désactivée, effort bas), avec `claude-sonnet-5`. Aux tarifs
publiés en août 2026 — 3 $ / MTok en entrée, 15 $ / MTok en sortie, tarif
d'introduction 2 $ / 10 $ jusqu'au 31/08/2026 — le prompt mesuré pèse
environ 3 800 caractères, soit de l'ordre de 1 100 jetons en entrée, et
la sortie quelques dizaines. **L'ordre de grandeur est donc de quelques
centimes par centaine de demandes.**

Et surtout : **une demande déjà analysée ne coûte rien** — le test « déjà
analysé » précède l'appel, et le coupe. Netlify et Supabase restent dans
leurs plans gratuits.

## Mise en ligne

Elle est **faite** : le service tourne en production depuis le
25/08/2026 (08h19), sous l'adresse canonique **https://demande.cdatso.be**.
Les gestes de mise en ligne — dépôt GitHub, site Netlify, sous-domaine,
variables d'environnement, SQL joué, les deux emplacements de
`file.html`, et les deux soumissions du critère de sortie — restent
décrits dans **`GUIDE-TEST-EN-LIGNE.md`**, dans l'ordre, à titre de
référence pour un futur redéploiement à neuf.

---

*Service du site — provenance BKL-FOR-006, en production sous
BKL-CIN-092. Aucune analyse n'est produite par ce service : le site
publie sous mandat et responsabilité humaine.*
