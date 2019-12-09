#import "PicardsSerialSolver.h"
#import "rightSide.h"

float getMaxDiff(float* answer, float* nextAnswer, unsigned long numX) {
    float maxDifference = FLT_MIN;
    
    for (int i = 0; i < numX; i ++) {
        float diff = fabsf(nextAnswer[i] - answer[i]);
        if (diff > maxDifference)
            maxDifference = diff;
    }
    
    return maxDifference;
}

float findIntegral(int i, float* x, float* y) {
    return (x[i] - x[i - 1]) * (f(x[i - 1], y[i - 1]) + f(x[i], y[i])) / 2;
}

float* picardsIteration(float* xs, float* ys, float y0, unsigned long numX) {
    float* answer = (float*)malloc(numX * sizeof(int));
    answer[0] = y0;
    for (int i = 1; i < numX; i++)
        answer[i] = answer[i - 1] + findIntegral(i, xs, ys);
    return answer;
}

float* serialPicardsMethod(float x0,
                              float xN,
                              float y0,
                              unsigned long numX,
                              double* time) {
    const float error = 0.0001;
    
    float* answer = (float*)malloc(numX * sizeof(int));
    float* nextAnswer = (float*)malloc(numX * sizeof(int));
    float* xs = (float*)malloc(numX * sizeof(int));
    float* ys = (float*)malloc(numX * sizeof(int));
    
    float h = (xN - x0) / (numX - 1);
    xs[0] = x0;
    xs[numX - 1] = xN;
    
    for (unsigned long index = 1; index < numX - 1; index++)
        xs[index] = xs[index - 1] + h;
    
    for (unsigned long index = 0; index < numX; index++) {
        nextAnswer[index] = y0;
        ys[index] = y0;
    }
    
    clock_t t, sumT = 0;
    
    do {
        for (int i = 0; i < numX; i ++)
            answer[i] = nextAnswer[i];
        
        t = clock();
        nextAnswer = picardsIteration(xs, nextAnswer, y0, numX);
        t = clock() - t;
        sumT += t;
    } while (getMaxDiff(answer, nextAnswer, numX) > error);
    
    double time_taken = ((double)sumT)/CLOCKS_PER_SEC;
    *time += time_taken;
    
    free(answer);
    free(xs);
    free(ys);
    
    return nextAnswer;
}
