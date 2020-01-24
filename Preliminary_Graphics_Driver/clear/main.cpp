#include <iostream>
#include <fstream>
#include <string>
#include <vector>
 
/*
 * It will iterate through all the lines in file and
 * put them in given vector
 */
bool getFileContent(std::string fileName, std::vector<std::string> & vecOfStrs)
{
 
	// Open the File
	std::ifstream in(fileName.c_str());
 
	// Check if object is valid
	if(!in)
	{
		std::cerr << "Cannot open the File : "<<fileName<<std::endl;
		return false;
	}
 
	std::string str;
	// Read the next line from File untill it reaches the end.
	while (std::getline(in, str))
	{
		// Line contains string of length > 0 then save it in vector
		if(str.size() > 0)
			vecOfStrs.push_back(str);
	}
	//Close The File
	in.close();
	return true;
}
 
 
int main()
{
	std::vector<std::string> vecOfStr;
 
	// Get the contents of file in a vector
	bool result = getFileContent("clr.txt", vecOfStr);
 
	if(result)
	{
		// Print the vector contents
		//for(std::string & line : vecOfStr)
			//std::cout<<line<<std::endl;

        int clearLeft, clearRight, clearUp, clearDown;

        std::vector<std::string> clearVect;

        for (int y = 0; y < 240; y++) {
            for (int x = 0; x < 320; x++) {
                clearVect.push_back("0000");
            }
        }
        int size = 10;

        for (int y = 0; y < 240; y++) {
            for (int x = 52; x < 216; x++) {

                clearLeft = 0;
                clearRight = 0;
                clearUp = 0;
                clearDown = 0;
                for (int pixel = 0; pixel < size; pixel++) {
                    
                    if (x > 0) {
                        if (!(vecOfStr[320*(y + pixel) + x - 1] != "000000000000")) {
                            clearLeft = 1;
                        }
                    } else {clearLeft = 0;}

                    if (x < 319) {
                        if (!(vecOfStr[320*(y + pixel) + x + size] != "000000000000")) {
                            clearRight = 1;
                        }
                    } else {clearRight = 0;}

                    if (y > 0) {
                        if (!(vecOfStr[320*(y - 1) + x + pixel] != "000000000000")) {
                            clearUp = 1;
                        }
                    } else {clearUp = 0;}

                    if (y < 239) {
                        if (!(vecOfStr[320*(y + size) + x + pixel] != "000000000000")) {
                            clearDown = 1;
                        }
                    } else {clearDown = 0;}

                    if (((x > 51 && x < 51 + 37) || (x < 216 && x > 216-37)) && y > 90 && y < 150) {
                        clearLeft = 0;
                        clearDown = 0;
                        clearUp = 0;
                        clearRight = 0;
                    }
                }
                clearVect[320*y + x] = std::to_string(clearLeft) + std::to_string(clearRight) + std::to_string(clearUp) + std::to_string(clearDown);
            }
        }

        std::ofstream outFile("out.txt");
        // the important part
        for (int i = 0; i < 76801; i++) {
            outFile << "    " << i << ": " << clearVect[i] << ";" << "\n";
        }
    }
}