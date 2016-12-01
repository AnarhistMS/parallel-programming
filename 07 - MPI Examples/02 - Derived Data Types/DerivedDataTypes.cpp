#include <mpi.h>
#include <stdio.h>
#include <string.h>

const int BUFFER_SIZE = 20;
const size_t N_TYPES = 3;
const char message[N_TYPES][80] = {
	"recieived 2 items of contiguous(7) datatype",
	"recieived 2 items of vector(2, 3, 4) datatype",
	"recieived 2 items of indexed(2, {2, 1}, {0, 5}) datatype"
	};

int main( int argc, char *argv[])
{
	int myrank, nprocs;

	// ������������� MPI (�������� ���������)
	MPI_Init(&argc, &argv);

	// ������������� �������� ��������
	MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
	MPI_Comm_size(MPI_COMM_WORLD, &nprocs);

	// ���������� ����������� ����� ������
	MPI_Datatype types[N_TYPES];
	MPI_Type_contiguous(7, MPI_INT, &types[0]);
	MPI_Type_vector(2, 3, 5, MPI_INT, &types[1]);

	int block_len[2] = {2, 1};
	int block_disp[2] = {0, 5};
	MPI_Type_indexed(2, block_len, block_disp, MPI_INT, &types[2]);

	// ������������ ����� ������
	for (size_t i = 0; i < N_TYPES; ++i)
		MPI_Type_commit(&types[i]);

	// �������� ��������� ������� ���������
	if (myrank == 0)
	{
		// ������������� ��������� �������
		int *A = new int[BUFFER_SIZE];
		for (int i = 0; i < BUFFER_SIZE; ++i)
			A[i] = i + 1;

		// ������ ��������� �������
		printf("%s\n", "source data");
		for (int i = 0; i < BUFFER_SIZE; ++i)
			printf("%3d", A[i]);
		printf("\n\n");

		// �������� ������ ����������� �����
		for (int i = 0; i < N_TYPES; ++i)
			MPI_Send(A, 2, types[i], 1, i, MPI_COMM_WORLD);

		// �������� ��������� �������
		delete [] A;
	}
	// ����� ��������� ������ ���������
	else if (myrank == 1)
	{
		// ��������� ������ ��� ����� ���������
		int *B = new int[BUFFER_SIZE];
		MPI_Status status;

		for (int i = 0; i < N_TYPES; ++i)
		{
			// ��������� ������ ���������
			for (int j = 0; j < BUFFER_SIZE; ++j)
				B[j] = 0;

			// ��������� ������
			MPI_Recv(B, BUFFER_SIZE, types[i], 0, i, MPI_COMM_WORLD, &status);

			// ������ �������� ������
			printf("%s\n", message[i]);
			for (int j = 0; j < BUFFER_SIZE; ++j)
				printf("%3d", B[j]);
			printf("\n\n");
		}

		// ������������ ������ ���������
		delete [] B;
	}

	// ���������� ������ (�������� ���������)
	MPI_Finalize();
	return 0;
}
