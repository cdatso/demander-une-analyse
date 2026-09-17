# Test en ligne — « Demander une analyse » (fiche A)

**Tes douze gestes, tels qu'exécutés.** Le service tourne en production
depuis le 25/08/2026 (08h19) sous **https://demande.cdatso.be**. Ce guide
reste la référence de ces gestes — utile pour un redéploiement à neuf ou
un audit, pas pour une mise en ligne restant à faire.

**La borne, avant tout** : la clé de l'API Claude et la clé **secrète**
Supabase ne sortent **jamais** des variables d'environnement. Seule la clé
**publiable** entre dans `file.html` : c'est son rôle.

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
→ *Run*. Un seul tableau, treize lignes (douze jusqu'au 16/09/2026, contrôle n°12 ajouté par BKL-CIN-096 lot 0), colonnes *mesure* et *attendu* :
la table est certifiée quand chaque mesure satisfait son attendu. Le
contrôle 5 doit montrer **une** demande, pas deux — les Tontons ne
s'insèrent pas.

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

*Le service alimente une table ; **tu** décides. Rien ne s'écrit jamais
dans `films-a-traiter.md`, et l'IA ne pose jamais un statut.*
