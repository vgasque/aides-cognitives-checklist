// La Page : svTreePlan (colonnes, rangées, arêtes), cartouche (svValidWarn, svSources, svCountsTxt,
// svRevTxt), carryParts, SV_COL — sur le corpus partagé de fiches.
import { FICHES } from './_fiches.mjs';

export const inputs = FICHES.map(fiche => ({ fiche }));
export function run(inputs) {
  const J = x => JSON.parse(JSON.stringify(x === undefined ? null : x));
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  return inputs.map(x => {
    const f = migrate(J(x.fiche));
    return { f: J(f), tree: J(svTreePlan(f)), warn: svValidWarn(f), src: svSources(f), counts: svCountsTxt(f), carry: carryParts(f),
      rev: svRevTxt(f), tz, col: SV_COL };
  });
}

// Fixture compacte ; la fiche brute n'y est pas recopiée (la sortie `f` porte sa forme migrée).
export const compact = true;
export const slim = ({ fiche, fiches, ...rest }) => rest;
