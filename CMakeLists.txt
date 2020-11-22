project(stuff)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
cmake_minimum_required(VERSION 3.5)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic")
if(CMAKE_BUILD_TYPE MATCHES Debug)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -fno-omit-frame-pointer")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fsanitize=undefined")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rdynamic -fsanitize=address -fsanitize=undefined")
endif()

add_subdirectory(thirdparty/spdlog)

include_directories(
    common
    stuff
)

add_executable(stuff
    main.cpp
)

target_link_libraries(stuff
    spdlog::spdlog
    sfml-system
    sfml-network
    sfml-window
    sfml-graphics
    sfml-audio
)