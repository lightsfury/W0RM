
project(W0RM)
cmake_minimum_required(VERSION 2.8)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR
"In-source builds are not allowed. Please specify a directory outside \
the GCC-ARM directory. This process created the file 'CMakeCache.txt' and \
the directory 'CMakeFiles'; please delete them.")
endif()

# Set up proper output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

set(W0RM_GTEST_PATH "${CMAKE_SOURCE_DIR}/deps/gtest-1.7.0" CACHE FILEPATH "Absolute path to the root of the GoogleTest directory.")

include_directories("${CMAKE_SOURCE_DIR}/include")
link_directories("${CMAKE_BINARY_DIR}/lib")

add_subdirectory(src)
add_subdirectory(tests)
