# Считает треугольники в OBJ из assets/source (группы g). Запуск из корня репозитория: python -I notes/tools/count_tris.py
import sys,os,glob,collections
for path in sorted(glob.glob('assets/source/**/*.obj',recursive=True)):
    groups=collections.OrderedDict(); g='(none)'; tot=0; ngon=0
    for line in open(path,encoding='utf-8',errors='replace'):
        if line.startswith('g '): g=line[2:].strip(); groups.setdefault(g,0)
        elif line.startswith('f '):
            n=len(line.split())-1; t=n-2; tot+=t; groups[g]=groups.get(g,0)+t
            if n>4: ngon+=1
    print(f"{path}\t{tot}\tngons>4:{ngon}")
    for k,v in groups.items(): print(f"   {k}\t{v}")
