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



int main(){

    fix14_16 a0 = (fix14_16)0x0214;   // A
    fix14_16 a1 = (fix14_16)0x0222;   // B
    fix14_16 a2 = (fix14_16)0x0012;   // D

    printf("Fixed Mul: %04X * %04X = %04X\n", a0, a1, multfix14_16(a0, a1));

    printf("Fixed:\n\t(0x%04X * 0x%04X) + 0x%04X = 0x%04X\n\n",
            a0, a1, a2, (fix14_16)(a2 + (multfix14_16(a0, a1))));

    printf("Raw:\n\t(0x%04X * 0x%04X) + 0x%04X = 0x%04X\n",
            a0, a1, a2, (fix14_16)(a2 + (((int32_t)a0 * (int32_t)a1))));

    return 0;
}
