# bb8
Trying to make a printed BB8 that's strong, fast and accurate.

## Shell
I want a full spherical shell, that is strong, printable, and provides easy access to the innards.
To me, BB8 needs to be holonomic.  Thus, the inside AND the outside need to be spherical - therefore I'm cutting up a hollow sphere.  

- Current design is using a rombicuboctahedron, which has 18 square faces and 8 triangular faces.  
- Each square face, when oriented for printing, fits in a 180x180x180mm cube.
- The parts print on their edge - so there's no need for support material.

The parts are joined by screws on the center of their face, with washers at the corners biscuit-joint style.  

I've also grooved the parts, but don't plan to make them different colors - after printing, you'll clean up the pieces, screw them together and paint.  

## Hamster
For the hamster, I plan to make an omniwheel robot.  I have no experience with robot building.  

Right now I don't have any plans for the head.  


I'll be using an Arduino 101: https://www.arduino.cc/en/Main/ArduinoBoard101
- because I think that the internal IMU and faster processor will make my bb8 more realistic.  Existing designs seem too wobbly.
  - I will probably need another accelerometer for the head, when I get there.

First step is to hook that up to a Rover 5 Motor Controller:
- https://github.com/sparkfun/Rover5_Motor_Driver_Board
- http://smile.amazon.com/Motor-Controller-Channel-4-5A-4-5-12V/dp/B00B88F2A6

Motors:
- https://www.pololu.com/product/1163

Paul

