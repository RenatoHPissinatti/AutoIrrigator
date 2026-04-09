import network
import socket
from time import sleep
import machine
from machine import Pin
import sys
from config import SSID as ssid, PASSWORD as password

pico_led = Pin('LED', Pin.OUT)

def connect() :
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(ssid, password)

    while not wlan.isconnected():
        print('Tentando conectar...')
        sleep(5)

    conf_rede = wlan.ifconfig()
    ip_placa = conf_rede[0]

    print('Conectado ao Wi-fi!')
    print(f'Configuração da rede: {conf_rede}')
    print(f'IP: {ip_placa}')

    return ip_placa


def open_socket(ip):
    address = (ip, 80)
    connection = socket.socket()

    # ISSO resolve o erro 98 na maioria das vezes:
    connection.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    try:
        connection.bind(address)
        connection.listen(1)
        print(f'Socket Aberto em {ip}:80')
        return connection
    except OSError as e:
        connection.close()
        raise e

def webpage(temperature, state):
    #Template HTML
    html = f""" 
        <!DOCTYPE html>
        <html>
        <body>
        <form action="./lighton">
        <input type="submit" value="Light on" />
        </form>
        <form action="./lightoff">
        <input type="submit" value="Light off" />
        </form>
        <form action="./close">
        <input type="submit" value="Stop server" />
        </form>
        <p>LED is {state}</p>
        <p>Temperature is {temperature}</p>
        </body>
        </html>
        """
    return str(html)

def serve(connection):
    state = 'OFF'
    pico_led.off()
    temperature = 0
    while True:
        client = connection.accept()[0]
        request = client.recv(1024)
        request = str(request)
        try:
            request = request.split()[1]
        except IndexError:
            pass

        if request == '/lighton?' :
            pico_led.on()
            state = 'ON'
        elif request == '/lightoff?' :
            pico_led.off()
            state = 'OFF'
        elif request == '/close?':
            sys.exit()
        html = webpage(temperature, state)
        client.send(html)
        client.close()

try:
    ip = connect()
    connection = open_socket(ip)
    serve(connection)
except OSError as e:
    if e.args[0] == 98:
        print("Porta 80 ocupada. Reiniciando a placa em 2 segundos...")
        sleep(2)
        machine.reset() # Isso limpa TUDO no hardware
    else:
        print(f"Erro inesperado: {e}")