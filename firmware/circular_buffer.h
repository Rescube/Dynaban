#ifndef _CIRCULAR_BUFFER_H_
#define _CIRCULAR_BUFFER_H_
#include <wirish/wirish.h>

struct buffer {
    int size;
    long* buf;
    int start;
    int end;
    int nbElements;
};

void buffer_init(buffer * pBuf, int pSize, long pInit);
void buffer_add(buffer * pBuf, long pValue);
long buffer_get(buffer * pBuf);
void buffer_print(buffer * pBuf);

#endif /* _CIRCULAR_BUFFER_H_*/
