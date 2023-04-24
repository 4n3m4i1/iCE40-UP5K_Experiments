# ADC082S191 - iCE40-UP5k Interface
This is a simple interface that can  
operate with internally generated or  
externally provided clock sources.  
  
  
The example TOP module offers the last  
read ADC value on an LED bar graph display  
at ~15Hz.  
  
This is a fun way to see everything works well.  
  
  
## Known Issues  
There is a chance of desync if power is not delivered  
correctly. An example would be plugging in a USB  
plug to the development board slowly. There should  
be a larger delay to starting the interface,  
or power should be applied decisively.  
  
This is low priority and can be changed in  
your own implementation if desired.
