# bb8
Trying to make a printed BB8 that's strong, fast and accurate.

## Code
I'll be using an Arduino 101: https://www.arduino.cc/en/Main/ArduinoBoard101
- because I think that the internal IMU and faster processor will make my bb8 more realistic.  Existing designs seem too wobbly.

I was hoping to use an existing Android app to start with, to do simple driving; however none of them seem to work with Bluetooth Low Energy.  If anyone knows of an app, let me know.

The long-term plan was a proper Android BB8 app anyways, so I'm starting on that now.

#Progress: Android
- Just installed my first app.

##TODO: Android
- get Bluetooth LE working & connecting to the 101
- make a 4-button controller, motors to move NESW
- make the 4-button controller out of sliders/proportional speeds

#Progress: Arduino
- Motor control board is tested & working with the Curie
  - wrote a tiny motor control class, gotta break it out

- Accelerometer is tested and working
  - but not reliably giving orientation - needs some experimentation

- Simple bluetooth LE sketch worked - turning the LED on and off

##TODO: Arduino
- break out tests into classes, integrate into single sketch
- accept direction & speed from Android
