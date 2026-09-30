// Parcours : flowPlan, offPathSet, minimapData, cxAll/cxDetached, linkOf, jalonCondLbl, cycleHint/
// cycleTxt, phaseOf/phasesOf, completionSpots, revBlocks/revState/revKeysLift, posBandModel (avec un
// `moOf` déterministe), stepGroups/stepQualTxt/blkTimerTxt, listOf/stepsOf/forgetAll, tmShort/
// cnShort/cxShort — sur le corpus partagé (exemples, graphes écrits, graphes tirés au sort).
import { FICHES, scenarios } from './_fiches.mjs';

const LABELS = ['', 'Adrénaline', 'Réévaluation après adrénaline', 'Cycle RCP (2 min)', 'Délai entre deux doses d’amiodarone',
  'Temps depuis l’arrivée à l’hôpital', 'Chocs délivrés', 'Pression artérielle invasive', 'Nombre de chocs électriques externes',
  'Évaluation de la réponse au traitement', '  espaces   multiples  ', 'Hyperkaliémie (suspicion)', '**Tamponnade** sévère et prolongée',
  'Bronchospasme réfractaire aux bêta-2', 'a b c d e f g h i j k', 'Réévaluationnnnnnnnn aaaaaaaaaaa bbbbbbbbbbbbbb', 'l’adrénaline d’urgence',
  'Anaphylaxie (grade III) (bis)', '(tout entre parenthèses)', 'Élan'];
export const inputs = [
  ...FICHES.map((fiche, k) => ({ k: 'fiche', fiche, scen: scenarios(fiche, k) })),
  { k: 'labels', labels: LABELS },
  { k: 'optAbbr', lists: [['Oui (stabilisé)', 'Non (symptômes digestifs isolés)'], ['Choquable (FV/TV sans pouls)', 'Non choquable (AESP)', 'Signes de ROSC'],
    ['Non répondeur', 'Non stabilisé'], ['', 'Oui'], ['Non', 'Non', 'Non'], ['**Gras** oui', 'ßtraße', 'éléphant rose', 'Éléphant blanc', '12 ans', '12 mois'],
    ['a-b c', 'a_b c', '(x) y'], []] },
];
export function run(inputs) {
  const J = x => JSON.parse(JSON.stringify(x === undefined ? null : x));
  const sorted = s => [...s].sort();
  const moOf = (it, i) => (i % 3 === 0 ? { st: 'wait', why: 'from' } : (i % 3 === 1 ? { st: 'met', req: 1 } : (i % 5 === 2 ? { st: 'gone' } : null)));
  return inputs.map(x => {
    if (x.k === 'labels') return x.labels.map(l => ({ tm: tmShort({ label: l }), cn: cnShort({ label: l }), cx: cxShort({ label: l }),
      head: autoShortHead(l, 9), key: cxKeyLabel(l), parts: tmLabelParts(l) }));
    if (x.k === 'optAbbr') return x.lists.map(l => optAbbr(l));
    const f = migrate(J(x.fiche));
    const blocks = f.blocks || [];
    const scen = x.scen.map(s => ({
      off: sorted(offPathSet(f, s.nav, s.navPos)),
      mini: J(minimapData(f, s.nav, s.navSeq, s.checked, s.navPos)),
      lift: J(revKeysLift(f, J(s.checked))),
      rev: revBlocks(f).map(rb => J(revState(rb, 'r', s.checked))),
      band: blocks.map(b => J(posBandModel(f, b, (s.navSeq[0] || 1), s.checked, moOf))),
      bandNoMo: blocks.map(b => J(posBandModel(f, b, 1, s.checked))),
    }));
    return {
      f: J(f),
      plan: J(flowPlan(f)),
      cxAll: J(cxAll(f)), cxDetached: J(cxDetached(f)),
      links: (f.items || []).map(i => J(linkOf(i))),
      jalons: blocks.map(b => (b.milestones || []).map(j => jalonCondLbl(f, j))),
      cycle: J(cycleHint(f) ? cycleHint(f).id : null), cycleTxt: cycleTxt(f),
      phases: phasesOf(f), phase: blocks.map(b => phaseOf(f, b.id)),
      spots: completionSpots(f),
      lists: ['confirmation', 'notForget', 'verify', 'posology', 'differentials'].map(k => listOf(f, k)),
      steps: blocks.map(b => stepsOf(b)), forget: forgetAll(f),
      groups: blocks.map(b => { const its = bItems(b); return J(stepGroups(its, its.length)); }),
      groupsOver: blocks.map(b => { const its = bItems(b); return J(stepGroups(its, its.length + 2)); }),
      qual: (f.items || []).map(i => [stepQualTxt(f, i), stepQualTxt(f, i, { faite: true }), stepQualTxt(f, i, { sansOnce: true })]),
      btimer: blocks.map(b => blkTimerTxt(f, b)),
      shorts: { tm: (f.timers || []).map(tmShort), cn: (f.counters || []).map(cnShort), cx: (f.excursions || []).map(cxShort) },
      scen,
    };
  });
}

// Fixture compacte ; la fiche brute n'y est pas recopiée (la sortie `f` porte sa forme migrée).
export const compact = true;
export const slim = ({ fiche, fiches, ...rest }) => rest;
