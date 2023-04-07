#include <stdio.h>
#include <math.h>
#include <stdint.h>

#define _USE_MATH_DEFINES

#define NUM_BITS    8

#define NUM_SAMPLES     512         // 2^9 samples
#define SAMPLE_RATE     500000      // 500k Fs
#define ADC_VREF        3.3f
#define ADC_RES_STEPS   256

void init_sample_table(uint8_t *buff, double freq, double pkpk_amp, double DC_offset, int num_samples, int Fs_rate){
    double radfreq = freq * M_PI * 2.0;
    double rad_step_x = 1.0 / (double)Fs_rate;
    for(int n = 0; n < num_samples; n++){
        buff[n] = (uint8_t)((((pkpk_amp / 2.0) * sin(radfreq * rad_step_x * (double)n) + DC_offset) / ADC_VREF) * ADC_RES_STEPS);
    }
}

int main(){
    FILE *file;
    file = fopen("sample_table_8x512.mem", "w");

    uint8_t sample_buffer[NUM_SAMPLES];

    //                Buffer, freq, pk - pk V, DC_offset, num samples, sample rate
    init_sample_table(sample_buffer, 100000.0, 3.0, 3.0 / 2, NUM_SAMPLES, SAMPLE_RATE);

    for(int n = 0; n < NUM_SAMPLES; n++){
        fprintf(file, "%02X", sample_buffer[n]);
        if(n != NUM_SAMPLES - 1){
            fprintf(file, "\n");
        }
    }

    printf("Done!\n");

    return 0;
}
