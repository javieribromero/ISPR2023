
//#include "irr_coeff";

void
iir_direct_form_I_float(float output[LEN],
 float input[LEN],
 float b[M],
 float a[M-1])
{

// Function only per one filter
float x;
float y;

for(current=0; current<LEN; current++) {
    x = 0;
    for (i=0; i<M; i++){
        x += b[i] * input[current-i];
    }
    y = x;
    for (i=1; i<M; i++){
        y = y - (a[i-1] * output[current-i]);
    }
    output[current] = y;
}
}

// Calling for ALL filters

for (filter=0; filter<=28; filters++){
	iir_direct_form_I_float(&output[filters][0], (float*)(&input), (float*)(&b[filters][0]), (float*)(&a[filters][0]));
}

