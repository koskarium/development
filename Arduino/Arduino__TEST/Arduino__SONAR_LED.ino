// For the LED set up in series with the 200 Ohm resistor 
// HC-SR04 is separate from it


// Define the pins
const int trigPin = 39;  // Trigger pin for HC-SR04
const int echoPin = 37;  // Echo pin for HC-SR04
const int ledPin = 10;   // LED pin

// Variables to store the distance and duration
long duration;
int distance;
const int threshold = 10;  // Distance threshold in cm to trigger the LED

void setup() {
  // Start serial communication
  Serial.begin(9600);

  // Set pin modes
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(ledPin, OUTPUT);  // Set LED pin as an output
}

void loop() {
  // Clear the trigPin by setting it LOW for a brief moment
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  // Send a HIGH pulse to trigger the ultrasonic sensor
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Measure the duration of the pulse from the echoPin
  duration = pulseIn(echoPin, HIGH);

  // Calculate the distance in centimeters
  distance = duration * 0.0344 / 2;

  // Print the distance to the Serial Monitor
  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");

  // If the distance is less than the threshold, turn on the LED
  if (distance < threshold) {
    digitalWrite(ledPin, HIGH);  // Turn the LED on
  } else {
    digitalWrite(ledPin, LOW);  // Turn the LED off
  }

  // Wait a bit before the next reading
  delay(500);
}
