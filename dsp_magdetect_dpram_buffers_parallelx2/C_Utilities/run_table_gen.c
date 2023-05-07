#include <stdio.h>
#include <math.h>
#include <malloc.h>
#include <inttypes.h>

#define SHAMT           14  // initially 15
#define FL_CVT_CONST    16384.0 // prev 32768.0

// === the fixed point macros ========================================
typedef int16_t fix14_16 ;
//#define multfix14_16(a,b) ((fix14_16)((((signed long long)(a))*((signed long long)(b)))>>15)) //multiply two fixed 16.15
#define multfix14_16(a,b) ((fix14_16)((((int32_t)(a))*((int32_t)(b)))>>SHAMT)) //multiply two fixed 16.15
#define float2fix14_16(a) ((fix14_16)((a)*FL_CVT_CONST)) // 2^SHAMT
#define fix2float15(a) ((float)(a)/FL_CVT_CONST)
#define absfix14_16(a) abs(a)
#define int2fix14_16(a) ((fix14_16)(a << SHAMT))
#define fix2int15(a) ((int)(a >> SHAMT))
#define char2fix14_16(a) (fix14_16)(((fix14_16)(a)) << SHAMT)


#define NUM_SAMPLES     512         // 2^9 samples
#define SAMPLE_RATE     500000      // 500k Fs
#define ADC_VREF        3.3f
#define ADC_RES_STEPS   256

#define LUT_SIZE        512
#define LUT_W           8

//    t_sin = sin_table[bin];
//    t_cos = sin_table[bin + (NUM_SAMPLES >> 2)];    // num samples / 4 phase shift

//    coeff = t_cos << 1;                             // 2 * cos() term

int main(int argc, char **argv){

    // print all bins w/ upper freqs
    for(int n = 0; n < NUM_SAMPLES >> 1; n++){
        double bin_f = (double) n * ((double)SAMPLE_RATE / 2.0) / ((double)NUM_SAMPLES / 2.0);
        printf("Bin %3u\tf = %.2f kHz\n", n, bin_f / 1000.0);
    }

    if(argc > 1){
        FILE *fp;
        fp = fopen("run_table.mem", "w");

        // Remember: we process 2x at a time, thus this is 5 DSP process times
        const int num_args = 10;          // select 10 bins to sequence

        uint8_t *selected_bins;
        selected_bins = (uint8_t *)malloc(sizeof(uint8_t) * num_args);

        selected_bins[0] = 82;      // 80k
        selected_bins[1] = 87;      // 85k
        selected_bins[2] = 92;      // 90k
        selected_bins[3] = 97;      // 95k
        selected_bins[4] = 103;     // 100k
        selected_bins[5] = 108;     // 105k
        selected_bins[6] = 113;     // 110k
        selected_bins[7] = 118;     // 115k
        selected_bins[8] = 123;     // 120k
        selected_bins[9] = 128;     // 125k


        int n;
        for(n = 0; n < num_args; n++){
            fprintf(fp, "%02X\n", selected_bins[n]);
        }

        for(; n < LUT_SIZE - 1; n++){
            fprintf(fp, "%02X\n", 0x00);
        }
        fprintf(fp, "%02X", 0x00);

        fclose(fp);
        free(selected_bins);
    }



    return 0;
}


