cmake_minimum_required(VERSION 3.21)
project(llama_dart LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(NOT DEFINED LLAMA_CPP_DIR)
  message(FATAL_ERROR "LLAMA_CPP_DIR must point to third_party/llama.cpp")
endif()

# Build llama.cpp library
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)

add_subdirectory(${LLAMA_CPP_DIR} ${CMAKE_BINARY_DIR}/llama_cpp_build)

add_library(llama_dart SHARED
  llama_dart.cpp
)

target_include_directories(llama_dart PRIVATE
  ${LLAMA_CPP_DIR}/include
)

target_link_libraries(llama_dart PRIVATE llama)