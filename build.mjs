import {build} from 'esbuild';
import {writeFile,mkdir,readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
await build({entryPoints:['src/app.js'],bundle:true,format:'esm',minify:true,outfile:'dist/app.js'});
if(process.env.SUPABASE_URL && process.env.SUPABASE_PUBLISHABLE_KEY){
 await writeFile('dist/config.js','window.BALADI_CONFIG = '+JSON.stringify({supabaseUrl:process.env.SUPABASE_URL,supabasePublishableKey:process.env.SUPABASE_PUBLISHABLE_KEY})+';');
}
const assets = ['/app.js', '/style.css', '/config.js'];
let html = await readFile('dist/index.html', 'utf8');
for (const asset of assets) {
  const content = await readFile('dist' + asset);
  const version = createHash('sha256').update(content).digest('hex').slice(0, 12);
  html = html.replace(new RegExp(asset.replace('.', '[.]') + '(?:[?]v=[a-f0-9]+)?(?=")'), asset + '?v=' + version);
}
await writeFile('dist/index.html', html);
for (const route of ['admin', 'menu']) {
  await mkdir('dist/' + route, {recursive: true});
  await writeFile('dist/' + route + '/index.html', html);
}
