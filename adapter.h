#include <regex.h>
#include <stdint.h>

regex_t* alloc_regex_t(void);
size_t getNumSubexpression(regex_t* ptr);
void free_regex_t(regex_t* ptr);