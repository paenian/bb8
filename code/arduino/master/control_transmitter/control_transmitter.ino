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
#include "Adafruit_Trellis.h"
#include <Wire.h>

//comment this out to turn serial debugging off.
//With it on, you can monitor the debugging with an xbee over the
//Arduino serial monitor.
#define DEBUG 1


uint8_t pot_slop = 12;	//don't send a message unless the pot
			//reading is + or - this value.  Pots are 10 bit, so 1024 values.

////////Pin Defines are in the configuration.h!

////////Potentiometer Variables - these are stored as bytes, converted
// when they're read.
// 0 is full reverse, 123 full stop, 255 full forward
int bodyPot[3] = {900, 512, 512}; //the third is actually binary here, to spin the body.
int bodyAtt[3] = {900, 512, 512}; //the current body attitude
int bodyPotZero[3] = {900, 512, 512}; //everything perfectly centered


int headPot[3] = {900,900,900}; //the third is angle, for turning the head; it's in tens of degrees.
int headAtt[3] = {900, 900, 900}; //the current head attitude
int headPotZero[3] = {900, 900, 900}; //perfectly centered

//the 16 button array is the trellis
Adafruit_Trellis array = Adafruit_Trellis();
Adafruit_TrellisSet trellis = Adafruit_TrellisSet(&array);
uint8_t tellis_INTPIN = 0;  //the interrupt pin - we're not going to use it, just poll instead
//also need to connect the SDA and SCL pins :-)

////////Battery Voltage
// We also track battery voltage for the body, head and controller itself.
int controllerVoltage = 0;
int bodyVoltage = 0;
int headVoltage = 0;

#define MIN_VOLTAGE 2.9

//the range of voltages is restricted - and TBD.

void readBodyPot(uint8_t numSamples){
  int x=0;
  int y=0;

  //Spin?
  bodyPot[2] = 512;
  
  if(digitalRead(CONTROL_BODY_SPIN_LEFT_DPIN) == LOW){
    bodyPot[2] -= 512;
  }

  if(digitalRead(CONTROL_BODY_SPIN_RIGHT_DPIN) == LOW){
    bodyPot[2] += 512;
  }
    

  //XY movement
  for(uint8_t i=0; i<numSamples; i++){
    analogRead(CONTROL_BODY_POT_LR_APIN);
    x += analogRead(CONTROL_BODY_POT_LR_APIN);
    analogRead(CONTROL_BODY_POT_FR_APIN);
    y += analogRead(CONTROL_BODY_POT_FR_APIN);
#ifdef DEBUG
  Serial.println("readBodyPot: Raw");
  Serial.print("X: ");
  Serial.println(x);
  Serial.print("Y: ");
  Serial.println(y);
#endif
  }

  //cheap average
  bodyPot[0] = map(x, 0, 1023*numSamples, 0, 1800);
  bodyPot[1] = map(y, 0, 1023*numSamples, 0, 1024);


  //adjust to the true zero voltage of our pots
  bodyPot[0] = constrain(bodyPot[0] + (bodyPotZero[0] - 900), 0, 1800);
  bodyPot[1] = constrain(bodyPot[1] + (bodyPotZero[1] - 512), 0, 1024);

#ifdef DEBUG
  Serial.println("readBodyPot: Values");
  Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(bodyPot[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");
#endif
}

void readBodyPot(){
  readBodyPot(1);
}

void initTrellis(){
  //need to put a pullup on the int pin, if we decide to use it
  trellis.begin(0x70);
  
  //do a little LED dance
  for(uint8_t i=0; i<4; i++){
    for(uint8_t j=0; j<4; j++){
      trellis.setLED(i*4+j);
      trellis.writeDisplay();
      delay(100);
    }
  }
  
  //shut them off.  Notice the different style - wondering if they're in order :-)
  for(uint8_t i=0; i<16; i++){
    trellis.clrLED(i);
    trellis.writeDisplay();
    delay(50);
  }
}

void initBodyPot(){
  pinMode(CONTROL_BODY_SPIN_LEFT_DPIN, INPUT_PULLUP);
  pinMode(CONTROL_BODY_SPIN_RIGHT_DPIN, INPUT_PULLUP);

  for(uint8_t i=1; i<3; i++)
    bodyPotZero[i] = 512;
  bodyPotZero[0] = 900;

  readBodyPot(5);

  memcpy( bodyPotZero, bodyPot, sizeof(bodyPotZero));
  memcpy( bodyAtt, bodyPot, sizeof(bodyAtt));
}

void initHeadPot(){
  for(uint8_t i=0; i<3; i++)
    headPotZero[i] = 900;

  readHeadPot(5);

  memcpy( headPotZero, headPot, sizeof(headPotZero));
  memcpy( headAtt, headPot, sizeof(headAtt));
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
  headPot[0] = map(x, 0, 1023*numSamples, 0, 1800);
  headPot[1] = map(y, 0, 1023*numSamples, 0, 1800);
  headPot[2] = map(a, 0, 1023*numSamples, 0, 1800);

  //account for the zero point
  headPot[0] = constrain(headPot[0] + (headPotZero[0] - 900), 0, 1800);
  headPot[1] = constrain(headPot[1] + (headPotZero[1] - 900), 0, 1800);
  headPot[2] = constrain(headPot[2] + (headPotZero[2] - 900), 0, 1800);
}

void readButtonArray(){
  trellis.readSwitches();
}

bool arraysDifferent(int pot[], int att[]){
  #ifdef DEBUG
  Serial.println("ArraysDifferent: Values");
  Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(pot[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");

    Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(att[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");
  
#endif

  //first see if the controls have changed
  for(uint8_t i=0; i<2; i++){
    if((att[i] > pot[i]+pot_slop) || (att[i] < pot[i]-pot_slop)){
      return true; 
    }
  }

#ifdef DEBUG
  Serial.println("ArraysDifferent: returning false");
#endif

  return false;
}

//send an analog value to a pin
void sendPWMPin(char dest, uint8_t pin, int val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('W');
  Serial.print(InttoASCII(pin));
  Serial.print(pad(val, 3));
}

//send a digital value to a pin
void sendDPin(char dest, uint8_t pin, int val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('D');
  Serial.print(InttoASCII(pin));
  Serial.print(val);
}

//send a servo angle to a pin
void sendSPin(char dest, uint8_t pin, int val){
  Serial.print('$');
  Serial.print(dest);
  Serial.print('S');
  Serial.print(InttoASCII(pin));
  Serial.print(pad(val, 3));
}

//send speed and direction in a single function
void sendSpeedDir(char dest, uint8_t speed_pin, uint8_t dir_pin, int val){
  if( val >= 512 ){
    //send the speed first
    sendPWMPin(dest, speed_pin, map(val, 512, 1024, 0, 255));

    //and then the direction
    sendDPin(dest, dir_pin, 1);
  }else{
    //speed first again
    sendPWMPin(dest, speed_pin, map(val, 0, 511, 0, 255));

    //and then the direction
    sendDPin(dest, dir_pin, 0);
  }
}

//send angle - which is 0 to 1800
void sendAngle(char dest, uint8_t pin, int val){
  sendSPin(dest, pin, map(val, 0, 1800, 0, 180));
}

////////Handlers for position changes
void handleBodyPot(){
  if(!arraysDifferent(bodyPot, bodyAtt)){
    return;
  }

#ifdef DEBUG
  Serial.println("handleBodyPot: Pot Changed");
#endif

  //if any of them updated, great!  Update 'em all.
  memcpy( bodyAtt, bodyPot, sizeof(bodyAtt));


  //and then send them all, for good measure.
  //send the y - forward or reverse speed
  sendSpeedDir(BODYCHAR, BODY_FR_SPEED_PIN, BODY_FR_DIR_PIN, bodyAtt[1]);

  //send the x - which is a tilt, so gets converted to an angle
  sendAngle(BODYCHAR, BODY_LR_ANGLE_PIN, bodyAtt[0]);

  //send the spin
  sendSpeedDir(BODYCHAR, BODY_SPIN_SPEED_PIN, BODY_SPIN_DIR_PIN, bodyAtt[2]);
}

void handleHeadPot(){ //xya joystick
  if(!arraysDifferent(headPot, headAtt)){
    return;
  }

#ifdef DEBUG
  Serial.println("handleHeadPot: Pot Changed");
#endif

  //if any of them updated, great!  Update 'em all.
  memcpy( headAtt, headPot, sizeof(headAtt));

  //and then send them all, for good measure - this prevents creep,
  //without evaluating the axes individually.

  //send the x - which is a left/right tilt, so gets converted to an angle
  sendAngle(BODYCHAR, HEAD_LR_ANGLE_PIN, bodyAtt[0]);
  
  //send the y - front or rear angle
  sendAngle(BODYCHAR, HEAD_FR_ANGLE_PIN, bodyAtt[1]);

  //send the spin
  sendAngle(BODYCHAR, HEAD_SPIN_ANGLE_PIN, bodyAtt[2]);
}

void handleButtonArray(){ //funny noises in a big fancy grid
  //go through the button array, see which was pressed
  //these are the sound buttons :-)
  for(uint8_t i=0; i<12; i++){
    if(trellis.justPressed(i)){
      //sendTrellisButton(i);
    }
  }
  
  //the other four buttons are indicators, and the kill switch.
  
}

void shutdownButtonArray(){
  //simply turn off all the LEDs - this is to prevent battery drain when the controller batteries are low.
  for(uint8_t i=0; i<16; i++){
    trellis.clrLED(i);
  }
  
  //here's an idea: 12 buttons, and 4 status LEDs that look like buttons :-)
  //battery for the head, body and controller - blink red if low?
  //last LED open for now :-)
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
  //turn all LEDs off
  shutdownButtonArray();
  
  //disconnect the battery so it doesn't get too low
  delay(10000);

  //first shut down the head and body - don't want it to escape.
  //todo: implement a heartbeat for the body
  //OR we could do it like gcode commands - so that the body executes the last command, for X seconds?
  //just have the body use a 2-second timeout - if no commands recieved, kill the motors.
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

void setup()
{
  // Initialize Serial Software Serial port. Make sure the baud
  // rate matches your Serial setting (9600 is default).
  Serial.begin(9600); 

  //initialize the trellis
  initTrellis();

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
#ifdef DEBUG
  Serial.println("Loop Start"); // Print a helpful menu
#endif
  //check the battery voltage - shutdown if it's too low.
  checkBatteryForShutdown();

  readBodyPot();
  readHeadPot();
  readButtonArray();

  handleBodyPot(); //this also handles the spin buttons
  handleHeadPot(); //xya joystick
  handleButtonArray();  //funny noises in a big fancy grid

#ifdef DEBUG
  Serial.println("Loop End - pause 3 sec");
  delay(3000); //for debugging - to reduce the number of commands sent.
#endif
}
