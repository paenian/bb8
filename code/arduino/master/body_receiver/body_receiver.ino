/*****************************************************************
Serial_Remote_Control.ino
Write your Arduino's pins (analog or digital) or read from those
pins (analog or digital) using a remote Serial.
Jim Lindblom @ SparkFun Electronics
Original Creation Date: May 7, 2014

Heavily adapted by Paul Chase, but I started from Jim's sketch :-)

This code is beerware; if you see me (or any other SparkFun 
employee) at the local, and you've found our code helpful, please 
buy us a round!

Distributed as-is; no warranty is given.
*****************************************************************/
// no software serial, body's going to need servos eventually and
//it would conflict.
#include "configuration.h"

//comment this out to turn serial debugging off.
//With it on, you can monitor the debugging with an xbee over the
//Arduino serial monitor.
#define DEBUG 1

//the max chars should only be an issue with debugging on :-)
#define MAX_SERIAL_WAIT 250
#define MAX_CHARS_TO_READ 25


////////Battery Voltage
//batteries can't be below MIN_VOLTAGE
//that's just over 3 volts in 10 bit.
#define MIN_VOLTAGE 616

//and we check them every INTERVAL
#define BATTERY_CHECK_INTERVAL 10000

// We track battery voltage for the body, head and controller itself.
int controllerVoltage = MIN_VOLTAGE + 1;
int bodyVoltage = MIN_VOLTAGE + 1;
int headVoltage = MIN_VOLTAGE + 1;


//position variables
int bodyPot[3] = {512, 512, 512};   //this is the potentiometer reading from the controller.
                                    //The third one isn't used as yet, but it's for spinning bb8.
int bodyState[3] = {512, 512, 512}; //what the body is currently doing

uint8_t bodyDisabled = 0;

//pid settings... the head might need its own pid?  it shouldn't, though...
#define BODY_PROPORTIONAL 2
#define BODY_INTEGRAL .25
#define BODY_DIFFERENTIAL .25


//shutdown after 10 seconds of no signal
#define HEARTBEAT_TIMEOUT 10000
unsigned long lastHeartbeat;  //this is updated every time we receive a command.


void initPins(){
}

void setup()
{
  // Initialize Serial Software Serial port. Make sure the baud
  // rate matches your Serial setting (9600 is default).
  Serial.begin(9600);

#ifdef DEBUG
  printMenu(); // Print a helpful menu
#endif

  initPins();

  lastHeartbeat = millis();
}

void loop()
{
  checkBatteryForShutdown();
  
  handleXbee();
  
  handleHeartbeat();
  
  //readBodyAccel();
  //readHeadAccel();
  
  updateBodyMotors();
  updateHeadMotors();
}

void handleHeartbead(){
  if(millis() - lastHeartbeat > HEARTBEAT_TIMEOUT){
    //we don't need to panic, just stop BB8 from running away.
    bodyPot = {512, 512, 512};
  }
}

//process the xbee serial
void handleXbee(){
  
  //this will consume many characters - maybe too many.
  //So we set a max.
  int chars = 0;
  char sender = BODYCHAR;  //set it to us, in case it becomes necessary
  
  //WAIT for at least 4 characters to be in the buffer before doing anything!
  while((Serial.available() > 3) && (chars < MAX_CHARS_TO_READ)){
    char c = Serial.read();  //three chars left
    chars++;
    
    if(c == '$'){  //control char
      c = Serial.read();  //two chars left
      chars++;
      
      if(c == BODYCHAR){  //to char - we only care if it's for us
        sender = Serial.read();  //from char - record who sent the message
        chars++;
        
        c = Serial.read();  //command char - this is the last guaranteed char
        chars++;
        
        lastHeartbeat = millis();        
        
        switch(c){
          case 'S': //stop char!
            if(sender == CONTROLCHAR){
              bodyDisabled = 1;
            }
          return;
          
          case 'B': //adjust the body position
            readBodyCommand();
          return;
          
          case 'H': //move the head about
            //todo on this one is to make a head!
          return;
          
          case 'R': //request for information
            if(sender == CONTROLCHAR){
              sendInfoController();
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

void readBodyCommand(){
  //figure out what the controller wants us to do :-)
  //So far, we've consumed the characters $BCB
  //Next is X###Y###frea
  

  //if there's a problem with the read, we'll just ignore the command.
  //So set a sane default
  int newPot[3] = {512, 512, 512};
  
#ifdef DEBUG
  Serial.println("body: readBodyCommand");
#endif

  if(readSerialBlocking() != 'X'){
#ifdef DEBUG
  Serial.println("body: readBodyCommand: Bad format, no X");
#endif
    return;
  }
 
  //read x
  newPot[0] = readInteger(3);
  
  if(readSerialBlocking() != 'X'){
#ifdef DEBUG
  Serial.println("body: readBodyCommand: Bad format, no Y");
#endif
    return;
  }
  
  //read y
  newPot[1] = readInteger(3);
  
  memcpy( bodyPot, newPot, sizeof(bodyPot));
}

//turn off all the pins
void Stop(){
#ifdef DEBUG
  Serial.println("Body: Stopping All Motors");
#endif

  bodyPot = {512, 512, 512};
  bodyState = {512, 512, 512};
  bodyDisabled = 1;  

#ifdef DEBUG
  Serial.println("Body: Stopped All Motors");
#endif
  delay(10000);
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

int readInteger(uint8_t digits){
  //todo: throw an error if we can't read the serial
  int integer = 0;
  
  for(int multiplier = 10^(digits-1); multiplier > 0; multiplier = multiplier/10){
    integer += multiplier*ASCIItoInt(readSerialBlocking());
  }
  
  return integer;
}

String pad(int number, byte len){
  String ret = "";
  int curMax = 10;
  for(byte i=1; i<len; i++){
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
