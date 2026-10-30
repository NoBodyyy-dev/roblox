"""Convert MCP JPEG captures to PNG and make nearest-neighbour evidence crops."""
import json, math, runpy, sys
from pathlib import Path
from PIL import Image, ImageDraw

assets=Path(__file__).resolve().parent.parent
folder=assets/'textures/models/_tests'
manifest=json.loads((folder/'screenshot_manifest.json').read_text(encoding='utf-8'))
for p in folder.glob('*.jpg'):
    Image.open(p).save(p.with_suffix('.png'))
for q in manifest:
    if not q['name'].startswith('B_'): continue
    src=folder/(q['name']+'.png'); im=Image.open(src)
    factor=im.height/(2*math.tan(math.radians(35))*q['dist'])
    width=28 if q['target']=='TestUVBleed' else 4
    height=8 if width==28 else 4
    w=math.ceil(width*factor)+16;h=math.ceil(height*factor)+16
    x=int(im.width/2-w/2);y=int(im.height/2-h/2)
    sys.argv=[str(assets/'tools/crop_zoom.py'),str(src),str(x),str(y),str(w),str(h),str(src.with_stem(src.stem+'_zoom')),'--scale','8']
    runpy.run_path(str(assets/'tools/crop_zoom.py'),run_name='__main__')
sheet=Image.new('RGB',(1600,7*240),(230,230,230));draw=ImageDraw.Draw(sheet)
for row,face in enumerate(['posX','negX','posY','negY','posZ','negZ','bleed']):
    for col,dist in enumerate([50,200,500,1000]):
        name=f'B_bleed_{dist}' if face=='bleed' else f'B_world_{face}_{dist}'
        im=Image.open(folder/(name+'_zoom.png'))
        if im.width>380 or im.height>200: im.thumbnail((380,200),Image.Resampling.NEAREST)
        x=col*400+(400-im.width)//2;y=row*240+28+(205-im.height)//2
        sheet.paste(im,(x,y));draw.text((col*400+8,row*240+8),name,fill='black')
sheet.save(folder/'B_contact.png')
for prefix in ['A_world','C_world','D_','E_','G_']:
    files=sorted(p for p in folder.glob(prefix+'*.png') if not p.stem.endswith(('_zoom','_contact')))
    thumbw=400;thumbh=260;cols=3;rows=math.ceil(len(files)/cols)
    if not files: continue
    page=Image.new('RGB',(cols*thumbw,rows*thumbh),(230,230,230));draw=ImageDraw.Draw(page)
    for i,p in enumerate(files):
        im=Image.open(p)
        if prefix in ['A_world','C_world','D_']:
            cx,cy=im.width//2,im.height//2;im=im.crop((cx-180,cy-130,cx+180,cy+130))
        im.thumbnail((390,230));x=(i%cols)*thumbw;y=(i//cols)*thumbh
        page.paste(im,(x+(thumbw-im.width)//2,y+25));draw.text((x+5,y+5),p.stem,fill='black')
    page.save(folder/(prefix.rstrip('_')+'_contact.png'))
print('PNG captures, B nearest x8 crops and contact sheets saved')
