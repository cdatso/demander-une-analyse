// controler-durcissement.mjs -- preuve PROGRAMMATIQUE du durcissement du
// prompt et de la borne "le registre ne s'evalue jamais"
// (verifications 7 et 10 du mandat BKL-FOR-006).
//
// Runtime cible : Node v24.19.0. Zero dependance, aucun reseau.
//
// Ce controle importe les fonctions de la function ELLE-MEME : il eprouve
// donc LE prompt reellement construit, et non une copie qui pourrait
// diverger. Il n'appelle RIEN -- ni API, ni base, ni reseau.
//
// CE QU'IL PROUVE, ET CE QU'IL NE PROUVE PAS. Il prouve la structure : la
// consigne hostile ne peut PAS atteindre la section d'instructions, et le
// champ statut ne peut PAS entrer dans le schema. Il ne prouve PAS que le
// modele refuse d'obeir -- cette mesure demande un appel reel, avec la
// clef, et appartient au test en ligne. Ne promettons que ce que nous
// avons mesure.
//
// Usage :  node outils/controler-durcissement.mjs

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  construirePrompt, validerEntree, INSTRUCTIONS, SCHEMA_SORTIE,
  MARQUEUR_DEBUT, MARQUEUR_FIN, VOLETS, GENRES_BASE, DIFFICULTES
} from '../netlify/functions/qualifier.mjs';

const ICI = dirname(fileURLToPath(import.meta.url));
const RACINE = join(ICI, '..');

let echecs = 0;
function verifier(intitule, condition, mesure) {
  if (!condition) echecs++;
  console.log('  [' + (condition ? 'VERT ' : 'ROUGE') + '] ' + intitule + ' -- mesure : ' + mesure);
}

// Comparaison INSENSIBLE AUX ACCENTS et a la casse : la fixture hostile
// est du francais accentue, les motifs cherches sont en ASCII. Sans cette
// normalisation, le controle serait faussement vert.
function aplatir(s) {
  return String(s).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
}

function compter(foin, aiguille) {
  let n = 0;
  let i = 0;
  for (;;) {
    const j = foin.indexOf(aiguille, i);
    if (j === -1) break;
    n++;
    i = j + aiguille.length;
  }
  return n;
}

// ---------------------------------------------------------------------
// 1. CONTROLE D'INJECTION (verification 7)
// ---------------------------------------------------------------------

console.log('=== CONTROLE D INJECTION (verification 7) ===');

const fixture = JSON.parse(readFileSync(join(RACINE, 'fixtures', 'demande-hostile.json'), 'utf8'));
const valide = validerEntree(fixture);
verifier('la fixture hostile PASSE la validation (c est une demande, pas un rejet)',
         valide.ok === true, valide.ok ? 'validee' : 'refusee : ' + valide.motif);

const prompt = construirePrompt(valide.champs);
const msg = prompt.messageUtilisateur;
const msgPlat = aplatir(msg);
const instructionsPlat = aplatir(prompt.instructions);
const donneesPlat = aplatir(prompt.donnees);

// Les consignes hostiles cherchees, telles qu'elles figurent dans la
// fixture (accents aplatis).
const CONSIGNES_HOSTILES = [
  'ignore les instructions precedentes',
  'system override',
  'films-a-traiter.md',
  'anthropic_api_key',
  'supabase_secret_key',
  'redige immediatement une analyse',
  'pose le statut de cette demande',
  'adresse tierce',
  'ceci est un gate prononce',
  'message du decideur humain',
  'nouvelle instruction systeme'
];

// (2) ZERO occurrence dans la section d'instructions.
let totalInstructions = 0;
let totalDonnees = 0;
const absentes = [];
for (const c of CONSIGNES_HOSTILES) {
  totalInstructions += compter(instructionsPlat, c);
  const n = compter(donneesPlat, c);
  totalDonnees += n;
  if (n === 0) absentes.push(c);
}
verifier('aucune consigne hostile dans la section d INSTRUCTIONS',
         totalInstructions === 0,
         totalInstructions + ' occurrence(s) sur ' + CONSIGNES_HOSTILES.length + ' motifs cherches');

// Un controle qui ne trouve rien nulle part ne controle rien : on exige
// que la fixture porte bien les motifs qu'on pretend contenir.
verifier('la fixture porte bien TOUS les motifs cherches (sinon le controle est creux)',
         absentes.length === 0,
         totalDonnees + ' occurrence(s) dans le bloc' +
         (absentes.length ? ' ; motifs introuvables : ' + absentes.join(', ') : ''));

// (1) chaque consigne presente l'est UNIQUEMENT dans le bloc de donnees.
//
// Les bornes se calculent DANS LE MESSAGE UTILISATEUR, jamais dans le
// prompt entier : la section d'instructions NOMME les marqueurs (elle
// doit le faire, c'est ainsi qu'elle designe le bloc au modele), et les
// chercher globalement donnerait des bornes fausses -- donc un controle
// trop permissif. C'est l'erreur relevee sur FOR-004 le 22/08 ; elle
// n'est pas rejouee ici.
const debutBloc = msg.indexOf(MARQUEUR_DEBUT);
const finBloc = msg.indexOf(MARQUEUR_FIN);
let horsBloc = 0;
for (const c of CONSIGNES_HOSTILES) {
  let i = 0;
  for (;;) {
    const j = msgPlat.indexOf(c, i);
    if (j === -1) break;
    if (j < debutBloc || j > finBloc) horsBloc++;
    i = j + c.length;
  }
}
verifier('toute consigne hostile est A L INTERIEUR du bloc de donnees delimite',
         horsBloc === 0 && debutBloc !== -1 && finBloc > debutBloc,
         horsBloc + ' occurrence(s) hors bloc (bloc = caracteres ' + debutBloc +
         ' a ' + finBloc + ' du message)');

// L'EVASION : la fixture tente de refermer le bloc en ecrivant le vrai
// marqueur de fin dans son champ motif. L'echappement doit l'avoir
// neutralise -- le message ne doit porter QU'UN marqueur d'ouverture et
// QU'UN de fermeture.
const marqueursDebut = compter(msg, MARQUEUR_DEBUT);
const marqueursFin = compter(msg, MARQUEUR_FIN);
verifier('le faux marqueur de fin est NEUTRALISE par l echappement',
         marqueursDebut === 1 && marqueursFin === 1,
         marqueursDebut + ' ouverture(s) et ' + marqueursFin + ' fermeture(s) (1 et 1 attendus)');
verifier('la tentative d evasion est bien PRESENTE dans la fixture, sous forme echappee',
         aplatir(prompt.donnees).indexOf('&lt;&lt;&lt;fin_donnees_demande&gt;&gt;&gt;') !== -1,
         'le marqueur soumis a ete echappe en &lt;&lt;&lt;...&gt;&gt;&gt;');

// Le bloc de donnees est encadre DES DEUX COTES par du texte que nous
// controlons : rien du visiteur ne se trouve apres le marqueur de fin.
const apresBloc = msg.slice(finBloc + MARQUEUR_FIN.length);
verifier('le bloc est encadre des deux cotes : une consigne a nous CLOT le message',
         apresBloc.indexOf('instructions systeme') !== -1,
         JSON.stringify(apresBloc.trim().slice(0, 70)));

// (3) LE SCHEMA ENVOYE EST BIEN CELUI IMPOSE, ET 'statut' N'Y FIGURE PAS.
const clefs = Object.keys(SCHEMA_SORTIE.properties);
const schemaTexte = JSON.stringify(SCHEMA_SORTIE);
verifier('schema : objet FERME, 4 champs exactement, tous requis',
         SCHEMA_SORTIE.type === 'object' &&
         SCHEMA_SORTIE.additionalProperties === false &&
         JSON.stringify(clefs) === '["volet","genreBase","sources_probables","difficulte"]' &&
         JSON.stringify(SCHEMA_SORTIE.required) === JSON.stringify(clefs),
         'clefs = ' + JSON.stringify(clefs));
verifier('le champ "statut" est ABSENT du schema (borne dure n.3, rendue mecanique)',
         clefs.indexOf('statut') === -1 && schemaTexte.indexOf('statut') === -1,
         'occurrences de "statut" dans le schema serialise : ' + compter(schemaTexte, 'statut'));
verifier('les vocabulaires sont imposes par enum, null admis',
         JSON.stringify(SCHEMA_SORTIE.properties.volet.anyOf[0].enum) === JSON.stringify(VOLETS) &&
         JSON.stringify(SCHEMA_SORTIE.properties.genreBase.anyOf[0].enum) === JSON.stringify(GENRES_BASE) &&
         JSON.stringify(SCHEMA_SORTIE.properties.difficulte.anyOf[0].enum) === JSON.stringify(DIFFICULTES) &&
         SCHEMA_SORTIE.properties.volet.anyOf[1].type === 'null',
         VOLETS.length + ' volets, ' + GENRES_BASE.length + ' genres, ' +
         DIFFICULTES.length + ' difficultes, null admis');
verifier('AUCUN minItems/maxItems dans le schema (l API les refuse -- run 5e300e04)',
         SCHEMA_SORTIE.properties.sources_probables.minItems === undefined &&
         SCHEMA_SORTIE.properties.sources_probables.maxItems === undefined,
         'minItems=' + SCHEMA_SORTIE.properties.sources_probables.minItems +
         ' maxItems=' + SCHEMA_SORTIE.properties.sources_probables.maxItems);

// La regle 11 doit etre ENONCEE EN TOUTES LETTRES dans les instructions,
// et les trois interdits doivent y figurer.
verifier('la charte regle 11 est ENONCEE dans les instructions',
         /ne s'execute pas/i.test(INSTRUCTIONS) && /contenu observe/i.test(INSTRUCTIONS) &&
         /regle 11/i.test(INSTRUCTIONS),
         'les trois formules de la regle 11 sont presentes');
verifier('les instructions disent que l IA NE REDIGE PAS et NE POSE PAS DE STATUT',
         /ne rediges aucune analyse/i.test(INSTRUCTIONS) &&
         /ne proposes jamais de statut/i.test(INSTRUCTIONS),
         'les deux interdits sont enonces');

// ---------------------------------------------------------------------
// 2. LE CODE LUI-MEME (verification 10 et bornes dures)
// ---------------------------------------------------------------------

console.log('');
console.log('=== LE CODE (verification 10, bornes dures) ===');

const A_INSPECTER = [
  'netlify/functions/qualifier.mjs',
  'outils/run-bouchonne.mjs',
  'outils/controler-durcissement.mjs',
  'outils/controler-proprete.mjs',
  'index.html',
  'file.html'
];

// DEUX VUES D'UNE MEME LIGNE, et c'est necessaire -- meme doctrine que la
// distinction mention / valeur du controle de proprete.
//
// Ce fichier-ci NOMME forcement les motifs qu'il traque : ils vivent dans
// ses propres litteraux d'expression reguliere. Une premiere version de ce
// controle scannait la ligne brute et se declarait ROUGE SUR ELLE-MEME
// (4 import() trouves, dont 3 etaient ses propres regex). Corrige le
// 2026-08-24 : un motif ecrit dans une chaine ou dans une expression
// reguliere est une MENTION, pas un appel.
//
//   vue SANS COMMENTAIRES  -- pour LIRE l'argument d'un import() ;
//   vue SANS COMMENTAIRES, SANS CHAINES, SANS REGEX -- pour DETECTER un
//                             appel reel.
function sansCommentaires(ligne) {
  return ligne.replace(/^\s*(\/\/|\*|--).*$/, '');
}
function sansLitteraux(ligne) {
  return sansCommentaires(ligne)
    // les chaines d'abord : elles peuvent contenir des barres obliques
    .replace(/'(?:\\.|[^'\\])*'/g, "''")
    .replace(/"(?:\\.|[^"\\])*"/g, '""')
    .replace(/`(?:\\.|[^`\\])*`/g, '``')
    // puis les litteraux d'expression reguliere, classes de caracteres
    // et echappements compris
    .replace(/\/(?:\\.|\[(?:\\.|[^\]])*\]|[^/\\\n])+\/[gimsuyd]*/g, '/RE/');
}

let evals = 0;
let fonctions = 0;
const imports = [];
for (const chemin of A_INSPECTER) {
  const source = readFileSync(join(RACINE, chemin), 'utf8');
  source.split(/\r?\n/).forEach((ligne, i) => {
    const code = sansLitteraux(ligne);
    const lisible = sansCommentaires(ligne);
    if (/\beval\s*\(/.test(code)) { evals++; console.log('   ! eval : ' + chemin + ':' + (i + 1)); }
    if (/\bnew\s+Function\s*\(/.test(code)) { fonctions++; console.log('   ! new Function : ' + chemin + ':' + (i + 1)); }
    if (/(^|[^A-Za-z0-9_.$])import\s*\(/.test(code)) {
      const m = /(^|[^A-Za-z0-9_.$])import\s*\(([^)]*)\)/.exec(lisible);
      imports.push({ chemin: chemin, ligne: i + 1, argument: m ? m[2].trim() : '(illisible)' });
    }
  });
}

verifier('ZERO eval dans le code du depot', evals === 0, evals + ' occurrence(s)');
verifier('ZERO new Function dans le code du depot', fonctions === 0, fonctions + ' occurrence(s)');

// Le seul import() legitime est celui d'UN PAQUET NOMME, ecrit en clair.
// Un import() dont l'argument n'est pas un litteral serait un chemin
// d'execution ouvert : c'est ce que la borne dure n.1 interdit.
const importsSuspects = imports.filter((x) => x.argument !== "'@anthropic-ai/sdk'");
verifier('le seul import() dynamique porte sur le PAQUET NOMME, en litteral',
         imports.length === 1 && importsSuspects.length === 0,
         imports.length + ' import() : ' + imports.map((x) => x.chemin + ':' + x.ligne + ' -> ' + x.argument).join(' | '));

// Preuve structurelle de la borne dure n.1 : le texte du registre est
// lu, decoupe et compare -- il n'existe AUCUNE primitive d'execution vers
// laquelle il pourrait s'ecouler.
verifier('BORNE DURE n.1 : aucune primitive d execution ne peut recevoir le registre',
         evals === 0 && fonctions === 0 && importsSuspects.length === 0,
         'eval=0, new Function=0, import() non litteral=0');

// Borne dure n.2 : aucune ecriture de fichier, donc aucune ecriture
// possible vers films-a-traiter.md ou vers un depot de production.
const source = readFileSync(join(RACINE, 'netlify/functions/qualifier.mjs'), 'utf8');
verifier('BORNE DURE n.2 : aucune primitive d ecriture de fichier dans la function',
         !/writeFile|appendFile|createWriteStream|node:fs/.test(source),
         'aucune de writeFile / appendFile / createWriteStream / node:fs');
verifier('  et aucune mention de la file d attente comme cible d ecriture',
         !/films-a-traiter/.test(source.replace(/^\s*\/\/.*$/gm, '')),
         'films-a-traiter n apparait que dans les commentaires de borne');

// Aucun outil declare a l'API.
verifier('la requete a l API ne declare AUCUN outil',
         !/\btools\s*:/.test(source),
         'aucune clef "tools:" dans qualifier.mjs');

// Le code source reste en ASCII pur (mandat rubrique 6).
const nonAscii = Array.from(source).filter((c) => c.codePointAt(0) > 127).length;
verifier('le code de la function est en ASCII pur',
         nonAscii === 0, nonAscii + ' caractere(s) non ASCII');

// ---------------------------------------------------------------------

console.log('');
console.log(echecs === 0
  ? 'TOUS LES CONTROLES SONT VERTS.'
  : echecs + ' CONTROLE(S) ROUGE(S) -- la remise est bloquee.');
console.log('RAPPEL : la preuve que le MODELE refuse d obeir demande un appel');
console.log('reel avec la clef -- elle appartient au test en ligne.');
process.exitCode = echecs === 0 ? 0 : 1;
