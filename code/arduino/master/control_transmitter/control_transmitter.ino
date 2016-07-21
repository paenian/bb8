/*****************************************************************
This is the Control side of a remote control using a modified
version of the XBEE remote control code.

It sends commands in response to controller input, and transmits
to both the body and the head.



This sketch has been augmented by Paul Chase to allow for multiple
receivers.  Commands must be preceeded with $ to distinguish them
from comments, then the single-character ReceiverChar.

Also added the ability to control servos; this requires an array
of servo pointers, initially null, but populated as servos are
used.


Example usage (send these commands from your computer terminal):
    $Bw#nnn - analog WRITE pin # to nnn
      e.g. $Bw6088 - write pin 6 to 88
    $Bd#v   - digital WRITE pin # to v
      e.g. $Bddh - Write pin 13 High
    $Br#    - digital READ digital pin #
      e.g. $Br3 - Digital read pin 3
    $Ba#    - analog READ analog pin #
      e.g. $Ba0 - Read analog pin 0
    $Bs#aaa - servo WRITE pin # to angle aaa
      e.g. $Bs5180 - turn servo on pin five to 180 degrees

    - Use hex values for pins 10-13
    - Upper or lowercase works
    - Use 0, l, or L to write LOW
    - Use 1, h, or H to write HIGH

This code is beerware; if you see me (or any other SparkFun 
employee) at the local, and you've found our code helpful, please 
buy us a round!  Paul Chase would like a beer too :-)

Distributed as-is; no warranty is given.
*****************************************************************/
// SoftwareSerial is used to communicate with the Serial
//#include <SoftwareSerial.h>
// Trying it using hardware serial instead to avoid conflict with
//  the servo library.
#include "configuration.h"

//comment this out to turn serial debugging off.
//With it on, you can monitor the debugging with an xbee over the
//Arduino serial monitor.
#define DEBUG 1


char BodySendChar = 'B';	//messages with $B go to the body
char ReceiverChar = 'T';		//messages with $T are for us


uint8_t pot_slop = 5;	//don't send a message unless the pot
			//reading is + or - this value

////////Pin Defines are in the configuration.h!

////////Potentiometer Variables - these are stored as bytes, converted
// when they're read.
// 0 is full reverse, 123 full stop, 255 full forward
uint8_t bodyPotX = 123;
uint8_t bodyPotY = 123;

uint8_t headPotX = 123;
uint8_t headPotY = 123;
uint8_t headPotA = 90;


////////Battery Voltage
// We also track battery voltage for the body, head and controller itself.
uint8_t controllerVoltage = 0;
uint8_t bodyVoltage = 0;
uint8_t headVoltage = 0;

//the range of voltages is restricted - and TBD.

void setup()
{
  // Initialize Serial Software Serial port. Make sure the baud
  // rate matches your Serial setting (9600 is default).
  Serial.begin(9600); 


  //Initialize the potentiometers
  //body pot: two axes
  initBodyPot();

  //head pot: three axes
  initHeadPot();

#ifdef DEBUG
  printMenu(); // Print a helpful menu
#endif
}

void initBodyPot(){
  readBodyPot(5);
}

void readBodyPot(){
  readBodyPot(1);
}

void readBodyPot(uint8_t numSamples);
  int x=0;
  int y=0;

  for(uint8_t i=0, i<numSamples, i++){
    x += analogRead(BODY_POT_X_PIN);
    y += analogRead(BODY_POT_Y_PIN);
  }

  bodyPotX = map(x, 0, 1023*numSamples, 0, 255);
  bodyPotY = map(y, 0, 1023*numSamples, 0, 255);
}

void initHeadPot(){
  readHeadPot(5);
}

void readHeadPot(){
  readHeadPot(1);
}

void readHeadPot(uint8_t numSamples){
  int x=0;
  int y=0;
  int a=0;

  for(uint8_t i=0, i<numSamples, i++){
    x += analogRead(HEAD_POT_X_PIN);
    y += analogRead(HEAD_POT_Y_PIN);
    a += analogRead(HEAD_POT_A_PIN);
  }

  headPotX = map(x, 0, 1023*numSamples, 0, 255);
  headPotY = map(y, 0, 1023*numSamples, 0, 255);
  headPotA = map(a, 0, 1023*numSamples, 0, 180);
}

void loop()
{
  // In loop() we continously check to see if a command has been
  //  received.
  if (Serial.available())
  {
    char c = Serial.read();
    if(c == '$'){  //commands start with a $ sign
      while(Serial.available() < 1); //wait for the next character
      c = Serial.read();
      if( c == ReceiverChar){  //the code matches
        while(Serial.available() < 1);  //wait for the next character
	c = Serial.read(); //finally we get the command
        switch (c){
          case 'w':      // If received 'w'
          case 'W':      // or 'W'
            writeAPin(); // Write analog pin
          break;
          case 'd':      // If received 'd'
          case 'D':      // or 'D'
            writeDPin(); // Write digital pin
          break;
          case 'r':      // If received 'r'
          case 'R':      // or 'R'
            readDPin();  // Read digital pin
          break;
          case 'a':      // If received 'a'
          case 'A':      // or 'A'
            readAPin();  // Read analog pin
          break;
          case 's':
          case 'S':      //servo pin
            writeSPin();
          break;
        }
      }
    }
  }
}

// write servo pin
// send S or s to enter
// then pin #
// then 3 digit angle
void writeSPin()
{
  while (Serial.available() < 4);	//this just waits til the digits come in

  char pin  = ASCIItoInt(Serial.read());
  int angle = ASCIItoInt(Serial.read()) * 100 +
              ASCIItoInt(Serial.read()) * 10 +
	      ASCIItoInt(Serial.read());

  angle = constrain(value, 0, 180);

#ifdef DEBUG
  Serial.println("Body: servo "+pin+" to <"+angle);
#endif

  //todo: set this up.

}

// Write Digital Pin
// Send a 'd' or 'D' to enter.
// Then send a pin #
//   Use numbers for 0-9, and hex (a, b, c, or d) for 10-13
// Then send a value for high or low
//   Use h, H, or 1 for HIGH. Use l, L, or 0 for LOW
void writeDPin()
{
  while (Serial.available() < 2)
    ; // Wait for pin and value to become available
  char pin = Serial.read();
  char hl = ASCIItoHL(Serial.read());

#ifdef DEBUG
  // Print a message to let the control know of our intentions:
  Serial.print("\nBody: digital "+pin" to "+(hl ? "HIGH" : "LOW"));
#endif

  pin = ASCIItoInt(pin); // Convert ASCCI to a 0-13 value
  pinMode(pin, OUTPUT); // Set pin as an OUTPUT
  digitalWrite(pin, hl); // Write pin accordingly
}

// Write Analog Pin
// Send 'w' or 'W' to enter
// Then send a pin #
//   Use numbers for 0-9, and hex (a, b, c, or d) for 10-13
//   (it's not smart enough (but it could be) to error on
//    a non-analog output pin)
// Then send a 3-digit analog value.
//   Must send all 3 digits, so use leading zeros if necessary.
void writeAPin()
{
  while (Serial.available() < 4)
    ; // Wait for pin and three value numbers to be received
  char pin = Serial.read(); // Read in the pin number
  int value = ASCIItoInt(Serial.read()) * 100; // Convert next three
  value += ASCIItoInt(Serial.read()) * 10;     // chars to a 3-digit
  value += ASCIItoInt(Serial.read());          // number.
  value = constrain(value, 0, 255); // Constrain that number.

#ifdef DEBUG
  // Print a message to let the control know of our intentions:
  Serial.println("\nBody: analog "+pin+" to "+value);
#endif

  pin = ASCIItoInt(pin); // Convert ASCCI to a 0-13 value
  pinMode(pin, OUTPUT); // Set pin as an OUTPUT
  analogWrite(pin, value); // Write pin accordingly
}

// Read Digital Pin
// Send 'r' or 'R' to enter
// Then send a digital pin # to be read
// The Arduino will print the digital reading of the pin to Serial.
void readDPin()
{
  int value = 0;

  while (Serial.available() < 1); // Wait for pin # to be available.

  char pin = Serial.read(); // Read in the pin value

  pin = ASCIItoInt(pin); // Convert pin to 0-13 value
  pinMode(pin, INPUT); // Set as input
  
  value = digitalRead(pin);

  //send the character
  sendValue('D', value);


//print a debug message
#ifdef DEBUG
  Serial.println("\nBody: dRead "+pin+" -> "+value);
#endif
}

// Read Analog Pin
// Send 'a' or 'A' to enter
// Then send an analog pin # to be read.
// The Arduino will print the analog reading of the pin to Serial.
void readAPin()
{
  int value = 0;

  while (Serial.available() < 1)
    ; // Wait for pin # to be available
  char pin = Serial.read(); // read in the pin value

  pin = ASCIItoInt(pin); // Convert pin to 0-6 value

  value = analogRead(pin);

  //send it back
  sendValue('A', value);

  //debug
#ifdef DEBUG
  Serial.println("\nBody: aRead "+pin+" -> "+value);
#endif
}

// ASCIItoHL
// Helper function to turn an ASCII value into either HIGH or LOW
int ASCIItoHL(char c)
{
  // If received 0, byte value 0, L, or l: return LOW
  // If received 1, byte value 1, H, or h: return HIGH
  if ((c == '0') || (c == 0) || (c == 'L') || (c == 'l'))
    return LOW;
  else if ((c == '1') || (c == 1) || (c == 'H') || (c == 'h'))
    return HIGH;
  else
    return -1;
}

// ASCIItoInt
// Helper function to turn an ASCII hex value into a 0-15 byte val
int ASCIItoInt(char c)
{
  if ((c >= '0') && (c <= '9'))
    return c - 0x30; // Minus 0x30
  else if ((c >= 'A') && (c <= 'F'))
    return c - 0x37; // Minus 0x41 plus 0x0A
  else if ((c >= 'a') && (c <= 'f'))
    return c - 0x57; // Minus 0x61 plus 0x0A
  else
    return -1;
}

// send a value back to the controller - called in any of the read
//  functions.
void sendValue(char label, int value){
  Serial.print('$'+SendChar);
  Serial.print(label);
  if(label == 'A'){
    Serial.print(pad(value, 4));
  }else{
    Serial.print(value);
  }
}

String pad(int number, byte length){
  String ret = "";
  int curMax = 10;
  for(byte i=1; i<length; i++){
    if(number < curMax)
      ret += "0";

    curMax *= 10;
  }

  return ret + number;
}

// printMenu
// A big ol' string of Serial prints that print a usage menu over
// to the other Serial.
void printMenu()
{
#ifdef DEBUG
  // Everything is "F()"'d -- which stores the strings in flash.
  // That'll free up SRAM for more importanat stuff.
  Serial.println();
  Serial.println(F("Arduino Serial Remote Control!"));
  Serial.println(F("============================"));
  Serial.println(F("Usage: "));
  Serial.println(F("w#nnn - analog WRITE pin # to nnn"));
  Serial.println(F("  e.g. w6088 - write pin 6 to 88"));
  Serial.println(F("d#v   - digital WRITE pin # to v"));
  Serial.println(F("  e.g. ddh - Write pin 13 High"));
  Serial.println(F("r#    - digital READ digital pin #"));
  Serial.println(F("  e.g. r3 - Digital read pin 3"));
  Serial.println(F("a#    - analog READ analog pin #"));
  Serial.println(F("  e.g. a0 - Read analog pin 0"));
  Serial.println();
  Serial.println(F("- Use hex values for pins 10-13"));
  Serial.println(F("- Upper or lowercase works"));
  Serial.println(F("- Use 0, l, or L to write LOW"));
  Serial.println(F("- Use 1, h, or H to write HIGH"));
  Serial.println(F("============================"));  
  Serial.println();
#endif
}
