#include <mpi.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

int main( int argc, char *argv[])
{
	char message[20];
	int myrank, nprocs;
	MPI_Status status;

	// ������������� MPI (�������� ���������)
	MPI_Init(&argc, &argv);

	// ������������� �������� ��������
	MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
	MPI_Comm_size(MPI_COMM_WORLD, &nprocs);

	if (myrank == 0)
	{
		// ����������� ������� ���������
		strcpy_s(message,"Hello, there");
		int count = static_cast<int>(strlen(message)) + 1;
		MPI_Send(message, count,
			MPI_CHAR, 1, 99, MPI_COMM_WORLD);
	}
	else if (myrank == 1)
	{
		// ����������� ������ ���������
		MPI_Recv(message, 20,
			MPI_CHAR, 0, 99, MPI_COMM_WORLD,
			&status);
		printf("received: \"%s\"\n", message);
	}

	// ���������� ������ (�������� ���������)
	MPI_Finalize();
	return 0;
}