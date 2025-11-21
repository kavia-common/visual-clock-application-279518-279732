# BEGIN AUTO TEST_BASIC
add_executable(test_basic src/tests/test_basic.cpp)
target_include_directories(test_basic PRIVATE ${CMAKE_SOURCE_DIR}/vendor)
# END AUTO TEST_BASIC
