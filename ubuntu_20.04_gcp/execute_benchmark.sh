#!/bin/bash

source ~/.bashrc

adb devices

echo "Starting humanoid ..."
docker run -d --rm  -p 50405:50405 phtcosta/humanoid:1.0

echo "Executing benchmark"
cd $BENCHMARK_HOME
python main.py -tools monkey -t 30 -r 1 -s s
