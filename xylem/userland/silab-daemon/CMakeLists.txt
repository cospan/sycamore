cmake_minimum_required(VERSION 2.6.0)

# pull in the pods macros. See cmake/pods.cmake for documentation
set(POD_NAME silab-daemon)
include(cmake/pods.cmake)

# create an executable, and make it public
add_executable(silab-daemon src/main.c)

pods_install_executables(silab-daemon)
