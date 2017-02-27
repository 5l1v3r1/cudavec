extern "C" __global__
void divElements(float * x, float * y, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		x[tid] /= y[tid];
	}
}

extern "C" __global__
void elemMax(float * dst, float * src, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		dst[tid] = max(dst[tid], src[tid]);
	}
}

extern "C" __global__
void expElements(float * x, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		x[tid] = expf(x[tid]);
	}
}

extern "C" __global__
void logElements(float * x, int n) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		x[tid] = logf(x[tid]);
	}
}

extern "C" __global__
void tanhElements(float * x, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		x[tid] = tanhf(x[tid]);
	}
}

extern "C" __global__
void sinElements(float * x, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		x[tid] = sinf(x[tid]);
	}
}

extern "C" __global__
void sigmoidElements(float * x, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		x[tid] = (1 + tanhf(x[tid] / 2)) / 2;
	}
}

extern "C" __global__
void clipPositive(float * x, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		x[tid] = fmaxf(0, x[tid]);
	}
}

extern "C" __global__
void shiftRandUniform(float * x, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		if (x[tid] == 1.0f) {
			x[tid] = 0;
		}
	}
}

extern "C" __global__
void uniformToBernoulli(float * x, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
		if (x[tid] > 0.5) {
			x[tid] = 1;
		} else {
			x[tid] = 0;
		}
	}
}

extern "C" __global__
void addRepeated(float * dest, float * source, int destLen, int sourceLen) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] += source[tid % sourceLen];
	}
}

extern "C" __global__
void addRepeatedPow2(float * dest, float * source, int destLen, int srcMask) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] += source[tid & srcMask];
	}
}

extern "C" __global__
void scaleRepeated(float * dest, float * source, int destLen, int sourceLen) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] *= source[tid % sourceLen];
	}
}

extern "C" __global__
void scaleRepeatedPow2(float * dest, float * source, int destLen, int srcMask) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] *= source[tid & srcMask];
	}
}

extern "C" __global__
void addScaler(float s, float * dest, int destLen) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] += s;
	}
}

extern "C" __global__
void setScaler(float s, float * dest, int destLen) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] = s;
	}
}

extern "C" __global__
void addChunks(float * dest, float * source, int destLen, int chunkSize) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] += source[tid / chunkSize];
	}
}

extern "C" __global__
void subChunks(float * dest, float * source, int destLen, int chunkSize) {
  int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] -= source[tid / chunkSize];
	}
}

extern "C" __global__
void lessThan(float s, float * v, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
    if (v[tid] < s) {
      v[tid] = 1;
    } else {
      v[tid] = 0;
    }
	}
}

extern "C" __global__
void greaterThan(float s, float * v, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
    if (v[tid] > s) {
      v[tid] = 1;
    } else {
      v[tid] = 0;
    }
	}
}

extern "C" __global__
void equalTo(float s, float * v, int n) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < n) {
    if (v[tid] == s) {
      v[tid] = 1;
    } else {
      v[tid] = 0;
    }
	}
}

extern "C" __device__
float addLogPair(float x, float y) {
  float m = max(x, y);
  return logf(expf(x-m) + expf(y-m)) + m;
}

extern "C" __global__
void addLogs(float * dst, float * src, int rowSize) {
  extern __shared__ float chunk[];

  int rowIdx = blockIdx.y * blockDim.x + threadIdx.x;
  if (rowIdx < rowSize) {
    chunk[threadIdx.x] = src[rowIdx+rowSize*blockIdx.x];
  }
  __syncthreads();

  for (int stride = (blockDim.x>>1); stride >= 1; stride >>= 1) {
    if (threadIdx.x < stride && rowIdx+stride < rowSize) {
      chunk[threadIdx.x] = addLogPair(chunk[threadIdx.x],
        chunk[threadIdx.x+stride]);
    }
    __syncthreads();
  }

  if (threadIdx.x == 0) {
    dst[blockIdx.y + blockIdx.x*gridDim.y] = chunk[0];
  }
}

extern "C" __global__
void powScaler(float s, float * dest, int destLen) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < destLen) {
		dest[tid] = powf(dest[tid], s);
	}
}

extern "C" __global__
void mapForward(float * dst, float * src, int * table, int tableSize) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < tableSize) {
		dst[tid] = src[table[tid]];
	}
}

extern "C" __global__
void mapBackward(float * dst, float * src, int * table, int tableSize) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < tableSize) {
		atomicAdd(&dst[table[tid]], src[tid]);
	}
}

extern "C" __global__
void mapMax(int * table, float * data, int rows, int cols) {
	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	if (tid < rows) {
		int base = tid * cols;
		float * row = &data[base];
		int maxIdx = 0;
		float maxVal = row[0];
		for (int i = 1; i < cols; ++i) {
			if (row[i] > maxVal) {
				maxVal = row[i];
				maxIdx = i;
			}
		}
		table[tid] = maxIdx + base;
	}
}
