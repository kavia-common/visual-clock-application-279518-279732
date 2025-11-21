#define CATCH_CONFIG_MAIN
#include "catch.hpp"
#include <string>
TEST_CASE("basic string check"){
  REQUIRE(std::string("clock") + "" == "clock");
}
