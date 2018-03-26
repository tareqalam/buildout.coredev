#!/bin/bash
(
  time (

    if (hash chromium 2>/dev/null || hash chromedriver 2>/dev/null)
    then
      SELENIUM_DRIVER=chrome
    fi

    if (hash firefox 2>/dev/null || hash geckodriver 2>/dev/null)
    then
      SELENIUM_DRIVER=firefox
    fi

    if [ -z "$SELENIUM_DRIVER" ]
    then
      echo 'No suitable Selenium driver found, you need either chromedriver or firefox in your $PATH!'
      exit 1
    fi

    XVFB_RUN='bin/alltests'

    if hash xvfb-run 2>/dev/null
    then
      XVFB_RUN='xvfb-run bin/alltests'
    fi

    PARALLEL="$(getconf _NPROCESSORS_ONLN)"

    RUNS=()

    RUNS+=('time (bin/alltests-at --xml -j 1 > /dev/null 2>&1)')
    RUNS+=('time (bin/mtest --at -j 1 > /dev/null 2>&1)')

    if [ "$PARALLEL" -gt '1' ]
    then
      RUNS+=("time (bin/alltests-at --xml -j $PARALLEL > /dev/null 2>&1)")
      RUNS+=("time (bin/mtest --at -j $PARALLEL > /dev/null 2>&1)")
    fi

    RUNS+=('time (bin/alltests --xml -j 1 > /dev/null 2>&1)')
    RUNS+=('time (bin/mtest --dx -j 1 > /dev/null 2>&1)')

    if [ "$PARALLEL" -gt '1' ]
    then
      RUNS+=("time (bin/alltests --xml -j $PARALLEL > /dev/null 2>&1)")
      RUNS+=("time (bin/mtest --dx -j $PARALLEL > /dev/null 2>&1)")
    fi

    RUNS+=("time (ROBOTSUITE_PREFIX=ONLYROBOT ROBOT_BROWSER=$SELENIUM_DRIVER $XVFB_RUN --xml --all -t ONLYROBOT -j 1 > /dev/null 2>&1)")
    RUNS+=('time (bin/mtest --robot -j 1 > /dev/null 2>&1)')

    if [ "$PARALLEL" -gt '1' ]
    then
      RUNS+=("time (bin/mtest --robot -j $PARALLEL > /dev/null 2>&1)")
    fi

    RUNS+=("time (
      ROBOTSUITE_PREFIX=ONLYROBOT ROBOT_BROWSER=$SELENIUM_DRIVER $XVFB_RUN --xml --all -t ONLYROBOT -j 1 > /dev/null 2>&1
      bin/alltests-at --xml -j 1 > /dev/null 2>&1
      bin/alltests --xml -j 1 > /dev/null 2>&1
      )")

    RUNS+=('time (bin/mtest --at --dx --robot -j 1 > /dev/null 2>&1)')

    if [ "$PARALLEL" -gt '1' ]
    then
      RUNS+=("time (
        ROBOTSUITE_PREFIX=ONLYROBOT ROBOT_BROWSER=$SELENIUM_DRIVER $XVFB_RUN --xml --all -t ONLYROBOT -j 1 > /dev/null 2>&1
        bin/alltests-at --xml -j $PARALLEL > /dev/null 2>&1
        bin/alltests --xml -j $PARALLEL > /dev/null 2>&1
        )")

      RUNS+=("time (bin/mtest --at --dx --robot -j $PARALLEL > /dev/null 2>&1)")
    fi

    echo ""
    date -u +'%Y-%m-%d %H:%M:%S UTC'
    echo ""

    if hash lscpu 2>/dev/null
    then
      lscpu
      echo ""
      free -h
      echo ""
    fi

    if hash system_profiler 2>/dev/null
    then
      system_profiler SPHardwareDataType | grep -v -E '(Serial|UUID|ROM|SMC)'
      echo ""
    fi

    for run in "${RUNS[@]}"
    do
      echo "$run"
      (eval "$run" 2>&1)
      echo ""
    done

  ) 2>&1
) | tee "$(date -u +'%Y-%m-%d')-buildout.coredev-metrification.log"
# EOF
