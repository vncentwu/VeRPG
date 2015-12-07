/* Simple cpp program to handle and simulate display/output. It only writes to files and 
prints the content to screen. The rest is handled by the engine hardware*/

#include <iostream>
#include <fstream>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

using namespace std;

ofstream file;

char data[3];
char exit_char[] = "F";

int main (){
	usleep(2 * 1000 * 100);
	while(1)
	{
		cout << "____________________________________________________________________________________________________\n> ";
		cin.getline(data, 3);
		file.open("input.data", std::ios::app); //appends to end of file
		file << data << endl;
		if(!strcmp(data, exit_char))
			return 0;
/*		srand(time(NULL));
		int r = rand() % 4;
		switch(r)
		{
			case 0:
				file << "1" << endl;
			case 1:
				file << "2" << endl;
			case 2:
				file << "3" << endl;
			case 3:
				file << "4" << endl;
		}*/
		file.close();
		usleep(2 * 100 * 100);
	}
}
