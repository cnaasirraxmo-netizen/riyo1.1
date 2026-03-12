import{c as r,a as C,u as P,r as s,j as e}from"./index-DiGzm6ft.js";import{a as T}from"./api-xsDnzC0k.js";import{P as R}from"./play-BkJRtXr3.js";/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const S=r("ArrowLeft",[["path",{d:"m12 19-7-7 7-7",key:"1l729n"}],["path",{d:"M19 12H5",key:"x3x0zl"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const L=r("Maximize",[["path",{d:"M8 3H5a2 2 0 0 0-2 2v3",key:"1dcmit"}],["path",{d:"M21 8V5a2 2 0 0 0-2-2h-3",key:"1e4gt3"}],["path",{d:"M3 16v3a2 2 0 0 0 2 2h3",key:"wsl5sc"}],["path",{d:"M16 21h3a2 2 0 0 0 2-2v-3",key:"18trek"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const $=r("Pause",[["rect",{width:"4",height:"16",x:"6",y:"4",key:"iffhe4"}],["rect",{width:"4",height:"16",x:"14",y:"4",key:"sjin7j"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const V=r("RotateCcw",[["path",{d:"M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8",key:"1357e3"}],["path",{d:"M3 3v5h5",key:"1xhq8a"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const q=r("RotateCw",[["path",{d:"M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8",key:"1p45f6"}],["path",{d:"M21 3v5h-5",key:"1q7to0"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const E=r("Settings",[["path",{d:"M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z",key:"1qme2f"}],["circle",{cx:"12",cy:"12",r:"3",key:"1v7zrd"}]]);/**
 * @license lucide-react v0.331.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const A=r("Volume2",[["polygon",{points:"11 5 6 9 2 9 2 15 6 15 11 19 11 5",key:"16drj5"}],["path",{d:"M15.54 8.46a5 5 0 0 1 0 7.07",key:"ltjumu"}],["path",{d:"M19.07 4.93a10 10 0 0 1 0 14.14",key:"1kegas"}]]),D=()=>{var f;const{id:c}=C(),y=P(),[o,j]=s.useState(null),[l,u]=s.useState(!1),[g,h]=s.useState(0),[k,w]=s.useState(0),[d,m]=s.useState(!0),t=s.useRef(null),i=s.useRef(null);s.useEffect(()=>{(async()=>{try{const a=await T.get(`/movies/${c}`);j(a.data)}catch(a){console.error(a)}})()},[c]);const M=()=>{m(!0),i.current&&clearTimeout(i.current),i.current=setTimeout(()=>{l&&m(!1)},3e3)},x=()=>{t.current.paused?(t.current.play(),u(!0)):(t.current.pause(),u(!1))},b=()=>{h(t.current.currentTime/t.current.duration*100)},N=()=>{w(t.current.duration)},z=n=>{const a=n.target.value/100*t.current.duration;t.current.currentTime=a,h(n.target.value)},p=n=>{const a=Math.floor(n/60),v=Math.floor(n%60);return`${a}:${v<10?"0":""}${v}`};return o?e.jsxs("div",{className:"fixed inset-0 z-[100] bg-black group",onMouseMove:M,children:[e.jsx("video",{ref:t,src:o.videoUrl,className:"w-full h-full cursor-none",onTimeUpdate:b,onLoadedMetadata:N,onClick:x,autoPlay:!0}),e.jsx("div",{className:`absolute top-0 left-0 p-8 z-10 transition-opacity duration-300 ${d?"opacity-100":"opacity-0"}`,children:e.jsxs("button",{onClick:()=>y(-1),className:"flex items-center space-x-2 text-white hover:text-gray-300 font-bold uppercase tracking-widest text-sm",children:[e.jsx(S,{size:32}),e.jsx("span",{children:o.title})]})}),e.jsxs("div",{className:`absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/20 flex flex-col justify-end p-8 transition-opacity duration-300 ${d?"opacity-100":"opacity-0"}`,children:[e.jsxs("div",{className:"w-full mb-6",children:[e.jsx("input",{type:"range",min:"0",max:"100",value:g,onChange:z,className:"w-full h-1 bg-gray-600 rounded-lg appearance-none cursor-pointer accent-purple-600 hover:h-2 transition-all"}),e.jsxs("div",{className:"flex justify-between text-xs mt-2 font-bold font-mono",children:[e.jsx("span",{children:p(((f=t.current)==null?void 0:f.currentTime)||0)}),e.jsx("span",{children:p(k)})]})]}),e.jsxs("div",{className:"flex items-center justify-between",children:[e.jsxs("div",{className:"flex items-center space-x-8",children:[e.jsx("button",{onClick:x,className:"text-white hover:scale-110 transition-transform",children:l?e.jsx($,{size:36,fill:"white"}):e.jsx(R,{size:36,fill:"white"})}),e.jsx("button",{onClick:()=>t.current.currentTime-=10,className:"text-white hover:scale-110 transition-transform",children:e.jsx(V,{size:28})}),e.jsx("button",{onClick:()=>t.current.currentTime+=10,className:"text-white hover:scale-110 transition-transform",children:e.jsx(q,{size:28})}),e.jsxs("div",{className:"flex items-center space-x-3 group/vol",children:[e.jsx(A,{size:24}),e.jsx("input",{type:"range",className:"w-0 group-hover/vol:w-20 transition-all accent-white h-1 appearance-none bg-white/30"})]})]}),e.jsxs("div",{className:"flex items-center space-x-6",children:[e.jsx("button",{className:"text-white hover:rotate-90 transition-transform",children:e.jsx(E,{size:24})}),e.jsx("button",{onClick:()=>t.current.requestFullscreen(),className:"text-white hover:scale-110 transition-transform",children:e.jsx(L,{size:24})})]})]})]})]}):e.jsx("div",{className:"h-screen bg-black flex items-center justify-center",children:"Loading..."})};export{D as default};
