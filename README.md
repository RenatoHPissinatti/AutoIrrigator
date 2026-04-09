# 🌱 AutoIrrigator

Sistema de irrigação automática controlado por uma ESP32, com um app Flutter para controle pelo celular.

---

## 📁 Estrutura do projeto

```
AutoIrrigator/
├── IrrigationSystem/   → Código que roda na ESP32
└── App/irrigator/      → App Flutter (celular)
```

---

## ⚙️ Pré-requisitos

Antes de começar, você precisa ter instalado:

- [Python 3.x](https://www.python.org/downloads/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) (para rodar o app)

---

## 🔌 Parte 1 — Configurar a ESP32

### 1. Instale as ferramentas

Dentro da pasta `IrrigationSystem`, rode:

```bash
pip install -r requirements.txt
```

### 2. Grave o MicroPython na ESP32 (só na primeira vez)

Baixe o firmware em: https://micropython.org/download/ESP32_GENERIC/

Depois conecte a ESP32 no USB e rode:

```bash
python -m esptool --chip esp32 erase_flash
python -m esptool --chip esp32 write_flash -z 0x1000 firmware.bin
```

> Troque `firmware.bin` pelo nome do arquivo que você baixou.

### 3. Configure o Wi-Fi

Crie um arquivo chamado `config.py` dentro de `IrrigationSystem/` com o seguinte conteúdo:

```python
SSID = 'nome_da_sua_rede'
PASSWORD = 'senha_da_sua_rede'
```

> ⚠️ **Nunca suba esse arquivo pro git!** Ele já está no `.gitignore`.

### 4. Envie o código para a placa

```bash
python -m mpremote cp IrrigationSystem/config.py :config.py
python -m mpremote cp IrrigationSystem/main.py :main.py
```

Pronto! A ESP32 vai conectar no Wi-Fi e abrir um servidor na porta 80.

---

## 📱 Parte 2 — Rodar o App Flutter

### 1. Instale as dependências

Dentro da pasta `App/irrigator`, rode:

```bash
flutter pub get
```

### 2. Rode o app

Com um emulador aberto ou celular conectado:

```bash
flutter run
```

---

## 🚀 Como usar

1. Ligue a ESP32 — ela vai conectar na rede e exibir o IP no console serial
2. Abra o app no celular
3. Use os botões para ligar/desligar a irrigação

---

## ❓ Problemas comuns

| Problema | Solução |
|---|---|
| `esptool: command not found` | Use `python -m esptool` |
| `Porta 80 ocupada` | Reinicie a ESP32 |
| App não conecta | Verifique se o celular e a ESP32 estão na mesma rede Wi-Fi |
