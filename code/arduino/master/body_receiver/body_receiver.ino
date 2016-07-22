/*****************************************************************
Serial_Remote_Control.ino
Write your Arduino's pins (analog or digital) or read from those
pins (analog or digital) using a remote Serial.
Jim Lindblom @ SparkFun Electronics
Original Creation Date: May 7, 2014

This sketch requires an Serial, Serial Shield and another Serial tied to
your computer (via a USB Explorer). You can use XCTU's console, or
another serial terminal program (even the serial monitor!), to send
commands to the Arduino. 


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

Hardware Hookup:
  The Arduino shield makes all of the connections you'll need
  between Arduino and Serial. Make sure the SWITCH IS IN THE 
  "DLINE" POSITION.

Development environment specifics:
    IDE: Arduino 1.0.5
    Hardware Platform: SparkFun RedBoard
    Serial Shield & Serial Series 1 1mW (w/ whip antenna)
        Serial USB Explorer connected to computer with another
          Serial Series 1 1mW connected to that.

This code is beerware; if you see me (or any other SparkFun 
employee) at the local, and you've found our code helpful, please 
buy us a round!

Distributed as-is; no warranty is given.
*****************************************************************/
// SoftwareSerial is used to communicate with the Serial
//#include <SoftwareSerial.h>
// Trying it using hardware serial instead to avoid conflict with
//  the servo library.
#include <Servo.h>
#include "configuration.h"

//comment this out to turn serial debugging off.
//With it on, you can monitor the debugging with an xbee over the
//Arduino serial monitor.
#define DEBUG 1


//SoftwareSerial Serial(2, 3); // Arduino RX, TX (Serial Dout, Din)

#define NUMPINS 14
Servo *servoPins[NUMPINS];  	//array of servo pins - to keep
				//track of them quickly.

char ReceiverChar = 'B';	//read messages with a B
char SendChar = 'T';		//send messages $T

void setup()
{
  // Initialize Serial Software Serial port. Make sure the baud
  // rate matches your Serial setting (9600 is default).
  Serial.begin(9600); 

  //make all the pointers 0
  for(uint8_t i=0; i<NUMPINS; i++){
    servoPins[i] = 0;
  }

#ifdef DEBUG
  printMenu(); // Print a helpful menu
#endif
}

void loop()
{
  //TODO: check battery voltage, shut down if it's too low.


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

  angle = constrain(angle, 0, 180);

#ifdef DEBUG
  Serial.print("Body: servo ");
  Serial.print(pin);
  Serial.print(" to <");
  Serial.println(angle);
#endif

  //todo: set this up.
  //Could do a linked list of servos, or maybe an array of servo pointers
  //array of servo pointers, populated by pin number!
  //need to check if a pointer is null... I think an unset pointer is just
  //random.

  
  //first, see if it exists
  if(servoPins[pin] == 0){
    //create the servo, since it doesn't exist :-)
    servoPins[pin] = new Servo();
    servoPins[pin] -> attach(pin);

#ifdef DEBUG
  Serial.print("Body: created servo ");
  Serial.print(pin);
  Serial.print(" at memory location ");
  Serial.println(int(servoPins[pin]));
#endif
  }

  //and finally, write the angle to the servo
  servoPins[pin] -> write(angle);
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
  Serial.print("\nBody: digital ");
  Serial.print(pin);
  Serial.print(" to ");
  Serial.println((hl ? "HIGH" : "LOW"));
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
  Serial.print("\nBody: analog ");
  Serial.print(pin);
  Serial.print(" to ");
  Serial.println(value);
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
  Serial.print("\nBody: dRead ");
  Serial.print(pin);
  Serial.print(" -> ");
  Serial.println(value);
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
  Serial.print("\nBody: aRead ");
  Serial.print(pin);
  Serial.print(" -> ");
  Serial.println(value);
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
