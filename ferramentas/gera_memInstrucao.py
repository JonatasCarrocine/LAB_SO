#!/usr/bin/env python3
"""
Gera, a partir dos programas em programas/progNN.txt:
  - memInstrucao_multi.v : versão 2 (sem preempção), usada no testeComponentes_multi.bdf
  - memInstrucao_SO.v    : versão 1 (com e sem preempção), usada no processadorSO_nucleo

Cada arquivo contém a saída do compilador, no mesmo formato usado no
memInstrucao.v original:

    mem[0] = 32'b001101_00000_11011_0000000000000000;// ldi

Os programas continuam sendo compilados a partir do endereço 0. Aqui cada
um é colocado na sua partição da memória física:

    endereço físico = (programa * TAM_PARTICAO) + endereço lógico

A tradução de endereço (base + deslocamento) é feita pelo hardware, então
nenhum salto/endereço do programa precisa ser alterado.

Uso:  python3 ferramentas/gera_memInstrucao.py
"""
import glob
import os
import re
import sys

TAM_PARTICAO = 128  # instruções por programa (deve casar com o parâmetro do hardware)

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PASTA_PROGS = os.path.join(RAIZ, "programas")
SAIDA = os.path.join(RAIZ, "memInstrucao_SO.v")
SAIDA_MULTI = os.path.join(RAIZ, "memInstrucao_multi.v")

RE_INSTR = re.compile(r"^\s*mem\[(\d+)\]\s*=\s*32'b([01_]+)\s*;\s*(//.*)?$")


def le_programa(caminho):
    titulo = None
    instrucoes = []
    for num, linha in enumerate(open(caminho, encoding="utf-8"), 1):
        s = linha.strip()
        if not s:
            continue
        m = RE_INSTR.match(s)
        if m:
            end = int(m.group(1))
            bits = m.group(2).replace("_", "")
            if len(bits) != 32:
                sys.exit(f"{caminho}:{num}: instrução não tem 32 bits")
            if end >= TAM_PARTICAO:
                sys.exit(f"{caminho}:{num}: endereço {end} não cabe na partição ({TAM_PARTICAO})")
            instrucoes.append((end, m.group(2), (m.group(3) or "").strip()))
        elif s.startswith("//"):
            texto = s.lstrip("/").strip()
            if titulo is None:
                titulo = texto
            else:
                instrucoes.append((None, None, "//" + texto))
        else:
            sys.exit(f"{caminho}:{num}: linha não reconhecida: {s}")
    return titulo or os.path.basename(caminho), instrucoes


def gera_multi(arquivos):
    """Versão 2: mesmas portas da memInstrucao original + entrada programa (1..N)."""
    out = []
    out.append("// ARQUIVO GERADO por ferramentas/gera_memInstrucao.py - não edite à mão.")
    out.append("// Edite programas/progNN.txt e rode o script novamente.")
    out.append("//")
    out.append("// Memória de instruções com os programas, um em cada \"gaveta\" de")
    out.append("// TAM_PARTICAO instruções. Mesmas portas da memInstrucao original, mais a")
    out.append("// entrada programa (1, 2, ..., NUM_PROGS) que vem do PC_multi:")
    out.append("//")
    out.append("//     endereço real = (programa - 1) * TAM_PARTICAO + endInstr")
    out.append("//")
    out.append("// Assim cada programa continua começando no endereço 0, como o compilador")
    out.append("// gera, e nenhum salto precisa ser alterado.")
    out.append("//")
    out.append("// posMem vai para os displays: bits [6..0] = PC, bits [13..7] = programa.")
    out.append("module memInstrucao_multi #(")
    out.append(f"\tparameter NUM_PROGS    = {len(arquivos)},")
    out.append(f"\tparameter TAM_PARTICAO = {TAM_PARTICAO}")
    out.append(") (endInstr, clock, programa, pcInstr, posMem);")
    out.append("\tinput [31:0] endInstr;")
    out.append("\tinput clock;                 // não usado (leitura combinacional), mantido como na original")
    out.append("\tinput [3:0] programa;")
    out.append("")
    out.append("\toutput wire [31:0] pcInstr;")
    out.append("\toutput wire [31:0] posMem;")
    out.append("")
    out.append("\treg [31:0] mem [0:NUM_PROGS*TAM_PARTICAO-1];")
    out.append("")
    out.append("\tinteger i;")
    out.append("\tinitial begin")
    out.append("\t\tfor (i = 0; i < NUM_PROGS*TAM_PARTICAO; i = i + 1)")
    out.append("\t\t\tmem[i] = 32'b0;")
    for idx, arq in enumerate(arquivos):
        titulo, instrucoes = le_programa(arq)
        base = idx * TAM_PARTICAO
        out.append("")
        out.append(f"\t\t// ---- Programa {idx + 1} ({os.path.basename(arq)}): {titulo}")
        out.append(f"\t\t// começa no endereço real {base}")
        for end, bits, coment in instrucoes:
            if end is None:
                out.append(f"\t\t{coment}")
            else:
                out.append(f"\t\tmem[{base} + {end}] = 32'b{bits};{(' ' + coment) if coment else ''}")
    out.append("\tend")
    out.append("")
    out.append("\twire programaValido = (programa >= 1) && (programa <= NUM_PROGS);")
    out.append("\twire [31:0] enderecoReal = (programa - 1) * TAM_PARTICAO + endInstr;")
    out.append("")
    out.append("\t// Leitura combinacional - sem latência (como na original)")
    out.append("\tassign pcInstr = (programaValido && endInstr < TAM_PARTICAO) ? mem[enderecoReal] : 32'b0;")
    out.append("\tassign posMem  = {18'b0, 3'b0, programa, endInstr[6:0]};")
    out.append("endmodule")
    out.append("")
    with open(SAIDA_MULTI, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"{SAIDA_MULTI}: {len(arquivos)} programas, {TAM_PARTICAO} instruções por programa")


def main():
    arquivos = sorted(glob.glob(os.path.join(PASTA_PROGS, "prog*.txt")))
    if not arquivos:
        sys.exit("nenhum programa em programas/")
    if len(arquivos) > 15:
        sys.exit("no máximo 15 programas (o número do programa tem 4 bits)")

    gera_multi(arquivos)

    out = []
    out.append("// ARQUIVO GERADO por ferramentas/gera_memInstrucao.py - não edite à mão.")
    out.append("// Edite programas/progNN.txt e rode o script novamente.")
    out.append("//")
    out.append("// Memória de instruções particionada: cada programa ocupa TAM_PARTICAO")
    out.append("// palavras. O endereço físico é {processo, pc_logico} (registrador base")
    out.append("// implícito = processo * TAM_PARTICAO).")
    out.append("module memInstrucao_SO #(")
    out.append(f"    parameter NUM_PROGS    = {len(arquivos)},")
    out.append(f"    parameter TAM_PARTICAO = {TAM_PARTICAO}")
    out.append(") (")
    out.append("    input  wire [3:0]  processo,   // 0 = programa 1, 1 = programa 2, ...")
    out.append("    input  wire [31:0] pcLogico,   // PC como o programa enxerga (começa em 0)")
    out.append("    output wire [31:0] instrucao,")
    out.append("    output wire        foraLimite  // PC além da partição do processo")
    out.append(");")
    out.append("    localparam BITS_PART = $clog2(TAM_PARTICAO);")
    out.append("")
    out.append("    reg [31:0] mem [0:NUM_PROGS*TAM_PARTICAO-1];")
    out.append("")
    out.append("    integer i;")
    out.append("    initial begin")
    out.append("        for (i = 0; i < NUM_PROGS*TAM_PARTICAO; i = i + 1)")
    out.append("            mem[i] = 32'b0;")
    for idx, arq in enumerate(arquivos):
        titulo, instrucoes = le_programa(arq)
        base = idx * TAM_PARTICAO
        out.append("")
        out.append(f"        // ---- Programa {idx + 1} ({os.path.basename(arq)}): {titulo}")
        out.append(f"        // base física = {base}")
        for end, bits, coment in instrucoes:
            if end is None:
                out.append(f"        {coment}")
            else:
                out.append(f"        mem[{base} + {end}] = 32'b{bits};{(' ' + coment) if coment else ''}")
    out.append("    end")
    out.append("")
    out.append("    assign foraLimite = (pcLogico >= TAM_PARTICAO);")
    out.append("    assign instrucao  = foraLimite ? 32'b0")
    out.append("                      : mem[{processo, pcLogico[BITS_PART-1:0]}];")
    out.append("endmodule")
    out.append("")

    with open(SAIDA, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"{SAIDA}: {len(arquivos)} programas, partição de {TAM_PARTICAO} instruções")


if __name__ == "__main__":
    main()
