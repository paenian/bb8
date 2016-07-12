/*
  Copyright (c) 2015 Intel Corporation. All rights reserved.

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-
  1301 USA
*/


#include <CurieBLE.h>

#include "Motor.h"

const int ledPin = 13; // set ledPin to use on-board LED
BLEPeripheral blePeripheral; // create peripheral instance

BLEService ledService("19B10000-E8F2-537E-4F6C-D104768A1214"); // create services

// create switch characteristic and allow remote device to read and write
BLEUnsignedCharCharacteristic forwardSpeed("19B10001-E8F2-537E-4F6C-D104768A1215", BLERead | BLEWrite);
BLEUnsignedCharCharacteristic strafeSpeed("19B10001-E8F2-537E-4F6C-D104768A1216", BLERead | BLEWrite);



//Motors
//Motor(pwm, direction, current sense input
Motor motor1 = Motor(3, 2, A1);
Motor motor2 = Motor(5, 4, A2);
Motor motor3 = Motor(6, 7, A3); //now that I look at this design, there are really only two motors... we can link up the front and back motors.
Motor motor4 = Motor(9, 8, A4);   //I'll make a set of cables to join but for now they're software linked.
                                //I'll still be using the pins and all that, just for head movement?  that should all be servos, though.
                                //Might just leave it like this, double driver = double power.

void setup() {
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT); // use the LED on pin 13 as an output

  // set the local name peripheral advertises
  blePeripheral.setLocalName("BLEMT");
  // set the UUID for the service this peripheral advertises
  blePeripheral.setAdvertisedServiceUuid(ledService.uuid());

  // add service and characteristic
  blePeripheral.addAttribute(ledService);
  blePeripheral.addAttribute(forwardSpeed);
  
  blePeripheral.addAttribute(strafeSpeed);

  // assign event handlers for connected, disconnected to peripheral
  blePeripheral.setEventHandler(BLEConnected, blePeripheralConnectHandler);
  blePeripheral.setEventHandler(BLEDisconnected, blePeripheralDisconnectHandler);

  // assign event handlers for characteristic
  forwardSpeed.setEventHandler(BLEWritten, switchCharacteristicWritten);
// set an initial value for the characteristic
  forwardSpeed.setValue(0);
  //forwardSpeed.setUserDescription("fspeed");

    // assign event handlers for characteristic
  strafeSpeed.setEventHandler(BLEWritten, switchCharacteristicWritten2);
// set an initial value for the characteristic
  strafeSpeed.setValue(0);
  //strafeSpeed.setLocalName("sspeed");
  

  //set up the motors
  motor1.begin();
  motor2.begin();
  motor3.begin();
  motor4.begin();

  // advertise the service
  blePeripheral.begin();
  Serial.println(("Bluetooth device active, waiting for connections..."));
}

void loop() {
  // poll peripheral
  blePeripheral.poll();


  if(blePeripheral.connected()){
    //forward movement
    motor1.setDirection(true);
    motor1.setSpeed(forwardSpeed.value());
    motor3.setDirection(true);
    motor3.setSpeed(forwardSpeed.value());

    //strafe movement
    motor2.setDirection(true);
    motor2.setSpeed(strafeSpeed.value());
    motor4.setDirection(true);
    motor4.setSpeed(strafeSpeed.value());
  }
}

void blePeripheralConnectHandler(BLECentral& central) {
  // central connected event handler
  Serial.print("Connected event, central: ");
  Serial.println(central.address());
}

void blePeripheralDisconnectHandler(BLECentral& central) {
  // central disconnected event handler
  Serial.print("Disconnected event, central: ");
  Serial.println(central.address());

  motor1.stop();
  motor2.stop();
  motor3.stop();
  motor4.stop();
}

void switchCharacteristicWritten(BLECentral& central, BLECharacteristic& characteristic) {
  // central wrote new value to characteristic, update LED
  Serial.print("Characteristic event, written: ");

  if (forwardSpeed.value()) {
    Serial.print("Forward Speed: ");
    Serial.println(forwardSpeed.value());
    digitalWrite(ledPin, HIGH);
  } else {
    Serial.println("Forward off");
    digitalWrite(ledPin, LOW);
  }
}

void switchCharacteristicWritten2(BLECentral& central, BLECharacteristic& characteristic) {
  // central wrote new value to characteristic, update LED
  Serial.print("Characteristic event, written: ");

  if (strafeSpeed.value()) {
    Serial.print("Strafe Speed: ");
    Serial.println(strafeSpeed.value());
    digitalWrite(ledPin, HIGH);
  } else {
    Serial.println("Strafe off");
    digitalWrite(ledPin, LOW);
  }
}
