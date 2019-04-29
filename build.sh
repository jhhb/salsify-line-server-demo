#!/bin/bash
rvm install ruby-2.3.7
source ~/.rvm/scripts/rvm
rvm use ruby-2.3.7
gem install bundler --version 2.0.1
brew install redis
bundle install
