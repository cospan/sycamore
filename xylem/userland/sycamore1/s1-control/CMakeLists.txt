cmake_minimum_required(VERSION 2.6.0)

# pull in the pods macros. See cmake/pods.cmake for documentation
set(POD_NAME s1-control)
include(cmake/pods.cmake)
include(cmake/FindUSB.cmake)

# create an executable, and make it public
add_executable(s1-control src/main.c src/comm.c src/eeprom.c)
target_link_libraries(s1-control ftdi)

pods_install_executables(s1-control)
