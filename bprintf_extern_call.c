#include <stdio.h>

extern int bprintf(const char*, ...);

int main()
{
    bprintf("1. %s\n", "Hello, world!");

    bprintf("2. %x %x %x %x\n", 0xFF, 0xABCD, 0x0, 0xDEADBEEF);

    bprintf("3. %o %o %o\n", 8, 64, 0777);

    bprintf("4. %b %b %b\n", 0b1010, 0xFF, 0x7F);

    bprintf("5. %c %c %c\n", 'C', '\n', 'D');

    bprintf("6. %%\n");

    bprintf("7. %d %x %o %b %c %s\n", 255, 255, 255, 255, '!', "mixed");

    bprintf("8. %d %x %o %b\n",
            0x7FFFFFFF, 0x7FFFFFFF,
            0x7FFFFFFF, 0x7FFFFFFF);

    bprintf("9. %s\n",
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
            "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
            "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. "
            "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum. "
            "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.");
    return 0;
}
