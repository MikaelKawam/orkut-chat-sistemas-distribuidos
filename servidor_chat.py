import socket
import threading

# Detalhes do servidor
HOST = 'localhost'
PORT = 12345

# Armazenar clientes conectados
clientes = []

# Broadcast uma mensagem para todos os clientes
def broadcast(mensagem, cliente_socket):
    for cliente in clientes:
        if cliente != cliente_socket:
            try:
                cliente.send(mensagem)
            except:
                clientes.remove(cliente)

# Lidar com a conexão do cliente
def handle_client(cliente_socket, endereco_cliente):
    print(f"Nova conexão de {endereco_cliente}")
    cliente_socket.send("Conexão estabelecida".encode('utf-8'))
    
    while True:
        try:
            mensagem = cliente_socket.recv(1024)
            if not mensagem or mensagem.decode('utf-8').strip() == 'EXIT':
                clientes.remove(cliente_socket)
                cliente_socket.send("Conexão encerrada pelo servidor".encode('utf-8'))
                cliente_socket.close()
                break
            print(f"Recebida mensagem de {endereco_cliente}: {mensagem.decode('utf-8')}")
            broadcast(mensagem, cliente_socket)
        except:
            clientes.remove(cliente_socket)
            cliente_socket.close()
            break

# Iniciar o servidor
def start_server():
    servidor_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    servidor_socket.bind((HOST, PORT))
    servidor_socket.listen()
    print(f"Servidor ouvindo em {HOST}:{PORT}")

    while True:
        cliente_socket, endereco_cliente = servidor_socket.accept()
        clientes.append(cliente_socket)
        cliente_thread = threading.Thread(target=handle_client, args=(cliente_socket, endereco_cliente))
        cliente_thread.start()

if __name__ == "__main__":
    start_server()
