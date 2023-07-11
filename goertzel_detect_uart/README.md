# Goertzel Detect UART
This will run the detection of 10 total frequencies using the  
parallel optimized goertzel algorithm developed on other projects  
within this repository.  
  
These are calculated as 5 runs of 2 detections done in parallel.


# Serial Protocol
A standard packet is sent consisting of 8 bytes send at 500k BAUD 8N1.
These bytes are:
- Run Number (Binary, 1 - 5)
- Comma (ASCII, 0x2C)
- Magnitude 0 (Binary, 2 bytes, LSB first)
- Comma (ASCII, 0x2C)
- Magnitude 1 (Binary, 2 bytes, LSB first)
- TERM (ASCII, 0x0A, newline)