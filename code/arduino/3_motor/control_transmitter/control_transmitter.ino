/*****************************************************************
This is the Control side of a remote control using a modified
version of the XBEE remote control code.

It sends commands in response to controller input, and transmits
to both the body and the head.


This sketch has been augmented by Paul Chase to allow for multiple
receivers.  Commands must be preceeded with $ to distinguish them
from comments, then the single-character ReceiverChar.


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
//#define DEBUG 1

#define MAX_SERIAL_WAIT 250
#define MAX_CHARS_TO_READ 25

uint8_t pot_slop = 12;	//don't send a message unless the pot
			//reading is + or - this value.  Pots are 10 bit, so 1024 values.

////////Pin Defines are in the configuration.h!

////////Potentiometer Variables - these are stored as bytes, converted
// when they're read.
// 0 is full reverse, 1023 full stop, 512 full forward
int bodyPot[3] = {512, 512, 512}; //the third is actually binary here, to spin the body.
int bodyAtt[3] = {512, 512, 512}; //the current body attitude
int bodyPotZero[3] = {512, 512, 512}; //everything perfectly centered


int headPot[3] = {512, 512, 512}; //the third is angle, for turning the head.
int headAtt[3] = {512, 512, 512}; //the current head attitude
int headPotZero[3] = {512, 512, 512}; //perfectly centered

unsigned long lastHeartbeat = 0;
#define HEARTBEAT_TIMER 1000

//the 16 button array is the trellis
Adafruit_Trellis array = Adafruit_Trellis();
Adafruit_TrellisSet trellis = Adafruit_TrellisSet(&array);
uint8_t tellis_INTPIN = 0;  //the interrupt pin - we're not going to use it, just poll instead
//also need to connect the SDA and SCL pins :-)

////////Battery Voltage
//batteries can't be below MIN_VOLTAGE
//that's just over 3 volts in 10 bit.
//also, possibly, the number of the beast.
#define MIN_VOLTAGE 616

//and we check them every INTERVAL
#define BATTERY_CHECK_INTERVAL 10000

// We track battery voltage for the body, head and controller itself.
int controllerVoltage = MIN_VOLTAGE + 1;
int bodyVoltage = MIN_VOLTAGE + 1;
int headVoltage = MIN_VOLTAGE + 1;

uint8_t headDisabled = 0;
uint8_t bodyDisabled = 0;

#define allStopLedIndex 12
#define controllerLedIndex 13
#define bodyLedIndex 14
#define headLedIndex 15



unsigned long lastBatteryCheck = millis();


void readBodyPot(uint8_t numSamples){
  int x=0;
  int y=0;

  //Spin? This isn't used yet... or maybe ever.. so we read it as 512.
  bodyPot[2] = 512;
  
  //XY movement
  for(uint8_t i=0; i<numSamples; i++){
    analogRead(CONTROL_BODY_POT_LR_APIN);
    x += analogRead(CONTROL_BODY_POT_LR_APIN);
    analogRead(CONTROL_BODY_POT_FR_APIN);
    y += analogRead(CONTROL_BODY_POT_FR_APIN);
  }
  
#ifdef DEBUG
  Serial.println();
  Serial.println("readBodyPot: Raw");
  Serial.print("X: ");
  Serial.println(x);
  Serial.print("Y: ");
  Serial.println(y);
#endif

  //cheap average
  bodyPot[0] = map(x, 0, 1023*numSamples, 1, 1023);
  bodyPot[1] = map(y, 0, 1023*numSamples, 1, 1023);

  //adjust to the true zero voltage of our pots
  bodyPot[0] = constrain(bodyPot[0] + (bodyPotZero[0] - 512), 1, 1023);
  bodyPot[1] = constrain(bodyPot[1] + (bodyPotZero[1] - 512), 1, 1023);

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
  readBodyPot(2);
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

  for(uint8_t i=0; i<3; i++)
    bodyPotZero[i] = 512;

  readBodyPot(5);

  memcpy( bodyPotZero, bodyPot, sizeof(bodyPotZero));
  memcpy( bodyAtt, bodyPot, sizeof(bodyAtt));
}

void initHeadPot(){
  for(uint8_t i=0; i<3; i++)
    headPotZero[i] = 512;

  readHeadPot(5);

  memcpy( headPotZero, headPot, sizeof(headPotZero));
  memcpy( headAtt, headPot, sizeof(headAtt));
}

void initPins(){
  //set each pin to input/output as needed.
  
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
  headPot[0] = map(x, 0, 1023*numSamples, 1, 1023);
  headPot[1] = map(y, 0, 1023*numSamples, 1, 1023);
  headPot[2] = map(a, 0, 1023*numSamples, 1, 1023);

  //account for the zero point
  headPot[0] = constrain(headPot[0] + (headPotZero[0] - 512), 1, 1023);
  headPot[1] = constrain(headPot[1] + (headPotZero[1] - 512), 1, 1023);
  headPot[2] = constrain(headPot[2] + (headPotZero[2] - 512), 1, 1023);
}

void readButtonArray(){
  trellis.readSwitches();
}

bool arraysDifferent(int pot[], int att[]){
#ifdef DEBUG2
  Serial.println();
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

#ifdef DEBUG2
  Serial.println("ArraysDifferent: returning false");
#endif

  return false;
}

/*********** NEW PROTOCOL - do not use other send functions. *******/
void sendBody(){
#ifdef DEBUG
  Serial.println("sendBody: raw attitude");
  Serial.print("{ ");
  for(uint8_t i = 0; i<3; i++){
    Serial.print(bodyAtt[i]);
    Serial.print("\t, ");
  }
  Serial.println("}");
#endif

  //looks like $BCBX###Y###
  int x = map(bodyAtt[0], 1, 1023, 1, 511);
  int y = map(bodyAtt[1], 1, 1023, 1, 511);

#ifdef DEBUG
  Serial.println("sendBody: Values");
  Serial.print("{ \t");
  Serial.print(x);
  Serial.print("\t, ");
  Serial.print(y);
  Serial.println(" }");
#endif

#ifdef DEBUG
  Serial.println("sendBody: padded");
  Serial.print("{ \t");
  Serial.print(pad(x,3));
  Serial.print("\t, ");
  Serial.print(pad(y,3));
  Serial.println(" }");
#endif


  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("BX");
  Serial.print(pad(x, 3));
  Serial.print("Y");
  Serial.println(pad(y, 3));
}

void sendHead(){
  //looks like $BCHX###Y###A###
  uint8_t x = map(headAtt[0], 1, 1023, 1, 511);
  uint8_t y = map(headAtt[1], 1, 1023, 1, 511);
  uint8_t a = map(headAtt[2], 1, 1023, 1, 511);

  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("HX");
  Serial.print(pad(x, 3));
  Serial.print("Y");
  Serial.print(pad(y, 3));
  Serial.print("A");
  Serial.println(pad(y, 3));
}

void sendStop(){
  //need to send two - to the head and the body.
  //Looks like $BCSTOP and $HCSTOP
  //
  //Only the first character (S) is actually read.  The rest is for debugging.
  //If a human can read the chatter, a human can debug the chatter :-)
  
  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print("STOP");

  Serial.print('$');
  Serial.print(HEADCHAR);
  Serial.print(CONTROLCHAR);
  Serial.println("STOP");
}

void sendHeartbeat(){
  //not sure what to send as a heartbeat, or how to handle it.  For now, we'll just send the current head and body positions.
  sendBody();
  sendHead();

  //the heartbeat can then be implemented entirely in the body.  The head doesn't get a heartbeat, cuz it doesn't do anything crazy.
  //like... move around.
  //The point here is that if the body loses signal, it'll stop running away eventually.
}

void sendTrellisButton(uint8_t button){
  //these go to the head
  //looks like $HP##
  Serial.print('$');
  Serial.print(HEADCHAR);
  Serial.print(CONTROLCHAR);
  Serial.print('P');
  Serial.println(pad(button, 2));
}

void requestBodyBattery(){
  Serial.print('$');
  Serial.print(BODYCHAR);
  Serial.print(CONTROLCHAR);
  Serial.println("RBATT");
}

void requestHeadBattery(){
  Serial.print('$');
  Serial.print(HEADCHAR);
  Serial.print(CONTROLCHAR);
  Serial.println("RBATT");
}

//get results from battery questions, accept commands
//right now, the battery's the only thing we care about.
//This function will consume ONE command, or MAX_CHARS_TO_READ characters before returning.
void handleXbee(){
  
  //this will consume many characters - maybe too many.
  //So we set a max.
  int chars = 0;
  char sender = CONTROLCHAR;  //set it to us, in case it becomes necessary
  
  //WAIT for at least 4 characters to be in the buffer before doing anything!
  while((Serial.available() > 3) && (chars < MAX_CHARS_TO_READ)){
    char c = Serial.read();  //three chars left
    chars++;
    
    if(c == '$'){  //control char
      c = Serial.read();  //two chars left
      chars++;
      
      if(c == CONTROLCHAR){  //to char - we only care if it's for us
        sender = Serial.read();  //record who sent the message
        chars++;
        
        c = Serial.read();  //this is the last guaranteed char
        chars++;
        
        switch(c){
          case 'S': //stop char!
            if(sender == BODYCHAR){
              bodyDisabled = 1;
            }
            if(sender == HEADCHAR){
              headDisabled = 1;
            }
          return;
          
          case 'V': //returning a value to read
            if(sender == BODYCHAR){
              bodyVoltage = readVoltage();
            }
            if(sender == HEADCHAR){
              headVoltage = readVoltage();
            }
          return;
        }
      }
    }
    
    if(chars > MAX_CHARS_TO_READ){
      return;
    }
  }
}

//simple code to block while reading the serial bus.
char readSerialBlocking(){
  unsigned long start = millis();
  
  while(Serial.available() == 0){
    if(millis()-start > MAX_SERIAL_WAIT){
#ifdef DEBUG
      Serial.println("Timeout waiting for character!");
#endif
      return -1;
    }
  }
  
  return Serial.read();
}

int readVoltage(){
  //grab three chars from the serial, and convert them to an int
  long voltage = 100*ASCIItoInt(readSerialBlocking());
  voltage += 10*ASCIItoInt(readSerialBlocking());
  voltage += 1*ASCIItoInt(readSerialBlocking());
  
  return voltage;
}


/*********** END NEW PROTOCOL - do not use other send functions. *******/

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

  //let the body know what's up
  sendBody();
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
  sendHead();
}

void handleButtonArray(){ //funny noises in a big fancy grid
  delay(30);
  if(trellis.readSwitches()){
    //go through the button array, see which was pressed
    //these are the sound buttons :-)
    for(uint8_t i=0; i<12; i++){
      if(trellis.justPressed(i)){
        sendTrellisButton(i);
        trellis.setLED(i);
        delay(100);
      }
      if(trellis.justReleased(i)){
        trellis.clrLED(i);
        delay(100);
      }
    }
  
    //the other four buttons are indicators, and the kill switch.
    //check for disabled stuff, and flash the appropriate button.
    if(trellis.justPressed(allStopLedIndex)){
      sendStop();
      shutdownController(); 
    }
  
    //the other buttons can't be pressed yet, but they blink if something's dead.
    if(headDisabled == 1){
      trellis.setLED(headLedIndex);
      trellis.writeDisplay();
      delay(125);
      trellis.clrLED(headLedIndex);
      trellis.writeDisplay(); 
    }
  
    if(bodyDisabled == 1){
      trellis.setLED(bodyLedIndex);
      trellis.writeDisplay();
      delay(125);
      trellis.clrLED(bodyLedIndex);
      trellis.writeDisplay();
    }

    trellis.writeDisplay();
  }
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

int readBattery(uint8_t numSamples){
  int voltage = 0;
  
  for(uint8_t i = 0; i<numSamples; i++){
    voltage += analogRead(CONTROL_BATTERY_MONITOR_APIN);
  }
  
  return map(voltage, 0, 1023*numSamples, 0, 1023);
}

//reads the controller's voltage
int readBattery(){
  return readBattery(3);
}

// Used to safe the robot if the controller battery is low.
// The controller monitors its battery, and shuts down the body and
// head before it packs in itself.
void checkBatteryForShutdown(){

  //if the controller's low, everything has to go down with it.
  if(controllerVoltage < MIN_VOLTAGE){
    sendStop();
    shutdownButtonArray();

    //blink the right trellis thinger annoyingly
    for(uint8_t i=0; i<100; i++){
      if(i%0 == 0){
        trellis.setLED(controllerLedIndex);
      }else{
        trellis.clrLED(controllerLedIndex);
      }

      delay(50);
    }

    shutdownController();
  }

  //if the body's low, blink the body, but we don't need to do anything else
  //the body will prevent itself from moving on low batt
  if(bodyVoltage < MIN_VOLTAGE){
    bodyDisabled = 1;
  }

  //if the head is low, blink the head, but we don't need to worry any further.
  if(headVoltage < MIN_VOLTAGE){
    headDisabled = 1;
  }
  
  //if it's been a while since the last check, reread the voltages.
  //This only asks for them - they're read in the serial message handling area.
  if(millis() > lastBatteryCheck + BATTERY_CHECK_INTERVAL){
    requestBodyBattery();
    requestHeadBattery();
    controllerVoltage = readBattery();
    lastBatteryCheck = millis();
  }
}

void shutdownController(){
  //turn all LEDs off
  shutdownButtonArray();
  
  //disconnect the battery so it doesn't get too low
  delay(10000);
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
  Serial.println(F("Arduino Serial BB8 Control!"));
  Serial.println(F("============================"));
  Serial.println(F("Usage: "));
  Serial.println(F("Command format is $, TO_CHAR, FROM_CHAR, COMMAND*"));
  Serial.println(F("All numbers are fixed length, zero padded"));
  Serial.println();
  Serial.println(F("$BCBX127Y127        -> to Body from Controller Body motion X127 Y127"));
  Serial.println(F("$BCHX***Y***A***    -> Move head - note X, Y and Angle of Rotation."));
  Serial.println(F("$BCSTOP             -> Full stop to the body"));
  Serial.println(F("$HCSTOP             -> Full stop to the head"));
  Serial.println(F("$BCRBATT            -> Have the body send us its battery voltage"));
  Serial.println(F("$CBV***            -> Here's that voltage you wanted, controlleer"));
  Serial.println(F("$HCP02              -> Play sound effect 02 - goes from 00 to 11"));
  Serial.println(F("  e.g. a0 - Read analog pin 0"));
  Serial.println();
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
  
  initPins();

#ifdef DEBUG
  printMenu(); // Print a helpful menu
#endif


  lastHeartbeat = millis();
}

void checkHeartbeat(){
  if(millis() > lastHeartbeat + HEARTBEAT_TIMER){
    sendHeartbeat();
  }
}

void loop()
{
#ifdef DEBUG
  Serial.println();
  Serial.println("Loop Start"); // Print a helpful menu
#endif
  //check the battery voltage - shutdown if it's too low.
  //checkBatteryForShutdown();
  checkHeartbeat();

  //read the xbee radio in
  handleXbee();

  //read all of our sensors
  readBodyPot();
  readHeadPot();
  //readButtonArray();

  //send messages from our sensors
  handleBodyPot(); //this also handles the spin buttons
  handleHeadPot(); //xya joystick
  handleButtonArray();  //funny noises in a big fancy grid
  

#ifdef DEBUG
  Serial.println();
  Serial.println("Loop End - pause 3 sec");
  delay(1000); //for debugging - to reduce the number of commands sent.
#endif
}