#!/bin/bash

echo -e "[*] Lab 2 Tests:s"

# for lab2-red namespace
if [[ $(kubectl auth can-i delete deployment --as jane -A) == yes ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl auth can-i delete deployment --as jane -n default) == yes ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl auth can-i delete deployment --as jane -n lab2-red) == yes ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl auth can-i delete pod --as jane -A) == no ]]; then echo "success";else echo "failed"; fi

# for blue namespace
if [[ $(kubectl auth can-i delete deployment --as jim -A) == no ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl auth can-i delete deployment --as jim -n default) == no ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl auth can-i delete deployment --as jim -n lab2-red) == yes ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl auth can-i delete pod --as jim -A) == no ]]; then echo "success";else echo "failed"; fi