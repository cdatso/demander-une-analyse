// controler-proprete.mjs -- ZERO SECRET, ZERO ADRESSE (verification 13 du
// mandat BKL-FOR-006). BORNE DURE n.1 : AUCUN COMMIT tant que ce controle
// n'est pas vert. Un secret entre dans un historique git n'en sort plus.
//
// Runtime cible : Node v24.19.0. Zero dependance, aucun reseau.
//
// Usage :  node outils/controler-proprete.mjs
//
// ---------------------------------------------------------------------
// AMENDEMENT DU 2026-08-25 (BKL-CIN-092 (b), regle S-6 du patron) --
// L'ATTENDU A CHANGE AU PASSAGE EN PRODUCTION.
// ---------------------------------------------------------------------
// Jusqu'au 25/08, l'attendu de la passe C etait "les deux emplacements de
// file.html VIDES". Le commit 92bf10c les a valorises SUR ARBITRAGE AH
// (mise en ligne reelle), rendant ce controle ROUGE EN PERMANENCE sur la
// tete servie depuis -- exactement le risque que S-6 nomme : "un controle
// dont l'attendu a change reste rouge, il cesse d'etre un detecteur".
//
// Le nouvel attendu, mesure sur la tete servie : SUPABASE_URL et
// SUPABASE_CLE_PUBLIABLE sont VALORISES, et c'est desormais CORRECT --
// une cle PUBLIABLE (prefixe sb_publishable_) est publique PAR
// CONSTRUCTION (doctrine S-4 du patron : "publiable != secrete", une cle
// publiable "peut vivre dans une page servie"). Ce que ce controle
// continue d'interdire, absolument, c'est qu'un PREFIXE SECRET
// (sb_secret_, service_role, sk-ant, un jeton eyJ...) se glisse dans l'un
// de ces deux emplacements.
//
// ---------------------------------------------------------------------
// TROIS PASSES, ET POURQUOI
// ---------------------------------------------------------------------
// Le mandat demande zero occurrence VALORISEE de motifs de VRAIS secrets
// (sb_secret, service_role, sk-ant, eyJ, adresses mail). Or il demande
// AUSSI (geste 5 du guide) que le guide NOMME les variables et dise ou
// trouver la clef secrete -- ce qui ecrit necessairement la chaine
// "sb_secret_" dans un fichier versionne.
//
// Les deux exigences ne se contredisent que si l'on confond le NOM d'une
// clef et sa VALEUR. Ce controle les separe :
//
//   PASSE A -- comptage BRUT, motif par motif, tel que le mandat le
//              formule. Le chiffre est rapporte quel qu'il soit, y
//              compris pour sb_publishable (trace informative : une cle
//              publiable valorisee n'est PAS un defaut).
//   PASSE B -- qualification, sur les VRAIS motifs de secret SEULEMENT
//              (sb_publishable en est exclu depuis le 25/08, S-4) : une
//              occurrence est un SECRET VALORISE si le motif est suivi
//              d'un jeton d'au moins 16 caracteres de l'alphabet des
//              clefs. Sinon c'est une MENTION (le nom de la variable, une
//              consigne, un commentaire).
//   PASSE C -- LES DEUX EMPLACEMENTS DE file.html (arbitrage AH n.10,
//              amende le 25/08 -- voir plus haut). L'attendu : les DEUX
//              VALORISES, SUPABASE_URL avec une valeur non vide,
//              SUPABASE_CLE_PUBLIABLE avec un prefixe sb_publishable_
//              EXACTEMENT -- tout autre prefixe (notamment un prefixe
//              secret) est ROUGE.
//
// Le controle est VERT si la passe B (vrais secrets) compte ZERO secret
// valorise, la passe C trouve les deux emplacements conformes a son
// nouvel attendu, et aucun mot de passe litteral n'est trouve. Toute
// occurrence brute est imprimee avec son fichier et sa ligne, pour que la
// lecture reste possible a l'oeil.
//
// Fail-closed : ce script se lance SEUL et son EXIT SE LIT (lecon 4 de
// FOR-004). Il annonce ce qu'il a verifie, jamais ce qu'il a tente.

import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ICI = dirname(fileURLToPath(import.meta.url));
const RACINE = join(ICI, '..');

// EXACTEMENT le pathspec de la rubrique 8 du mandat -- ce qui sera
// commite, et rien d'autre. node_modules/ n'y est pas.
// 'admin.html' ajoute le 18/09/2026 (BKL-CIN-096 (b) lot 2) : la page
// privee d'administration est nee ce jour-la, elle est SERVIE, et elle
// porte les deux memes emplacements de configuration que file.html.
// Sans cette ligne, ce controle etait VERT PAR CECITE sur elle -- mesure
// le 18/09 : le mot 'admin' n'apparaissait nulle part dans sa sortie.
const A_INSPECTER = [
  'netlify', 'outils', 'supabase', 'fixtures',
  'index.html', 'file.html', 'admin.html', 'netlify.toml',
  'package.json', 'package-lock.json',
  'GUIDE-TEST-EN-LIGNE.md', 'README.md', '.gitignore'
];

// VRAIS motifs de secret : une occurrence VALORISEE de l'un d'eux est
// ROUGE, ou qu'elle vive. 'sb_publishable' N'EN FAIT PLUS PARTIE depuis le
// 25/08 (S-4 du patron : une cle publiable est publique par construction)
// -- elle est tracee separement plus bas, a titre informatif seulement.
const MOTIFS = [
  'sk-ant', 'sb_secret', 'service_role', 'eyJ',
  '@cdatso.be', '@yahoo.com', '@gmail.com'
];

const MOTIF_PUBLIABLE = 'sb_publishable';

// Un mot de passe VALORISE : une affectation dont la valeur est un
// litteral non vide. Les lectures d'environnement sont exclues.
const MOTIF_MOTDEPASSE = /(mot_?de_?passe|motdepasse|password|passwd|pass)\s*[:=]\s*['"][^'"]{3,}['"]/i;

// Jeton de clef : au moins 16 caracteres de l'alphabet usuel des clefs,
// COLLES au motif. "sb_secret_..." ou "sb_secret_<valeur>" n'en sont pas.
const JETON = /^[A-Za-z0-9_\-]{16,}/;

function fichiers(chemin) {
  const abs = join(RACINE, chemin);
  let s;
  try { s = statSync(abs); } catch (e) { return []; }
  if (s.isFile()) return [abs];
  const sortie = [];
  for (const e of readdirSync(abs)) {
    if (e === 'node_modules' || e === '.git') continue;
    sortie.push(...fichiers(join(chemin, e)));
  }
  return sortie;
}

const listeFichiers = [];
const manquants = [];
for (const c of A_INSPECTER) {
  const trouves = fichiers(c);
  if (trouves.length === 0) manquants.push(c);
  listeFichiers.push(...trouves);
}

console.log('=== CONTROLE DE PROPRETE (verification 13) ===');
console.log('  ' + listeFichiers.length + ' fichier(s) inspecte(s), pathspec de la rubrique 8');
if (manquants.length > 0) {
  console.log('  ATTENTION : ' + manquants.length + ' entree(s) du pathspec introuvable(s) : ' +
              manquants.join(', '));
}
console.log('');

let totalBrut = 0;
let totalValorise = 0;
const detail = [];

for (const motif of MOTIFS) {
  let brut = 0;
  let valorise = 0;
  for (const f of listeFichiers) {
    let texte;
    try { texte = readFileSync(f, 'utf8'); } catch (e) { continue; }
    const lignes = texte.split(/\r?\n/);
    lignes.forEach((ligne, i) => {
      let depuis = 0;
      for (;;) {
        const j = ligne.indexOf(motif, depuis);
        if (j === -1) break;
        brut++;
        const estValorise = JETON.test(ligne.slice(j + motif.length));
        if (estValorise) valorise++;
        detail.push({
          motif: motif,
          fichier: relative(RACINE, f).replace(/\\/g, '/'),
          ligne: i + 1,
          valorise: estValorise,
          extrait: ligne.trim().slice(0, 90)
        });
        depuis = j + motif.length;
      }
    });
  }
  totalBrut += brut;
  totalValorise += valorise;
  console.log('  ' + motif.padEnd(16) + ' : ' + brut + ' occurrence(s) brute(s), ' +
              valorise + ' valorisee(s)');
}

// Trace INFORMATIVE de sb_publishable : comptee et affichee, mais SANS
// influence sur le verdict (S-4 -- une cle publiable valorisee n'est pas
// un defaut, ou qu'elle vive dans le depot).
let publiableBrut = 0;
let publiableValorise = 0;
for (const f of listeFichiers) {
  let texte;
  try { texte = readFileSync(f, 'utf8'); } catch (e) { continue; }
  const lignes = texte.split(/\r?\n/);
  lignes.forEach((ligne, i) => {
    let depuis = 0;
    for (;;) {
      const j = ligne.indexOf(MOTIF_PUBLIABLE, depuis);
      if (j === -1) break;
      publiableBrut++;
      const estValorise = JETON.test(ligne.slice(j + MOTIF_PUBLIABLE.length));
      if (estValorise) publiableValorise++;
      detail.push({
        motif: MOTIF_PUBLIABLE,
        fichier: relative(RACINE, f).replace(/\\/g, '/'),
        ligne: i + 1,
        valorise: estValorise,
        extrait: ligne.trim().slice(0, 90),
        informatif: true
      });
      depuis = j + MOTIF_PUBLIABLE.length;
    }
  });
}
console.log('  ' + MOTIF_PUBLIABLE.padEnd(16) + ' : ' + publiableBrut + ' occurrence(s) brute(s), ' +
            publiableValorise + ' valorisee(s) -- INFORMATIF, S-4 (publiable != secrete)');

// Mots de passe
let motsDePasse = 0;
for (const f of listeFichiers) {
  let texte;
  try { texte = readFileSync(f, 'utf8'); } catch (e) { continue; }
  texte.split(/\r?\n/).forEach((ligne, i) => {
    if (MOTIF_MOTDEPASSE.test(ligne)) {
      motsDePasse++;
      detail.push({
        motif: 'mot de passe',
        fichier: relative(RACINE, f).replace(/\\/g, '/'),
        ligne: i + 1,
        valorise: true,
        extrait: ligne.trim().slice(0, 90)
      });
    }
  });
}
console.log('  ' + 'mot de passe'.padEnd(16) + ' : ' + motsDePasse + ' affectation(s) litterale(s)');

console.log('');
if (detail.length > 0) {
  console.log('  Detail des occurrences brutes :');
  for (const d of detail) {
    const etat = d.informatif ? (d.valorise ? 'PUBLIABLE' : 'mention  ')
                               : (d.valorise ? 'VALORISE ' : 'mention  ');
    console.log('   - [' + etat + '] ' + d.motif +
                ' -- ' + d.fichier + ':' + d.ligne + ' -- ' + d.extrait);
  }
  console.log('');
}

// ---------------------------------------------------------------------
// PASSE C -- LES DEUX EMPLACEMENTS DE file.html
// ---------------------------------------------------------------------
// AMENDEMENT DU 2026-08-25 (BKL-CIN-092 (b), S-6) : l'attendu N'EST PLUS
// "vide". Le service est en production ; les deux emplacements portent la
// configuration reelle, et c'est correct. Ce que cette passe verifie
// desormais :
//   SUPABASE_URL            : present ET non vide (une adresse de projet
//                              n'est pas un secret).
//   SUPABASE_CLE_PUBLIABLE  : present ET non vide ET son prefixe est
//                              EXACTEMENT 'sb_publishable_' -- tout autre
//                              prefixe (notamment un prefixe secret :
//                              sb_secret_, service_role, sk-ant...) est
//                              ROUGE, ici plus qu'ailleurs : c'est
//                              l'emplacement qu'un navigateur charge.
// Un emplacement ABSENT reste un defaut, comme avant : sans lui, AH ne
// saurait pas ou poser la valeur.

// AMENDEMENT DU 2026-09-18 (BKL-CIN-096 (b) lot 2) -- CETTE PASSE NE
// REGARDAIT QUE file.html.
// admin.html, la page privee d'administration, est nee au lot 2 et porte
// LES DEUX MEMES emplacements. Elle ne figurait ni dans A_INSPECTER ni
// ici : ce controle etait donc VERT PAR CECITE sur elle. Si la clef
// SECRETE y avait ete collee, rien ne l'aurait vu, et K-5 ("proprete
// verte avant chaque commit") aurait ete satisfait sans rien garantir --
// sur la page qui detient justement le JETON DE SESSION d'AH, c'est-a-dire
// celle ou l'erreur couterait le plus cher.
// La passe boucle desormais sur TOUTES les pages servies qui portent ces
// emplacements. En ajouter une, c'est ajouter une ligne a PAGES_SERVIES
// -- et a A_INSPECTER.
const PAGES_SERVIES = ['file.html', 'admin.html'];

console.log('  --- Les deux emplacements des PAGES SERVIES (arbitrage n.10, attendus amendes le 25/08 puis le 18/09) ---');
const PREFIXE_PUBLIABLE_ATTENDU = 'sb_publishable_';

function lireEmplacement(page, nom) {
  const re = new RegExp('(?:var|let|const)\\s+' + nom + "\\s*=\\s*('([^']*)'|\"([^\"]*)\")\\s*;");
  const m = re.exec(page);
  if (!m) return { trouve: false, valeur: null };
  return { trouve: true, valeur: m[2] !== undefined ? m[2] : m[3] };
}

let passeC = true;
for (const nomPage of PAGES_SERVIES) {
  let page = '';
  try { page = readFileSync(join(RACINE, nomPage), 'utf8'); } catch (e) { page = ''; }
  if (page === '') {
    console.log('   - [ABSENTE ] ' + nomPage + ' : page introuvable -- ROUGE');
    passeC = false;
    continue;
  }

  const url = lireEmplacement(page, 'SUPABASE_URL');
  if (!url.trouve) {
    console.log('   - [ABSENT  ] ' + nomPage + ' : SUPABASE_URL introuvable');
    passeC = false;
  } else if (url.valeur === '') {
    console.log('   - [VIDE    ] ' + nomPage + ' : SUPABASE_URL -- configuration absente, attendu VALORISE en production');
    passeC = false;
  } else {
    console.log('   - [VALORISE] ' + nomPage + ' : SUPABASE_URL porte une valeur de ' + url.valeur.length +
                ' caractere(s) -- conforme (adresse de projet, pas un secret)');
  }

  const cle = lireEmplacement(page, 'SUPABASE_CLE_PUBLIABLE');
  if (!cle.trouve) {
    console.log('   - [ABSENT  ] ' + nomPage + ' : SUPABASE_CLE_PUBLIABLE introuvable');
    passeC = false;
  } else if (cle.valeur === '') {
    console.log('   - [VIDE    ] ' + nomPage + ' : SUPABASE_CLE_PUBLIABLE -- configuration absente, attendu VALORISE en production');
    passeC = false;
  } else if (!cle.valeur.startsWith(PREFIXE_PUBLIABLE_ATTENDU)) {
    console.log('   - [!SECRET?] ' + nomPage + ' : SUPABASE_CLE_PUBLIABLE ne porte PAS le prefixe ' +
                PREFIXE_PUBLIABLE_ATTENDU + ' -- ROUGE : un prefixe non publiable dans une page servie');
    passeC = false;
  } else {
    console.log('   - [VALORISE] ' + nomPage + ' : SUPABASE_CLE_PUBLIABLE porte le prefixe ' +
                PREFIXE_PUBLIABLE_ATTENDU + ' -- conforme (publiable par construction, S-4)');
  }
}

// ---------------------------------------------------------------------

console.log('');
console.log('  TOTAL : ' + totalBrut + ' occurrence(s) brute(s) de vrais motifs de secret, ' +
            (totalValorise + motsDePasse) + ' valorisee(s) (secrets reels + mots de passe) ; ' +
            'passe C (' + PAGES_SERVIES.join(' + ') + ') ' + (passeC ? 'CONFORME' : 'NON CONFORME') + '.');

const vert = totalValorise === 0 && motsDePasse === 0 && passeC && manquants.length === 0;
console.log(vert
  ? '  VERT -- le commit est autorise.'
  : '  ROUGE -- BORNE DURE n.1 : aucun commit.');
process.exitCode = vert ? 0 : 1;
