import { analyseAccountableUpload, startAccountableImport, accountableImportStatus, accountableOpenItems } from "./src/server/modules/archiv/index.ts";

const pfad = process.argv[2] ?? "/tmp/2025_3.zip";
const bytes = new Uint8Array(await Bun.file(pfad).arrayBuffer());
console.log("Datei:", pfad, (bytes.byteLength / 1_048_576).toFixed(1), "MB");

const analyse = analyseAccountableUpload(bytes, pfad.split("/").pop()!);
console.log("Analyse:", JSON.stringify(analyse, null, 2).slice(0, 1500));

const id = await startAccountableImport("hermes-probe", { wait: true });
const status = await accountableImportStatus(id);
console.log("Lauf:", id, "| Status:", status?.status, "| Phase:", status?.phase);
console.log("Fortschritt:", JSON.stringify(status?.progress ?? null).slice(0, 800));
const offen = await accountableOpenItems(id);
console.log("Offene Posten:", offen.length);
process.exit(0);
