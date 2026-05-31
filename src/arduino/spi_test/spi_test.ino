// Arduino -> TinyFPGA BX 6502 control bus
const int RESB_PIN = 15;  // TinyFPGA 3: RESB
const int CSB_PIN = 20;   // TinyFPGA 14: CSB
const int RDB_PIN = 19;  // TinyFPGA 5: RDB
const int WRB_PIN = 18;  // TinyFPGA 4: WRB

// Arduino -> TinyFPGA BX register select bus
const int REG_SELECT_1_PIN = 16;  // TinyFPGA 1: REG_SELECT[1]
const int REG_SELECT_0_PIN = 17;  // TinyFPGA 2: REG_SELECT[0]

// Arduino <-> TinyFPGA BX data bus
// High nibble is hardwired low
const int DATA_3_PIN = 24;  // TinyFPGA 10: DATA[3]
const int DATA_2_PIN = 23;  // TinyFPGA 11: DATA[2]
const int DATA_1_PIN = 22;  // TinyFPGA 12: DATA[1]
const int DATA_0_PIN = 0;  // TinyFPGA 13: DATA[0]

// TinyFPGA BX -> Arduino observed bus control
const int DATA_OUT_PIN = 21;  // TinyFPGA 15: DATA_OUT

// TinyFPGA BX -> Arduino observed SPI bus
const int SPI_CSB_0_PIN = 5;  // TinyFPGA 16: SPI_CSB[0]
const int SPI_CSB_1_PIN = 6;  // TinyFPGA 17: SPI_CSB[1]
const int SPI_CSB_2_PIN = 9;  // TinyFPGA 18: SPI_CSB[2]
const int SPI_CSB_3_PIN = 10;  // TinyFPGA 19: SPI_CSB[3]
const int SCK_PIN = 11;        // TinyFPGA 20: SCK
const int MOSI_PIN = 12;       // TinyFPGA 21: MOSI

// Arduino -> TinyFPGA BX SPI input
const int MISO_PIN = 1;       // TinyFPGA 22: MISO

const int DATA_PINS[4] = {
  DATA_0_PIN,
  DATA_1_PIN,
  DATA_2_PIN,
  DATA_3_PIN,
};

const int REG_DATA = 0x00;
const int REG_CONF = 0x01;
const int REG_STATUS = 0x02;

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(RESB_PIN, OUTPUT);
  pinMode(CSB_PIN, OUTPUT);
  pinMode(RDB_PIN, OUTPUT);
  pinMode(WRB_PIN, OUTPUT);

  // Arduino -> TinyFPGA BX register select bus
  pinMode(REG_SELECT_1_PIN, OUTPUT);
  pinMode(REG_SELECT_0_PIN, OUTPUT);

  // Arduino <-> TinyFPGA BX data bus
  // High nibble is hardwired low
  pinMode(DATA_3_PIN, INPUT);
  pinMode(DATA_2_PIN, INPUT);
  pinMode(DATA_1_PIN, INPUT);
  pinMode(DATA_0_PIN, INPUT);

  // TinyFPGA BX -> Arduino observed bus control
  pinMode(DATA_OUT_PIN, INPUT);

  // TinyFPGA BX -> Arduino observed SPI bus
  pinMode(SPI_CSB_0_PIN, INPUT);
  pinMode(SPI_CSB_1_PIN, INPUT);
  pinMode(SPI_CSB_2_PIN, INPUT);
  pinMode(SPI_CSB_3_PIN, INPUT);
  pinMode(SCK_PIN, INPUT);
  pinMode(MOSI_PIN, INPUT);

  // Arduino -> TinyFPGA BX SPI input
  pinMode(MISO_PIN, OUTPUT);

  // set to known good
  digitalWrite(RESB_PIN, HIGH);
  digitalWrite(CSB_PIN, HIGH);
  digitalWrite(RDB_PIN, HIGH);
  digitalWrite(WRB_PIN, HIGH);
  digitalWrite(MISO_PIN, LOW);
}

void loop() {
  readWriteConfig();
  delay(500);

  chipSelectDecode();
  delay(500);

  txnExample();
  delay(500);

  Serial.println("-- -- --");
  Serial.println(" ");
  delay(1000);
}

void readWriteConfig() {
  Serial.println("-- readWriteConfig --");
  setBusIdle();
  reset();

  int expected = 0x05;
  writeRegister(REG_CONF, expected);

  int actual = readRegister(REG_CONF);

  if (expected != actual) {
    Serial.println("Fail!");
    Serial.print("expected: 0x");
    Serial.print(expected, HEX);    
    Serial.print(", actual: 0x");
    Serial.println(actual, HEX);
  }
}

void chipSelectDecode() {
  Serial.println("-- chipSelectDecode --");
  setBusIdle();
  reset();

  writeRegister(REG_CONF, 0x04);
  if (!(digitalRead(SPI_CSB_0_PIN) == LOW)) {
    Serial.println("Fail! SPI_CSB_0_PIN is not low");
  }

  writeRegister(REG_CONF, 0x05);
  if (!(digitalRead(SPI_CSB_1_PIN) == LOW)) {
    Serial.println("Fail! SPI_CSB_1_PIN is not low");
  }

  writeRegister(REG_CONF, 0x06);
  if (!(digitalRead(SPI_CSB_2_PIN) == LOW)) {
    Serial.println("Fail! SPI_CSB_2_PIN is not low");
  }

  writeRegister(REG_CONF, 0x07);
  if (!(digitalRead(SPI_CSB_3_PIN) == LOW)) {
    Serial.println("Fail! SPI_CSB_3_PIN is not low");
  }
}

void txnExample() {
  int output;

  Serial.println("-- txnExample --");
  setBusIdle();
  reset();
  digitalWrite(MISO_PIN, HIGH);

  writeRegister(REG_CONF, 0x04);
  writeRegister(REG_DATA, 0x5);
  waitNotBusy();
  output = readRegister(REG_DATA);

  Serial.print("first nibble: 0x");
  Serial.println(output, HEX);    

  writeRegister(REG_DATA, 0x5);
  waitNotBusy();
  output = readRegister(REG_DATA);

  Serial.print("second nibble: 0x");
  Serial.println(output, HEX);    

  writeRegister(REG_DATA, 0x5);
  waitNotBusy();
  output = readRegister(REG_DATA);

  Serial.print("third nibble: 0x");
  Serial.println(output, HEX);

  digitalWrite(MISO_PIN, LOW);
}

int readRegister(int reg) {
  Serial.print("READ  reg=0x");
  Serial.print(reg, HEX);

  int value = 0;

  setBusIdle();
  setDataBusInput();
  setRegister(reg);

  digitalWrite(CSB_PIN, LOW);
  digitalWrite(RDB_PIN, LOW);

  delayMicroseconds(1);

  for (int i = 0; i < 4; i++) {
    if (digitalRead(DATA_PINS[i]) == HIGH) {
      value |= (1 << i);
    }
  }

  digitalWrite(RDB_PIN, HIGH);
  digitalWrite(CSB_PIN, HIGH);

  Serial.print(" value=0x");
  Serial.println(value, HEX);

  return value;
}

void writeRegister(int reg, int value) {
  Serial.print("WRITE reg=0x");
  Serial.print(reg, HEX);
  Serial.print(" value=0x");
  Serial.println(value, HEX);

  setBusIdle();
  setRegister(reg);
  setDataBusOutput();

  for (int i = 0; i < 4; i++) {
    digitalWrite(DATA_PINS[i], (value & (1 << i)) ? HIGH : LOW);
  }

  digitalWrite(CSB_PIN, LOW);
  digitalWrite(WRB_PIN, LOW);

  delayMicroseconds(1);

  digitalWrite(WRB_PIN, HIGH);
  digitalWrite(CSB_PIN, HIGH);

  setBusIdle();
  setDataBusInput();
}

void setBusIdle() {
  digitalWrite(CSB_PIN, HIGH);
  digitalWrite(RDB_PIN, HIGH);
  digitalWrite(WRB_PIN, HIGH);
}

void setRegister(int reg) {
  digitalWrite(REG_SELECT_0_PIN, (reg & 0x01) ? HIGH : LOW);
  digitalWrite(REG_SELECT_1_PIN, (reg & 0x02) ? HIGH : LOW);
}

void setDataBusInput() {
  for (int i = 0; i < 4; i++) {
    pinMode(DATA_PINS[i], INPUT);
  }
}

void setDataBusOutput() {
  for (int i = 0; i < 4; i++) {
    pinMode(DATA_PINS[i], OUTPUT);
  }
}

void reset() {
  digitalWrite(RESB_PIN, LOW);
  delay(1);
  digitalWrite(RESB_PIN, HIGH);
  delay(1);
}

void waitNotBusy() {
  while (readRegister(REG_STATUS) & 0x01) {
    delayMicroseconds(10);
  }
}