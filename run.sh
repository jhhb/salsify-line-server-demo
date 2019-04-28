#!/bin/bash
redis-server &
bundle exec passenger start
