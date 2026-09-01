int Pin = 7;   // pin where your analog signal is connected
int value = 0;        // variable to store the read value
int VPrev = 0;
int voltage = 0;
void setup() {
  Serial.begin(9600); // start serial monitor
}

void loop() {
  value = digitalRead(Pin);  // read the analog value (0–1023 for 10-bit ADC)
  Serial.println(value);
  delay(500);
  // if (value < 10)
  // {
  //   // Serial.println("Distance more than 5cm or reciever not axially aligned !! Signal weak to decode !! Please align axially or move reciever closer");
  //    delay(100);                     // small delay
  // }
  // else
  // {
  //   //Serial.println(value); 
  //   if(value < (VPrev*0.75))
  //   {
  //     Serial.println("Trigger : Off");
  //    delay(100); 
  //   }
  //   else {
  //     Serial.println("Trigger : On");
  //    delay(100);
  //   }
  //   }
  //  VPrev = value;
}


