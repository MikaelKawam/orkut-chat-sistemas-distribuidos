import socket
import threading
import sys

# Lidar com mensagens recebidas do servidor
def receive_messages(cliente_socket):
    while True:
        try:
            mensagem = cliente_socket.recv(1024).decode('utf-8')
            if mensagem:
                print(mensagem)
            else:
                break
        except:
            break

# Iniciar o cliente
def start_client(username):
    cliente_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    cliente_socket.connect(('localhost', 12345))

    # Iniciar thread de recebimento
    receive_thread = threading.Thread(target=receive_messages, args=(cliente_socket,))
    receive_thread.start()

    print(f"{username} conectado ao servidor de chat.")
    
    while True:
        mensagem = input()
        if mensagem == 'EXIT':
            cliente
