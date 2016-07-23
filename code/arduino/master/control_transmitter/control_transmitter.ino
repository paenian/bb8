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


uint8_t pot_slop = 5;	//don't send a message unless the pot
			//reading is + or - this value

////////Pin Defines are in the configuration.h!

////////Potentiometer Variables - these are stored as bytes, converted
// when they're read.
// 0 is full reverse, 123 full stop, 255 full forward
uint8_t bodyPot[3] = {127, 127, 127}; //the third is actually binary here, to spin the body.
uint8_t bodyAtt[3] = {127, 127, 127}; //the current body attitude
uint8_t bodyPotZero[3] = {127,127,127}; //everything perfectly centered


uint8_t headPot[3] = {127,127,90}; //the third is angle, for turning the head
uint8_t headAtt[3] = {127, 127, 90}; //the current head attitude
uint8_t headPotZero[3] = {127, 127, 90}; //perfectly centered


////////Battery Voltage
// We also track battery voltage for the body, head and controller itself.
uint8_t controllerVoltage = 0;
uint8_t bodyVoltage = 0;
uint8_t headVoltage = 0;

#define MIN_VOLTAGE 2.9

//the range of voltages is restricted - and TBD.

void readBodyPot(uint8_t numSamples){
  int x=0;
  int y=0;

  //Spin?
  bodyPot[2] = 127;
  
  if(digitalRead(CONTROL_BODY_SPIN_LEFT_DPIN) == LOW){
    bodyPot[2] -= 127;
  }

  if(digitalRead(CONTROL_BODY_SPIN_RIGHT_DPIN) == LOW){
    bodyPot[2] += 127;
  }
    

  //XY movement
  for(uint8_t i=0; i<numSamples; i++){
    x += analogRead(CONTROL_BODY_POT_LR_APIN);
    y += analogRead(CONTROL_BODY_POT_FR_APIN);
  }

  //cheap average
  bodyPot[0] = map(x, 0, 1023*numSamples, 0, 255);
  bodyPot[1] = map(y, 0, 1023*numSamples, 0, 255);


  //adjust to the true zero voltage of our pots
  bodyPot[0] += constrain(bodyPotZero[0] - 127, 0, 255);
  bodyPot[1] += constrain(bodyPotZero[1] - 127, 0, 255);
}

void readBodyPot(){
  readBodyPot(1);
}

void initBodyPot(){
  pinMode(CONTROL_BODY_SPIN_LEFT_DPIN, INPUT_PULLUP);
  pinMode(CONTROL_BODY_SPIN_RIGHT_DPIN, INPUT_PULLUP);

  for(uint8_t i=0; i<3; i++)
    bodyPotZero[i] = 127;

  readBodyPot(5);

  memcpy( bodyPotZero, bodyPot, 3);
}

void initHeadPot(){
  for(uint8_t i=0; i<2; i++)
    headPotZero[i] = 127;
  headPotZero[2] = 90;
  
  readHeadPot(5);

  memcpy( headPotZero, headPot, 3);
}

void readHeadPot(){
  readHeadPot(1);
}

void readHeadPot(uint8_t numSamples){
  int x=0;
  int y=0;
  int a=0;

  for(uint8_t i=0; i<numSamples; i++){
    x += analogRead(CONTROL_HEAD_POT_LR_APIN);
    y += analogRead(CONTROL_HEAD_POT_FR_APIN);
    a += analogRead(CONTROL_HEAD_POT_A_APIN);
  }

  //cheap way to calculate the average
  headPot[0] = map(x, 0, 1023*numSamples, 0, 255);
  headPot[1] = map(y, 0, 1023*numSamples, 0, 255);
  headPot[2] = map(a, 0, 1023*numSamples, 0, 180);

  //account for the zero point
  headPot[0] += constrain(headPotZero[0] - 127, 0, 255);
  headPot[1] += constrain(headPotZero[1] - 127, 0, 255);
  headPot[2] += constrain(headPotZero[2] - 90, 0, 255);
}

bool arraysEqual(uint8_t pot[], uint8_t att[]){
  //first see if the controls have changed
  for(uint8_t i=0; i<2; i++){
    if((att[i] < pot[i]+pot_slop) && (att[i] > pot[i]-pot_slop)){
      return true; 
    }
  }

  return false;
}

//send an analog value to a pin
void sendAPin(char dest, uint8_t pin, uint8_t val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('W');
  Serial.print(pad(val, 4));
}

//send a digital value to a pin
void sendDPin(char dest, uint8_t pin, uint8_t val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('D');
  Serial.print(val);
}

//send speed and direction in a single function
void sendSpeedDir(char dest, uint8_t speed_pin, uint8_t dir_pin, uint8_t val){
  if( val >= 127 ){
    //send the speed first
    sendAPin(dest, speed_pin, map(val, 127, 255, 0, 255));

    //and then the direction
    sendDPin(dest, dir_pin, 1);
  }else{
    //speed first again
    sendAPin(dest, speed_pin, map(val, 0, 126, 0, 255));

    //and then the direction
    sendDPin(dest, dir_pin, 0);
  }
}

////////Handlers for position changes
void handleBodyPot(){
  if(arraysEqual(bodyPot, bodyAtt)){
    return;
  }

  //send the x
  bodyAtt[0] = bodyPot[0];
  sendSpeedDir(BODYCHAR, BODY_LR_SPEED_PIN, BODY_LR_DIR_PIN, bodyAtt[0]);

  //send the y

  //send the spin
}

////////BATTERY AND SHUTDOWN
// Used to safe the robot if the controller battery is low.
// The controller monitors its battery, and shuts down the body and
// head before it packs in itself.
void checkBatteryForShutdown(){

  //if battery voltage is too low, then:
  if(5 > 6){
    shutdownBody();
    shutdownHead();
    shutdownController();
  }
}

void shutdownBody(){
  //need to turn off the motors
}

void shutdownHead(){
  //probably don't need any shutdown here
}

void shutdownController(){
  //disconnect the battery so it doesn't get too low

  //first shut down the head and body - don't want it to escape.
  //todo: implement a heartbeat - make sure the body doesn't go rogue on signal loss!
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

//todo: test this function :-)
char InttoASCII(int i){
  if((i >= 0) && (i <= 9)){
    return (char)(i+0x30);
  }
  else if ((i >= 10) && (i <= 15))
    return (char)(i + 0x37); // Minus 0x41 plus 0x0A
  else
    return -1;  
}

// send a value back to the controller - called in any of the read
//  functions.
void sendValue(char sendChar, char label, int value){
  Serial.print('$'+sendChar);
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
{//TODO: update this :-/
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

void handleHeadPot(){ //xya joystick
}

void handleButtonArray(){ //funny noises in a big fancy grid
}

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

void loop()
{
  //check the battery voltage - shutdown if it's too low.
  checkBatteryForShutdown();

  readBodyPot();
  readHeadPot();
//  readButtonArray();

  handleBodyPot(); //this also handles the spin buttons
  handleHeadPot(); //xya joystick
  handleButtonArray();  //funny noises in a big fancy grid

#ifdef DEBUG
  delay(1000); //for debugging - to reduce the number of commands sent.
#endif
}
