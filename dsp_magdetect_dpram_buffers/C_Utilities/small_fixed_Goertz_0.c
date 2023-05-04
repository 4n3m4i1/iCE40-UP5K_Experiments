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

void init_sample_table(uint8_t *buff, double freq, double pkpk_amp, double DC_offset, int num_samples, int Fs_rate){
    double radfreq = freq * M_PI * 2.0;
    double rad_step_x = 1.0 / (double)Fs_rate;
    for(int n = 0; n < num_samples; n++){
        buff[n] = (uint8_t)((((pkpk_amp / 2.0) * sin(radfreq * rad_step_x * (double)n) + DC_offset) / ADC_VREF) * ADC_RES_STEPS);
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

fix14_16 goertzel_mag(uint8_t* data, fix14_16* sin_table, int bin){
    fix14_16 t_sin, t_cos, coeff, t0, t1, t2;

    t_sin = sin_table[bin];
    t_cos = sin_table[bin + (NUM_SAMPLES >> 2)];    // num samples / 4 phase shift

    coeff = t_cos << 1;                             // 2 * cos() term

    printf("Coeff: %4X\t", coeff);

    t0 = t1 = t2 = 0x0000;                          // init 0

    printf("Sin: %04x\tCos: %04x\t", t_sin, t_cos);

    printf("\n");

    for(int n=0; n<NUM_SAMPLES; n++){
 //       printf("Start: t0 = %04X  t1 = %04X  t2 = %04X  ", t0, t1, t2);
        t0 = multfix14_16(coeff, t1);
 //       printf("\t%04X * %04X = %04X\t", coeff, t1, t0);
 //       printf("%3d\t%04X\t\t", n, t0);
 //       print_fix14_16(t0);
 //       printf("\n");
        //t0 = t0 - t2;
        //t0 = t0 + (fix14_16)data[n];
        t0 = (fix14_16)data[n] + t0 - t2;
        t2 = t1;
        t1 = t0;

  //      printf("Result: %3u\tt1 = %04X\tdata[n] = %04X\n", n, t1, (fix14_16)data[n]);
        //printf("%3u\t%04X\n", n, (uint16_t)t1);
        //printf("%d\n", t1);
    }


    //t1 = t1 - multfix14_16(t2, t_cos);

    t_cos = multfix14_16(t_cos, int2fix14_16(-1));
    printf("INVCOS: 0x%04X\n", t_cos);
    t1 = multfix14_16(t2, t_cos) + t1;

    t2 = multfix14_16(t2, t_sin);

    // Should sqrt this, but whatever
    return multfix14_16(t1, t1) + multfix14_16(t2, t2);
}

void print_all_bins(uint8_t *sample_buffer, fix14_16 *sin_lut){
    for(int n = 0; n < NUM_SAMPLES / 2; n++){
        // fix14_16 goertzel_mag(uint8_t* data, fix14_16* sin_table, int bin){
        fix14_16 res = goertzel_mag(sample_buffer, sin_lut, n);
        printf("Iter: %u\tHz: %u\t%u\t%04X\t", n, n*(int)((double)SAMPLE_RATE / (double)NUM_SAMPLES), (uint16_t)res, (uint16_t)res);
        print_fix14_16(res);
        printf("\n");
    }
}

int main(){
    printf("Fixed Size: %2u\n", 8*sizeof(fix14_16));

    uint8_t *sample_buffer = (uint8_t *)malloc(NUM_SAMPLES * sizeof(uint8_t));

    fix14_16 *sin_lut = (fix14_16 *)malloc(NUM_SAMPLES * sizeof(fix14_16));

    // Buffer, freq, pk - pk V, DC_offset, num samples, sample rate
    init_sample_table(sample_buffer, 100000.0, 3.0, 1.5, NUM_SAMPLES, SAMPLE_RATE);

    // Sin Look up table gen
    init_sin_table(sin_lut, NUM_SAMPLES);

/*
    for(int n = 0; n < NUM_SAMPLES / 2; n++){
        uint32_t freq_of_bin = (uint32_t)((double)n * (((double)SAMPLE_RATE) / (double)NUM_SAMPLES));
                printf("f = %6u SIN[%3u] = %04X\tCOS[%3u] = %04X\n",
                freq_of_bin, n, sin_lut[n], n, sin_lut[n + (NUM_SAMPLES >> 2)]);
    }
*/

    // print_all_bins;
    fix14_16 res;

    // Bin 62 @ 60k ish, for baseline level
//    printf("\nConst Bin @ 60k:\n");
//    res = goertzel_mag(sample_buffer, sin_lut, 62);
//    printf("Power:\t%4X\n", (uint16_t)res);

    // Bin 99
    printf("\nConst Bin @ 97.6k:\n");
    res = goertzel_mag(sample_buffer, sin_lut, 99);
    printf("Power:\t%4X\n", (uint16_t)res);

    printf("\n\n");

    // Bin 102 @ 100k, for 100k sense
    printf("\nConst Bin @ 100k:\n");
    res = goertzel_mag(sample_buffer, sin_lut, 102);
    printf("Power:\t%4X\n", (uint16_t)res);

    printf("\n\n");

    // Bin 108 @ 110k, for 110k sense
    printf("\nConst Bin @ 110k:\n");
    res = goertzel_mag(sample_buffer, sin_lut, 108);
    printf("Power:\t%4X\n", (uint16_t)res);


    printf("\n\n");

    // Bin 153 @ 120k, for 150k sense
    printf("\nConst Bin @ 150k:\n");
    res = goertzel_mag(sample_buffer, sin_lut, 153);
    printf("Power:\t%4X\n", (uint16_t)res);


//    for(int n = 0; n < NUM_SAMPLES >> 1; n++){
//        res = goertzel_mag(sample_buffer, sin_lut, n);
//        printf("Mag at bin %3d = %4X\n", n, res);
//    }



    free(sample_buffer);
    free(sin_lut);

    return 0;
}


