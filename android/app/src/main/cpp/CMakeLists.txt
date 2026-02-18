cmake_minimum_required(VERSION 3.10.2)

project(video_engine VERSION 1.0.0 LANGUAGES CXX)

add_library(video_engine SHARED video_engine.cpp)

# Optional: Add any dependencies like FFmpeg if they were available
# target_link_libraries(video_engine log)
