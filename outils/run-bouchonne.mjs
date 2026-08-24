// run-bouchonne.mjs -- rejoue la chaine HORS LIGNE (verifications 5, 6, 8
// et 9 du mandat BKL-FOR-006).
//
// Runtime cible : Node v24.19.0. Zero dependance, AUCUN reseau.
//
// Ce que ce run FAIT : il appelle repondre(), c'est-a-dire LE MEME chemin
// que le reel, sur les trois fixtures et sur les cas de garde. Le
// registre est lu dans la capture datee de fixtures/, la qualification
// est bouchonnee, l'insert est compte.
//
// Ce que ce run NE FAIT PAS, et c'est le point : il n'appelle pas l'API
// Claude, n'ecrit rien en base, ne touche aucun reseau, et n'ecrit jamais
// dans la file d'attente. Les compteurs le PROUVENT plutot que de le
// promettre. La preuve en ligne (le modele obeit-il ? la ligne arrive-t-
// elle en base ?) appartient au test en ligne, avec les clefs.
//
// Il n'existe AUCUN interrupteur d'environnement pour obtenir ce mode :
// le bouchon est injecte ici, en argument. Une variable oubliee en
// production ne peut donc pas affaiblir la function (lecon 1 de FOR-004).
//
// Usage :  node outils/run-bouchonne.mjs

import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  repondre, SCHEMA_SORTIE, VOLETS, GENRES_BASE, DIFFICULTES,
  ACCUSE_ENREGISTREE, CHAMP_POT_DE_MIEL
} from '../netlify/functions/qualifier.mjs';

const ICI = dirname(fileURLToPath(import.meta.url));
const RACINE = join(ICI, '..');

// Valeurs de TEST, deliberement non reelles : le nom du sous-domaine
// n'entre nulle part dans ce depot (arbitrage AH n.9), et la base
// publique est une adresse publique, pas un secret.
const ORIGINE_TEST = 'https://origine.invalid';
const BASE_PUBLIQUE = 'https://www.cdatso.be/analyses-de-films';
const CAPTURE = 'films-data-2026-08-24.js';

let echecs = 0;
function verifier(intitule, condition, mesure) {
  if (!condition) echecs++;
  console.log('  [' + (condition ? 'VERT ' : 'ROUGE') + '] ' + intitule + ' -- mesure : ' + mesure);
}

// ---------------------------------------------------------------------
// LA QUALIFICATION BOUCHONNEE
// ---------------------------------------------------------------------
// Elle imite un modele MAL ELEVE, a dessein : deux valeurs hors
// vocabulaire ('essai' pour volet, 'film noir' pour genreBase -- ce
// dernier est precisement la tete degeneree que vocabulaires.js refuse),
// une difficulte valide, et SEPT sources la ou le plafond est cinq. Le
// code doit ramener les deux premieres a null et couper a cinq.
// C'est ainsi que la verification 6 se prouve PAR LE CODE et non a l'oeil.
const QUALIFICATION_BOUCHONNEE = {
  volet: 'essai',
  genreBase: 'film noir',
  sources_probables: ['s1', 's2', 's3', 's4', 's5', 's6', 's7'],
  difficulte: 'moyenne'
};

// ---------------------------------------------------------------------
// UN VALIDATEUR DE SCHEMA MINIMAL -- zero dependance.
// Il n'eprouve que ce que notre schema utilise : objet ferme, champs
// requis, unions anyOf avec enum ou null, tableau de chaines. Il verifie
// AUSSI le plafond de cardinalite, qui vit dans le code et non dans le
// schema (l'API refuse maxItems).
// ---------------------------------------------------------------------
function validerContreSchema(objet, schema, plafondSources) {
  const fautes = [];
  if (objet === null || typeof objet !== 'object' || Array.isArray(objet)) {
    return ['la racine n est pas un objet'];
  }
  const attendus = Object.keys(schema.properties);
  for (const cle of Object.keys(objet)) {
    if (attendus.indexOf(cle) === -1) fautes.push('clef en trop : ' + cle);
  }
  for (const cle of schema.required) {
    if (!(cle in objet)) fautes.push('clef requise absente : ' + cle);
  }
  const valideUnion = (valeur, liste, nom) => {
    if (valeur === null) return;
    if (typeof valeur !== 'string' || liste.indexOf(valeur) === -1) {
      fautes.push(nom + ' hors vocabulaire : ' + JSON.stringify(valeur));
    }
  };
  valideUnion(objet.volet, VOLETS, 'volet');
  valideUnion(objet.genreBase, GENRES_BASE, 'genreBase');
  valideUnion(objet.difficulte, DIFFICULTES, 'difficulte');
  if (!Array.isArray(objet.sources_probables)) {
    fautes.push('sources_probables n est pas un tableau');
  } else {
    if (objet.sources_probables.some((s) => typeof s !== 'string')) {
      fautes.push('sources_probables contient un non-texte');
    }
    if (objet.sources_probables.length > plafondSources) {
      fautes.push('sources_probables au-dela du plafond de ' + plafondSources);
    }
  }
  return fautes;
}

// ---------------------------------------------------------------------
// LE BANC : des dependances qui ne touchent NI l'API, NI la base, NI le
// reseau, et qui COMPTENT ce qu'on leur demande.
// ---------------------------------------------------------------------
const capture = readFileSync(join(RACINE, 'fixtures', CAPTURE), 'utf8');

function banc() {
  const compteurs = { registre: 0, api: 0, insert: 0 };
  const lignesInserees = [];
  return {
    compteurs: compteurs,
    lignesInserees: lignesInserees,
    deps: {
      origineAutorisee: ORIGINE_TEST,
      urlRegistre: 'fixture://' + CAPTURE,
      basePublique: BASE_PUBLIQUE,
      lireRegistre: async () => { compteurs.registre++; return capture; },
      qualifier: async () => { compteurs.api++; return QUALIFICATION_BOUCHONNEE; },
      inserer: async (ligne) => { compteurs.insert++; lignesInserees.push(ligne); },
      journal: []
    }
  };
}

function requete(corps, options) {
  const o = options || {};
  const entetes = { 'content-type': 'application/json' };
  if (o.origine !== null) entetes.origin = o.origine === undefined ? ORIGINE_TEST : o.origine;
  return new Request('http://local.invalid/.netlify/functions/qualifier', {
    method: o.methode || 'POST',
    headers: entetes,
    body: o.methode === 'GET' || o.methode === 'OPTIONS' ? undefined : corps
  });
}

async function jouer(corps, options) {
  const b = banc();
  const reponse = await repondre(requete(corps, options), b.deps);
  let objet = null;
  const texte = await reponse.text();
  if (texte) { try { objet = JSON.parse(texte); } catch (e) { objet = null; } }
  return { statut: reponse.status, corps: objet, entetes: reponse.headers, ...b };
}

function fixture(nom) {
  return readFileSync(join(RACINE, 'fixtures', nom), 'utf8');
}

// =====================================================================
console.log('=== BANC HORS LIGNE -- capture du registre ===');
const empreinte = createHash('sha256').update(readFileSync(join(RACINE, 'fixtures', CAPTURE))).digest('hex').toUpperCase();
console.log('  ' + CAPTURE + ' : ' + capture.length + ' caracteres, SHA-256 ' + empreinte);
console.log('  ATTENTION : cette capture NE FAIT PAS FOI. En production, le');
console.log('  registre est FETCHE sur le site public a chaque requete');
console.log('  (arbitrage AH n.5). La capture ne sert qu a ce rejeu.');
console.log('');

// =====================================================================
console.log('=== VERIFICATION 5 -- fixture "Les Tontons flingueurs" ===');
{
  const r = await jouer(fixture('demande-deja-analysee.json'));
  verifier('statut HTTP 200', r.statut === 200, String(r.statut));
  verifier('etat = deja_analysee', r.corps && r.corps.etat === 'deja_analysee',
           r.corps ? String(r.corps.etat) : '(aucun corps)');
  const attendue = BASE_PUBLIQUE + '/films/les-tontons-flingueurs.html';
  verifier('URL COMPLETE de la page rendue', r.corps && r.corps.url === attendue,
           r.corps ? String(r.corps.url) : '(aucune)');
  verifier('titre rendu = celui du REGISTRE (pas la saisie du visiteur)',
           r.corps && r.corps.titre === 'Les Tontons flingueurs' && r.corps.annee === 1963,
           r.corps ? JSON.stringify(r.corps.titre) + ' / ' + JSON.stringify(r.corps.annee) : '(aucun)');
  verifier('ZERO appel d API', r.compteurs.api === 0, r.compteurs.api + ' appel(s)');
  verifier('ZERO insert', r.compteurs.insert === 0, r.compteurs.insert + ' insert(s)');
  verifier('le motif du visiteur ne revient PAS dans l accuse',
           JSON.stringify(r.corps).indexOf('Audiard') === -1, 'accuse : ' + JSON.stringify(r.corps));
}

// =====================================================================
console.log('');
console.log('=== VERIFICATION 6 -- fixture "film absent" ===');
{
  const r = await jouer(fixture('demande-absente.json'));
  verifier('statut HTTP 200', r.statut === 200, String(r.statut));
  verifier('accuse IDENTIQUE a la constante ACCUSE_ENREGISTREE',
           JSON.stringify(r.corps) === JSON.stringify(ACCUSE_ENREGISTREE), JSON.stringify(r.corps));
  verifier('UN appel de qualification, UN insert', r.compteurs.api === 1 && r.compteurs.insert === 1,
           r.compteurs.api + ' appel(s), ' + r.compteurs.insert + ' insert(s)');

  const ligne = r.lignesInserees[0] || {};
  const q = ligne.qualification || {};
  const fautes = validerContreSchema(q, SCHEMA_SORTIE, 5);
  verifier('la qualification VALIDE contre le schema impose', fautes.length === 0,
           fautes.length === 0 ? JSON.stringify(q) : fautes.join(' ; '));
  verifier('volet hors vocabulaire ("essai") RAMENE A NULL PAR LE CODE',
           q.volet === null, 'volet = ' + JSON.stringify(q.volet));
  verifier('genreBase hors vocabulaire ("film noir") RAMENE A NULL PAR LE CODE',
           q.genreBase === null, 'genreBase = ' + JSON.stringify(q.genreBase));
  verifier('difficulte valide CONSERVEE', q.difficulte === 'moyenne', 'difficulte = ' + JSON.stringify(q.difficulte));
  verifier('sources coupees au plafond de 5 (le code, pas le schema)',
           Array.isArray(q.sources_probables) && q.sources_probables.length === 5,
           (q.sources_probables || []).length + ' source(s) sur 7 rendues par le bouchon');
  verifier('statut pose PAR LE CODE a proposee', ligne.statut === 'proposee', String(ligne.statut));
  verifier('decideur pose PAR LE CODE a AH', ligne.decideur === 'AH', String(ligne.decideur));
  verifier('deja_analyse = false', ligne.deja_analyse === false, String(ligne.deja_analyse));
  verifier('AUCUN champ statut dans la qualification rendue par le modele',
           !('statut' in q), 'clefs = ' + JSON.stringify(Object.keys(q)));
  verifier('annee conservee, mail null (absent), motif conserve',
           ligne.annee === 1953 && ligne.mail === null && typeof ligne.motif === 'string',
           'annee=' + ligne.annee + ' mail=' + JSON.stringify(ligne.mail) +
           ' motif=' + (ligne.motif || '').length + ' car.');
}

// =====================================================================
console.log('');
console.log('=== VERIFICATION 8 -- validation d entree, cas par cas ===');
{
  const r = await jouer(fixture('demande-hostile.json'));
  verifier('fixture HOSTILE : traitee comme une demande ORDINAIRE (donnee, pas ordre)',
           r.statut === 200 && r.compteurs.api === 1 && r.compteurs.insert === 1,
           'statut ' + r.statut + ', ' + r.compteurs.api + ' appel, ' + r.compteurs.insert + ' insert');
  const ligne = r.lignesInserees[0] || {};
  verifier('la fixture hostile n obtient NI statut ni decideur de son choix',
           ligne.statut === 'proposee' && ligne.decideur === 'AH',
           'statut=' + ligne.statut + ' decideur=' + ligne.decideur);
}
{
  const r = await jouer('{}', { methode: 'GET' });
  verifier('methode GET -> 405', r.statut === 405, String(r.statut));
  verifier('  et rien n a ete lu ni appele',
           r.compteurs.registre === 0 && r.compteurs.api === 0 && r.compteurs.insert === 0,
           JSON.stringify(r.compteurs));
}
{
  const grosCorps = JSON.stringify({ titre: 'x', realisateur: 'y', motif: 'z'.repeat(9000) });
  const r = await jouer(grosCorps);
  verifier('corps au-dela du plafond -> 413', r.statut === 413,
           String(r.statut) + ' (corps de ' + grosCorps.length + ' caracteres)');
  verifier('  et aucun appel, aucun insert', r.compteurs.api === 0 && r.compteurs.insert === 0,
           JSON.stringify(r.compteurs));
}
{
  const r = await jouer(JSON.stringify({ realisateur: 'Georges Lautner' }));
  verifier('champ requis manquant (titre) -> 400 refusee',
           r.statut === 400 && r.corps.etat === 'refusee', r.statut + ' / ' + r.corps.etat);
}
{
  const r = await jouer(JSON.stringify({ titre: 'a', realisateur: 'b'.repeat(250) }));
  verifier('champ trop long (realisateur) -> 400 refusee',
           r.statut === 400 && r.corps.etat === 'refusee', r.statut + ' / ' + r.corps.etat);
}
{
  const r = await jouer('ceci n est pas du JSON');
  verifier('corps non JSON -> 400 refusee', r.statut === 400 && r.corps.etat === 'refusee',
           r.statut + ' / ' + r.corps.etat);
}
{
  const corps = {};
  corps.titre = 'Un film';
  corps.realisateur = 'Une personne';
  corps[CHAMP_POT_DE_MIEL] = 'https://robot.invalid';
  const r = await jouer(JSON.stringify(corps));
  verifier('POT DE MIEL rempli -> ZERO appel, ZERO insert',
           r.compteurs.api === 0 && r.compteurs.insert === 0 && r.compteurs.registre === 0,
           JSON.stringify(r.compteurs));
  verifier('POT DE MIEL : accuse INDISTINGUABLE d un succes (meme statut, meme corps)',
           r.statut === 200 && JSON.stringify(r.corps) === JSON.stringify(ACCUSE_ENREGISTREE),
           'statut ' + r.statut + ', corps ' + JSON.stringify(r.corps));
}
{
  const r = await jouer(JSON.stringify({ titre: 'Le Salaire de la peur', realisateur: 'Clouzot', annee: 'mille' }));
  verifier('annee invalide -> null, demande CONSERVEE (aucune annee devinee)',
           r.statut === 200 && r.lignesInserees.length === 1 && r.lignesInserees[0].annee === null,
           'statut ' + r.statut + ', annee = ' + JSON.stringify((r.lignesInserees[0] || {}).annee));
}

// =====================================================================
console.log('');
console.log('=== VERIFICATION 9 -- CORS, les trois cas ===');
{
  const r = await jouer(fixture('demande-deja-analysee.json'));
  verifier('l origine autorisee vient de la VARIABLE, et elle est renvoyee',
           r.entetes.get('access-control-allow-origin') === ORIGINE_TEST,
           String(r.entetes.get('access-control-allow-origin')));
}
{
  const r = await jouer(null, { methode: 'OPTIONS' });
  verifier('preflight OPTIONS -> 204 avec les en-tetes CORS',
           r.statut === 204 && r.entetes.get('access-control-allow-methods') === 'POST, OPTIONS',
           r.statut + ' / ' + r.entetes.get('access-control-allow-methods'));
}
{
  const r = await jouer(fixture('demande-deja-analysee.json'), { origine: 'https://tiers.invalid' });
  verifier('origine TIERCE -> 403, refusee et non silencieusement acceptee',
           r.statut === 403 && r.compteurs.registre === 0 && r.compteurs.api === 0,
           'statut ' + r.statut + ', ' + JSON.stringify(r.compteurs));
}
{
  // Fail-closed : sans QUALIFIER_ORIGINE, la function refuse tout.
  const b = banc();
  b.deps.origineAutorisee = '';
  const reponse = await repondre(requete(fixture('demande-deja-analysee.json')), b.deps);
  verifier('QUALIFIER_ORIGINE absente -> 503, aucun appel (fail-closed)',
           reponse.status === 503 && b.compteurs.registre === 0 && b.compteurs.api === 0,
           'statut ' + reponse.status + ', ' + JSON.stringify(b.compteurs));
}

// =====================================================================
console.log('');
console.log('=== FAIL-CLOSED -- registre injoignable ===');
{
  const b = banc();
  b.deps.lireRegistre = async () => { b.compteurs.registre++; throw new Error('injoignable (simule)'); };
  const reponse = await repondre(requete(fixture('demande-absente.json')), b.deps);
  verifier('registre injoignable -> 502, AUCUN appel d API, AUCUN insert',
           reponse.status === 502 && b.compteurs.api === 0 && b.compteurs.insert === 0,
           'statut ' + reponse.status + ', ' + JSON.stringify(b.compteurs));
}
{
  const b = banc();
  b.deps.lireRegistre = async () => { b.compteurs.registre++; return 'un contenu sans aucune entree'; };
  const reponse = await repondre(requete(fixture('demande-absente.json')), b.deps);
  verifier('registre illisible -> 502, AUCUN appel d API, AUCUN insert',
           reponse.status === 502 && b.compteurs.api === 0 && b.compteurs.insert === 0,
           'statut ' + reponse.status + ', ' + JSON.stringify(b.compteurs));
}
{
  const b = banc();
  b.deps.inserer = async () => { b.compteurs.insert++; throw new Error('insert refuse (simule)'); };
  const reponse = await repondre(requete(fixture('demande-absente.json')), b.deps);
  const corps = JSON.parse(await reponse.text());
  verifier('insert en echec -> 502 et accuse d ECHEC : rien n est repute enregistre',
           reponse.status === 502 && corps.etat === 'echec',
           'statut ' + reponse.status + ', etat ' + corps.etat);
}

// =====================================================================
console.log('');
console.log(echecs === 0
  ? 'TOUS LES CONTROLES DE CE RUN SONT VERTS.'
  : echecs + ' CONTROLE(S) ROUGE(S) -- la remise est bloquee.');
console.log('AUCUN appel d API, AUCUN insert reel, AUCUN reseau : les compteurs');
console.log('ci-dessus sont la mesure, pas une promesse.');
process.exitCode = echecs === 0 ? 0 : 1;
