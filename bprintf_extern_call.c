extern int bprintf(const char*, ...);

int main()
{
    bprintf("%s %x %d", "hello world", 12, -13);
    return 0;
}
