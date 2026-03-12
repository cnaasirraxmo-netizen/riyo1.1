import{c as n}from"./index-B1gJmt7I.js";import{a as o}from"./index-42ANG6Sg.js";/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const p=n("Loader2",[["path",{d:"M21 12a9 9 0 1 1-6.219-8.56",key:"13zald"}]]),r="http://localhost:5000",t=o.create({baseURL:r,headers:{"Content-Type":"application/json"}});t.interceptors.request.use(e=>{const s=localStorage.getItem("token");return s&&(e.headers.Authorization=`Bearer ${s}`),e},e=>Promise.reject(e));const d={getAll:async()=>(await t.get("/admin/movies?paginate=false")).data,create:async e=>(await t.post("/admin/movies",e)).data,update:async(e,s)=>(await t.put(`/admin/movies/${e}`,s)).data,delete:async e=>(await t.delete(`/admin/movies/${e}`)).data,publish:async(e,s)=>(await t.put(`/admin/movies/${e}/publish`,{isPublished:s})).data},m={getConfig:async()=>(await t.get("/system-config")).data,updateConfig:async e=>(await t.put("/admin/system-config",e)).data};export{p as L,d as m,m as s};
