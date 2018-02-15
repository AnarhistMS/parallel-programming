#pragma once

#include <cstdlib>
#include <CL\cl.h>

// ������� ���� ������ � ������
const char* TranslateOpenCLError(cl_int errorCode);

// ������ ��� �������� �� ������, ��� ������ ������� OpenCL
#define OPENCL_CHECK(call)                                                \
{                                                                         \
    cl_int err = call;                                                    \
    if (err != CL_SUCCESS)                                                \
    {                                                                     \
        printf("Error calling \"%s\"\n", #call);                          \
        printf("Error code = %s(%d)\n", TranslateOpenCLError(err), err);  \
        exit(EXIT_FAILURE);                                               \
    }                                                                     \
}

// ������ ��������� ���� ���� OpenCL �� �����
int ReadSourceFromFile(const char* fileName, char** source, size_t* sourceSize);

// �������� � ���������� ��������� �� ���������
cl_program CreateAndBuildProgram(const char* fileName, cl_context& context, cl_device_id& deviceId);
