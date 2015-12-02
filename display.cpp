/* Simple cpp program to handle and simulate display/output. It only writes to files and 
prints the content to screen. The rest is handled by the engine hardware*/

#include <iostream>
#include <fstream>
#include <unistd.h>

using namespace std;

ofstream file;
ifstream output;

void print_map();

int main (){

	char data[100];
	usleep(2 * 1000 * 100);
	print_map();
	while(1)
	{
		cout << "> ";
		cin.getline(data, 100);
		for(int i = 0; i < 30; i++)
			cout << endl;
		file.open("input.data", std::ios::app); //appends to end of file
		file << data << endl;
		file.close();
		usleep(2 * 100 * 100);
		print_map();
	}
}

void print_map()
{
	output.open("output.data");
	if(output.fail())
		cout << "Opening output data file failed." << endl;
	else
	{
		filebuf* buf = output.rdbuf();
		if(buf != NULL)
			cout << buf << endl;
		else
			cout << "Print failed" << endl;
	}	
	output.close();
}