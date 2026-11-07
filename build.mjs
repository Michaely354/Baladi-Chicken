import {build} from 'esbuild';
import {writeFile,mkdir,copyFile} from 'node:fs/promises';
await build({entryPoints:['src/app.js'],bundle:true,format:'esm',minify:true,outfile:'dist/app.js'});
if(process.env.SUPABASE_URL && process.env.SUPABASE_PUBLISHABLE_KEY){
 await writeFile('dist/config.js','window.BALADI_CONFIG = '+JSON.stringify({supabaseUrl:process.env.SUPABASE_URL,supabasePublishableKey:process.env.SUPABASE_PUBLISHABLE_KEY})+';');
}
for(const route of ['admin','menu']){await mkdir('dist/'+route,{recursive:true});await copyFile('dist/index.html','dist/'+route+'/index.html');}
