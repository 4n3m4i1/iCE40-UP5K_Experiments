#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include <malloc.h>

#define SYSCLK_F    48000000ul
#define SIZEOF_BRAM 256
#define NUM_NOTES   128 // MIDI Note count
#define NOTESCALAR  1.059463094
#define BASEFREQ    8.18        // C -1


/*
    Generate a table that can map every midi note (0-127)
    to the appropriate dividers used in the associated
    NCO.
*/

void generate_freqs(double *bdlarr);
void cvt_freq_to_nco_divider(uint16_t *bram_dat, double *dblarr, uint32_t clk_f);
void check_divider_outputs(uint16_t *bram_dat, uint32_t clk_f);

int main(){
    printf("hello\n");
    double *freq_arr;
    freq_arr = (double *)malloc(NUM_NOTES * sizeof(double));

    uint16_t *bram;
    bram = (uint16_t *)malloc(SIZEOF_BRAM * sizeof(uint16_t));

    generate_freqs(freq_arr);
    cvt_freq_to_nco_divider(bram, freq_arr, SYSCLK_F);

    check_divider_outputs(bram, SYSCLK_F);


    FILE *fp;
    fp = fopen("midi_note_table.mem", "w");

    int n;
    for(n = 0; n < NUM_NOTES; n++){
        fprintf(fp, "%04X\n", bram[n]);
    }

    for(; n < SIZEOF_BRAM; n++){
        fprintf(fp, "%04X\n", 0x0000);
    }


    free(bram);
    free(freq_arr);
    return 0;
}


void generate_freqs(double *dblarr){
    double note_freq = BASEFREQ;
    dblarr[0] = note_freq;

    printf("  0 = %f\n", note_freq);

    for(int n = 1; n < NUM_NOTES; n++){
        note_freq *= NOTESCALAR;
        dblarr[n] = note_freq;
        printf("%3d = %f\n", n, note_freq);
    }
}

void cvt_freq_to_nco_divider(uint16_t *bram_dat, double *dblarr, uint32_t clk_f){
    // ( sysclk_f / divider ) / NUM_SAMPLES = output_f

    /*
        output_f * NUM_SAMPLES = sysclk_f / divider

        divider = sysclk_f / ( output_f * NUM_SAMPLES )
    */

    for(int n = 0; n < NUM_NOTES; n++){
        bram_dat[n] = (uint16_t) (((double)clk_f) / (dblarr[n] * (double)SIZEOF_BRAM));
        printf("%03X = 0x%04X == %u\n", n, bram_dat[n], bram_dat[n]);
    }
}

void check_divider_outputs(uint16_t *bram_dat, uint32_t clk_f){
    for(int n = 0; n < NUM_NOTES; n++){
        double out_f = ((double)clk_f / (double)bram_dat[n]) / ((double)SIZEOF_BRAM);
        printf("%3d = 0x%04X => %f\n", n, bram_dat[n], out_f);
    }
}
