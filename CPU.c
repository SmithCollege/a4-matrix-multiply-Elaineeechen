#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#define SIZE 10

double get_clock() {
  struct timeval tv; int ok;
  ok = gettimeofday(&tv, (void *) 0);
  if (ok<0) { printf("gettimeofday error"); }
  return (tv.tv_sec * 1.0 + tv.tv_usec * 1.0E-6);
}

void MatrixMulOnHost(float* M, float* N, float* P, int Width) {
  for (int i = 0; i < Width; ++i) {
    for (int j = 0; j < Width; ++j) {
      float sum = 0;
      for (int k = 0; k < Width; ++k) {
        float a = M[i*Width+k];
        float b = N[k*Width+j];
        sum += a*b;
      }
      P[i*Width+j] = sum;
    }
  }
}

int main() {
  float* M = malloc(sizeof(float) * SIZE * SIZE);
  float* N = malloc(sizeof(float) * SIZE * SIZE);
  float* P = malloc(sizeof(float) * SIZE * SIZE);

  for (int i = 0; i < SIZE; i++) {
    for (int j = 0; j < SIZE; j++) {
      M[i*SIZE+j] = 1;
      N[i*SIZE+j] = 1;
    }
  }

  double t0 = get_clock();
  MatrixMulOnHost(M, N, P, SIZE);
  double t1 = get_clock();
  
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
