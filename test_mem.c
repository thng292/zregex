#include "adapter.h"

int main()
{
    regex_t* tmp = alloc_regex_t();
    regcomp(tmp, "[ab]c", 0);
    free_regex_t(tmp);
    return 0;
}