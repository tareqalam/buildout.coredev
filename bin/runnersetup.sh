#!/bin/bash
set -e

time (
  set -e
  apt update
  apt build-dep -y python python-imaging python-lxml python-pyscss python-yaml
  apt install -y git python-pip python-virtualenv wv pdftohtml locales-all xvfb firefoxdriver
  )

useradd -s /bin/bash -m plone

su - plone -c '(
  set -e
  git clone --branch roto-testrunner-wrapper-51 --depth 1 https://github.com/plone/buildout.coredev.git
  cd buildout.coredev
  time ./bootstrap.sh
  bin/benchmark-tests.sh
  )'
