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

    return 0; // parasoft-cov-suppress "validated - will be removed in the future"
}

