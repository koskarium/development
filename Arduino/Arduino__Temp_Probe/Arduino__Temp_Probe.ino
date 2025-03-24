#include "max6675.h"

// Define the MAX6675 module pins
const int thermoSO = 33;  // MISO (SO) - Data Out
const int thermoSCK = 31; // Serial Clock (SCK)

const int thermoCS1 = 49;  // Chip Select (CS)
const int thermoCS2 = 47;  // Chip Select (CS)
const int thermoCS3 = 45;  // Chip Select (CS)

// Create a MAX6675 object
MAX6675 thermocouple1(thermoSCK, thermoCS1, thermoSO);
MAX6675 thermocouple2(thermoSCK, thermoCS2, thermoSO);
MAX6675 thermocouple3(thermoSCK, thermoCS3, thermoSO);

void setup() {
  Serial.begin(9600);  // Start Serial Monitor
  delay(500);          // Allow the sensor to stabilize
  Serial.println("MAX6675 Thermocouple Test");
}

void loop() {
  // Read temperature from the sensor
  float tempF1 = thermocouple1.readFahrenheit();
  float tempF2 = thermocouple2.readFahrenheit();
  float tempF3 = thermocouple3.readFahrenheit();  
  
  // Print temperature in Celsius
  Serial.print("Temperature 1: ");  Serial.print(tempF1);  Serial.println(" °F");
  delay(500);
  Serial.print("Temperature 2: ");  Serial.print(tempF2);  Serial.println(" °F");  
  delay(500);
  Serial.print("Temperature 3: ");  Serial.print(tempF3);  Serial.println(" °F");
  delay(500);
  Serial.println("-----------------");
  delay(500);  // Wait 1 second before reading again
}
