project(set10108-lab04)
cmake_minimum_required(VERSION 3.17)
set(CMAKE_CXX_STANDARD 17)
include_directories(../contrib)

find_package(OpenMP)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")

add_executable(hello-openmp hello-openmp.cpp)
add_executable(pi-openmp pi-openmp.cpp)
add_executable(bubble-sort bubble-sort.cpp)
add_executable(parallel-sort parallel-sort.cpp)
add_executable(trapezoidal trapezoidal.cpp)
add_executable(scheduler-test schedule-test.cpp)
add_executable(my-mandelbart my-mandelbart.cpp)
add_executable(my-queue my-queue.cpp)