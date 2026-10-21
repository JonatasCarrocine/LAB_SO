#!/bin/sh
# Simula a versão 2 (sem preempção) a partir do próprio BDF.
# Uso (na pasta do projeto):  sh simulacao_v2/simula_v2.sh
set -e
cd "$(dirname "$0")/.."
python3 ferramentas/bdf_para_verilog.py testeComponentes_multi.bdf multi_bdf > simulacao_v2/multi_bdf.v
iverilog -g2012 -o simulacao_v2/tb.vvp \
    simulacao_v2/tb_multi_v2.v simulacao_v2/multi_bdf.v simulacao_v2/primitivas_sim.v \
    PC_multi.v memInstrucao_multi.v registradorSaida.v \
    registradores.v memoriaDados_combinacional.v in_user.v out_device.v \
    teste_unidadeControle.v teste_mux_jump_TESTE.v ULA.v extensorSinal.v \
    mux_regdst.v mux_alusrc.v mux_memtoreg.v somadorUm.v \
    display7seg_decimal.v display7seg_2decimais.v
vvp -n simulacao_v2/tb.vvp | tee simulacao_v2/log.txt
