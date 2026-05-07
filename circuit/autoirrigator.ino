#include <WiFi.h>
#include <DHT.h>
#include <PubSubClient.h>

// — Configurações WiFi — altere para sua rede
const char* WIFI_SSID     = "SUA_REDE_WIFI";
const char* WIFI_PASSWORD = "SUA_SENHA_WIFI";

// — Configurações MQTT — altere para o IP do seu broker (ex: Mosquitto local)
const char* MQTT_BROKER = "192.168.1.100";
const int   MQTT_PORT   = 1883;
const char* MQTT_CLIENT = "autoirrigator-esp32";

// — Tópicos MQTT —
const char* TOPIC_SENSORES = "autoirrigator/sensores";
const char* TOPIC_IRRIGAR  = "autoirrigator/irrigar";

// — Pinos —
const int PINO_RELE   = 14;
const int PINO_LED    = 5;
const int PINO_SENSOR = 32;
const int PINO_DHT    = 4;

// — Calibração do sensor de solo —
const int VALOR_SECO  = 3200;
const int VALOR_UMIDO = 2600;
const int LIMITE_REGA = 40;

#define DHTTYPE DHT11
DHT dht(PINO_DHT, DHTTYPE);

WiFiClient   espClient;
PubSubClient mqttClient(espClient);

bool modoManual    = false;
bool irrigarManual = false;

unsigned long ultimaPublicacao    = 0;
const long INTERVALO_PUBLICACAO   = 2000;

// — Callback: recebe comandos do app via MQTT —
void callbackMQTT(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];

  Serial.printf("[MQTT] '%s' -> %s\n", topic, msg.c_str());

  if (String(topic) == TOPIC_IRRIGAR) {
    if (msg == "1") {
      modoManual    = true;
      irrigarManual = true;
      Serial.println("[MQTT] Modo manual: IRRIGANDO");
    } else if (msg == "0") {
      modoManual    = false;
      irrigarManual = false;
      Serial.println("[MQTT] Modo automático reativado");
    }
  }
}

void conectarWiFi() {
  Serial.print("Conectando ao WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.printf("\nWiFi OK! IP: %s\n", WiFi.localIP().toString().c_str());
}

void conectarMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Conectando ao broker MQTT...");
    if (mqttClient.connect(MQTT_CLIENT)) {
      Serial.println(" OK!");
      mqttClient.subscribe(TOPIC_IRRIGAR);
    } else {
      Serial.printf(" falhou (rc=%d), tentando em 5s\n", mqttClient.state());
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(PINO_RELE, OUTPUT);
  pinMode(PINO_LED, OUTPUT);
  digitalWrite(PINO_RELE, LOW);
  digitalWrite(PINO_LED, LOW);

  dht.begin();
  conectarWiFi();

  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(callbackMQTT);
  conectarMQTT();

  Serial.println("Sistema iniciado!");
}

void loop() {
  if (!mqttClient.connected()) conectarMQTT();
  mqttClient.loop();

  unsigned long agora = millis();
  if (agora - ultimaPublicacao < INTERVALO_PUBLICACAO) return;
  ultimaPublicacao = agora;

  // — Leitura dos sensores —
  int leituraCrua = analogRead(PINO_SENSOR);
  int solo = constrain(map(leituraCrua, VALOR_SECO, VALOR_UMIDO, 0, 100), 0, 100);

  float umidadeAr   = dht.readHumidity();
  float temperatura = dht.readTemperature();

  if (isnan(umidadeAr) || isnan(temperatura)) {
    Serial.println("Erro no DHT11!");
    umidadeAr   = 0;
    temperatura = 0;
  }

  // — Decisão de irrigação: manual (app) ou automático (sensor) —
  bool deveIrrigar = modoManual ? irrigarManual : (solo < LIMITE_REGA);

  digitalWrite(PINO_RELE, deveIrrigar ? HIGH : LOW);
  digitalWrite(PINO_LED,  deveIrrigar ? HIGH : LOW);

  // — Publicar dados no tópico de sensores —
  char payload[128];
  snprintf(payload, sizeof(payload),
    "{\"solo\":%d,\"temperatura\":%.1f,\"umidadeAr\":%.1f,\"irrigando\":%s}",
    solo, temperatura, umidadeAr, deveIrrigar ? "true" : "false");

  mqttClient.publish(TOPIC_SENSORES, payload);

  Serial.printf("Solo:%d%% Temp:%.1f°C Ar:%.1f%% Irrigando:%s\n",
    solo, temperatura, umidadeAr, deveIrrigar ? "SIM" : "NAO");
  Serial.println("-----------------------");
}
