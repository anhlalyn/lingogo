'use strict';
const {test,before,after} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails} = require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,getDocs,collection,query,where,writeBatch,serverTimestamp,updateDoc,deleteDoc} = require('firebase/firestore');
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Only run against Firestore Emulator.');
let env,admin,student,anonymous;
function content() {
 return {languageCode:'en',level:'A1',title:'Greetings',subtitle:'Learn greetings',icon:'Book',order:100,
 vocabulary:[{word:'Hello',meaning:'Xin chÃ o',pronunciation:'hello',example:'Hello Anna',exampleTranslation:'Xin chÃ o Anna'}],
 exercises:[
 {type:'multiple_choice',prompt:'Hello?',options:['Xin chÃ o','Táº¡m biá»‡t'],answer:'Xin chÃ o',explanation:'A greeting'},
 {type:'fill_blank',prompt:'My ___ is Anna',options:[],answer:'name',explanation:'My name'},
 {type:'reorder_words',prompt:'Arrange',options:['name','your','What','is'],answer:'What is your name',explanation:'Ask a name'},
 {type:'match_pairs',prompt:'Match',options:['Hello','Thanks','Bye','Táº¡m biá»‡t','Xin chÃ o','Cáº£m Æ¡n'],answer:'Hello:Xin chÃ o|Thanks:Cáº£m Æ¡n|Bye:Táº¡m biá»‡t',explanation:'Three phrases'}]};
}
function audit(db,id,revision,action,actor='admin') {
 return {ref:doc(db,'adminAuditLogs',`${id}_r${revision}`),data:{actorUid:actor,entityId:id,revision,action,createdAt:serverTimestamp()}};
}
function create(db,id,data=content(),{actor='admin',withAudit=true,status='draft'}={}) {
 const batch=writeBatch(db);
 batch.set(doc(db,'lessons',id),{...data,status,revision:1,version:1,source:'manual',createdBy:actor,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
 if(withAudit){const log=audit(db,id,1,'save_draft',actor);batch.set(log.ref,log.data);}
 return batch.commit();
}
function change(db,id,revision,patch,action,actor='admin') {
 const batch=writeBatch(db);
 batch.update(doc(db,'lessons',id),{...patch,revision,updatedAt:serverTimestamp()});
 const log=audit(db,id,revision,action,actor); batch.set(log.ref,log.data);return batch.commit();
}
before(async()=>{
 env=await initializeTestEnvironment({projectId:'demo-lingogo',firestore:{rules:readFileSync('../firestore.rules','utf8')}});
 await env.clearFirestore();admin=env.authenticatedContext('admin',{admin:true}).firestore();student=env.authenticatedContext('student').firestore();anonymous=env.unauthenticatedContext().firestore();
});
after(async()=>{if(env)await env.cleanup();});
test('Spark client can author, edit, publish and archive with immutable atomic audit records',async()=>{
 const id='l_spark_flow_12345';
 await assertSucceeds(create(admin,id)); 
 await assertSucceeds(getDoc(doc(admin,'lessons',id)));
 await assertFails(getDoc(doc(student,'lessons',id)));
 await assertFails(getDocs(collection(student,'lessons')));
 await assertFails(updateDoc(doc(admin,'lessons',id),{title:'Unlogged edit',revision:2,updatedAt:serverTimestamp()}));
 await assertSucceeds(change(admin,id,2,{title:'Updated draft'},'save_draft')); 
 await assertFails(change(admin,id,2,{title:'Stale overwrite'},'save_draft'));
 await assertSucceeds(change(admin,id,3,{status:'published',version:2,publishedAt:serverTimestamp()},'publish')); 
 assert.equal((await assertSucceeds(getDocs(query(collection(student,'lessons'),where('status','==','published'))))).size,1);
 await assertFails(getDoc(doc(anonymous,'lessons',id)));
 await assertFails(change(admin,id,4,{title:'Mutated published'},'save_draft'));
 await assertFails(deleteDoc(doc(admin,'lessons',id)));
 await assertFails(updateDoc(doc(admin,'adminAuditLogs',`${id}_r1`),{actorUid:'other'}));
 await assertSucceeds(change(admin,id,4,{status:'archived'},'archive'));
 await assertFails(getDoc(doc(student,'lessons',id)));
 assert.equal((await getDocs(query(collection(student,'lessons'),where('status','==','published')))).size,0);
 await assertFails(change(admin,id,5,{status:'draft'},'save_draft'));
 await assertFails(getDocs(collection(student,'adminAuditLogs')));
 assert.equal((await getDocs(collection(admin,'adminAuditLogs'))).size,4);
});
test('No unauthenticated/user writes, direct publication, forged audit or self-admin',async()=>{
 await assertFails(create(student,'l_bad_student_12345',content(),{actor:'student'}));
 await assertFails(create(anonymous,'l_bad_anon_123456'));
 await assertFails(create(admin,'l_without_log_12345',content(),{withAudit:false}));
 await assertFails(create(admin,'l_direct_publish_123',content(),{status:'published'}));
 await assertFails(create(admin,'l_forged_actor_12345',content(),{actor:'student'}));
 await assertFails(setDoc(doc(student,'users','student'),{role:'admin'}));
 await assertFails(getDocs(collection(student,'aiTutorRequests')));
 const orphan=audit(admin,'l_spark_flow_12345',5,'archive');
 await assertFails(setDoc(orphan.ref,orphan.data));
});
test('Rejects nested invalid vocabulary/exercises and oversized Spark lessons',async()=>{
 const mutations=[
 d=>{d.vocabulary=Array(6).fill(d.vocabulary[0]);},
 d=>{d.exercises=Array(5).fill(d.exercises[0]);},
 d=>{d.vocabulary=Array.from({length:5},(_,i)=>({...d.vocabulary[0],word:`word${i}`}));d.vocabulary[4].meaning=123;},
 d=>{d.exercises[3].explanation=123;},
 d=>{d.exercises[0].answer=123;},
 d=>{d.exercises[2].options[2]=123;},
 d=>{d.exercises[3].type='unsupported';},
 d=>{d.level='HSK 6';},d=>{d.order=-1;},d=>{d.title='';},d=>{d.role='admin';}
 ];
 for(let i=0;i<mutations.length;i++){const d=content();mutations[i](d);await assertFails(create(admin,`l_invalid_case_000${i}`,d));}
});
test('Maximum short lesson with 5 words and 4 twelve-token reorder questions is allowed',async()=>{
 const d=content();
 d.vocabulary=Array.from({length:5},(_,i)=>({...d.vocabulary[0],word:`word${i}`}));
 const tokens=Array.from({length:12},(_,i)=>`token${i}`);
 d.exercises=Array.from({length:4},()=>({type:'reorder_words',prompt:'Arrange',options:tokens,answer:tokens.join(' '),explanation:'Use every word'}));
 await assertSucceeds(create(admin,'l_maximum_size_12345',d));
});

test('Advanced courses accept valid language-level pairs and reject mismatched pairs',async()=>{
 const levels={en:'C2',zh:'HSK 6',ja:'JLPT N1',ko:'TOPIK II 6'};
 for(const [languageCode,level] of Object.entries(levels)) {
   await assertSucceeds(create(admin,`l_advanced_${languageCode}_12345`,{...content(),languageCode,level}));
 }
 await assertFails(create(admin,'l_wrong_level_12345',{...content(),languageCode:'zh',level:'C2'}));
});
