// Les deux fiches d'exemple de la PWA (seed/seed2) : entrée = leur forme migrée, sortie = migrate(entrée).
// Sert aussi de CONTENU d'exemple pour l'app native (écran de bienvenue « fiches d'exemple »).
export const inputs = ['seed', 'seed2', 'seed-idem'];
export function run(inputs) {
  const c = x => JSON.parse(JSON.stringify(x));
  const a = c(seed('')), b = c(seed2(''));
  return [{ fiche: a }, { fiche: b }, { input: a, output: c(__ac_test__.migrate(c(a))) }];
}
