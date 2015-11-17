#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Proper syntax is $0 encrypted_file dictionary"
	exit 1
fi

if [ ! -f $1 ]; then
	echo "Encrypted file, $1, doesn't exist!"
	exit 2
fi

if [ ! -f $2 ]; then
	echo "Dictionary, $2, doesn't exist!"
	exit 3
fi

tput clear

echo "Brute forcing $1 using dictionary $2"

wordlist_file=$(cat $2)
wordlist=(${wordlist_file// / })
total_words=${#wordlist[@]}
file=$1
running_workers=0
num_workers=8
password_found=0

trap "exit" INT TERM
trap "tput cnorm && times && kill 0" EXIT

function worker_thread {
  start=0
  end=$total_words

  if [ $num_workers -gt 1 ]; then
    if [ $running_workers -ne 1 ]; then
      start=$((($end/$num_workers)*(running_workers-1)))
    fi
    end=$((($end/$num_workers)*running_workers))
  fi

  tput cup $(($running_workers+1)) 0 && echo "Worker $running_workers has processed 0/$(($end-$start)) words"

  for i in `seq $start $(($end-1))`;
  do
    word=${wordlist[$i]}
    word=$(tr -dc '[[:print:]]' <<< "$word")

    if [ $(($i%50)) -eq 0 ]; then
      tput cup $(($running_workers+1)) 0 && echo "Worker $running_workers has processed $(($i-$start))/$(($end-$start)) words"
    fi
    gpg --passphrase $word --decrypt $file &> /dev/null && tput cup $(($num_workers+2)) 0 && echo "Password found by worker $running_workers: $word" && kill 0
  done
}

echo "Total words to process: $total_words"

tput civis

for i in $(seq $num_workers); do
  running_workers=$(($running_workers+1))
  worker_thread &
done

wait
