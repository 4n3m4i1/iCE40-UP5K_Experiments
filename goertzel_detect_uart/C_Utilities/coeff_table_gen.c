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

void print_fix14_16(fix14_16 val){
    uint32_t t_val = (uint32_t)val;
    int max = (8 * sizeof(fix14_16) );
    for(int n = 0; n < max; n++){
        if(t_val & (1 << ((max - 1) - n))){
            printf("1");
        } else {
            printf("0");
        }
        if(n == (max - SHAMT - 1)) printf(".");
    }
}

void init_sin_table(fix14_16 *sinbuf, int num_samples){
    for(int n = 0; n < num_samples; n++){
        double omega = 2.0 * M_PI * ((double)n) / (double)num_samples;
        //printf("Iter: %2u\tOmega: %.6f\tSin() = %.6f\t", n, omega, sin(omega));
        sinbuf[n] = float2fix14_16(((float)sin(omega)));
        //print_fix14_16(sinbuf[n]);
        //printf("\t%04X\n", sinbuf[n]);
    }
}


//    t_sin = sin_table[bin];
//    t_cos = sin_table[bin + (NUM_SAMPLES >> 2)];    // num samples / 4 phase shift

//    coeff = t_cos << 1;                             // 2 * cos() term

int main(){
    printf("Fixed Size: %2u\n", 8*sizeof(fix14_16));

    fix14_16 *sin_lut = (fix14_16 *)malloc(NUM_SAMPLES * sizeof(fix14_16));

    // Sin Look up table gen
    init_sin_table(sin_lut, NUM_SAMPLES);

    FILE *fp;

    fp = fopen("sin_table.mem", "w");

    int n = 0;
    for(n = 0; n < (NUM_SAMPLES / 2) - 1; n++){
        printf("Sin(%03u) = 0x%04X\n", n, (uint16_t)sin_lut[n]);
        fprintf(fp, "%04X\n", (uint16_t)sin_lut[n]);
    }
    printf("Sin(%03u) = 0x%04X\n", NUM_SAMPLES / 2 - 1, (uint16_t)sin_lut[(NUM_SAMPLES / 2) - 1]);
    fprintf(fp, "%04X", (uint16_t)sin_lut[(NUM_SAMPLES / 2) - 1]);

    fclose(fp);

    fp = fopen("cos_table.mem", "w");

    int pi_over_4_phase_shift = NUM_SAMPLES >> 2;

    for(n = pi_over_4_phase_shift; n < (pi_over_4_phase_shift + 255); n++){
        printf("Cos(%03u) = 0x%04X\n", n - (NUM_SAMPLES >> 2), (uint16_t)sin_lut[n]);
        fprintf(fp, "%04X\n", (uint16_t)sin_lut[n]);
    }
    printf("Cos(%03u) = 0x%04X\n", n - (NUM_SAMPLES >> 2), (uint16_t)sin_lut[n]);
    fprintf(fp, "%04X", (uint16_t)sin_lut[n]);


    fclose(fp);

    free(sin_lut);

    return 0;
}


