#include <stdio.h>
#include <stdlib.h>
#include "read.hpp"
#define SIZE_OF_INPUT 110
#define NUMBER_OF_PATTERN 21

#define WIDTH_OF_PATTERN 16
int read_from_string(int req)
{

	// input
	static int result[NUMBER_OF_PATTERN] = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
	};
	static int input[SIZE_OF_INPUT] = {2, 2, 2, 3, 3, 3, 0, 0, 0, 1, 1, 1, 5, 5, 5, 4, 4, 4, 6, 6, 6, 17, 17, 26, 32, 16, 16, 8,
									   25, 8, 29, 7, 7, 9, 9, 9, 9, 9, 9, 10, 10, 10, 19, 19, 20, 20, 12, 12, 11, 11, 18, 8, 8,
									   8, 18, 8, 17, 27, 17, 26, 21, 32, 22, 25, 13, 14, 29, 35, 12, 12, 12, 36, 12, 19, 37, 19,
									   15, 15, 15, 15, 18, 18, 18, 18, 27, 27, 23, 23, 23, 23, 35, 33, 36, 33, 15, 37, 30, 31, 24,
									   28, 34, 34, 23, 26, 32, 25, 29, 35, 36, 37};

	static int pattern[NUMBER_OF_PATTERN][WIDTH_OF_PATTERN] =
		{
			{2, 26, 256},
			{2, 17, 19, 26, 256},
			{2, 17, 19, 21, 15, 23, 30, 26, 256},

			{3, 32, 256},
			{3, 16, 20, 32, 256},
			{3, 16, 20, 22, 15, 23, 31, 32, 256},

			{0, 25, 256},
			{0, 8, 12, 25, 256},
			{0, 8, 12, 13, 15, 23, 24, 25, 256},

			{1, 29, 256},
			{1, 7, 11, 29, 256},
			{1, 7, 11, 14, 15, 23, 28, 29, 256},

			{5, 9, 18, 35, 256},
			{5, 9, 8, 12, 18, 35, 256},
			{5, 9, 8, 12, 18, 33, 34, 35, 256},

			{4, 9, 18, 36, 256},
			{4, 9, 8, 12, 18, 36, 256},
			{4, 9, 8, 12, 18, 33, 34, 36, 256},

			{6, 10, 27, 37, 256},
			{6, 10, 17, 19, 27, 37, 256},
			{6, 10, 17, 19, 27, 15, 23, 37, 256}

		};

	//-----------------------
	static int pointer[NUMBER_OF_PATTERN] = {0};

	static int error_array[3];
	int i = 0;
	int j = 0;
	int k = 0;
	int z = 0;
	int e = 0;
	static int fail = 0;
	int count = 0;
	static bool read = 0;


	for (i = 0; i < SIZE_OF_INPUT; i++)
	{

		if (fail == 1)
		{
			result[0] = 256;
			result[1] = i - 1;
			result[2] = error_array[0];
			result[3] = error_array[1];
			result[4] = error_array[2];
			for (e = 5; e < 21; e++)
			{
				result[e] = 256;
			}
			fail = 2;
			return result[req];
		}
		else if (fail == 2){
			return result[req];
		}
		if(read == 1){
			return result[req];
		}

		for (j = 0; j < NUMBER_OF_PATTERN; j++)
		{
			k = pointer[j];
			if (input[i] == pattern[j][k])
			{
				k++;
				pointer[j] = k;

				if (pointer[j] == WIDTH_OF_PATTERN || pattern[j][k] == 256)
				{
					pointer[j] = 0;
					result[j] = result[j] + 1;
				}
				break;
			}

			else
			{
				if (j == 20)
				{

					for (z = i; z >= 0; z--)
					{
						error_array[count] = input[z];

						if (count == 3)
						{
							break;
						}

						count++;
					}
					//printf("error\n");
					fail = 1;
					break;
				}
			}
		}
	}
	read = 1;
	return result[req];
}
