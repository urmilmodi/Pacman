#include<iostream>
using namespace std;

int main() {

    int counterX = 0;
    int counterY = 0;
    bool test = false;

    for (int i = 0; i < 19200; i++) {

    if (true) {
    cout << counterX << " " << counterY << " " << (160*(counterY + 1) + counterX - 1) << " " << i + 159 << endl;
    test = true;
    }
    if (counterX == 159) {
		counterX = 0;
		counterY = counterY + 1;
    }
	else {
        counterX = counterX + 1;
    }
    }
}