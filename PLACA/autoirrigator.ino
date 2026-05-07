#include <WiFi.h>
#include <DHT.h> 

// const char* ssid = "M55 de Murilo";
// const char* password = "CRVG1898";

const int PINO_RELE   = 14; 
const int PINO_LED    = 5;  
const int PINO_SENSOR = 32; 
const int PINO_DHT    = 4;  

#define DHTTYPE DHT11
DHT dht(PINO_DHT, DHTTYPE);

const int VALOR_SECO    = 3200; 
const int VALOR_UMIDO   = 2600; 
const int LIMITE_REGA   = 40;  

void setup() {
  Serial.begin(115200);
  
  pinMode(PINO_RELE, OUTPUT);
  pinMode(PINO_LED, OUTPUT);

  // Inicializa o relé e LED como desligados (Lógica de Transistor NPN)
  digitalWrite(PINO_RELE, LOW); 
  digitalWrite(PINO_LED, LOW);

  dht.begin();
  Serial.println("Sistema Iniciado!");
}

void loop() {
  int leituraCrua = analogRead(PINO_SENSOR);
  int umidadePorcentagem = map(leituraCrua, VALOR_SECO, VALOR_UMIDO, 0, 100);
  umidadePorcentagem = constrain(umidadePorcentagem, 0, 100);

  float h = dht.readHumidity();
  float t = dht.readTemperature();

  Serial.print("Umidade Solo: ");
  Serial.print(umidadePorcentagem);
  Serial.println("%");

  if (isnan(h) || isnan(t)) {
    Serial.println("Erro no DHT11!");
  } else {
    Serial.printf("Ar: %.1f°C | %.1f%%\n", t, h);
  }

  // Lógica para Transistor CG9905 (NPN)
  if (umidadePorcentagem < LIMITE_REGA) {
    Serial.println(">> Solo seco: LIGANDO RELE");
    digitalWrite(PINO_RELE, HIGH); // Ativa a base do transistor
    digitalWrite(PINO_LED, HIGH);
  } 
  else {
    Serial.println(">> Solo úmido: DESLIGANDO RELE");
    digitalWrite(PINO_RELE, LOW);  // Corta a base do transistor
    digitalWrite(PINO_LED, LOW);
  }

  Serial.println("-----------------------");
  delay(2000); 
}