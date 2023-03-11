//let's call this file do_bam.cpp

#include <iostream>
#include "api/BamReader.h"
#include "api/BamWriter.h"

using namespace std;
using namespace BamTools;

int main(int argc, char* argv[])
{
    string  inputFileName;

    if ( argc == 2 ) 
    {
            inputFileName  = argv[1] ;
    }
    else {
        cerr << "Wrong number of arguments." << endl;
        return 1;
    }

    BamReader reader;
    if (!reader.Open(inputFileName)) {
        cerr << "Could not open input BAM file." << endl;
        return 1;
    }

    BamAlignment al;
    while (reader.GetNextAlignment(al)) {
         cout << "Qualities " << al.Qualities <<endl;
    }

reader.Close();
return 0;
}
