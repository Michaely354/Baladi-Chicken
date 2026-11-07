import {createClient} from 'https://esm.sh/@supabase/supabase-js@2.99.3';
const ALLOWED_ORIGIN = 'https://baladi-chicken-menu.onrender.com';
const headers={'Access-Control-Allow-Origin':ALLOWED_ORIGIN,'Access-Control-Allow-Headers':'apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Cache-Control':'no-store','Content-Type':'application/json','Vary':'Origin'};
const reply=(status:number,message:string)=>new Response(JSON.stringify({message}),{status,headers});
Deno.serve(async req=>{
 if(req.headers.get('origin')&&req.headers.get('origin')!==ALLOWED_ORIGIN)return reply(403,'Not allowed');
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers});
 if(req.method!=='POST')return reply(405,'Use POST');
 if(Number(req.headers.get('content-length')||0)>4096)return reply(413,'Request too large');
 let body;try{body=await req.json()}catch{return reply(400,'Invalid request')}
 const {token,email,password}=body;
 if(typeof token!=='string'||token.length!==43||typeof email!=='string'||email.length>254||!/^\S+@\S+\.\S+$/.test(email)||typeof password!=='string'||password.length<12||password.length>128)return reply(400,'Invalid setup details');
 const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(token)))).map(b=>b.toString(16).padStart(2,'0')).join('');
 const client=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
 // A conditional UPDATE claims the single-use token before creating an account.
 const {data:claim,error:claimError}=await client.from('owner_setup').update({claimed:true}).eq('id',1).eq('token_hash',hash).eq('claimed',false).eq('used',false).gt('expires_at',new Date().toISOString()).select('id');
 if(claimError||claim?.length!==1)return reply(403,'Setup link expired or already used');
 const {data,error}=await client.auth.admin.createUser({email:email.trim(),password,email_confirm:true});
 if(error||!data.user){await client.from('owner_setup').update({claimed:false}).eq('id',1).eq('used',false);return reply(400,'Could not create owner. Use a new email or contact the project administrator.');}
 const {error:ownerError}=await client.from('menu_owners').insert({user_id:data.user.id});
 if(ownerError){await client.auth.admin.deleteUser(data.user.id);await client.from('owner_setup').update({claimed:false}).eq('id',1).eq('used',false);return reply(500,'Could not activate owner');}
 await client.from('owner_setup').update({used:true}).eq('id',1);
 return reply(201,'Owner account created');
});
