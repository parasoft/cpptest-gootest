#include "goo.h"

int getValue(int a, int b)
{
    if ((a > 0) && (b > 0)) {
        return a * b;
    }

    if (a > 0) {
        return a;
    } else {
        return b;
    }

    return 0; // parasoft-cov-suppress "This is a dead-code that will be fixed later"
}

int otherFoo()
{
    int k;
    return k + 0;
}
