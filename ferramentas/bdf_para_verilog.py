#!/usr/bin/env python3
"""Converte um .bdf do Quartus (só blocos, pinos e fios) em um módulo Verilog
estrutural, ligando por geometria e por nome (bit a bit, sem diferenciar
maiúsculas), para simular o diagrama com o Icarus."""
import re
import sys
from collections import defaultdict

src, modname = sys.argv[1], sys.argv[2]
s = open(src, encoding="latin-1").read()


def top_blocks(s):
    out = []; d = 0; st = None; i = 0
    while i < len(s):
        c = s[i]
        if c == '"':
            i = s.index('"', i + 1) + 1; continue
        if c == '(':
            if d == 0: st = i
            d += 1
        elif c == ')':
            d -= 1
            if d == 0: out.append(s[st:i + 1])
        i += 1
    return out


def parse_name(n):
    """'abc[31..0]' -> ('abc', [31..0]); 'abc[3]' -> ('abc',[3]); 'abc' -> ('abc', None)"""
    n = n.strip()
    m = re.match(r'^([A-Za-z_]\w*)\[(\d+)\.\.(\d+)\]$', n)
    if m:
        a, b = int(m.group(2)), int(m.group(3))
        bits = list(range(a, b - 1, -1)) if a >= b else list(range(a, b + 1))
        return m.group(1), bits
    m = re.match(r'^([A-Za-z_]\w*)\[(\d+)\]$', n)
    if m:
        return m.group(1), [int(m.group(2))]
    return n, None


par = {}
def f(x):
    par.setdefault(x, x)
    while par[x] != x:
        par[x] = par[par[x]]; x = par[x]
    return x
def u(a, b): par[f(a)] = f(b)

pins = []      # (dir, name, base, bits, pt)
insts = []     # (type, inst, [(port, dir, base, width, pt)])
segs = []      # (a, b, name or None)
juncs = set()

for b in top_blocks(s):
    kind = re.match(r'\((\w+)', b).group(1)
    if kind == 'pin':
        d = re.search(r'\((input|output|bidir)\)', b).group(1)
        r = list(map(int, re.search(r'\(rect (-?\d+) (-?\d+) (-?\d+) (-?\d+)\)', b).groups()))
        nm = re.findall(r'\(text "([^"]+)"', b)[1]
        pt = tuple(map(int, re.findall(r'^\t\(pt (-?\d+) (-?\d+)\)', b, re.M)[0]))
        base, bits = parse_name(nm)
        pins.append((d, nm, base, bits, (r[0] + pt[0], r[1] + pt[1])))
    elif kind == 'symbol':
        r = list(map(int, re.search(r'\(rect (-?\d+) (-?\d+) (-?\d+) (-?\d+)\)', b).groups()))
        t = re.findall(r'^\t\(text "([^"]+)"', b, re.M)
        ps = []
        for pm in re.finditer(r'\(port\s*\(pt (-?\d+) (-?\d+)\)\s*\((input|output|bidir)\)\s*\(text "([^"]+)"', b):
            base, bits = parse_name(pm.group(4))
            ps.append((pm.group(4), pm.group(3), base, len(bits) if bits else 1,
                       (r[0] + int(pm.group(1)), r[1] + int(pm.group(2)))))
        insts.append((t[0], t[1], ps))
    elif kind == 'junction':
        juncs.add(tuple(map(int, re.search(r'\(pt (-?\d+) (-?\d+)\)', b).groups())))
    elif kind == 'connector':
        pts = [tuple(map(int, x)) for x in re.findall(r'\(pt (-?\d+) (-?\d+)\)', b)]
        nm = re.search(r'\(text "([^"]+)"', b)
        segs.append((pts[0], pts[1], nm.group(1) if nm else None))


def on(p, a, c):
    if a[0] == c[0] == p[0]: return min(a[1], c[1]) <= p[1] <= max(a[1], c[1])
    if a[1] == c[1] == p[1]: return min(a[0], c[0]) <= p[0] <= max(a[0], c[0])
    return False

# 1) geometria. Cada componente tem uma largura (None = ainda desconhecida).
#    Só junta componentes de larguras compatíveis: uma derivação com nome de
#    largura diferente que encosta num barramento liga pelo NOME (bus ripper).
width = {}
def jf(a, b):
    ra, rb = f(a), f(b)
    if ra == rb: return
    wa, wb = width.get(ra), width.get(rb)
    if wa is not None and wb is not None and wa != wb: return
    par[ra] = rb
    width[rb] = wa if wa is not None else wb

def touches(p, a, c, allow_mid):
    if p == a or p == c: return True
    return allow_mid and on(p, a, c)

for i, (a, c, nm) in enumerate(segs):
    f(('seg', i))
    if nm:
        _, bits = parse_name(nm)
        width[f(('seg', i))] = len(bits) if bits else 1

# fios sem nome entre si
for i, (a, c, nm) in enumerate(segs):
    if nm: continue
    for j, (a2, c2, nm2) in enumerate(segs):
        if j <= i or nm2: continue
        if a in (a2, c2) or c in (a2, c2) or \
           (a in juncs and on(a, a2, c2)) or (c in juncs and on(c, a2, c2)) or \
           (a2 in juncs and on(a2, a, c)) or (c2 in juncs and on(c2, a, c)):
            jf(('seg', i), ('seg', j))

# pinos e portas: ligam em qualquer fio que passe pelo ponto
terminals = []
for k, (d, nm, base, bits, p) in enumerate(pins):
    terminals.append((('pin', k), p, len(bits) if bits else 1))
for typ, inst, ps in insts:
    for pn, d, base, w, p in ps:
        terminals.append((('port', inst, pn), p, w))
for key, p, w in terminals:
    f(key); width[f(key)] = w
for key, p, w in terminals:
    for i, (a, c, nm) in enumerate(segs):
        if touches(p, a, c, True):
            jf(key, ('seg', i))

# fios com nome encostando em fios sem nome (pelas pontas)
for i, (a, c, nm) in enumerate(segs):
    if not nm: continue
    for j, (a2, c2, nm2) in enumerate(segs):
        if j == i or nm2: continue
        if a in (a2, c2) or c in (a2, c2):
            jf(('seg', i), ('seg', j))

def grp_of_pt(key): return f(key)

# 2) cada grupo geométrico vira um "fio" com largura; os pontos de porta
#    dizem a largura. Nomes nos fios e nos pinos ligam bits por nome.
groups = defaultdict(lambda: {'ports': [], 'names': []})
for k, (d, nm, base, bits, p) in enumerate(pins):
    groups[f(('pin', k))]['names'].append((base, bits))
for i, (a, c, nm) in enumerate(segs):
    if nm: groups[f(('seg', i))]['names'].append(parse_name(nm))
for typ, inst, ps in insts:
    for pn, d, base, w, p in ps:
        groups[f(('port', inst, pn))]['ports'].append((inst, pn, w))

# nós bit a bit
bitpar = {}
def bf(x):
    bitpar.setdefault(x, x)
    while bitpar[x] != x:
        bitpar[x] = bitpar[bitpar[x]]; x = bitpar[x]
    return x
def bu(a, b): bitpar[bf(a)] = bf(b)

for g, info in groups.items():
    widths = [w for *_, w in info['ports']]
    for base, bits in info['names']:
        widths.append(len(bits) if bits else 1)
    W = max(widths) if widths else 1
    for i in range(W): bf((g, i))   # bit i = LSB-relativo (i=0 é o bit menos significativo)
    for base, bits in info['names']:
        lb = base.lower()
        if bits is None:
            bu((g, 0), ('nm', lb, None))
        else:
            # bits está do MSB para o LSB; posição i a partir do LSB
            for i, bit in enumerate(reversed(bits)):
                bu((g, i), ('nm', lb, bit))

# 3) gera Verilog
wid = {}
def wname(node):
    r = bf(node)
    if r not in wid: wid[r] = f"n{len(wid)}"
    return wid[r]

def vid(n):
    return re.sub(r'\W', '_', n)

lines = [f"// gerado de {src}", f"module {modname} ("]
portdecl = []
for d, nm, base, bits, p in pins:
    w = f"[{len(bits)-1}:0] " if bits else ""
    portdecl.append(f"    {'input' if d=='input' else 'output'} wire {w}{vid(base)}")
lines.append(",\n".join(portdecl)); lines.append(");")
body = []
for k, (d, nm, base, bits, p) in enumerate(pins):
    g = f(('pin', k))
    n = len(bits) if bits else 1
    for i in range(n):
        node = (g, i)
        tgt = f"{vid(base)}[{i}]" if bits else vid(base)
        if d == 'input': body.append(f"    assign {wname(node)} = {tgt};")
        else:            body.append(f"    assign {tgt} = {wname(node)};")
for typ, inst, ps in insts:
    conns = []
    for pn, d, base, w, p in ps:
        g = f(('port', inst, pn))
        bitsv = [wname((g, i)) for i in range(w - 1, -1, -1)]
        conns.append(f".{vid(base)}({{{', '.join(bitsv)}}})" if w > 1 else f".{vid(base)}({bitsv[0]})")
    body.append(f"    {typ} {inst} ({', '.join(conns)});")
lines.append("    wire " + ", ".join(sorted(set(wid.values()), key=lambda x: int(x[1:]))) + ";")
lines += body
lines.append("endmodule")
print("\n".join(lines))
