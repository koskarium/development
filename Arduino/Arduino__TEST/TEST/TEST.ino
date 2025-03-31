void setup() {
    Serial.begin(9600);    // Start communication with Serial Monitor (USB)
    Serial2.begin(9600);   // Start communication with HC-06 via Serial2 (Pins 16, 17 on Mega)
    Serial.println("Bluetooth communication started!");
}

void loop() {
    // Check if there's data available from HC-06 (via Serial2)
    if (Serial2.available()) {
        char receivedChar = Serial2.read();  // Read data from HC-06
        Serial.print("Received from BT: ");  // Print received character to Serial Monitor
        Serial.println(receivedChar);

        // Respond based on the received character
        if (receivedChar == 'A') {
            Serial2.println("You sent A!");  // Respond back with a message
            Serial.print("Sent to BT: You sent A!");
        }
        else if (receivedChar == 'B') {
            Serial2.println("You sent B!");
            Serial.print("Sent to BT: You sent B!");
        }
        else if (receivedChar == 'C') {
            Serial2.println("You sent C!");
            Serial.print("Sent to BT: You sent C!");
        }
        else {
            Serial2.println("Unknown letter.");
            Serial.print("Sent to BT: Unknown letter.");
        }
    }

    // Check if there's data available from Serial Monitor (USB)
    if (Serial.available()) {
        char inputChar = Serial.read();  // Read data from Serial Monitor
        if (inputChar != '\n' && inputChar != '\r') {
            Serial2.write(inputChar);  // Send data to HC-06
            Serial.print("Sent to BT: ");
            Serial.println(inputChar);  // Print data sent to HC-06
        }
    }
}
