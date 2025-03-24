void setup() {
    // Start communication with Serial Monitor (USB) at 9600 baud
    Serial.begin(9600);  
    
    // Start communication with HC-06 via Serial2 (Pins 16, 17 on Mega) at 9600 baud
    Serial2.begin(9600);  
    
    // Print message to Serial Monitor to show it's ready
    Serial.println("Bluetooth communication started!");
}

void loop() {
    // Check if there's data available from HC-06 (via Serial2)
    if (Serial2.available()) {
        char receivedChar = Serial2.read();  // Read data from HC-06
        // Print the received data to Serial Monitor
        Serial.print("Received from BT: ");
        Serial.println(receivedChar);  
    }

    // Check if there's data available from Serial Monitor (USB)
    if (Serial.available()) {
        char inputChar = Serial.read();  // Read data from Serial Monitor
        // If the character is not a newline or carriage return, send to HC-06
        if (inputChar != '\n' && inputChar != '\r') {
            Serial2.write(inputChar);  // Send data to HC-06
            Serial.print("Sent to BT: ");
            Serial.println(inputChar);  // Print the data being sent to HC-06
            delay(100);  // Add a short delay for debugging
        }
    }
}
