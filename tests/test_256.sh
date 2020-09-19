#!/bin/bash
echo Testing ./mul
time=$(date +%s%N | cut -b1-13)
for number in {1..68}
do
    python3 generate.py $number > input.txt
    result=$(cat input.txt | ../build/mul)
    for line in $(cat output.txt) 
    do
        if [[ "$line" == "$result" ]]; then
            echo "Test $number: OK"
            rm output.txt input.txt
        else
            echo "Test $number: Fail!"
            echo "Expected $line."
            echo "Found $result"
            echo "You failed on test $number"
            exit 1
        fi
    done
done
echo "Tests passed in $(($(date +%s%N | cut -b1-13) - $time)) miliseconds"
