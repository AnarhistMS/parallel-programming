__device__
unsigned char GetPixel(unsigned char * src, unsigned int w, unsigned int h, int x, int y, int c)
{
	x = x < 0 ? 0 : x;
	x = x < w ? x : w - 1;
	y = y < 0 ? 0 : y;
	y = y < h ? y : h - 1;
	return src[3 * (w * y + x) + c];
}

__global__
void grayscale_kernel(unsigned char * src, unsigned char * dest, unsigned int w, unsigned int h)
{
	unsigned int x = blockIdx.x * blockDim.x + threadIdx.x;
	unsigned int y = blockIdx.y * blockDim.y + threadIdx.y;

	if (y < h && x < w)
	{
		float luma = 0;
		luma += 0.2126f * src[3 * (w * y + x) + 0];
		luma += 0.7152f * src[3 * (w * y + x) + 1];
		luma += 0.0722f * src[3 * (w * y + x) + 2];
		
		unsigned char l = (unsigned char)luma;
		
		dest[3 * (w * y + x) + 0] = l;
		dest[3 * (w * y + x) + 1] = l;
		dest[3 * (w * y + x) + 2] = l;
	}
}

__global__
void sobel_kernel(unsigned char * src, unsigned char * dest, unsigned int w, unsigned int h)
{
	int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;
	int c = blockIdx.z;

	if (x < w && y < h)
	{
		/*
			Sobel X-filter:             Sobel Y-filter:
			-1   0  +1                  -1  -2  -1
			-2   0  +2                   0   0   0
			-1   0  +1                  +1  +2  +1
		*/
		float Gx = 0;
		float Gy = 0;

		if (x > 1)
		{
			if (y > 1)
				Gx -= src[3 * (w * (y - 1) + (x - 1)) + c];
			Gx -= 2.0f * src[3 * (w * y + (x - 1)) + c];
			if (y < h - 1)
				Gx -= src[3 * (w * (y + 1) + (x - 1)) + c];
		}

		if (x < w - 1)
		{
			if (y > 1)
				Gx += src[3 * (w * (y - 1) + (x + 1)) + c];
			Gx += 2.0f * src[3 * (w * y + (x + 1)) + c];
			if (y < h - 1)
				Gx += src[3 * (w * (y + 1) + (x + 1)) + c];
		}

		if (y > 1)
		{
			if (x > 1)
				Gy -= src[3 * (w * (y - 1) + (x - 1)) + c];
			Gx -= 2.0f * src[3 * (w * (y - 1) + x) + c];
			if (x < w - 1)
				Gx -= src[3 * (w * (y - 1) + (x + 1)) + c];

		}

		if (y < h - 1)
		{
			if (x > 1)
				Gy += src[3 * (w * (y + 1) + (x - 1)) + c];
			Gx += 2.0f * src[3 * (w * (y + 1) + x) + c];
			if (x < w - 1)
				Gx += src[3 * (w * (y + 1) + (x + 1)) + c];
		}

		float G = sqrt(Gx*Gx + Gy*Gy);
		dest[3 * (w * y + x) + c] = G > 32 ? 255 : 0;
	}
}

__global__
void sobel_kernel_shared(unsigned char * src, unsigned char * dest, unsigned int w, unsigned int h)
{
	int x_block = blockIdx.x * blockDim.x;
	int y_block = blockIdx.y * blockDim.y;
	unsigned int tx = threadIdx.x;
	unsigned int ty = threadIdx.y;
	unsigned int c = blockIdx.z;

	__shared__ unsigned char pixels[16 + 2][16 + 2];
	for (unsigned int i = blockDim.x * ty + tx;
		i < (blockDim.x + 2) * (blockDim.y + 2);
		i += blockDim.x * blockDim.y)
	{
		char y_off = i / (blockDim.x + 2);
		char x_off = i % (blockDim.x + 2);
		pixels[y_off][x_off] = GetPixel(src, w, h, x_block + x_off - 1, y_block + y_off - 1, c);
	}

	__syncthreads();

	if (x_block + tx < w && y_block + ty < h)
	{
		/*
		Sobel X-filter:             Sobel Y-filter:
		-1   0  +1                  -1  -2  -1
		-2   0  +2                   0   0   0
		-1   0  +1                  +1  +2  +1
		*/

		float Gx = 0
			- 1.0 * pixels[ty + 0][tx + 0]
			- 2.0 * pixels[ty + 1][tx + 0]
			- 1.0 * pixels[ty + 2][tx + 0]
			+ 1.0 * pixels[ty + 0][tx + 2]
			+ 2.0 * pixels[ty + 1][tx + 2]
			+ 1.0 * pixels[ty + 2][tx + 2];

		float Gy = 0
			- 1.0 * pixels[ty + 0][tx + 0]
			- 2.0 * pixels[ty + 0][tx + 1]
			- 1.0 * pixels[ty + 0][tx + 2]
			+ 1.0 * pixels[ty + 2][tx + 0]
			+ 2.0 * pixels[ty + 2][tx + 1]
			+ 1.0 * pixels[ty + 2][tx + 2];

		float G = sqrt(Gx*Gx + Gy*Gy);
		dest[3 * (w * (y_block + ty) + x_block + tx) + c] = G > 32 ? 255 : 0;
	}
}

extern "C"
void GPUFiltering(unsigned char * src, unsigned char * dest, unsigned int w, unsigned int h)
{
	// �������������� � ������� ������
	dim3 BlockDim1(16, 16, 1);
	dim3 GridDim1((w - 1)/BlockDim1.x + 1, (h - 1)/BlockDim1.y + 1, 1);
	grayscale_kernel<<<GridDim1, BlockDim1>>>(src, dest, w, h);

	// ������ ������
	dim3 BlockDim2(16, 16, 1);
	dim3 GridDim2((w - 1) / BlockDim2.x + 1, (h - 1) / BlockDim2.y + 1, 3);
	sobel_kernel_shared<<<GridDim2, BlockDim2>>>(dest, src, w, h);
}
