# Lot v5.56 — A496-A497

Trois retours d'usage de l'auteur, le même jour : « Crée un protocole : affiche “Nouvelle aide” sur la pancarte
identité » ; « Ajoute la possibilité de choisir la collection directement lors de la création d'une aide ou d'un
protocole — fais de la même manière que les catégories et bibliothèque : réutilise les fenêtres existantes pour les
collections, et la possibilité de créer une collection » ; « Sur les fenêtres modales, notamment sur smartphone,
lorsqu'on clique en dehors de la fenêtre en pensant la fermer, ça clique sur l'item correspondant en dessous du
grisé ».

## A496 — La collection se choisit à la création, comme la catégorie et la bibliothèque ; « Nouveau protocole » (v5.56.0)

**Avant.** Une collection (A475) ne se rejoignait qu'APRÈS coup, depuis l'accueil ou le menu ⋯ d'une aide ouverte :
l'auteur qui créait une aide pour sa garde devait la finir, revenir à l'accueil, la retrouver, puis « Ajouter à une
collection… ». La pancarte d'identité de l'éditeur, elle, disait « Nouvelle aide » pour un protocole neuf aussi :
`editorMetaFieldsHtml` est le tronc COMMUN des deux éditeurs (audit v4.1.0) et le résumé du dépliant avait été écrit
pour une seule entité, le genre (`L.fem`) étant déjà passé pour tout le reste.

**Après.**
- Le résumé suit le genre : « Nouvelle aide » / « Nouveau protocole ».
- La pancarte porte une rangée **Collections**, sous Bibliothèque, dessinée comme la rangée Catégorie
  (`collPickerHtml`, mêmes jetons `.cat-chip-selected` / `.cat-chip-other`) : un jeton par collection qui contient le
  brouillon — signet ou ★ pour l'Accès direct — ou « Aucune collection » (neutre), puis « Choisir… ». La rangée ouvre
  **la feuille à cases de l'accueil** (`openCollPick`, A475), sur ce seul brouillon : Accès direct, les collections,
  « ＋ Nouvelle collection… » (`collAsk` → `collNew`) — aucune fenêtre neuve, comme demandé. Un jeton de collection
  n'a pas de registre : `--catcol:var(--ink-soft)` (règle 8 : un rangement personnel ne tue pas, ne trompe pas, n'est
  ni fait ni en cours).
- **Rien n'est écrit dans le brouillon.** Une collection est une liste d'ids PERSONNELLE (`colls`, document perso),
  jamais un champ de l'aide : la rangée est LUE par `collsOf(d.id)`, exactement comme à l'accueil. C'est ce qui
  permet de la proposer en lecture seule aussi (une aide d'une bibliothèque `viewer` se range sans la modifier).
- **Créer depuis une collection affichée y range le brouillon**, sur le patron d'A304 (« créer dans la bibliothèque
  affichée, et le dire ») : `newFiche`/`newProtocol` posent l'id dans `state.coll` (jamais dans l'Accès direct, K5),
  et la pancarte — ouverte d'office pour une entité neuve, A465 — le montre en jeton, retirable d'un tap.
- **K5 vaut avant la première frappe.** `pinBlocked` ne connaissait que `fiches`/`protocols` ; un brouillon neuf n'y
  entre qu'à son premier titre (K5, v4.72.0), si bien que « Accès direct » l'aurait épinglé une seconde avant qu'il
  devienne un brouillon inépinglable. Il regarde aussi `state.draft`/`state.pdraft` ; la case le dit (« 1 brouillon
  ne s'épingle pas ») et reste décochée.
- **Un brouillon abandonné sort des collections.** Un brouillon sans titre n'existe jamais (`edUntitled`) ; son id,
  posé dans une collection, aurait compté « 1 indisponible » pour toujours dans l'en-tête de la collection (A475 :
  les ids absents se comptent). `bindEditorExit` — le seul lieu où l'on sait qu'un brouillon n'est « jamais entré
  dans la bibliothèque » (il y purge déjà les PDF joints) — appelle `collForget(d.id)`, qui ne sauve rien s'il n'y
  avait rien.
- `openCollPick` accepte `ents` : l'appelant passe le brouillon lui-même, puisque la liste ne le connaît pas encore
  (contexte « Sans titre · Perso », notice de bibliothèque justes).

**Écarté.** Un champ « collection » dans le dialogue « Créer » (une question de plus AVANT d'écrire, pour un rangement
qu'on fait après avoir vu l'aide) ; un `<select>` à choix unique (une aide vit dans PLUSIEURS collections, A475) ;
une collection stockée dans l'aide (elle voyagerait dans la bibliothèque partagée — le rangement d'un membre imposé
aux autres, exactement ce qu'A475 refuse).

**Témoin.** `audit-doctrine` « ÉDITEUR · A496-A497 … » à 390 px tactile : nom du protocole neuf et de l'aide neuve,
rangée présente sur les deux éditeurs, création depuis une collection affichée, feuille à cases ouverte depuis la
rangée, brouillon non épinglé et case qui le dit, jeton repeint à la fermeture, purge à la sortie d'un brouillon sans
titre.

### Amende v5.56.1 — le menu des collections s'ANCRE dans l'éditeur, comme celui des catégories

**Signalé par l'auteur sur capture** : au bureau, « Choisir… » ouvrait une feuille BASSE centrée en bas de page, là où
« Autre… » (catégorie) ouvre un menu ancré sous ses jetons. Ce n'était pas un choix : `openPickMenu` gère les deux
formes et choisit la feuille sous 780 px OU quand l'appelant l'impose ; `openCollPick` l'impose (`sheet:true`) parce
que ses appelants d'origine — menu ⋯, barre de sélection (A475) — n'ont pas d'ancre. L'éditeur en a une, et le
forçage n'avait pas été levé.

**Après.** L'éditeur passe son hôte (`#collPicker`), `sheet:false` et `compact:true` ; `openCollPick` respecte
`o.sheet` quand il est donné. Trois ajustements mesurés sur la capture suivante :
- **Une coque large** (`.catmenu.wide`, 320-420 px, hauteur 520 bornée par `dvh ÷ zoom`) : celle des catégories
  (340 × 340) coupait « ＋ Nouvelle collection… » sous le pied « Terminé ».
- **Titre, contexte et notice RESTENT** (décision de l'auteur : « Ajouter à une collection » et sa définition « à vous
  seul, rien n'est déplacé » se lisent au moment du geste), resserrés d'un cran dans la coque ancrée (titre 15,
  contexte et notice 12) — la tête est collante et les rangées doivent rester visibles sous elle. Une première forme
  sans tête, « comme les catégories », a été ÉCARTÉE.
- **Un menu ancré tient sous son ancre** : à 1280 × 900, sept collections sous la rangée sortaient de l'écran.
  `openPickMenu` borne désormais tout menu ancré à l'espace disponible sous lui (même mesure que `fitMoreMenu`,
  J203 : hauteur visuelle, px CSS ÷ zoom, plancher 180) — vaut pour tous les sélecteurs ancrés, pas seulement
  celui-ci.
- **Filtre de texte dès cinq collections** (`seuilFiltre:4`, demande de l'auteur « pour rechercher facilement ») — le
  mécanisme est celui des catégories (`.catmenu-filter`), qui l'ouvre à partir de neuf ; une collection se cherche
  par son nom dès qu'il y en a une poignée, et la feuille de l'accueil en profite aussi.

## A497 — Le voile d'une feuille absorbe le tap (v5.56.0)

**Le défaut, mesuré.** Sous 780 px, un sélecteur (`openPickMenu`) est une feuille basse sous un voile plein écran
(`.popmenu-veil.sheet`). Deux fermetures coexistaient : `veil.onclick` ET un `pointerdown` capturé sur le document,
qui fermait tout ce qui n'était pas « dans le menu ». Or le voile n'est pas dans le menu. Séquence relevée au tap
(Chromium tactile, sonde jetable, le résumé de la pancarte d'identité sous le voile) : `pointerdown:popmenu-veil` →
fermeture, voile RETIRÉ → `pointerup`, `mousedown`, `mouseup`, `click` : **`id-t`** — le clic du même doigt tombe sur
ce que le voile couvrait et l'active (ici, le dépliant se referme ; à l'accueil, la rangée s'ouvre). C'est mot pour
mot le signalement : « ça clique sur l'item correspondant en dessous du grisé ». Au pointeur fin, rien à voir :
au-delà de 780 le menu est ancré et SANS voile (`.popmenu-veil{display:none}`).

**Après.** Le `pointerdown` ignore le voile (`if(e.target===veil)return`) : un tap sur le voile se ferme à son
`click`, que le voile reçoit parce qu'il est encore là. Séquence relevée après : `pointerdown`, `pointerup`,
`mousedown`, `mouseup`, `click` — tous `popmenu-veil` ; rien dessous n'a bougé. Le `pointerdown` garde son office
pour ce qui est VRAIMENT dehors : le menu ancré sans voile (fermer ET laisser le clic agir, le comportement d'un menu
de bureau), et le chrome posé au-dessus du voile.

**Les autres couches ont été regardées, et ne sont pas concernées.** `.ai-modal` ferme au `click` sur elle-même
(`bindModalDismiss`) ; le menu ⋯ ferme au `click` sur le document (`closeMoreMenu`), son voile `_moreVeil` compris :
dans les deux cas la couche reçoit le clic qui la ferme. Les trois autres `pointerdown` du document (segmenté,
`#dockSheet`, `.rt-dock`) ne retirent rien de sous le doigt.

**Témoin.** Même section : `page.touchscreen.tap` sur le voile (touch → pointer → clic synthétisé par le moteur, pas
un `click()` programmatique qui n'aurait rien prouvé) ; `elementFromPoint` atteste que le voile est bien sous le
point ; la feuille est fermée ET le dépliant d'identité toujours ouvert. Vérifié ROUGE sur l'ancien gestionnaire
(dépliant refermé), vert après.
