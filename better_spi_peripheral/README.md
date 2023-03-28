# Better SPI Peripheral
This SPI peripheral module is a hardcoded mode 0 peripheral  
that operates within a single clock domain, preventing  
Global Buffer usage by piping in the SPI SCK.  
  
This module samples the SCK input at the systems main clock  
rate, looking for `rising` and `falling` edges.  
Sampling occurs at `rising` events, shifting occurs at  
`falling` events.  
  
In a pure loopback mode as presented in the current module  
there is a 1 byte delay between input and output.