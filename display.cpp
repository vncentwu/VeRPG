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

	char data[100] = "2";
	usleep(2 * 1000 * 100);
	//print_map();
	while(1)
	{
		cout << "> ";
		cin.getline(data, 100);
		file.open("input.data", std::ios::app); //appends to end of file
		file << data << endl;
		file.close();
		usleep(4 * 1000 * 100);
		//print_map();
	}
}

void print_map()
{
	for(int i = 0; i < 30; i++)
	cout << endl;
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

/*void print_map_clean()
{
	 ifstream fin; // Initialise filestream object. 
	 char c; 
	 fin.open("test.txt", ios::in); // Open an input filestream. 
	 // Check if file opened. 
	 // fin.fail() returns 1 if there is a fail in the filestream. 
	 if(fin.fail()) 
	 { 
	 cout << "Error: Unable to open test.c.\n"; 
	 exit(1); 
	 } 
	 fin.get(c); // Get first character for kicks. 
	 // While the stream hasn't failed or reached the end of file, read and display. 
	 while(!fin.fail() && !fin.eof()) 
	 { 
	 	cout << c; // Display character. 
	 	fin.get(c); // Get the next character from the stream. 
	 } fin.close(); // - See more at: https://www.gidforums.com/t-5188.html#sthash.V6ZFBLQm.dpuf
}*/