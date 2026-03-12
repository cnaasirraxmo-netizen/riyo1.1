import{c as t,j as e}from"./index-B1gJmt7I.js";import{A as c}from"./activity-g7Y2tbnc.js";/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const l=t("Database",[["ellipse",{cx:"12",cy:"5",rx:"9",ry:"3",key:"msslwz"}],["path",{d:"M3 5V19A9 3 0 0 0 21 19V5",key:"1wlel7"}],["path",{d:"M3 12A9 3 0 0 0 21 12",key:"mv7ke4"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const i=t("RefreshCw",[["path",{d:"M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8",key:"v9h5vc"}],["path",{d:"M21 3v5h-5",key:"1q7to0"}],["path",{d:"M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16",key:"3uifl3"}],["path",{d:"M8 16H3v5",key:"1cv678"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const d=t("Trash2",[["path",{d:"M3 6h18",key:"d0wm0j"}],["path",{d:"M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6",key:"4alrt4"}],["path",{d:"M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2",key:"v07s0e"}],["line",{x1:"10",x2:"10",y1:"11",y2:"17",key:"1uufr5"}],["line",{x1:"14",x2:"14",y1:"11",y2:"17",key:"xtxkd"}]]),h=()=>{const a=[{title:"Clear Cache",desc:"Flush all system and image caches",icon:e.jsx(d,{size:24}),action:"Flush"},{title:"Rebuild Thumbnails",desc:"Regenerate all movie/TV show thumbnails",icon:e.jsx(i,{size:24}),action:"Rebuild"},{title:"Database Backup",desc:"Create a full backup of the system database",icon:e.jsx(l,{size:24}),action:"Backup"},{title:"System Health",desc:"Check API and storage server connectivity",icon:e.jsx(c,{size:24}),action:"Check"}];return e.jsxs("div",{className:"space-y-6",children:[e.jsx("h1",{className:"text-2xl font-bold text-[#1d2327]",children:"System Tools"}),e.jsx("div",{className:"grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6",children:a.map(s=>e.jsxs("div",{className:"admin-card flex flex-col items-center text-center",children:[e.jsx("div",{className:"p-4 bg-gray-100 rounded-full text-gray-600 mb-4",children:s.icon}),e.jsx("h3",{className:"font-bold mb-2",children:s.title}),e.jsx("p",{className:"text-xs text-gray-500 mb-6 flex-1",children:s.desc}),e.jsx("button",{className:"btn-secondary w-full justify-center text-sm",children:s.action})]},s.title))})]})};export{h as default};
