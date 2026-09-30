// Vérifie le câblage de l'oracle lui-même (cas trivial).
export const inputs = ['', 'bonjour', 'é€𝄞'];
export function run(inputs) {
  return inputs.map(s => __ac_test__.crc32(new TextEncoder().encode(s)));
}
