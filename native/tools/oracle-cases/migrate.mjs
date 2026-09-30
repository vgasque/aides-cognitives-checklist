// migrate() : exemples réels, aide v4 complète, aide HOSTILE, cas limites.
import { readFileSync } from 'node:fs';
export const inputs = JSON.parse(readFileSync(new URL('./migrate.inputs.json', import.meta.url)));
export function run(inputs) {
  return inputs.map(x => JSON.parse(JSON.stringify(__ac_test__.migrate(JSON.parse(JSON.stringify(x))))));
}
