#include <stdio.h>
#include "read.hpp"

int main()
{
	int i = 0;
	int g = 0;
	read_from_string(0);

	for (i = 0; i < 21; i++)
	{
		g = read_from_string(i);
		printf("pattern %d: %d\n", i, g);
	}
	return 0;
}
