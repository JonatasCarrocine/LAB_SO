#!/usr/bin/env python3
"""
Desenha o diagrama de Gantt das execuções simuladas pelo tb_processadorSO.v.

Lê simulacao/gantt_sem_preempcao.csv e simulacao/gantt_com_preempcao.csv
(colunas: tempo, programa, pc) e salva simulacao/gantt.png.

Uso:  python3 ferramentas/gantt.py      (precisa do matplotlib)
"""
import csv
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PASTA = os.path.join(RAIZ, "simulacao")


def fatias(arquivo):
    """Agrupa instruções consecutivas do mesmo programa em (programa, início, duração)."""
    linhas = list(csv.DictReader(open(arquivo)))
    resultado = []
    for linha in linhas:
        t, prog = int(linha["tempo"]), int(linha["programa"])
        if resultado and resultado[-1][0] == prog and resultado[-1][1] + resultado[-1][2] == t:
            resultado[-1][2] += 1
        else:
            resultado.append([prog, t, 1])
    return resultado


def main():
    modos = [("Sem preempção (FCFS)", "gantt_sem_preempcao.csv"),
             ("Com preempção (Round-Robin)", "gantt_com_preempcao.csv")]
    cores = plt.get_cmap("tab10")

    fig, eixos = plt.subplots(len(modos), 1, figsize=(14, 7), sharex=True)
    for eixo, (titulo, nome) in zip(eixos, modos):
        dados = fatias(os.path.join(PASTA, nome))
        for prog, inicio, duracao in dados:
            eixo.broken_barh([(inicio, duracao)], (prog - 0.4, 0.8), color=cores((prog - 1) % 10))
        eixo.set_title(titulo)
        eixo.set_ylabel("Programa")
        eixo.set_yticks(range(1, 11))
        eixo.set_ylim(0.4, 10.6)
        eixo.invert_yaxis()
        eixo.grid(axis="x", alpha=0.3)
    eixos[-1].set_xlabel("Tempo (instruções executadas)")
    fig.tight_layout()

    saida = os.path.join(PASTA, "gantt.png")
    fig.savefig(saida, dpi=120)
    print(saida)


if __name__ == "__main__":
    main()
