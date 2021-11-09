#include <vector>
#include <iostream>
#include <random>

#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#include "gpuErrchk.h"

using namespace std;

constexpr size_t AMOUNT = 10;
constexpr size_t THREADS_NUMBER = 5;
constexpr size_t MASK_SIZE = 5;

__global__ void OneDSmooth(const float* input, const float* mask, float* output)
{
    // Get block index
    unsigned int bIdx = blockIdx.x;
    // Get thread index
    unsigned int tIdx = threadIdx.x;
    // Get the number of threads per block
    unsigned int blockSize = blockDim.x;
    // Get the index
    int idx = tIdx + bIdx * blockSize;
    // The radius of the mask
    int maskRadius = ((MASK_SIZE - 1) / 2);
    // The index of the region
    int startingIdx = idx - maskRadius;
    // Size of the region to calculate the smoothing from
    unsigned int maskSize = MASK_SIZE;
    // Overlap of the beginning
    unsigned int startingOverlap = 0;

    __shared__ float maskLocal[5];
    maskLocal[0] = 0.06136f;
    maskLocal[1] = 0.24477f;
    maskLocal[2] = 0.38774f;
    maskLocal[3] = 0.24477f;
    maskLocal[4] = 0.06136f;


    // Adjust the mask size based on the location
    
    if ((idx - maskRadius) < 0) // if it is at the beginning
    {
        while (startingIdx != 0)
        {
            maskSize--;
            startingIdx++;
            startingOverlap++;
        }
    }
    else if ((idx + maskRadius) > (AMOUNT-1))
    {
        unsigned int endingIndx = (idx + maskRadius);
        while (endingIndx != (AMOUNT-1))
        {
            maskSize--;
            endingIndx--;
        }
    }
    
    /*
    if ((idx - maskRadius) == -1)
    {
        startingOverlap = 1;
        maskSize = 4;
        startingIdx = 0;
    }
    else if ((idx - maskRadius) == -2)
    {
        startingOverlap = 2;
        maskSize = 3;
        startingIdx = 0;
    }
    else if ((idx + maskRadius) == (AMOUNT + 1))
    {
        maskSize = 4;
    }
    else if ((idx + maskRadius) == (AMOUNT + 2))
    {
        maskSize = 3;
    }
    */
    // Calculate the result
    float result = 0.0f;
    // The mask has to have 5 elements
    for (int i = 0; i < maskSize; i++)
    {
        result += input[startingIdx + i] * maskLocal[i + startingOverlap];
    }
    result = result / maskSize;
    output[idx] = result;
}

int main(int argc, char **argv)
{
    // Create the host memory
    vector<float> h_Input(AMOUNT);
    vector<float> h_Mask(5);
    vector<float> h_Output(AMOUNT);
    auto dataSize = sizeof(float) * AMOUNT;

    // Random generator
    random_device r;
    default_random_engine e(r());
    uniform_real_distribution<float> distribution(0.0f, 1.0f);

    // Generate random numbers
    for (unsigned int i = 0; i < AMOUNT; i++)
    {
        h_Input[i] = distribution(e);
    }

    // Save the mask
    h_Mask = { 0.06136f, 0.24477f, 0.38774f, 0.24477f, 0.06136f };

    cout << "Input:" << endl;

    //print the input
    for (unsigned int i = 0; i < h_Input.size(); i++)
    {
        cout << i << ": " << h_Input[i] << endl;
    }
    cout << "Mask:" << endl;
    for (unsigned int i = 0; i < MASK_SIZE; i++)
    {
        cout << i << ": " << h_Mask[i] << endl;
    }

    // Buffer
    float* inputBuffer, *outputBuffer, *maskBuffer;

    // Initialise buffers
    cudaMalloc((void**)&inputBuffer, dataSize);
    cudaMalloc((void**)&maskBuffer, MASK_SIZE);
    cudaMalloc((void**)&outputBuffer, dataSize);

    // Write host data to device
    cudaMemcpy(inputBuffer, &h_Input[0], dataSize, cudaMemcpyHostToDevice);
    cudaMemcpy(maskBuffer, &h_Mask[0], MASK_SIZE, cudaMemcpyHostToDevice);
    
    // Run the function
    OneDSmooth<<<AMOUNT / THREADS_NUMBER, THREADS_NUMBER>>>(inputBuffer, maskBuffer, outputBuffer);

    // Wait until it's completed
    cudaDeviceSynchronize();

    // Read the output buffer
    cudaMemcpy(&h_Output[0], outputBuffer, dataSize, cudaMemcpyDeviceToHost);

    // Free memory
    cudaFree(inputBuffer);
    cudaFree(outputBuffer);
    cudaFree(maskBuffer);

    cout << "Output:" << endl;

    //print the output
    for (unsigned int i = 0; i < h_Output.size(); i++)
    {
        cout << i << ": " << h_Output[i] << endl;
    }

    float checkup = h_Input[0] * h_Mask[2] + h_Input[1] * h_Mask[3] + h_Input[2] * h_Mask[4];
    checkup /= 3;
    cout << "Checkup for value 0: " << checkup << endl;

    checkup = h_Input[3] * h_Mask[0] + h_Input[4] * h_Mask[1] + h_Input[5] * h_Mask[2] + h_Input[6] * h_Mask[3] + h_Input[7] * h_Mask[4];
    checkup /= 5;

    cout << "Checkup for value 5: " << checkup<< endl;

    return 0;
}