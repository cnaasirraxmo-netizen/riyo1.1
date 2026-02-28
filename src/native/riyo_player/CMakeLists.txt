cmake_minimum_required(VERSION 3.10)
project(riyo_player)

set(CMAKE_CXX_STANDARD 17)

include_directories(include)

add_library(riyo_player SHARED src/riyo_player.cpp)

# Target-specific platform dependencies (placeholders)
if (ANDROID)
    # Add MediaCodec dependencies
elseif (APPLE)
    # Add VideoToolbox dependencies
elseif (UNIX)
    # Add VAAPI/VDPAU dependencies
endif()
