#include <stdio.h>

extern int bprintf(const char*, ...);

int main()
{
    bprintf("%s %x %d %d %d %d %d %d", "hello world", 12, -13, -12, -11, -200, -9, -8);
    return 0;
}
