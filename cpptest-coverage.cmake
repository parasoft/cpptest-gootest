#
# CMake extension for integrating C/C++test code coverage.
#

# Enable C/C++test code coverage integration:
#   cmake -DCPPTEST_COVERAGE=ON ...
option(CPPTEST_COVERAGE "Enable C/C++test code coverage integration")

function (cpptest_enable_coverage)
  if(CYGWIN OR MSYS)
    execute_process(COMMAND cygpath
                            -m
                            ${CMAKE_SOURCE_DIR}
                    OUTPUT_VARIABLE CPPTEST_SOURCE_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND cygpath
                            -m
                            ${CMAKE_BINARY_DIR}
                    OUTPUT_VARIABLE CPPTEST_BINARY_DIR
                    OUTPUT_STRIP_TRAILING_WHITESPACE)
  else()
    set(CPPTEST_BINARY_DIR "${CMAKE_BINARY_DIR}")
    set(CPPTEST_SOURCE_DIR "${CMAKE_SOURCE_DIR}")
  endif()

  # Configure C/C++test compiler identifier
  set(CPPTEST_COMPILER_ID "gcc_10-64")
  # Configure coverage type(s) for instrumentation engine - see 'cpptestcc -help' for details
  set(CPPTEST_COVERAGE_TYPE_INSTRUMENTATION -line-coverage -decision-coverage -mcdc-coverage)
  # Configure coverage type(s) for reporting engine - see 'cpptestcov -help' for details
  set(CPPTEST_COVERAGE_TYPE_REPORT "LC,DC,MCDC" )
  # Configure C/C++test project name
  set(CPPTEST_PROJECT_NAME ${CMAKE_PROJECT_NAME})
  # Configure coverage workspace folder
  set(CPPTEST_COVERAGE_WORKSPACE ${CPPTEST_BINARY_DIR}/cpptest-coverage/${CPPTEST_PROJECT_NAME})
  # Configure coverage log file
  set(CPPTEST_COVERAGE_LOG_FILE ${CPPTEST_COVERAGE_WORKSPACE}/${CPPTEST_PROJECT_NAME}.clog)
  # Configure C/C++test installation directory
  set(CPPTEST_HOME "" CACHE STRING "C/C++test installation directory")
  if(CPPTEST_HOME)
    set(CPPTEST_HOME_DIR ${CPPTEST_HOME})
  else()
    set(CPPTEST_HOME_DIR $ENV{CPPTEST_HOME})
  endif()
  
  if(NOT CPPTEST_HOME_DIR)
    message(FATAL_ERROR "CPPTEST_HOME not set" )
  endif()

  # Build C/C++test coverage runtime library
  set(CPPTEST_RUNTIME_BUILD_DIR ${CMAKE_BINARY_DIR}/cpptest-runtime)

  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
                          ${CPPTEST_RUNTIME_BUILD_DIR})
  execute_process(COMMAND ${CMAKE_COMMAND}
                          ${CPPTEST_HOME_DIR}/runtime
                          "-G${CMAKE_GENERATOR}"
                          "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
                          "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
                          "-DCPPTEST_LOG_FILE_NAME=${CPPTEST_COVERAGE_LOG_FILE}"
                  WORKING_DIRECTORY
                          ${CPPTEST_RUNTIME_BUILD_DIR})
  execute_process(COMMAND ${CMAKE_COMMAND}
                          --build .
                  WORKING_DIRECTORY
                          ${CPPTEST_RUNTIME_BUILD_DIR})

  if(MSVC)
    set(CPPTEST_LINKER_FLAGS
        "\"${CPPTEST_RUNTIME_BUILD_DIR}/cpptest_shared.lib\"")

    # Add C/C++test coverage runtime library to shared library linker flags
    set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} ${CPPTEST_LINKER_FLAGS}"
        PARENT_SCOPE)
  else()
    set(CPPTEST_LINKER_FLAGS
        "-Wl,--whole-archive \"${CPPTEST_RUNTIME_BUILD_DIR}/libcpptest_static.a\" -Wl,--no-whole-archive")
  endif()

  # Add C/C++test coverage runtime library to executable linker flags
  set(CMAKE_EXE_LINKER_FLAGS
      "${CMAKE_EXE_LINKER_FLAGS} ${CPPTEST_LINKER_FLAGS}"
      PARENT_SCOPE)

  # Configure cpptestcc command line
  set(CPPTEST_CPPTESTCC ${CPPTEST_HOME_DIR}/bin/cpptestcc)
  set(CPPTEST_CPPTESTCC_OPTS
      -workspace "${CPPTEST_COVERAGE_WORKSPACE}"
      -compiler ${CPPTEST_COMPILER_ID}
      ${CPPTEST_COVERAGE_TYPE_INSTRUMENTATION}
      -exclude "regex:*"
      -include "regex:${CPPTEST_SOURCE_DIR}/*"
      -exclude "regex:${CPPTEST_BINARY_DIR}/*"
      -ignore "regex:*_test.cpp"
      -ignore "regex:${CPPTEST_BINARY_DIR}/*")

  # Use advanced settings file for cpptestcc, if exists
  if(EXISTS "${CMAKE_SOURCE_DIR}/.cpptestcc")
    set(CPPTEST_CPPTESTCC_OPTS
        ${CPPTEST_CPPTESTCC_OPTS}
        -psrc "${CPPTEST_SOURCE_DIR}/.cpptestcc")
  endif()

  # Prefix C++ compiler with cpptestcc
  set(CMAKE_CXX_COMPILER_LAUNCHER
      ${CPPTEST_CPPTESTCC} ${CPPTEST_CPPTESTCC_OPTS} -- PARENT_SCOPE)

  # Prefix C compiler with cpptestcc
  set(CMAKE_C_COMPILER_LAUNCHER
      ${CPPTEST_CPPTESTCC} ${CPPTEST_CPPTESTCC_OPTS} -- PARENT_SCOPE)

  # For compatibility with older CMake versions:  
  # set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE
  #    "${CPPTEST_CPPTESTCC} ${CPPTEST_CPPTESTCC_OPTS} -- ")

  # Compute coverage data files (.json) into ${CPPTEST_SOURCE_DIR}/.coverage
  add_custom_target(cpptestcov-compute
    COMMAND
    rm -rf "${CPPTEST_SOURCE_DIR}/.coverage"
    &&
    mkdir -p "${CPPTEST_SOURCE_DIR}/.coverage"
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov compute
        -map="${CPPTEST_COVERAGE_WORKSPACE}/.cpptest/cpptestcc"
        -clog="${CPPTEST_COVERAGE_LOG_FILE}"
        -out="${CPPTEST_SOURCE_DIR}/.coverage"
        -coverage=${CPPTEST_COVERAGE_TYPE_REPORT}
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov index
        "${CPPTEST_SOURCE_DIR}/.coverage"   
  )

  # Generate coverage reports:
  # - plain text: ${CPPTEST_SOURCE_DIR}/.coverage/coverage.txt
  # - markdown: ${CPPTEST_SOURCE_DIR}/.coverage/coverage.md
  # - html: ${CPPTEST_SOURCE_DIR}/.coverage/coverage.html
  # - console output
  add_custom_target(cpptestcov-report
    COMMAND
    date +'build-%m_%d_%y-%H_%M_%S' >
        "${CPPTEST_BINARY_DIR}/build.id"
    &&
    mkdir -p "${CPPTEST_SOURCE_DIR}/reports"
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov report dtp-summary
        -coverage=${CPPTEST_COVERAGE_TYPE_REPORT}
        -root ${CPPTEST_SOURCE_DIR}
        -build `cat "${CPPTEST_BINARY_DIR}/build.id"`
        "${CPPTEST_SOURCE_DIR}/.coverage" >
        "${CPPTEST_SOURCE_DIR}/reports/dtp-summary.xml"
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov report dtp-details
        -root ${CPPTEST_SOURCE_DIR}
        -build `cat "${CPPTEST_BINARY_DIR}/build.id"`
        -scm
        "${CPPTEST_SOURCE_DIR}/.coverage" >
        "${CPPTEST_SOURCE_DIR}/reports/dtp-details.xml"
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov report dtp-gtest
        -root ${CPPTEST_SOURCE_DIR}
        -build `cat "${CPPTEST_BINARY_DIR}/build.id"`
        -scm
        "${CPPTEST_BINARY_DIR}/gtest-report/*.xml" >
        "${CPPTEST_SOURCE_DIR}/reports/dtp-gtest.xml"
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov report html-multipage
        -scm
        -code
        -root ${CPPTEST_SOURCE_DIR}
        -coverage=${CPPTEST_COVERAGE_TYPE_REPORT}
        "${CPPTEST_SOURCE_DIR}/.coverage"
        -out "${CPPTEST_SOURCE_DIR}/reports"
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov report text
        -root ${CPPTEST_SOURCE_DIR}
        -coverage=${CPPTEST_COVERAGE_TYPE_REPORT}
        "${CPPTEST_SOURCE_DIR}/.coverage"
    &&
    ${CPPTEST_HOME_DIR}/bin/cpptestcov report mcdc
        "${CPPTEST_SOURCE_DIR}/.coverage"
  )

  # Apply coverage suppressions to existing coverage data files
  add_custom_target(cpptestcov-suppress
    COMMAND
    ${CPPTEST_HOME_DIR}/bin/cpptestcov suppress
        "${CPPTEST_SOURCE_DIR}/.coverage"
  )

  # Publish results to Parasoft DTP
  add_custom_target(cpptestcov-publish
    COMMAND
    ${CPPTEST_HOME_DIR}/bin/cpptestcov publish
        -settings "${CPPTEST_SOURCE_DIR}/cpptestcov.properties"
        "${CPPTEST_SOURCE_DIR}/reports/*.xml"
  )

endfunction()

if(CPPTEST_COVERAGE)
  cpptest_enable_coverage()
endif()
