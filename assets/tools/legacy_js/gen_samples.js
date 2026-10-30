
const {rgb2lab,hex2rgb,dE,png}=PL;
const C={};CELLS.flat().forEach(c=>C[c.name]=hex2rgb(c.hex));
const SEED=20261030;
function rng(seed){let s=seed>>>0;return()=>{s=(s+0x6D2B79F5)>>>0;let t=s;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296;};}
function img(w,h){return {w,h,d:new Uint8Array(w*h*4)};}
function blend(im,x,y,rgb,a){if(x<0||y<0||x>=im.w||y>=im.h||a<=0)return;const i=(y*im.w+x)*4,da=im.d[i+3]/255,sa=a/255,oa=sa+da*(1-sa);
 for(let k=0;k<3;k++)im.d[i+k]=Math.round(oa?(rgb[k]*sa+im.d[i+k]*da*(1-sa))/oa:0);im.d[i+3]=Math.round(oa*255);}
const SS=[0.125,0.375,0.625,0.875];
function fillShape(im,inside,bbox,rgb,alpha=255){const[x0,y0,x1,y1]=bbox.map(Math.floor);
 for(let y=Math.max(0,y0);y<=Math.min(im.h-1,y1+1);y++)for(let x=Math.max(0,x0);x<=Math.min(im.w-1,x1+1);x++){let n=0;for(const sy of SS)for(const sx of SS)if(inside(x+sx,y+sy))n++;if(n)blend(im,x,y,rgb,alpha*n/16);}}
function polyIn(P){return(x,y)=>{let c=false;for(let i=0,j=P.length-1;i<P.length;j=i++){const[xi,yi]=P[i],[xj,yj]=P[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)c=!c;}return c;};}
const bb=P=>[Math.min(...P.map(p=>p[0])),Math.min(...P.map(p=>p[1])),Math.max(...P.map(p=>p[0])),Math.max(...P.map(p=>p[1]))];
const fillPoly=(im,P,rgb,a)=>fillShape(im,polyIn(P),bb(P),rgb,a);
function seg(im,a,b,w,rgb,alpha){const[ax,ay]=a,[bx,by]=b,dx=bx-ax,dy=by-ay,L2=dx*dx+dy*dy||1;
 fillShape(im,(x,y)=>{let t=((x-ax)*dx+(y-ay)*dy)/L2;t=Math.max(0,Math.min(1,t));return Math.hypot(x-ax-t*dx,y-ay-t*dy)<=w/2;},[Math.min(ax,bx)-w,Math.min(ay,by)-w,Math.max(ax,bx)+w,Math.max(ay,by)+w],rgb,alpha);}
function bleed(im){const{w,h,d}=im;let filled=new Uint8Array(w*h),front=[];for(let i=0;i<w*h;i++)if(d[i*4+3]>0)filled[i]=1;
 const nb=(i,f)=>{const x=i%w,y=(i/w)|0;for(let oy=-1;oy<=1;oy++)for(let ox=-1;ox<=1;ox++){const xx=x+ox,yy=y+oy;if(xx>=0&&yy>=0&&xx<w&&yy<h)f(yy*w+xx);}};
 for(let i=0;i<w*h;i++)if(!filled[i]){let any=false;nb(i,j=>{if(filled[j])any=true;});if(any)front.push(i);}
 while(front.length){const vals=front.map(i=>{let s=[0,0,0],n=0;nb(i,j=>{if(filled[j]){for(let k=0;k<3;k++)s[k]+=d[j*4+k];n++;}});return s.map(v=>Math.round(v/n));});
  front.forEach((i,q)=>{for(let k=0;k<3;k++)d[i*4+k]=vals[q][k];filled[i]=1;});
  const nf=new Set();for(const i of front)nb(i,j=>{if(!filled[j])nf.add(j);});front=[...nf].sort((a,b)=>a-b);}}
function haloCheck(im){const{w,h,d}=im;let worst=0;for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=y*w+x;if(d[i*4+3])continue;let s=[0,0,0],n=0;for(let oy=-1;oy<=1;oy++)for(let ox=-1;ox<=1;ox++){const xx=x+ox,yy=y+oy;if(xx<0||yy<0||xx>=w||yy>=h)continue;const j=yy*w+xx;if(d[j*4+3]){for(let k=0;k<3;k++)s[k]+=d[j*4+k];n++;}}
 if(n){const e=dE(rgb2lab([d[i*4],d[i*4+1],d[i*4+2]]),rgb2lab(s.map(v=>v/n)));if(e>worst)worst=e;}}return worst;}
function build(){const out={};
{const im=img(1024,1024);const band=(c,wid,col)=>{const h=wid/2;fillPoly(im,[[c-h-300,1064],[c+h-300,1064],[c+h+300,-40],[c-h+300,-40]],col);};
 band(430,120,C.neutral_15);band(600,60,C.signal_red_base);
 const cx=770,cy=720,R=150,r=60,P=[];for(let k=0;k<10;k++){const a=-Math.PI/2+k*Math.PI/5,rr=k%2?r:R;P.push([cx+rr*Math.cos(a),cy+rr*Math.sin(a)]);}fillPoly(im,P,C.signal_yellow_base);
 bleed(im);out.T_VehicleSkin_Test={im,ch:4};}
{const im=img(512,512);const R=rng(SEED);const tongues=[];let x=40;while(x<440){const wd=56+R()*36;tongues.push({x,wd,h:150+R()*190,lean:(R()-0.3)*60});x+=wd*0.66;}
 const layer=k=>{const bot=488-10*k,base=bot-24,L=40+16*k,Rr=472-16*k,P=[[L,bot]];
  for(const t of tongues){const x0=Math.max(L,t.x+t.wd*0.16*k),x1=Math.min(Rr,t.x+t.wd*(1-0.16*k));if(x1-x0<10)continue;const top=base-t.h*(1-0.24*k);
   P.push([x0,base]);P.push([x0+(x1-x0)*0.3+t.lean*0.4,(base+top)/2]);P.push([(x0+x1)/2+t.lean,top]);P.push([x0+(x1-x0)*0.78+t.lean*0.3,(base+top)/2+12]);P.push([x1,base]);}
  P.push([Rr,bot]);return P;};
 [C.signal_red_dark,C.signal_orange_base,C.signal_yellow_base,C.signal_yellow_lighter].forEach((c,k)=>fillPoly(im,layer(k),c));
 bleed(im);out.T_Sticker_Flames_01={im,ch:4};}
{const im=img(256,128);fillShape(im,()=>true,[0,0,255,127],C.neutral_02);
 const rr=(x,y,w,h,rad,col)=>fillShape(im,(px,py)=>{const qx=Math.max(x+rad,Math.min(px,x+w-rad)),qy=Math.max(y+rad,Math.min(py,y+h-rad));return Math.hypot(px-qx,py-qy)<=rad;},[x,y,x+w,y+h],col);
 rr(4,4,248,120,12,C.neutral_15);rr(10,10,236,108,8,C.neutral_02);rr(14,14,228,100,6,C.neutral_15);
 for(const sx of [40,216])fillShape(im,(x,y)=>Math.hypot(x-sx,y-26)<=4.5,[sx-6,20,sx+6,32],C.metal_08);
 const G={T:['11111','00100','00100','00100','00100','00100','00100'],R:['11110','10001','10001','11110','10100','10010','10001'],'5':['11111','10000','11110','00001','00001','10001','01110'],'0':['01110','10001','10011','10101','11001','10001','01110'],'8':['01110','10001','10001','01110','10001','10001','01110']};
 const text='TR 508',cw=6,chh=8,gap=6;let w=0;for(const ch of text)w+=ch===' '?cw*3:5*cw+gap;w-=gap;let px=Math.round(128-w/2);const py=Math.round(70-3.5*chh);
 for(const ch of text){if(ch===' '){px+=cw*3;continue;}G[ch].forEach((row,ry)=>[...row].forEach((b,rx)=>{if(b==='1')fillShape(im,()=>true,[px+rx*cw,py+ry*chh,px+rx*cw+cw-1,py+ry*chh+chh-1],C.neutral_01);}));px+=5*cw+gap;}
 out.T_Plate_01={im,ch:3};}
{const im=img(512,512);const R=rng(SEED+7);const ox=200,oy=220,N=13,rays=[];
 for(let k=0;k<N;k++){const a=k/N*2*Math.PI+R()*0.35,pts=[[ox,oy]];let r=0,ang=a;while(r<520){r+=30+R()*40;ang+=(R()-0.5)*0.25;pts.push([ox+r*Math.cos(ang),oy+r*Math.sin(ang)]);}rays.push(pts);}
 const crack=C.neutral_15;
 rays.forEach(p=>{for(let i=0;i<p.length-1;i++)seg(im,p[i],p[i+1],Math.max(1.2,3.2-i*0.4),crack,215);});
 for(const ring of [38,85,150,230])for(let k=0;k<N;k++){if(R()<0.3)continue;const pick=p=>p.reduce((b,q)=>Math.abs(Math.hypot(q[0]-ox,q[1]-oy)-ring)<Math.abs(Math.hypot(b[0]-ox,b[1]-oy)-ring)?q:b,p[1]);
  const a=pick(rays[k]),b=pick(rays[(k+1)%N]),m=[(a[0]+b[0])/2+(R()-0.5)*14,(a[1]+b[1])/2+(R()-0.5)*14];seg(im,a,m,1.6,crack,190);seg(im,m,b,1.6,crack,190);}
 fillShape(im,(x,y)=>Math.hypot(x-ox,y-oy)<=9,[ox-10,oy-10,ox+10,oy+10],crack,235);
 for(let y=0;y<512;y++)for(let x=0;x<512;x++){const e=Math.min(x,y,511-x,511-y);if(e>60)continue;const a=Math.round((1-e/60)**2*70*(0.55+0.45*R()));if(a>0)blend(im,x,y,C.sand_10,a);}
 bleed(im);out.T_Glass_Cracked_01={im,ch:4};}
return out;}
globalThis.SAMPLES={build,haloCheck};