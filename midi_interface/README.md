# MIDI Interfaces
MIDI is just 8N1 uart at 31k250 baud, and it's entirely a one way street  
for communications.  
  
A simple example is provided that is effectively just a UART RX module,  
a more complex build that handles latching of command bytes is coming shortly.  
  
  
As built the modules are designed to operate with an undivided HFOSC output of  
48MHz, though this can be easily changed with module parameters.  
  
  
  

