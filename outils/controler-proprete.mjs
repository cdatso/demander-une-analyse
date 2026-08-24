// controler-proprete.mjs -- ZERO SECRET, ZERO ADRESSE (verification 13 du
// mandat BKL-FOR-006). BORNE DURE n.1 : AUCUN COMMIT tant que ce controle
// n'est pas vert. Un secret entre dans un historique git n'en sort plus.
//
// Runtime cible : Node v24.19.0. Zero dependance, aucun reseau.
//
// Usage :  node outils/controler-proprete.mjs
//
// ---------------------------------------------------------------------
// TROIS PASSES, ET POURQUOI
// ---------------------------------------------------------------------
// Le mandat demande zero occurrence de motifs comme sb_secret ou
// service_role. Or il demande AUSSI (geste 5 du guide) que le guide NOMME
// les variables et dise ou trouver la clef secrete -- ce qui ecrit
// necessairement la chaine "sb_secret_" dans un fichier versionne.
//
// Les deux exigences ne se contredisent que si l'on confond le NOM d'une
// clef et sa VALEUR. Ce controle les separe :
//
//   PASSE A -- comptage BRUT, motif par motif, tel que le mandat le
//              formule. Le chiffre est rapporte quel qu'il soit.
//   PASSE B -- qualification : une occurrence est un SECRET VALORISE si
//              le motif est suivi d'un jeton d'au moins 16 caracteres de
//              l'alphabet des clefs. Sinon c'est une MENTION (le nom de
//              la variable, une consigne, un commentaire).
//   PASSE C -- LES DEUX EMPLACEMENTS DE file.html. C'est la subtilite
//              propre a ce depot (arbitrage AH n.10) : la page porte deux
//              constantes qui doivent rester VIDES. Cette passe distingue
//              un EMPLACEMENT VIDE d'une VALEUR, et c'est LA VALEUR
//              qu'elle interdit -- une chaine vide est le resultat
//              ATTENDU, pas un defaut.
//
// Le controle est VERT si la passe B compte ZERO secret valorise, la
// passe C trouve les deux emplacements VIDES, et aucun mot de passe
// litteral n'est trouve. Toute occurrence brute est imprimee avec son
// fichier et sa ligne, pour que la lecture reste possible a l'oeil.
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
const A_INSPECTER = [
  'netlify', 'outils', 'supabase', 'fixtures',
  'index.html', 'file.html', 'netlify.toml',
  'package.json', 'package-lock.json',
  'GUIDE-TEST-EN-LIGNE.md', 'README.md', '.gitignore'
];

const MOTIFS = [
  'sk-ant', 'sb_secret', 'sb_publishable', 'service_role', 'eyJ',
  '@cdatso.be', '@yahoo.com', '@gmail.com'
];

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
    console.log('   - [' + (d.valorise ? 'VALORISE' : 'mention ') + '] ' + d.motif +
                ' -- ' + d.fichier + ':' + d.ligne + ' -- ' + d.extrait);
  }
  console.log('');
}

// ---------------------------------------------------------------------
// PASSE C -- LES DEUX EMPLACEMENTS DE file.html
// ---------------------------------------------------------------------
// On cherche l'affectation elle-meme, et on exige une chaine VIDE. Un
// emplacement absent est aussi un defaut : il faut que la page porte bien
// les deux constantes, sinon AH ne saurait pas ou poser les valeurs.

console.log('  --- Les deux emplacements de file.html (arbitrage n.10) ---');
const EMPLACEMENTS = ['SUPABASE_URL', 'SUPABASE_CLE_PUBLIABLE'];
let emplacementsVides = 0;
let emplacementsTrouves = 0;
let page = '';
try { page = readFileSync(join(RACINE, 'file.html'), 'utf8'); } catch (e) { page = ''; }
for (const nom of EMPLACEMENTS) {
  const re = new RegExp('(?:var|let|const)\\s+' + nom + "\\s*=\\s*('([^']*)'|\"([^\"]*)\")\\s*;");
  const m = re.exec(page);
  if (!m) {
    console.log('   - [ABSENT  ] ' + nom + ' : l emplacement est introuvable dans file.html');
    continue;
  }
  emplacementsTrouves++;
  const valeur = m[2] !== undefined ? m[2] : m[3];
  if (valeur === '') {
    emplacementsVides++;
    console.log('   - [VIDE    ] ' + nom + " = '' -- c'est l'attendu : AH le remplira au test en ligne");
  } else {
    console.log('   - [VALORISE] ' + nom + ' porte une valeur de ' + valeur.length +
                ' caractere(s) -- INTERDIT avant commit');
  }
}
const passeC = emplacementsTrouves === EMPLACEMENTS.length && emplacementsVides === EMPLACEMENTS.length;

// ---------------------------------------------------------------------

console.log('');
console.log('  TOTAL : ' + totalBrut + ' occurrence(s) brute(s), ' +
            (totalValorise + motsDePasse) + ' secret(s) valorise(s), ' +
            emplacementsVides + '/' + EMPLACEMENTS.length + ' emplacement(s) vide(s).');

const vert = totalValorise === 0 && motsDePasse === 0 && passeC && manquants.length === 0;
console.log(vert
  ? '  VERT -- le commit est autorise.'
  : '  ROUGE -- BORNE DURE n.1 : aucun commit.');
process.exitCode = vert ? 0 : 1;
