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
- **Aucune clé dans ce dépôt.** Tout par variables d'environnement
  Netlify. Les deux emplacements de `file.html` sont livrés **vides** :
  c'est l'attendu, et le contrôle de propreté le vérifie.
- **Le champ « adresse électronique » est stocké et inutilisé.** Aucun
  message n'est envoyé à personne. La vue publique ne l'expose pas — pas
  plus que le motif.

### Ce qui n'est PAS dans le périmètre, et qui est déclaré

**La limitation de débit (*rate limiting*) est implémentée** depuis le
durcissement production du 25/08/2026 (BKL-CIN-092) : règle Netlify
`rateLimit` posée dans le `config` exporté de `qualifier.mjs`, **10
requêtes par 60 secondes, agrégées par IP et domaine**, filtre appliqué
**avant** l'invocation de la fonction — donc avant l'appel au modèle, le
fetch du registre et l'insert. Au-delà, la requête est refusée avec un
statut **429**. L'anti-abus complémentaire reste en place : **validation
stricte** (plafonds de taille sur le corps et sur chaque champ) plus un
**pot de miel**. Limite assumée : un adversaire distribué (adresses IP
tournantes) n'est pas arrêté par cette règle — elle protège du cas réel :
un robot, un script, une boucle oubliée.

Hors périmètre également : toute page d'administration, et le lien depuis
le site de production vers ce service.

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
node outils/controler-proprete.mjs       # zéro secret, emplacements vides
```

Aucun de ces trois n'appelle l'API, n'écrit en base, ni ne touche le
réseau. Leur **code de sortie** est le résultat : `0` vert, `1` rouge.

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
