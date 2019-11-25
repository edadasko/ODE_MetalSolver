#import "PicardsIterativeSolver.h"
#import "rightSide.h"

float getMaxDiff(float* answer, float* nextAnswer, unsigned long numX)
{
    float maxDifference = FLT_MIN;
    
    for (int i = 0; i < numX; i ++)
    {
        float diff = fabsf(nextAnswer[i] - answer[i]);
        if (diff > maxDifference)
            maxDifference = diff;
    }
    
    return maxDifference;
}

float findIntegral(int i, float* x, float* y)
{
    return (x[i] - x[i - 1]) * (f(x[i - 1], y[i - 1]) + f(x[i], y[i])) / 2;
}

float* picardsIteration(float* xs, float* ys, float y0, unsigned long numX)
{
    float* answer = (float*)malloc(numX * sizeof(int));
    answer[0] = y0;
    for (int i = 1; i < numX; i++)
        answer[i] = answer[i - 1] + findIntegral(i, xs, ys);
    return answer;
}

float* iterativePicardsMethod(float x0, float xN, float y0, unsigned long numX)
{
    const float error = 0.0001;
    
    float* answer = (float*)malloc(numX * sizeof(int));
    float* xs = (float*)malloc(numX * sizeof(int));
    float* ys = (float*)malloc(numX * sizeof(int));
    
    float h = (xN - x0) / (numX - 1);
    xs[0] = x0;
    xs[numX - 1] = xN;
    for (unsigned long index = 1; index < numX - 1; index++)
    {
        xs[index] = xs[index - 1] + h;
    }
    
    for (unsigned long index = 0; index < numX; index++)
    {
        ys[index] = y0;
    }
    
    NSDate *start = [NSDate date];
    float* nextAnswer = picardsIteration(xs, ys, y0, numX);
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    
    while (getMaxDiff(answer, nextAnswer, numX) > error)
    {
        for (int i = 0; i < numX; i ++)
            answer[i] = nextAnswer[i];
        
        start = [NSDate date];
        nextAnswer = picardsIteration(xs, nextAnswer, y0, numX);
        timeInterval += [start timeIntervalSinceNow];
    }
    
    printf("Iterative method time:\n%f\n", fabs(timeInterval));
    return nextAnswer;
}
