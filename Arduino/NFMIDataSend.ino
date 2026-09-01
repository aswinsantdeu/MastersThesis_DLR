const int txPin = 6; // to 74HC08 input

void setup() {
  pinMode(txPin, OUTPUT);
}

void loop() {
  //sendByte(0xA5);  // example patternde
  digitalWrite(txPin, LOW);
  delay(250);
  digitalWrite(txPin, HIGH);
  delay(250);
}

// void sendByte(uint8_t b) {
//   for (int i = 0; i < 8; i++) {
//     bool bitVal = b & (1 << (7 - i));
//     digitalWrite(txPin, bitVal ? HIGH : LOW);
//     delayMicroseconds(5000); // bit period, e.g. 1 kHz baud
//   }


// TX on D0 (hardware UART)
// const int TX_PIN = 0;  

// // Simple CRC-8 (polynomial 0x07)
// uint8_t crc8(const uint8_t* d, size_t n) {
//   uint8_t c = 0;
//   for (size_t i=0;i<n;i++){
//     c ^= d[i];
//     for (int b=0;b<8;b++)
//       c = (c & 0x80) ? (c<<1) ^ 0x07 : (c<<1);
//   }
//   return c;
// }

// void setup() {
//   pinMode(TX_PIN, OUTPUT);
//   Serial.begin(600);   // use hardware UART
//   delay(50);
// }

// void loop() {
//   const char* msg = "HELLO, UNO!";

//   // Preamble
//   for (int i=0;i<20;i++) Serial.write(0x55);

//   // Frame: <len><payload...><crc>
//   uint8_t len = (uint8_t)strlen(msg);
//   Serial.write(len);
//   Serial.write((const uint8_t*)msg, len);
//   uint8_t c = crc8((const uint8_t*)msg, len);
//   Serial.write(c);

//   delay(200);
// }
