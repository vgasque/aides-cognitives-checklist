/* Dépouilleur de commentaires partagé par check-tokens et check-fns (une seule source).
   Retire les blocs `slash-étoile` et les lignes `//` (le garde [^:'"`\\] épargne les
   https:// et la plupart des chaînes) : un identifiant cité dans la DOCTRINE ne doit jamais
   compter comme un usage — c'est ainsi que filtersActive et --hover ont survécu. Limite dite :
   un `//` au cœur d'une chaîne suivie du motif cherché passerait au travers — jamais vu ici,
   et l'erreur ferait un ROUGE bruyant à exempter, pas un vert menteur. */
export const stripComments = s => s
  .replace(/\/\*[\s\S]*?\*\//g, ' ')
  .replace(/(^|[^:'"`\\])\/\/[^\n]*/g, '$1');
