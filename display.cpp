/* Simple cpp program to handle and simulate display/output. It only writes to files and 
prints the content to screen. The rest is handled by the engine hardware*/

#include <iostream>
#include <fstream>
#include <unistd.h>

using namespace std;

int main (){
	ofstream file;
	char data[100];
	while(1)
	{
		cout << "Command: ";
		cin.getline(data, 100);
		file.open("input.data", std::ios::app);
		//cout << "data: "<< data << endl;
		file << data << endl;
		file.close();
		//sleep(1);

	}


}