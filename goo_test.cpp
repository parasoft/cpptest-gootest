#include <gtest/gtest.h>
#include "goo.h"

// 
TEST(GooTest, TestGetValueWithZero) {
  EXPECT_EQ(getValue(0, 0), 0);
}

// 
TEST(GooTest, TestGetValueWithPositive) {
  EXPECT_EQ(getValue(5, 5), 25);
}

//
TEST(GooTest, TestGetValueWithMix) {
  EXPECT_EQ(getValue(5, -5), 5);
}

