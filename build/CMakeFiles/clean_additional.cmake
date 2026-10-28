# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/DashboardApp_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/DashboardApp_autogen.dir/ParseCache.txt"
  "DashboardApp_autogen"
  )
endif()
