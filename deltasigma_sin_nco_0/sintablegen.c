#include <stdio.h>
#include <math.h>
#include <stdint.h>

#define _USE_MATH_DEFINES

#define NUM_BITS    16

#if NUM_BITS == 8
#define NUM_SAMPLES 512
#else
#define NUM_SAMPLES 256
#endif

int main(){
    FILE *file;
    file = fopen("sin_table_8x512.mem", "w");

    for(int n = 0; n < NUM_SAMPLES; n++){
#if NUM_BITS == 8
        int8_t sam = (int8_t)(110.0 * (sin((double)n * ((M_PI * 2.0) / (4.0 * (double) NUM_SAMPLES)))));
#endif

#if NUM_BITS == 16
        uint16_t sam = (uint16_t)(((double)((UINT16_MAX / 16) - 1)) * (1.0 + (sin((double)n * ((M_PI * 2.0) / ((double) NUM_SAMPLES))) 
                                                                                * sin(16.0 * (double)n * ((M_PI * 2.0) / ((double) NUM_SAMPLES))))) );
#endif

#if NUM_BITS == 0
        uint16_t sam = UINT16_MAX ;
#endif
        
        fprintf(file, "%d", sam);
        if(n != NUM_SAMPLES - 1){
            fprintf(file, "\n");
        }
    }

    printf("Done!\n");

    return 0;
}