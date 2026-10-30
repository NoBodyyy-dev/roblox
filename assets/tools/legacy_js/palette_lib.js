
const s2l=c=>{c/=255;return c<=0.04045?c/12.92:Math.pow((c+0.055)/1.055,2.4)};
const l2s=c=>{c=c<=0.0031308?12.92*c:1.055*Math.pow(c,1/2.4)-0.055;return c*255};
function rgb2lab([R,G,B]){const r=s2l(R),g=s2l(G),b=s2l(B);
const l=Math.cbrt(0.4122214708*r+0.5363325363*g+0.0514459929*b),m=Math.cbrt(0.2119034982*r+0.6806995451*g+0.1073969566*b),s=Math.cbrt(0.0883024619*r+0.2817188376*g+0.6299787005*b);
return [0.2104542553*l+0.7936177850*m-0.0040720468*s,1.9779984951*l-2.4285922050*m+0.4505937099*s,0.0259040371*l+0.7827717662*m-0.8086757660*s];}
function lab2lin([L,a,b]){const l=(L+0.3963377774*a+0.2158037573*b)**3,m=(L-0.1055613458*a-0.0638541728*b)**3,s=(L-0.0894841775*a-1.2914855480*b)**3;
return [4.0767416621*l-3.3077115913*m+0.2309699292*s,-1.2684380046*l+2.6097574011*m-0.3413193965*s,-0.0041960863*l-0.7034186147*m+1.7076147010*s];}
const inG=v=>v.every(x=>x>=-1e-7&&x<=1+1e-7);
function lab2rgb(lab){let [L,a,b]=lab;L=Math.max(0,Math.min(L,1));let C=Math.hypot(a,b),h=Math.atan2(b,a);
if(!inG(lab2lin([L,a,b]))){let lo=0,hi=C;for(let i=0;i<60;i++){const mid=(lo+hi)/2;inG(lab2lin([L,mid*Math.cos(h),mid*Math.sin(h)]))?lo=mid:hi=mid;}C=lo;}
return lab2lin([L,C*Math.cos(h),C*Math.sin(h)]).map(x=>Math.round(l2s(Math.max(0,Math.min(1,x)))));}
const hex2rgb=h=>[1,3,5].map(i=>parseInt(h.slice(i,i+2),16));
const rgb2hex=v=>'#'+v.map(x=>x.toString(16).padStart(2,'0')).join('').toUpperCase();
const hex2lab=h=>rgb2lab(hex2rgb(h));
const dE=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1],a[2]-b[2]);
const dEh=(x,y)=>dE(hex2lab(x),hex2lab(y));
function path(stops,n){const P=stops.map(hex2lab);const seg=[];let tot=0;for(let i=0;i<P.length-1;i++){const d=dE(P[i],P[i+1]);seg.push(d);tot+=d;}
const out=[];for(let j=0;j<n;j++){let t=tot*j/(n-1),i=0;while(i<seg.length-1&&t>seg[i]+1e-12){t-=seg[i];i++;}const f=seg[i]?Math.min(1,t/seg[i]):0;out.push(rgb2hex(lab2rgb(P[i].map((x,q)=>x+(P[i+1][q]-x)*f))));}return out;}
function op(rgb,mixHex,t,cm,lm){let lab=rgb2lab(rgb);if(mixHex){const m=hex2lab(mixHex);lab=lab.map((x,i)=>x+(m[i]-x)*t);}let [L,a,b]=lab;a*=cm;b*=cm;L=Math.min(1,L*lm);return lab2rgb([L,a,b]);}
const CRC=(()=>{const t=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=c&1?0xEDB88320^(c>>>1):c>>>1;t[n]=c>>>0;}return t;})();
function crc(bytes){let c=0xFFFFFFFF;for(let i=0;i<bytes.length;i++)c=CRC[(c^bytes[i])&255]^(c>>>8);return (c^0xFFFFFFFF)>>>0;}
async function png(w,h,data,ch){const rl=w*ch+1,raw=new Uint8Array(rl*h);for(let y=0;y<h;y++)raw.set(data.subarray(y*w*ch,(y+1)*w*ch),y*rl+1);
const z=new Uint8Array(await new Response(new Blob([raw]).stream().pipeThrough(new CompressionStream('deflate'))).arrayBuffer());
const chunk=(type,d)=>{const o=new Uint8Array(12+d.length),dv=new DataView(o.buffer);dv.setUint32(0,d.length);for(let i=0;i<4;i++)o[4+i]=type.charCodeAt(i);o.set(d,8);dv.setUint32(8+d.length,crc(o.subarray(4,8+d.length)));return o;};
const ih=new Uint8Array(13),dv=new DataView(ih.buffer);dv.setUint32(0,w);dv.setUint32(4,h);ih[8]=8;ih[9]=ch===4?6:2;
return new Blob([new Uint8Array([137,80,78,71,13,10,26,10]),chunk('IHDR',ih),chunk('IDAT',z),chunk('IEND',new Uint8Array(0))],{type:'image/png'});}
async function sha(blob){try{const d=await crypto.subtle.digest('SHA-256',await blob.arrayBuffer());return [...new Uint8Array(d)].map(x=>x.toString(16).padStart(2,'0')).join('');}catch(e){return 'unavailable';}}
globalThis.PL={rgb2lab,lab2rgb,hex2rgb,rgb2hex,hex2lab,dE,dEh,path,op,png,sha};