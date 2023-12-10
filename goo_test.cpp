#include <gtest/gtest.h>
#include "goo.h"

// 
TEST(GooTest, TestGetValueWithZero) {
  RecordProperty("cpptest_filename", __FILE__);
  RecordProperty("req", "CIC-4");
 
  EXPECT_EQ(getValue(0, 0), 0);
}

// 
TEST(GooTest, TestGetValueWithPositive) {
  RecordProperty("cpptest_filename", __FILE__);
  RecordProperty("req", "CIC-5");

  EXPECT_EQ(getValue(5, 5), 25);
}

// 
TEST(GooTest, TestGetValueWithMix) {
  RecordProperty("cpptest_filename", __FILE__);
  RecordProperty("req", "CIC-6");

  EXPECT_EQ(getValue(5, -5), 5);
}

// 
TEST(GooTest, TestGetValueWithNegative) {
  RecordProperty("cpptest_filename", __FILE__);
  RecordProperty("req", "CIC-7");

  EXPECT_EQ(getValue(-5, -5), -5);
}