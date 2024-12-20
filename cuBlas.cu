#include <assert.h>
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include <stdio.h>
#include <sys/time.h>

#define MATRIX_SIZE 10

double get_clock() {
  struct timeval tv; int ok;
  ok = gettimeofday(&tv, (void *) 0);
  if (ok<0) { printf("gettimeofday error"); }
  return (tv.tv_sec * 1.0 + tv.tv_usec * 1.0E-6);
}

void init(float *data, int size) {
    for (int i = 0; i < size; ++i) {
        data[i] = 1;
    }
}

// Perform matrix multiplication on the GPU using cuBLAS
void matrixMultiplyCUDA() {
    const int size = MATRIX_SIZE * MATRIX_SIZE;
    const float alpha = 1.0f;
    const float beta = 0.0f;

    float *h_A = (float *)malloc(size * sizeof(float));
    float *h_B = (float *)malloc(size * sizeof(float));
    float *h_C = (float *)malloc(size * sizeof(float));

    init(h_A, size);
    init(h_B, size);

    float *d_A, *d_B, *d_C;
    cudaMalloc((float **)&d_A, size * sizeof(float));
    cudaMalloc((float **)&d_B, size * sizeof(float));
    cudaMalloc((float **)&d_C, size * sizeof(float));

    cudaMemcpy(d_A, h_A, size * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, size * sizeof(float), cudaMemcpyHostToDevice);

    cublasHandle_t handle;
    cublasCreate(&handle);

    double t0 = get_clock();
    // Matrix multiplication: C = A * B using cuBLAS (column-major order)
    cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, MATRIX_SIZE, MATRIX_SIZE, MATRIX_SIZE, &alpha, d_B, MATRIX_SIZE, d_A, MATRIX_SIZE, &beta, d_C, MATRIX_SIZE);
    double t1 = get_clock();

    // Copy result back to host
    cudaMemcpy(h_C, d_C, size * sizeof(float), cudaMemcpyDeviceToHost);

    for (int i = 0; i < MATRIX_SIZE; i++) {
    	for (int j = 0; j < MATRIX_SIZE; j++) {
      	    if (h_C[i*MATRIX_SIZE+j] != MATRIX_SIZE) {
               printf("Error at c[%d][%d]: %f\n", i, j, h_C[i*MATRIX_SIZE+j]);
      	    }
    	}
    }

    printf("Time: %f ns\n", 1000000000.0*(t1 - t0));

    // Clean up
    cublasDestroy(handle);
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    free(h_A);
    free(h_B);
    free(h_C);
}

int main() {
    matrixMultiplyCUDA();
    return 0;
}


