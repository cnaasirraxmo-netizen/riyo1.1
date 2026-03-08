cmake_minimum_required(VERSION 3.10.2)

project("riyo_video_engine")

set(CMAKE_CXX_STANDARD 17)

add_library(riyo_video_engine SHARED
    src/video_engine.cpp
    src/native_bridge.cpp
    modules/demuxer.cpp
    modules/decoder.cpp
    modules/renderer.cpp
    modules/buffer_manager.cpp
    modules/network_loader.cpp
    modules/av_sync.cpp
)

target_include_directories(riyo_video_engine PRIVATE
    include
    modules
)

find_library(log-lib log)
find_library(android-lib android)
find_library(mediandk-lib mediandk)
find_library(jnigraphics-lib jnigraphics)

target_link_libraries(riyo_video_engine
    ${log-lib}
    ${android-lib}
    ${mediandk-lib}
    ${jnigraphics-lib}
)
