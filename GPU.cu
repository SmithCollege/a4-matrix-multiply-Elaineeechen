#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#define SIZE 10
#define TILE_WIDTH 32

double get_clock() {
  struct timeval tv; int ok;
  ok = gettimeofday(&tv, (void *) 0);
  if (ok<0) { printf("gettimeofday error"); }
  return (tv.tv_sec * 1.0 + tv.tv_usec * 1.0E-6);
}

__global__ void MatrixMulKernel(float* d_M, float* d_N, float* d_P, int Width) {
  int Row = blockIdx.y*blockDim.y+threadIdx.y;
  int Col = blockIdx.x*blockDim.x+threadIdx.x;
  if ((Row < Width) && (Col < Width)) {
     float Pvalue = 0;
     for (int k = 0; k < Width; ++k){
     	 Pvalue += d_M[Row * Width + k] * d_N[k * Width + Col];
     }
     d_P[Row * Width + Col] = Pvalue;
  }
}

int main() {
  float* M = (float*)malloc(sizeof(float) * SIZE * SIZE);
  float* N = (float*)malloc(sizeof(float) * SIZE * SIZE);
  float* P = (float*)malloc(sizeof(float) * SIZE * SIZE);
  float *d_M, *d_N, *d_P;
  cudaMalloc(&d_M, SIZE* SIZE * sizeof(float));
  cudaMalloc(&d_N, SIZE* SIZE * sizeof(float));
  cudaMalloc(&d_P, SIZE* SIZE * sizeof(float));

  for (int i = 0; i < SIZE; i++) {
    for (int j = 0; j < SIZE; j++) {
      M[i*SIZE+j] = 1;
      N[i*SIZE+j] = 1;
    }
  }

  cudaMemcpy(d_M, M, SIZE * SIZE * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(d_N, N, SIZE * SIZE * sizeof(float), cudaMemcpyHostToDevice);

  dim3 dimGrid(ceil((1.0*SIZE)/TILE_WIDTH), ceil((1.0*SIZE)/TILE_WIDTH), 1);
  dim3 dimBlock(TILE_WIDTH, TILE_WIDTH, 1);

  double t0 = get_clock();
  MatrixMulKernel<<<dimGrid, dimBlock>>>(d_M, d_N, d_P, SIZE);
  cudaDeviceSynchronize();
  double t1 = get_clock();

  cudaMemcpy(P, d_P, SIZE * SIZE *sizeof(float), cudaMemcpyDeviceToHost);

  for (int i = 0; i < SIZE; i++) {
    for (int j = 0; j < SIZE; j++) {
      if (P[i*SIZE+j] != SIZE) {
        printf("Error at z[%d][%d]: %f\n", i, j, P[i*SIZE+j]);
      }
    }
  }
  printf("Time: %f ns\n", 1000000000.0*(t1 - t0));

  return 0;    
}