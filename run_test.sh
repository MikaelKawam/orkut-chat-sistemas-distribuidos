#!/bin/bash

# Porta a ser utilizada
porta=12345
total_testes=6
testes_passados=0

# Função para encerrar processos na porta 12345
encerrar_processos_na_porta() {
    pids=$(lsof -t -i:$porta)
    if [ -n "$pids" ]; then
        echo "Finalizando processos que estão usando a porta $porta (PIDs: $pids)..."
        kill -9 $pids
        sleep 2
    fi
}

# Função para iniciar um cliente e enviar uma mensagem usando expect
iniciar_cliente() {
    username="$1"
    mensagem="$2"
    logfile="$3"
    echo "Iniciando cliente $username..."
    (
    expect <<EOF
        log_file $logfile
        log_user 1
        set timeout -1
        spawn python3 cliente_chat.py "$username"
        expect {
            "Conexão estabelecida" {
                send -- "$mensagem\r"
                send_user "Mensagem '$mensagem' enviada por $username\n"
            }
        }
        expect {
            "Conexão encerrada pelo servidor" {
                send_user "Cliente $username desconectado do servidor\n"
                exit 0
            }
            eof {
                send_user "Cliente $username terminou a execução\n"
                exit 0
            }
        }
EOF
    ) &
    CLIENT_PID=$!
    sleep 2  # Tempo de espera para garantir que o cliente inicie corretamente e processe a mensagem
}

# Função para verificar se o servidor está em execução
verificar_servidor() {
    if ps -p $SERVER_PID > /dev/null; then
        echo "Servidor está em execução"
    else
        echo "Erro: Servidor não está em execução"
        exit 1
    fi
}

# Função para verificar se um cliente está em execução
verificar_cliente() {
    if ps -p $CLIENT_PID > /dev/null; then
        echo "Cliente está em execução"
        return 0
    else
        echo "Cliente não está em execução"
        return 1
    fi
}

# Encerra qualquer processo que esteja usando a porta 12345 antes de iniciar o servidor
encerrar_processos_na_porta

# Inicia o servidor
echo "Iniciando o servidor..."
python3 servidor_chat.py &
SERVER_PID=$!
sleep 2
verificar_servidor

# Teste 1: Conexão única
echo "Iniciando teste 1: Conexão única"
iniciar_cliente "Cliente 1" "Olá" "cliente1.log"
sleep 5

# Verifique a saída e incremente a contagem de testes passados
if verificar_cliente; then
    echo "Passou no teste 1: Conexão única"
    testes_passados=$((testes_passados + 1))
else
    echo "Falhou no teste 1: Conexão única"
fi
echo -e "\n****************************************"

# Teste 2: Envio de mensagem EXIT e encerramento de conexão
echo "Iniciando teste 2: Envio de mensagem EXIT"
iniciar_cliente "Cliente 2" "EXIT" "cliente2.log"
sleep 5

# Verifique a saída e incremente a contagem de testes passados
if ! verificar_cliente; then
    echo "Passou no teste 2: Envio de mensagem EXIT"
    testes_passados=$((testes_passados + 1))
else
    echo "Falhou no teste 2: Envio de mensagem EXIT"
fi
echo -e "\n****************************************"

# Teste 3: Conexão de múltiplos clientes
echo "Iniciando teste 3: Conexão de múltiplos clientes"
for i in {3..5}; do
    iniciar_cliente "Cliente $i" "Olá do Cliente $i" "cliente${i}.log"
done
sleep 10

# Verifique a saída e incremente a contagem de testes passados
passou_multiplos=1
for i in {3..5}; do
    if verificar_cliente; then
        echo "Cliente $i está em execução"
    else
        echo "Cliente $i não está em execução"
        passou_multiplos=0
    fi
done

if [ $passou_multiplos -eq 1 ]; then
    echo "Passou no teste 3: Conexão de múltiplos clientes"
    testes_passados=$((testes_passados + 1))
else
    echo "Falhou no teste 3: Conexão de múltiplos clientes"
fi
echo -e "\n****************************************"

# Teste 4: Verificação de broadcast de mensagens
echo "Iniciando teste 4: Verificação de broadcast de mensagens"
iniciar_cliente "Cliente 6" "Broadcast test message" "cliente6.log"
sleep 10

# Verifique se todos os clientes receberam a mensagem de broadcast
passou_broadcast=1
for i in {3..5}; do
    if grep -q "Broadcast test message" "cliente${i}.log"; then
        echo "Cliente $i recebeu a mensagem de broadcast"
    else
        echo "Cliente $i não recebeu a mensagem de broadcast"
        passou_broadcast=0
    fi
done

if [ $passou_broadcast -eq 1 ]; then
    echo "Passou no teste 4: Verificação de broadcast de mensagens"
    testes_passados=$((testes_passados + 1))
else
    echo "Falhou no teste 4: Verificação de broadcast de mensagens"
fi
echo -e "\n****************************************"

# Teste 5: Reenvio de mensagens
echo "Iniciando teste 5: Reenvio de mensagens"
iniciar_cliente "Cliente 7" "Testando reenvio" "cliente7.log"
sleep 10

# Verifique se todos os clientes receberam a mensagem de reenvio
passou_reenvio=1
for i in {3..5}; do
    if grep -q "Testando reenvio" "cliente${i}.log"; then
        echo "Cliente $i recebeu a mensagem de reenvio"
    else
        echo "Cliente $i não recebeu a mensagem de reenvio"
        passou_reenvio=0
    fi
done

if [ $passou_reenvio -eq 1 ]; then
    echo "Passou no teste 5: Reenvio de mensagens"
    testes_passados=$((testes_passados + 1))
else
    echo "Falhou no teste 5: Reenvio de mensagens"
fi
echo -e "\n****************************************"

# Teste 6: Desconexão e Reconexão
echo "Iniciando teste 6: Desconexão e Reconexão"
iniciar_cliente "Cliente 8" "Olá do Cliente 8" "cliente8.log"
sleep 5

# Desconectar o cliente
kill $CLIENT_PID
sleep 2

# Reconectar o cliente
iniciar_cliente "Cliente 8" "Reconectando Cliente 8" "cliente8_recon.log"
sleep 10

# Verifique se o cliente recebeu a mensagem após a reconexão
if grep -q "Reconectando Cliente 8" "cliente8_recon.log"; then
    echo "Cliente 8 reconectado e mensagem recebida"
    passou_reconexao=1
else
    echo "Cliente 8 não recebeu a mensagem após a reconexão"
    passou_reconexao=0
fi

if [ $passou_reconexao -eq 1 ]; then
    echo "Passou no teste 6: Desconexão e Reconexão"
    testes_passados=$((testes_passados + 1))
else
    echo "Falhou no teste 6: Desconexão e Reconexão"
fi
echo -e "\n****************************************"

# Encerra todos os processos iniciados
echo "Encerrando todos os processos..."
kill $SERVER_PID
kill $(pgrep -f "python3 cliente_chat.py")
echo "Testes concluídos."

# Remove os arquivos de log criados
echo "Removendo arquivos de log..."
rm -f cliente1.log cliente2.log cliente3.log cliente4.log cliente5.log cliente6.log cliente7.log cliente8.log cliente8_recon.log
echo "Arquivos de log removidos."

# Calcula a nota final
nota=$(echo "scale=2; ($testes_passados / $total_testes) * 10" | bc)
echo -e "\n****************************************"
echo -e "             NOTA FINAL: $nota"
echo -e "****************************************\n"
