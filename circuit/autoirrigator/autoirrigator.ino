#include <WiFi.h>
#include <DHT.h> 
#include <PubSubClient.h>

#define DHTTYPE DHT11

 const char* ssid = "M55 de Murilo";
 const char* password = "CRVG1898";

const char *mqtt_broker = "test.mosquitto.org";
const int mqtt_port = 1883;

// Tópicos MQTT
const char* topico_pub_umidade_solo = "horta/irrigation/solo";
const char* topico_pub_temperatura  = "horta/irrigation/temperatura";
const char* topico_pub_status_bomba = "horta/irrigation/bomba/status";

// Instâncias do Wifi e MQTT
WifiClient espClient;
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

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Conectando-se à rede: ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi conectado!");
  Serial.print("Endereço IP: ");
  Serial.println(WiFi.localIP())
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Tentando conexão MQTT...");
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);

    if (client.connect(clientId.c.str())) {
      Serial.println("Conectado ao Mosquitto!");
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
  client.setServer(mqtt_broker, mqtt_port);


  
  Serial.println("Sistema Iniciado e configurado!");
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long tempoAtual = millis();
  if (tempoAtual - temAnterior >= intervaloLeitura) {
    tempoAnterior = tempoAutal;

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
    if (umidadePorcentagem < LIMITE_REGA) {
      Serial.println(">> Solo seco: LIGANDO RELE");
      digitalWrite(PINO_RELE, HIGH);
      digitalWrite(PINO_LED, HIGH);
    } 
    else {
      Serial.println(">> Solo úmido: DESLIGANDO RELE");
      digitalWrite(PINO_RELE, LOW);
      digitalWrite(PINO_LED, LOW);
    }

    Serial.println("-----------------------");

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