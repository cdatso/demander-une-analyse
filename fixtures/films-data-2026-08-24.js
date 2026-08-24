// Registre des analyses publiées sur le site.
// Pour ajouter un film : ajouter un objet à ce tableau et créer le fichier HTML correspondant dans /films.
// Convention d'images : déposer l'affiche dans assets/posters/<slug>.jpg
// (le champ poster peut être omis tant qu'aucune image n'est disponible —
// l'absence de fichier est gérée proprement par la page).
// Promotion de l'objet en une (accueil-deux-cartes, BKL-CIN, 30/07/2026) :
// `promotion: true` sur UNE SEULE entrée pousse cette analyse en second
// volet de l'accueil, à la place de l'avant-dernière publiée (repli par
// défaut). Jamais sur la dernière publiée elle-même (Corpus.rendUne
// l'ignore alors et replie sur l'avant-dernière). Un acte délibéré,
// distinct de la publication d'une analyse (même doctrine que P-12).
const FILMS = [
  {
    slug: 'annie-hall',
    title: 'Annie Hall',
    director: 'Woody Allen',
    year: 1977,
    summary: "Comment un film sur une rupture amoureuse a redéfini la comédie romantique américaine.",
    url: 'films/annie-hall.html',
    poster: 'assets/posters/annie-hall.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-03 09:00',
    genreBase: 'comedie',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['couleur']
  },
  {
    slug: 'the-old-oak',
    title: 'The Old Oak',
    director: 'Ken Loach',
    year: 2023,
    summary: "Le dernier pub debout, la dernière fable de Ken Loach : réfugiés syriens et mineurs abandonnés dans le nord-est de l'Angleterre.",
    url: 'films/the-old-oak.html',
    poster: 'assets/posters/the-old-oak.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-03 09:00',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Royaume-Uni', 'France', 'Belgique'],
    technique: ['couleur']
  },
  {
    slug: 'soudain-lete-dernier',
    title: "Soudain l'été dernier",
    director: 'Joseph L. Mankiewicz',
    year: 1959,
    summary: "Un mélodrame gothique sur l'emprise maternelle, la censure du Code Hays et une vérité qu'on tente de faire taire à coups de scalpel.",
    url: 'films/soudain-lete-dernier.html',
    poster: 'assets/posters/soudain-lete-dernier.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-03 10:14',
    genreBase: 'melodrame',
    producteur: 'non spécifié',
    pays: ['Etats-Unis', 'Royaume-Uni'],
    technique: ['n&b']
  },
  {
    slug: 'soy-cuba',
    title: 'Soy Cuba',
    director: 'Mikhaïl Kalatozov',
    year: 1964,
    summary: "Un manifeste de propagande cubano-soviétique dont la virtuosité visuelle a fini par échapper à ses propres commanditaires.",
    url: 'films/soy-cuba.html',
    poster: 'assets/posters/soy-cuba.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-03 18:11',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Cuba', 'Union sovietique'],
    technique: ['n&b']
  },
  {
    slug: 'sud',
    title: 'Sud',
    director: 'Chantal Akerman',
    year: 1999,
    summary: "Une traversée silencieuse du Sud des États-Unis, hantée par le meurtre raciste de James Byrd Jr.",
    url: 'films/sud.html',
    poster: 'assets/posters/sud.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-03 18:11',
    genreBase: 'documentaire',
    producteur: 'non spécifié',
    pays: ['France', 'Belgique'],
    technique: ['couleur']
  },
  {
    slug: 'shutter-island',
    title: 'Shutter Island',
    director: 'Martin Scorsese',
    year: 2010,
    summary: "Un marshal fédéral enquête sur une île-asile où la vérité qu'il cherche finit par se retourner contre lui.",
    url: 'films/shutter-island.html',
    poster: 'assets/posters/shutter-island.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-03 18:12',
    genreBase: 'thriller',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['couleur']
  },
  {
    slug: 'hamnet',
    title: 'Hamnet',
    director: 'Chloé Zhao',
    year: 2025,
    summary: "Comment le deuil d'un fils disparu a pu donner naissance à l'un des chefs-d'œuvre de Shakespeare.",
    url: 'films/hamnet.html',
    poster: 'assets/posters/hamnet.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-03 18:12',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Royaume-Uni', 'Etats-Unis'],
    technique: ['couleur']
  },
  {
    slug: 'les-deux-orphelines',
    title: 'Les Deux Orphelines',
    director: 'D. W. Griffith',
    year: 1921,
    summary: "Deux sœurs de cœur séparées par la Révolution française, dans le dernier mélodrame muet où Griffith réunit une dernière fois les sœurs Gish.",
    url: 'films/les-deux-orphelines.html',
    poster: 'assets/posters/les-deux-orphelines.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-04 10:11',
    genreBase: 'melodrame',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['muet', 'n&b']
  },
  {
    slug: 'rosetta',
    title: 'Rosetta',
    director: 'Jean-Pierre & Luc Dardenne',
    year: 1999,
    summary: "Une adolescente en quête désespérée d'un emploi stable, filmée caméra à l'épaule par les frères Dardenne jusqu'à la Palme d'or.",
    url: 'films/rosetta.html',
    poster: 'assets/posters/rosetta.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-04 10:11',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Belgique', 'France'],
    technique: ['couleur']
  },
  {
    slug: 'rouges-et-blancs',
    title: 'Rouges et Blancs',
    director: 'Miklós Jancsó',
    year: 1967,
    summary: "Une chorégraphie glaciale de la guerre civile russe, où Miklós Jancsó filme la violence comme une géométrie sans héros.",
    url: 'films/rouges-et-blancs.html',
    poster: 'assets/posters/rouges-et-blancs.jpg',
    // --- schéma v2 (annexe B) — entrée migrée par le prototype BKL-065-3 ---
    volet: 'critique',
    datePublication: '2026-07-04 10:11',
    pays: ['Hongrie', 'Union sovietique'],
    genreBase: 'drame',
    technique: ['n&b'],
    producteur: 'non spécifié'
  },
  {
    slug: 'persona',
    title: 'Persona',
    director: 'Ingmar Bergman',
    year: 1966,
    summary: "Écrit en quatorze jours sur un lit d'hôpital, un huis clos entre une infirmière et une actrice devenue muette qui a fini par redéfinir le cinéma moderne.",
    url: 'films/persona.html',
    poster: 'assets/posters/persona.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 00:33',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Suede'],
    technique: ['n&b'],
    deleuze: { oeuvre: 'IM', pages: [142, 149], concepts: 'la limite du visage ou le néant : Bergman ; les composantes affectives du gros plan' }
  },
  {
    slug: 'au-fil-de-leau',
    title: "Au fil de l'eau",
    director: 'Fritz Lang',
    year: 1950,
    summary: "Un romancier raté transforme son crime en roman à succès — mais la rivière de Fritz Lang rend toujours ce qu'on lui confie.",
    url: 'films/au-fil-de-leau.html',
    poster: 'assets/posters/au-fil-de-leau.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 16:58',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['n&b'],
    genreBase: 'polar'
  },
  {
    slug: 'raging-bull',
    title: 'Raging Bull',
    director: 'Martin Scorsese',
    year: 1980,
    summary: "Scorsese pensait signer son dernier film ; il a filmé la jalousie d'un champion comme un opéra en noir et blanc, à hauteur de coups.",
    url: 'films/raging-bull.html',
    poster: 'assets/posters/raging-bull.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 17:06',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['n&b']
  },
  {
    slug: 'le-cheval-de-turin',
    title: 'Le Cheval de Turin',
    director: 'Béla Tarr',
    year: 2011,
    summary: "Six jours de vent, un cheval qui refuse, la lumière qui s'éteint : le dernier film de Béla Tarr regarde la fin du monde à hauteur de pommes de terre.",
    url: 'films/le-cheval-de-turin.html',
    poster: 'assets/posters/le-cheval-de-turin.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 17:14',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Hongrie', 'France', 'Allemagne', 'Suisse'],
    technique: ['n&b']
  },
  {
    slug: 'la-mariee-etait-en-noir',
    title: 'La mariée était en noir',
    director: 'François Truffaut',
    year: 1968,
    summary: "Cinq noms sur une liste, une robe mi-lys mi-corbeau : Truffaut filme la vengeance comme un chagrin d'amour, sous le regard d'Hitchcock.",
    url: 'films/la-mariee-etait-en-noir.html',
    poster: 'assets/posters/la-mariee-etait-en-noir.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 20:13',
    genreBase: 'thriller',
    producteur: 'non spécifié',
    pays: ['France', 'Italie'],
    technique: ['couleur']
  },
  {
    slug: 'bienvenue-a-suburbicon',
    title: 'Bienvenue à Suburbicon',
    director: 'George Clooney',
    year: 2017,
    summary: "Un scénario noir des Coen greffé sur un fait divers de la ségrégation : pendant que la banlieue assiège sa seule famille innocente, le crime blanc prospère pavillon contre pavillon.",
    url: 'films/bienvenue-a-suburbicon.html',
    poster: 'assets/posters/bienvenue-a-suburbicon.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 20:19',
    genreBase: 'comedie',
    producteur: 'non spécifié',
    pays: ['Etats-Unis', 'Royaume-Uni'],
    technique: ['couleur']
  },
  {
    slug: 'manhattan',
    title: 'Manhattan',
    director: 'Woody Allen',
    year: 1979,
    summary: "Une déclaration d'amour en Scope noir et blanc à une ville rêvée sur du Gershwin — chef-d'œuvre formel devenu pièce à conviction de son propre auteur.",
    url: 'films/manhattan.html',
    poster: 'assets/posters/manhattan.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 21:04',
    genreBase: 'comedie',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['n&b']
  },
  {
    slug: 'sans-filtre',
    title: 'Sans Filtre',
    director: 'Ruben Östlund',
    year: 2022,
    summary: "Un yacht d'oligarques, une tempête gastrique, une dame pipi promue capitaine : la Palme d'or la plus clivante de la décennie filme la lutte des classes à hauteur d'estomac.",
    url: 'films/sans-filtre.html',
    poster: 'assets/posters/sans-filtre.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 21:14',
    genreBase: 'comedie',
    producteur: 'non spécifié',
    pays: ['Suede', 'Allemagne', 'France', 'Royaume-Uni'],
    technique: ['couleur']
  },
  {
    slug: 'retour-a-seoul',
    title: 'Retour à Séoul',
    director: 'Davy Chou',
    year: 2022,
    summary: "Une adoptée française rentre « chez elle » dans un pays dont elle ne parle pas la langue — et refuse huit ans durant toutes les identités qu'on lui tend.",
    url: 'films/retour-a-seoul.html',
    poster: 'assets/posters/retour-a-seoul.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 21:21',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['France', 'Allemagne', 'Belgique', 'Coree du Sud'],
    technique: ['couleur']
  },
  {
    slug: 'waterloo',
    title: 'Waterloo',
    director: 'Sergueï Bondartchouk',
    year: 1970,
    summary: "Vingt mille soldats soviétiques, un producteur italien et deux empires du cinéma pour rejouer la journée qui a défait Napoléon — la dernière bataille filmée sans trucage à cette échelle.",
    url: 'films/waterloo.html',
    poster: 'assets/posters/waterloo.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 23:32',
    genreBase: 'fresque',
    producteur: 'non spécifié',
    pays: ['Italie', 'Union sovietique'],
    technique: ['couleur']
  },
  {
    slug: 'nouvelle-vague',
    title: 'Nouvelle Vague',
    director: 'Richard Linklater',
    year: 2025,
    summary: "Le tournage d'À bout de souffle rejoué plan par plan, en français et en 1.37 : la déclaration d'amour d'un cinéphile texan au geste le plus libre du cinéma.",
    url: 'films/nouvelle-vague.html',
    poster: 'assets/posters/nouvelle-vague.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-05 23:44',
    genreBase: 'comedie',
    producteur: 'non spécifié',
    pays: ['Etats-Unis', 'France'],
    technique: ['n&b']
  },
  {
    slug: 'julie-en-12-chapitres',
    title: 'Julie (en 12 chapitres)',
    director: 'Joachim Trier',
    year: 2021,
    summary: "Quatre ans de la vie d'une femme qui essaie toutes les vies possibles, racontés comme un roman — et le prix d'interprétation de Cannes pour Renate Reinsve.",
    url: 'films/julie-en-12-chapitres.html',
    poster: 'assets/posters/julie-en-12-chapitres.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-06 08:20',
    genreBase: 'comedie',
    producteur: 'non spécifié',
    pays: ['Norvege', 'France', 'Suede', 'Danemark'],
    technique: ['couleur']
  },
  {
    slug: 'le-golem',
    title: 'Le Golem',
    director: 'Julien Duvivier',
    year: 1936,
    summary: "Un cinéaste français filme à Prague, trois ans après l'arrivée de Hitler au pouvoir, la légende du géant d'argile qui venge le ghetto : le fantastique comme éditorial.",
    url: 'films/le-golem.html',
    poster: 'assets/posters/le-golem.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-06 08:26',
    genreBase: 'fantastique',
    producteur: 'non spécifié',
    pays: ['France', 'Tchecoslovaquie'],
    technique: ['n&b']
  },
  {
    slug: 'moi-daniel-blake',
    title: 'Moi, Daniel Blake',
    director: 'Ken Loach',
    year: 2016,
    summary: "Trop malade pour travailler, pas assez pour être indemnisé : la Palme d'or la plus politique de la décennie, écrite à la bombe sur le mur d'une administration.",
    url: 'films/moi-daniel-blake.html',
    poster: 'assets/posters/moi-daniel-blake.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-06 08:32',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Royaume-Uni', 'France', 'Belgique'],
    technique: ['couleur']
  },
  {
    slug: 'la-chevauchee-fantastique',
    title: 'La Chevauchée fantastique',
    director: 'John Ford',
    year: 1939,
    summary: "Neuf voyageurs que la bonne société ne mettrait jamais dans la même pièce, une diligence, le territoire apache : le film qui a rendu au western ses lettres de noblesse.",
    url: 'films/la-chevauchee-fantastique.html',
    poster: 'assets/posters/la-chevauchee-fantastique.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-06 11:21',
    genreBase: 'western',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['n&b'],
    deleuze: { oeuvre: 'IM', pages: [203], concepts: "le western (Ford) : de la situation à l'action, l'englobant et le duel" }
  },
  {
    slug: 'le-doulos',
    title: 'Le Doulos',
    director: 'Jean-Pierre Melville',
    year: 1962,
    summary: "Un mot d'argot qui désigne à la fois un chapeau et un indicateur : Melville construit tout un polar sur l'impossibilité de savoir, jusqu'au bout, qui porte lequel des deux sens.",
    url: 'films/le-doulos.html',
    poster: 'assets/posters/le-doulos.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-07 06:38',
    producteur: 'Claude Sonnet 5 (pipeline, routine nocturne)',
    pays: ['France', 'Italie'],
    technique: ['n&b'],
    genreBase: 'polar'
  },
  {
    slug: 'sur-la-route-domaha',
    title: "Sur la route d'Omaha",
    director: 'Cole Webley',
    year: 2025,
    summary: "Un père ruiné par la crise de 2008 conduit ses deux enfants vers une destination qu'il leur tait — et que ce road movie ne dévoile qu'à ses tout derniers mètres, quitte à rétroéclairer chaque étape parcourue.",
    url: 'films/sur-la-route-domaha.html',
    poster: 'assets/posters/sur-la-route-domaha.jpg',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-10 08:29',
    genreBase: 'drame',
    producteur: 'non spécifié',
    pays: ['Etats-Unis'],
    technique: ['couleur']
  },
  {
    slug: 'pandora',
    title: 'Pandora — Champ',
    director: 'Albert Lewin',
    year: 1951,
    summary: "Albert Lewin filme Ava Gardner comme une statue de déesse pour mieux la faire redescendre parmi les mortels : un mélodrame ouvertement surréaliste, jugé prétentieux à sa sortie avant d'être reconnu comme un sommet du romantisme noir.",
    url: 'films/pandora.html',
    poster: 'assets/posters/pandora.jpg',
    producteur: 'Claude Sonnet 5 (pipeline, routine nocturne)',
    // --- schéma v2 (annexe B) — entrée migrée par le prototype BKL-065-3 ---
    volet: 'critique',
    datePublication: '2026-07-18 20:45',
    pays: ['Royaume-Uni', 'Etats-Unis'],
    genreBase: 'melodrame',
    technique: ['couleur'],
    courant: ['romantisme noir', 'surrealisme']
  },
  {
    slug: 'pandora-contrechamp',
    title: 'Pandora — Contrechamp',
    director: 'Albert Lewin',
    year: 1951,
    summary: "La même œuvre relue par un second regard : reprise et enrichissement squad d'une analyse déléguée à OpenAI GPT-5.5, avec un appareil théorique deleuzien (l'ouverture à la lunette, la « femme originaire ») absent du champ.",
    url: 'films/pandora-contrechamp.html',
    poster: 'assets/posters/pandora.jpg',
    producteur: 'OpenAI GPT-5.5 (reprise et enrichissement squad)',
    variantOf: 'pandora',
    // --- schéma v2 (annexe B) — entrée migrée par le prototype BKL-065-3 ---
    volet: 'etude',
    datePublication: '2026-07-18 23:45',
    pays: ['Royaume-Uni', 'Etats-Unis'],
    genreBase: 'melodrame',
    technique: ['couleur'],
    courant: ['romantisme noir', 'surrealisme']
  },
  {
    slug: 'la-nuit-de-san-lorenzo',
    title: 'La Nuit de San Lorenzo',
    director: 'Paolo et Vittorio Taviani',
    year: 1982,
    summary: "Les Taviani racontent le massacre de leur propre ville comme une berceuse d'étoiles filantes — parti pris magnifique, qui aura aussi fixé pour le monde entier une responsabilité que les archives ont depuis déplacée.",
    url: 'films/la-nuit-de-san-lorenzo.html',
    poster: 'assets/posters/la-nuit-de-san-lorenzo.jpg',
    producteur: 'Claude Opus (session supervisée)',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-21 09:06',
    genreBase: 'drame',
    pays: ['Italie'],
    technique: ['couleur']
  },
  {
    slug: 'hamlet',
    title: 'Hamlet',
    director: 'Grigori Kozintsev',
    year: 1964,
    summary: "Kozintsev retire au rôle le plus commenté du théâtre occidental ce dont on croyait qu'il était fait — l'hésitation : son prince n'est pas empêché par lui-même, mais par une forteresse d'État dont le film ne cesse de filmer les barreaux.",
    url: 'films/hamlet.html',
    poster: 'assets/posters/hamlet.jpg',
    producteur: 'Claude Opus (session supervisée)',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-21 09:20',
    genreBase: 'tragedie',
    pays: ['Union sovietique'],
    technique: ['n&b']
  },
  {
    slug: 'le-samourai',
    title: 'Le Samouraï',
    director: 'Jean-Pierre Melville',
    year: 1967,
    summary: "Un tueur à gages qui n'est plus qu'une méthode : Melville retire la couleur de la couleur, invente de toutes pièces la citation du Bushido qui ouvre le film, et fait tenir une morale entière sur un document faux.",
    url: 'films/le-samourai.html',
    poster: 'assets/posters/le-samourai.jpg',
    producteur: 'Claude Sonnet 5 (pipeline, routine nocturne)',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-21 11:13',
    genreBase: 'polar',
    pays: ['France', 'Italie'],
    technique: ['couleur']
  },
  {
    slug: 'hitchcock-truffaut',
    title: 'Hitchcock/Truffaut',
    director: 'Kent Jones',
    year: 2015,
    summary: "Truffaut avait enfermé Hitchcock huit jours dans un bureau d'Universal pour le sauver de sa réputation d'amuseur ; cinquante ans plus tard, Kent Jones rouvre les bandes et compose, sans tout à fait le vouloir, le portrait d'un panthéon devenu club.",
    url: 'films/hitchcock-truffaut.html',
    poster: 'assets/posters/hitchcock-truffaut.jpg',
    producteur: 'Claude Sonnet 5 (pipeline, routine nocturne)',
    // --- schema v2 (annexe B) -- retrofit BKL-065-5, 22/07/2026 ---
    volet: 'critique',
    datePublication: '2026-07-21 23:38',
    genreBase: 'documentaire',
    pays: ['Etats-Unis', 'France'],
    technique: ['couleur']
  },
  {
    slug: 'hommes-porcs-et-loups',
    title: 'Hommes, porcs et loups',
    director: 'Kinji Fukasaku',
    year: 1964,
    summary: "Trois frères d'un bidonville de Tokyo, quarante millions de yens volés à leur propre clan : le film où Kinji Fukasaku a trouvé sa violence, sorti dans des salles vides à quelques semaines des Jeux olympiques.",
    url: 'films/hommes-porcs-et-loups.html',
    poster: 'assets/posters/hommes-porcs-et-loups.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    datePublication: '2026-07-25 01:09',
    genreBase: 'polar',
    producteur: 'Claude Opus 5 (session supervisée)',
    pays: ['Japon'],
    technique: ['n&b']
  },
  {
    slug: 'voyage-en-italie',
    title: 'Voyage en Italie',
    director: 'Roberto Rossellini',
    year: 1954,
    summary: "Un couple anglais se défait au fil d'un séjour à Naples : salué par les Cahiers du cinéma comme le premier « film moderne », le film est aussi, chez Deleuze, la charnière entre l'image-mouvement et l'image-temps — étude à double éclairage deleuzien (IM 286, IT 9), première Étude produite par le processus Scholar.",
    url: 'films/voyage-en-italie.html',
    poster: 'assets/posters/voyage-en-italie.jpg',
    producteur: 'Claude Opus 4.8 (session supervisée)',
    // --- schema v2 (annexe B) — Étude régime B, pilote BKL-065-4 ---
    volet: 'etude',
    datePublication: '2026-07-25 11:02',
    pays: ['Italie', 'France'],
    genreBase: 'drame',
    technique: ['n&b'],
    courant: ['neorealisme']
  },
  {
    slug: 'blade-runner',
    title: 'Blade Runner',
    director: 'Ridley Scott',
    year: 1982,
    summary: "Un film où l'identité ne se prouve ni par le souvenir ni par la sincérité, mais par un appareil, une photographie et un témoin.",
    url: 'films/blade-runner.html',
    poster: 'assets/posters/blade-runner.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    datePublication: '2026-07-26 14:29',
    genreBase: 'science-fiction',
    producteur: 'Claude Opus 5 (session supervisée)',
    pays: ['Etats-Unis', 'Hong Kong', 'Royaume-Uni'],
    technique: ['couleur']
  },
  {
    slug: 'coffee-and-cigarettes',
    title: 'Coffee and Cigarettes',
    director: 'Jim Jarmusch',
    year: 2003,
    summary: "Onze conversations tournées sur vingt ans que Jarmusch présente comme un passe-temps sans dessein — jusqu'à ce qu'un acteur, dans un aveu de vulnérabilité que rien n'annonçait, vienne démentir la nonchalance de façade.",
    url: 'films/coffee-and-cigarettes.html',
    poster: 'assets/posters/coffee-and-cigarettes.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    datePublication: '2026-07-26 23:09',
    genreBase: 'comedie',
    producteur: 'Claude Opus 5 (session supervisée)',
    pays: ['Etats-Unis'],
    technique: ['n&b']
  },
  {
    slug: 'lhomme-au-crane-rase',
    title: "L'Homme au crâne rasé",
    director: 'André Delvaux',
    year: 1965,
    summary: "Le film fondateur du cinéma belge moderne : un professeur glisse de l'amour tu à l'internement, sans que le spectateur puisse jamais dire où la réalité s'est arrêtée.",
    url: 'films/lhomme-au-crane-rase.html',
    poster: 'assets/posters/lhomme-au-crane-rase.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    datePublication: '2026-07-27 17:34',
    genreBase: 'drame',
    producteur: 'Claude Opus 5 (pipeline, routine nocturne)',
    pays: ['Belgique'],
    technique: ['n&b'],
    // P-12 soldée (gate AH 27/07 soir) : `realisme magique` entré au vocabulaire,
    // facette rétrofittée — l'omission initiale de la routine était la bonne
    // conduite (terme absent, jamais inventé, jamais rabattu sur 'surrealisme').
    courant: ['realisme magique']
  },
  {
    slug: 'dogville',
    title: 'Dogville',
    director: 'Lars von Trier',
    year: 2003,
    summary: "Sur un plateau nu où les maisons ne sont que des traits de craie, Lars von Trier piège la charité chrétienne dans une expérience de laboratoire — et le spectateur avec elle.",
    url: 'films/dogville.html',
    poster: 'assets/posters/dogville.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    // DÉMONSTRATION — accueil-deux-cartes (BKL-CIN, 30/07/2026) : valeur
    // posée pour la capture « avec promue » remise à AH, PAS un choix
    // éditorial. À retirer, garder ou déplacer sur un autre film à la
    // relecture — le merge est le gate d'AH (mandat §5).
    promotion: true,
    datePublication: '2026-07-27 18:14',
    genreBase: 'drame',
    producteur: 'Claude Fable 5 (session supervisée)',
    // Coproduction au périmètre divergent selon les sources (5 pays selon
    // Wikipédia EN ; 9 selon Wikipédia FR, dont Pays-Bas et Finlande, absents
    // du vocabulaire fermé) : les 5 principaux retenus, divergence déclarée
    // dans la page (prologue) et au rapport de session — jamais tranchée en
    // silence (skill v2.1, étape 1).
    pays: ['Danemark', 'Suede', 'Royaume-Uni', 'France', 'Allemagne'],
    technique: ['couleur']
  },
  {
    slug: 'les-fraises-sauvages',
    title: 'Les Fraises sauvages',
    director: 'Ingmar Bergman',
    year: 1957,
    summary: "Bergman confie au fondateur du cinéma suédois le rôle d'un vieillard qui apprend, en une seule journée de route, qu'il est mort depuis longtemps.",
    poster: 'assets/posters/les-fraises-sauvages.jpg',
    url: 'films/les-fraises-sauvages.html',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    datePublication: '2026-07-29 10:11',
    genreBase: 'drame',
    producteur: 'Claude Opus 5 (session supervisée)',
    pays: ['Suede'],
    technique: ['n&b']
    // `poster` ajouté à l'intégration (29/07, greffe) : affiche prise en
    // priorité 1 dans la base locale D: (239 Ko < seuil P-36), la session
    // claude.ai productrice n'y avait pas accès — règle des deux gestes de
    // l'étape 8.2 respectée (fichier + champ ajoutés ensemble).
  },
  {
    slug: 'la-bataille-de-marathon',
    title: 'La Bataille de Marathon',
    director: 'Jacques Tourneur, Mario Bava et Bruno Vailati',
    year: 1959,
    summary: "Un péplum signé par un maître de l'ombre, terminé par son chef opérateur non crédité — et c'est ce dernier que la postérité est venue chercher.",
    url: 'films/la-bataille-de-marathon.html',
    poster: 'assets/posters/la-bataille-de-marathon.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    datePublication: '2026-07-30 00:18',
    // ESCALADE P-12 SOLDÉE (gate AH 30/07 00h1x, formule pré-remplie par la
    // routine) : 'peplum' inscrit au vocabulaire, entrée rétrofittée
    // fresque → peplum dans le même commit distinct de la publication.
    genreBase: 'peplum',
    producteur: 'Claude Opus 5 (pipeline, routine nocturne)',
    pays: ['Italie', 'France'],
    technique: ['couleur']
  },
  {
    slug: 'lolita',
    title: 'Lolita',
    director: 'Stanley Kubrick',
    year: 1962,
    summary: "Pour obtenir le droit de filmer l'infilmable, Kubrick a tout déplacé hors du cadre — et les archives montrent où ça a atterri : sur l'affiche.",
    url: 'films/lolita.html',
    poster: 'assets/posters/lolita.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    // datePublication = date du MERGE (point ferme nº 6 du mandat du 30/07),
    // actualisée au geste de statut post-merge : merge `1346ec3` du 30/07 à
    // 00h55, gate AH « go pour le merge sur main » (la valeur provisoire de
    // rédaction, 00:45, est remplacée).
    datePublication: '2026-07-30 00:55',
    // ESCALADE P-12 EN PROPOSITION — NON CONSIGNÉE, NON APPLIQUÉE.
    // Valeur retenue : 'comedie', valeur existante la plus juste (le film
    // choisit la comédie ; c'est la lecture dominante des sources 1, 2 et 3
    // de la page, et celle de l'analyse elle-même). Elle aplatit toutefois
    // le registre réel : le terme juste serait `comedie noire`, absent du
    // vocabulaire. Candidat au rétrofit si le terme entre : l'entrée
    // `bienvenue-a-suburbicon` (aujourd'hui 'comedie').
    // Formule de gate PRÉ-REMPLIE pour AH, à prononcer ou à écarter —
    // aucune écriture au vocabulaire sans elle (P-12, charte règle 9) :
    //   « ajoute comedie noire au vocabulaire genreBase »
    // (+ éventuellement « et rétrofitte suburbicon »). Le commit d'ajout
    // reste distinct de la publication de cette fiche.
    genreBase: 'comedie',
    producteur: 'Claude Opus 5 (session supervisée)',
    pays: ['Royaume-Uni', 'Etats-Unis'],
    technique: ['n&b']
    // `courant` OMIS plutôt qu'inventé (axe non bloquant) : aucune des cinq
    // valeurs du vocabulaire ne nomme le registre satirique de ce film.
  },
  {
    // RECTIFICATIF DE PROVENANCE (GATE-AH 30/07/2026 « go rectifie provenance
    // Rebecca ») : la session productrice a déclaré « Claude Opus 5 » de bonne
    // foi (calibre du mandat) mais l'audit du greffe établit claude-sonnet-5
    // sur 301/301 messages du transcript (fenêtre ouverte sans bascule /model,
    // erreur d'ouverture confirmée par AH). R-012 : seule la mesure fait foi.
    slug: 'rebecca',
    title: 'Rebecca',
    director: 'Alfred Hitchcock',
    year: 1940,
    summary: "À Manderley, la première Mrs de Winter n'apparaît jamais à l'écran — il a suffi que le Code de censure hollywoodien change un meurtre en accident pour que son fantôme, lui, ne quitte jamais la maison.",
    url: 'films/rebecca.html',
    poster: 'assets/posters/rebecca.jpg',
    // --- schema v2 (annexe B) ---
    volet: 'critique',
    // datePublication = date du MERGE (point ferme du mandat du 30/07),
    // actualisée au geste de statut post-merge : merge `cdd20ee` du 30/07 à
    // 10h59, gate AH « go pour le merge » (la valeur provisoire de
    // rédaction, 10:31, est remplacée).
    datePublication: '2026-07-30 10:59',
    // ESCALADE P-12 SOLDÉE (GATE AH « ajoute gothique au vocabulaire
    // genreBase », prononcé à la remise de la session supervisée du
    // 30/07/2026) : 'gothique' inscrit au vocabulaire (voir vocabulaires.js),
    // entrée rétrofittée thriller → gothique dans le même commit, distinct
    // de la publication (e504c19).
    genreBase: 'gothique',
    producteur: 'Claude Sonnet 5 (session supervisée)',
    // pays = ['Etats-Unis', 'Royaume-Uni'] (GATE AH à la remise, 30/07/2026) :
    // production et tournage integral Selznick International/UA en studio
    // (Etats-Unis), mais decor, auteure du roman (Daphne du Maurier) et
    // distribution tres majoritairement britanniques (Royaume-Uni ajoute).
    // Les deux valeurs existaient deja au vocabulaire, aucune escalade P-12.
    pays: ['Etats-Unis', 'Royaume-Uni'],
    technique: ['n&b'],
    // `courant` choisi avec confiance (aucune escalade) : le registre
    // gothique/mélodramatique du film correspond à la valeur existante.
    courant: 'romantisme noir'
  },
  {
    slug: 'the-sweet-east',
    title: 'The Sweet East',
    director: 'Sean Price Williams',
    year: 2023,
    summary: "Une lycéenne quitte son voyage scolaire et traverse une Amérique qui n'est plus un pays mais une collection de sectes — et le film refuse obstinément d'en tirer la leçon.",
    url: 'films/the-sweet-east.html',
    poster: 'assets/posters/the-sweet-east.jpg',
    volet: 'critique',
    // Valeur PROVISOIRE de rédaction (Get-Date du 02/08/2026), à actualiser
    // au geste de statut post-merge comme pour `rebecca` : la date de
    // publication est celle du merge, prononcé par AH.
    datePublication: '2026-08-02 14:26',
    // AUCUNE escalade P-12 : les quatre axes fermés sont servis par des
    // valeurs déjà au vocabulaire. `comedie` nomme le registre de base du
    // film (satire picaresque) sans rabattage. Le package d'entrée
    // proposait `comédie-dramatique`, `['16mm', 'cinéma indépendant']` et
    // `'États-Unis'` : trois valeurs hors vocabulaire fermé (P-10), qui
    // auraient bloqué la publication — voir la note de remise CIN-081.
    genreBase: 'comedie',
    // ESCALADE P-14/P-17 SOLDÉE (GATE AH du 02/08/2026, élicitation du §5
    // de la note de remise CIN-081, option « Opus 5 seul » retenue) : la
    // page a bien deux producteurs successifs — premier jet Haïku 4.5 en
    // session Chat, version publiée par Opus 5 en session supervisée — mais
    // le registre ne porte que le modèle du texte publié. Deux motifs :
    // (1) P-14 veut la formulation de signature invariante, et une valeur
    // composée fragmente la facette `producteur` (un filtre sur « Claude
    // Opus 5 » ne retrouverait pas cette fiche) ; (2) la double provenance
    // est portée ailleurs, et mieux — bloc `.provenance` de la page, journal
    // interne, et surtout l'ANNEXE PUBLIQUE `films/the-sweet-east-annexe.html`
    // qui documente en détail ce que le premier jet contenait de faux.
    // Valeur identique au segment de la phrase de signature (P-17).
    producteur: 'Claude Opus 5 (session supervisée)',
    pays: ['Etats-Unis'],
    technique: ['couleur'],
    // `courant` : enrichissement facultatif et non bloquant, repris du
    // descripteur encyclopédique du film (« satirical surrealist road
    // film ») — à retirer d'un trait si AH le juge trop appuyé.
    courant: 'surrealisme'
  },
  {
    slug: 'memories-of-murder',
    title: 'Memories of Murder',
    director: 'Bong Joon-ho',
    year: 2003,
    summary: "Dix victimes, trois suspects, aucun coupable : Bong Joon-ho retourne le polar en portrait d'un pays malade — et le dernier regard du film nous cherche encore.",
    url: 'films/memories-of-murder.html',
    poster: 'assets/posters/memories-of-murder.jpg',
    volet: 'critique',
    datePublication: '2026-08-03 09:44',
    // genreBase : 'thriller' choisi contre 'neo-noir' (existant) — le film
    // est un polar procédural rural et diurne, pas un noir urbain ; les
    // deux valeurs sont au vocabulaire, le choix est éditorial (P-11).
    genreBase: 'thriller',
    producteur: 'Claude Fable 5 (session supervisée)',
    pays: ['Coree du Sud'],
    technique: ['couleur']
  },
  {
    slug: 'les-tontons-flingueurs',
    title: 'Les Tontons flingueurs',
    director: 'Georges Lautner',
    year: 1963,
    summary: "Un film noir sabordé de l'intérieur par ceux-là mêmes qui l'avaient écrit — et ce qui a survécu, ce sont les scènes qui ne servaient à rien.",
    url: 'films/les-tontons-flingueurs.html',
    poster: 'assets/posters/les-tontons-flingueurs.jpg',
    volet: 'critique',
    datePublication: '2026-08-10 15:08',
    // genreBase : 'comedie' — valeur du vocabulaire fermé. Le film est une
    // comédie policière ; 'polar' existe aussi mais nommerait le genre
    // sabordé, pas le registre du film (P-11, choix éditorial, pas de
    // rabattage). Aucune escalade P-12 : les quatre axes bloquants sont
    // servis par des valeurs déjà inscrites.
    genreBase: 'comedie',
    producteur: 'Claude Opus 5 (session supervisée)',
    // Coproduction France / Italie / Allemagne de l'Ouest (Gaumont-SNEG,
    // Ultra Film et Sicilia Cinematografica, Corona Filmproduktion).
    pays: ['France', 'Italie', 'Allemagne'],
    technique: ['n&b']
  }
];
