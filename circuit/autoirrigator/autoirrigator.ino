#include <WiFi.h>
#include <DHT.h> 
#include <PubSubClient.h>

#include "config.h"

#define DHTTYPE DHT11

// Tópicos MQTT
const char* topico_pub_umidade_solo = "horta/irrigation_djmr/solo";
const char* topico_pub_temperatura  = "horta/irrigation_djmr/temperatura";
const char* topico_pub_status_bomba = "horta/irrigation_djmr/bomba/status";
const char* topico_sub_comando      = "horta/irrigation_djmr/comando";

// Instâncias do Wifi e MQTT

WiFiClient espClient;
PubSubClient client(espClient);

// Configuração do Hardware
const int PINO_RELE   = 14; 
const int PINO_LED    = 5;  
const int PINO_SENSOR = 32; 
const int PINO_DHT    = 4;  

const int VALOR_SECO    = 3200; 
const int VALOR_UMIDO   = 2600; 
const int LIMITE_REGA   = 40; 


DHT dht(PINO_DHT, DHTTYPE);

unsigned long tempoAnterior = 0;
const long intervaloLeitura = 2000;

bool modoManual = false;
String statusBomba = "DESLIGADA";

void callback(char *topic, byte* payload, unsigned int length) {
  String comandoRecebido = "";
  for (int i = 0; i < length; i++) {
    comandoRecebido += (char)payload[i];
  }
  Serial.print(">> COMANDO RECEBIDO DO APP: ");
  Serial.println(comandoRecebido);

  if (comandoRecebido == "LIGAR") {
    modoManual = true;
    statusBomba = "LIGADA (Manual)";
    digitalWrite(PINO_RELE, HIGH);
    digitalWrite(PINO_LED, HIGH);
  } else if (comandoRecebido == "DESLIGAR") {
    modoManual = true;
    statusBomba = "DESLIGAR (Manual)";
    digitalWrite(PINO_RELE, LOW);
    digitalWrite(PINO_LED, LOW);
  } else if (comandoRecebido == "AUTO") {
    modoManual = false;
    Serial.println(">> Retornando ao Modo Automático");
  }

  client.publish(topico_pub_status_bomba, statusBomba.c_str());
}

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Conectando-se à rede: ");
  Serial.println(WIFI_SSID);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi conectado!");
  Serial.print("Endereço IP: ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Tentando conexão MQTT...");
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);

    if (client.connect(clientId.c_str())) {
      Serial.println("Conectado ao Mosquitto!");
      client.subscribe(topico_sub_comando);
    } else {
      Serial.print("Falhou, rc=");
      Serial.print(client.state());
      Serial.println("Tentando novamente em 5 segundos");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  
  pinMode(PINO_RELE, OUTPUT);
  pinMode(PINO_LED, OUTPUT);

  // Inicializa o relé e LED como desligados (Lógica de Transistor NPN)
  digitalWrite(PINO_RELE, LOW); 
  digitalWrite(PINO_LED, LOW);
  dht.begin();

  //Inicialização rede e MQTT
  setup_wifi();
  client.setServer(MQTT_BROKER, MQTT_PORT);
  client.setCallback(callback);
  
  Serial.println("Sistema Iniciado e configurado!");
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long tempoAtual = millis();
  if (tempoAtual - tempoAnterior >= intervaloLeitura) {
    tempoAnterior = tempoAtual;

    // Leitura dos Sensores
    int leituraCrua = analogRead(PINO_SENSOR);
    int umidadePorcentagem = map(leituraCrua, VALOR_SECO, VALOR_UMIDO, 0, 100);
    umidadePorcentagem = constrain(umidadePorcentagem, 0, 100);

    float h = dht.readHumidity();
    float t = dht.readTemperature();

    // LOG no Monitor serial
    Serial.print("Umidade Solo: ");
    Serial.print(umidadePorcentagem);
    Serial.println("%");

    if (isnan(h) || isnan(t)) {
      Serial.println("Erro no DHT11!");
    } else {
      Serial.printf("Ar: %.1f°C | %.1f%%\n", t, h);
    }

    //Lógica de controle
    if (modoManual == false) {
      String statusBomba = "";
      if (umidadePorcentagem < LIMITE_REGA) {
        Serial.println(">> Solo seco: LIGANDO RELE");
        digitalWrite(PINO_RELE, HIGH);
        digitalWrite(PINO_LED, HIGH);
        statusBomba = "LIGADA";
      } 
      else {
        Serial.println(">> Solo úmido: DESLIGANDO RELE");
        digitalWrite(PINO_RELE, LOW);
        digitalWrite(PINO_LED, LOW);
        statusBomba = "DESLIGADA";
      }

      Serial.println("-----------------------");
    }


    // Publicação MQTT
    char msgBuffer[10];
    dtostrf(umidadePorcentagem, 1, 0, msgBuffer);
    client.publish(topico_pub_umidade_solo, msgBuffer);

    if (!isnan(t)) {
      dtostrf(t, 1, 1, msgBuffer);
      client.publish(topico_pub_temperatura, msgBuffer);
    }

    client.publish(topico_pub_status_bomba, statusBomba.c_str());
  }
}