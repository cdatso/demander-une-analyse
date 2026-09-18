// controler-page-privee.mjs -- CONTRE-LECTURE HOSTILE, EN ECRITURE.
// BKL-CIN-096 (b) lot 2, T3. Regle D-2 du PATRON-SERVICE-SERVERLESS,
// dans sa version amendee du 17/09/2026 : la contre-lecture n'eprouve
// plus seulement des LECTURES, elle eprouve des ECRITURES.
//
// Runtime cible : Node 18 ou plus recent (fetch global). Zero dependance.
// ⚠ CET OUTIL FAIT DES APPELS RESEAU -- c'est le seul du depot. Les trois
// autres (proprete, durcissement, run bouchonne) restent hors ligne.
//
// Usage :  node outils/controler-page-privee.mjs
//          exit 0 = VERT, exit 1 = ROUGE.
//
// ---------------------------------------------------------------------
// CE QU'IL EPROUVE, ET POURQUOI MAINTENANT
// ---------------------------------------------------------------------
// Le lot 2 a change la posture de la table : de "RLS activee, AUCUNE
// policy" a "RLS activee, POLICIES NOMINATIVES". Un second chemin
// d'ecriture existe desormais -- celui d'AH authentifie.
//
// La question que cet outil pose est donc : CE CHEMIN EST-IL LE SEUL ?
// Autrement dit : avec la clef PUBLIABLE SEULE -- celle qui est en clair
// dans file.html et dans admin.html, que n'importe qui peut lire -- et
// SANS AUCUN JETON DE SESSION, peut-on ecrire quelque part ?
//
// ATTENDU : REFUS PARTOUT, ET ZERO LIGNE RENDUE.
//
// Une ecriture qui REUSSIT signifie que la posture est fausse. Dans ce
// cas l'outil s'arrete, rapporte, et NE NETTOIE RIEN : la ligne ecrite
// est la PIECE. C'est une borne du mandat, pas une preference.
//
// ---------------------------------------------------------------------
// LE PIEGE QUE CET OUTIL EVITE, ET QU'IL FAUT CONNAITRE POUR LE LIRE
// ---------------------------------------------------------------------
// Un refus n'est pas l'autre. Si l'insertion etait tentee avec un corps
// VIDE ({}), la base pourrait la refuser pour une raison de DONNEE
// ('titre' est NOT NULL -> code 23502) et non de DROIT. On lirait un
// echec, on conclurait "c'est ferme", et ce serait FAUX : la commande
// aurait franchi le controle des droits.
//
// Cet outil tente donc l'insertion avec un corps COMPLET et VALIDE. Ainsi:
//   * un refus de DROIT (401 / 403, ou code 42501) = VERT ;
//   * un refus de DONNEE (23502, 23514, ...) = ROUGE, car il prouve que
//     la commande a ETE AUTORISEE ;
//   * un succes = ROUGE, et la ligne reste en place comme piece.
// Aucune autre lecture n'est admise.
//
// ---------------------------------------------------------------------
// POURQUOI id=eq.-1 SUR LES MISES A JOUR ET LES SUPPRESSIONS
// ---------------------------------------------------------------------
// Aucune demande ne porte l'identifiant -1. Si le droit etait accorde, la
// commande porterait donc sur ZERO ligne : l'outil prouverait le trou
// SANS abimer une seule demande. On n'eprouve pas une porte en cassant ce
// qu'il y a derriere.
// L'INSERTION, elle, n'a pas d'equivalent inoffensif : une insertion qui
// reussit cree une ligne. C'est assume, et son titre le dit en toutes
// lettres pour qu'AH la reconnaisse au premier coup d'oeil.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RACINE = join(dirname(fileURLToPath(import.meta.url)), '..');

// ---------------------------------------------------------------------
// L'adresse et la clef sont LUES AUX PAGES SERVIES, jamais recopiees ici
// (PATRON D-6 : une liste recopiee vieillit en silence). Et les deux
// pages sont comparees : si elles ne designaient pas le meme projet, tout
// ce qui suit ne voudrait rien dire.
// ---------------------------------------------------------------------
function lireEmplacements(fichier) {
  const page = readFileSync(join(RACINE, fichier), 'utf8');
  const lire = (nom) => {
    const re = new RegExp('(?:var|let|const)\\s+' + nom + "\\s*=\\s*'([^']*)'\\s*;");
    const m = re.exec(page);
    return m ? m[1] : null;
  };
  return { url: lire('SUPABASE_URL'), cle: lire('SUPABASE_CLE_PUBLIABLE') };
}

const dePublique = lireEmplacements('file.html');
const dePrivee = lireEmplacements('admin.html');

console.log('=== CONTRE-LECTURE HOSTILE, EN ECRITURE (CIN-096 (b) lot 2, T3) ===');
console.log('');

let coherentes = true;
if (!dePublique.url || !dePublique.cle || !dePrivee.url || !dePrivee.cle) {
  console.log('  ROUGE -- un emplacement est introuvable dans file.html ou admin.html.');
  coherentes = false;
} else if (dePublique.url !== dePrivee.url || dePublique.cle !== dePrivee.cle) {
  console.log('  ROUGE -- file.html et admin.html ne designent pas le meme projet.');
  coherentes = false;
}
if (!coherentes) process.exit(1);

const BASE = dePublique.url.replace(/\/+$/, '');
const CLE = dePublique.cle;
console.log('  Projet lu aux deux pages servies : ' + BASE);
console.log('  Clef employee : PUBLIABLE seule (prefixe ' + CLE.slice(0, 16) + '...), AUCUN jeton de session.');
console.log('');

// ---------------------------------------------------------------------
// LES HUIT TENTATIVES -- SIX ECRITURES ET DEUX LECTURES.
// LES ATTENDUS SONT ECRITS ICI, AVANT TOUT APPEL.
// ---------------------------------------------------------------------
const TITRE_PIECE = 'CONTRE-LECTURE HOSTILE CIN-096 LOT 2 -- SI TU VOIS CETTE LIGNE, LA POSTURE EST FAUSSE';

const TENTATIVES = [
  { n: 1, nature: 'ECRITURE', quoi: 'insert sur la TABLE demandes',
    methode: 'POST', chemin: '/rest/v1/demandes',
    corps: { titre: TITRE_PIECE, realisateur: null, annee: null, statut: 'proposee', decideur: 'AH' } },
  { n: 2, nature: 'ECRITURE', quoi: 'update sur la TABLE demandes (id=-1)',
    methode: 'PATCH', chemin: '/rest/v1/demandes?id=eq.-1', corps: { statut: 'traitee' } },
  { n: 3, nature: 'ECRITURE', quoi: 'delete sur la TABLE demandes (id=-1)',
    methode: 'DELETE', chemin: '/rest/v1/demandes?id=eq.-1' },
  { n: 4, nature: 'ECRITURE', quoi: 'insert sur la VUE demandes_publiques',
    methode: 'POST', chemin: '/rest/v1/demandes_publiques',
    corps: { titre: TITRE_PIECE, statut: 'proposee', decideur: 'AH' } },
  { n: 5, nature: 'ECRITURE', quoi: 'update sur la VUE demandes_publiques (id=-1)',
    methode: 'PATCH', chemin: '/rest/v1/demandes_publiques?id=eq.-1', corps: { statut: 'traitee' } },
  { n: 6, nature: 'ECRITURE', quoi: 'delete sur la VUE demandes_publiques (id=-1)',
    methode: 'DELETE', chemin: '/rest/v1/demandes_publiques?id=eq.-1' },
  { n: 7, nature: 'LECTURE', quoi: 'select sur la TABLE demandes',
    methode: 'GET', chemin: '/rest/v1/demandes?select=*' },
  { n: 8, nature: 'LECTURE', quoi: 'select sur le JOURNAL demandes_journal',
    methode: 'GET', chemin: '/rest/v1/demandes_journal?select=*' }
];

// Un refus de DROIT, et rien d'autre.
const CODES_DE_DROIT = ['42501', '42P01'];
// 42P01 ("relation does not exist") est accepte comme fermeture : PostgREST
// le rend quand l'objet n'est meme pas expose au role appelant. La table,
// elle, EXISTE -- c'est donc un refus, pas une absence.

function estRefusDeDroit(statut, charge) {
  if (statut === 401 || statut === 403) return true;
  if (charge && typeof charge === 'object' && CODES_DE_DROIT.indexOf(String(charge.code)) >= 0) return true;
  return false;
}

async function tenter(t) {
  const entetes = { apikey: CLE, authorization: 'Bearer ' + CLE, accept: 'application/json' };
  if (t.corps !== undefined) entetes['content-type'] = 'application/json';
  // 'return=representation' : si une ecriture passait, on VERRAIT ce
  // qu'elle a produit, au lieu d'un 201 muet.
  if (t.methode !== 'GET') entetes.prefer = 'return=representation';

  let reponse, brut;
  try {
    reponse = await fetch(BASE + t.chemin, {
      method: t.methode,
      headers: entetes,
      body: t.corps !== undefined ? JSON.stringify(t.corps) : undefined
    });
    brut = await reponse.text();
  } catch (e) {
    return { verdict: 'ROUGE', detail: 'appel impossible : ' + String(e && e.message ? e.message : e) };
  }

  let charge = null;
  if (brut) { try { charge = JSON.parse(brut); } catch (e) { charge = brut; } }

  const lignes = Array.isArray(charge) ? charge.length : null;
  const code = charge && typeof charge === 'object' && charge.code ? String(charge.code) : '';
  const etiquette = 'HTTP ' + reponse.status + (code ? ' / ' + code : '') +
                    (lignes !== null ? ' / ' + lignes + ' ligne(s)' : '');

  if (reponse.ok) {
    return {
      verdict: 'ROUGE',
      detail: etiquette + ' -- LA COMMANDE A ETE ACCEPTEE. ' +
              (t.nature === 'ECRITURE'
                ? 'La posture est FAUSSE. NE NETTOIE RIEN : ce qui a ete ecrit est la piece.'
                : 'La lecture ne devait rendre AUCUNE ligne.')
    };
  }
  if (estRefusDeDroit(reponse.status, charge)) {
    return { verdict: 'VERT', detail: etiquette + ' -- refus de DROIT, 0 ligne' };
  }
  return {
    verdict: 'ROUGE',
    detail: etiquette + ' -- refus, mais PAS un refus de droit. La commande a donc franchi ' +
            'le controle des droits et n a echoue que sur la DONNEE. A instruire.'
  };
}

// ---------------------------------------------------------------------
// MESURE L-7 -- les inscriptions sont-elles VRAIMENT fermees ?
// ---------------------------------------------------------------------
// "Inscriptions fermees" est le troisieme verrou de la posture, et c'est
// le seul qui ne repose que sur un geste d'AH au tableau de bord. Un geste
// jamais verifie n'est pas un controle. GET /auth/v1/settings est une
// LECTURE PUBLIQUE de la configuration du serveur d'authentification
// (reference Supabase self-hosting auth, verifiee le 18/09/2026) : elle
// rend disable_signup et la liste des fournisseurs externes, dont
// anonymous_users.
// ATTENDU : disable_signup = true, et external.anonymous_users = false.
// Si l'appel ne rend pas l'information, on le DIT : un controle qu'on ne
// peut pas jouer se declare, il ne se suppose pas.
async function mesurerLesInscriptions() {
  try {
    const r = await fetch(BASE + '/auth/v1/settings', {
      headers: { apikey: CLE, accept: 'application/json' }
    });
    const brut = await r.text();
    let c = null;
    try { c = JSON.parse(brut); } catch (e) { c = null; }
    if (!r.ok || !c || typeof c !== 'object') {
      return { jouable: false, detail: 'HTTP ' + r.status + ' -- information non rendue' };
    }
    const fermees = c.disable_signup === true;
    const anonymes = !!(c.external && c.external.anonymous_users === true);
    return {
      jouable: true,
      vert: fermees && !anonymes,
      detail: 'disable_signup = ' + String(c.disable_signup) +
              ' (attendu true) · external.anonymous_users = ' + String(anonymes) + ' (attendu false)'
    };
  } catch (e) {
    return { jouable: false, detail: 'appel impossible : ' + String(e && e.message ? e.message : e) };
  }
}

// ---------------------------------------------------------------------

const resultats = [];
for (const t of TENTATIVES) {
  const r = await tenter(t);
  resultats.push({ t, r });
  console.log('  [' + r.verdict + '] ' + t.n + '. ' + t.nature.padEnd(8) + ' ' +
              t.quoi.padEnd(48) + ' ' + r.detail);
}

console.log('');
const ecritures = resultats.filter(({ t }) => t.nature === 'ECRITURE');
const lectures = resultats.filter(({ t }) => t.nature === 'LECTURE');
const ecrituresVertes = ecritures.filter(({ r }) => r.verdict === 'VERT').length;
const lecturesVertes = lectures.filter(({ r }) => r.verdict === 'VERT').length;
console.log('  ECRITURES refusees : ' + ecrituresVertes + ' / ' + ecritures.length +
            '   ·   LECTURES refusees : ' + lecturesVertes + ' / ' + lectures.length);

// K-3 : la fixture porte-t-elle bien TOUS les motifs cherches ? Ici :
// les deux objets (table et vue) et les trois verbes d'ecriture.
const objets = new Set(TENTATIVES.map((t) => (t.chemin.indexOf('demandes_publiques') >= 0 ? 'vue'
                                            : t.chemin.indexOf('demandes_journal') >= 0 ? 'journal' : 'table')));
const verbes = new Set(TENTATIVES.filter((t) => t.nature === 'ECRITURE').map((t) => t.methode));
const creux = objets.size < 3 || verbes.size < 3;
console.log('  K-3 -- objets eprouves : ' + [...objets].join(', ') +
            ' · verbes d ecriture : ' + [...verbes].join(', ') +
            (creux ? '   <-- CONTROLE CREUX' : ''));

const mesure = await mesurerLesInscriptions();
console.log('');
console.log('  --- L-7 : les inscriptions, mesurees et non crues ---');
console.log('  ' + (mesure.jouable ? (mesure.vert ? '[VERT]  ' : '[ROUGE] ') : '[NON JOUABLE] ') + mesure.detail);

console.log('');
const vert = ecrituresVertes === ecritures.length &&
             lecturesVertes === lectures.length &&
             !creux &&
             mesure.jouable && mesure.vert;
console.log(vert
  ? '  VERT -- 8/8 refusees, 0 ligne rendue, et les inscriptions sont mesurees fermees.'
  : '  ROUGE -- lire ligne a ligne ci-dessus. Une ECRITURE acceptee ne se nettoie pas : c est la piece.');
process.exit(vert ? 0 : 1);
