#!/bin/bash

# for red namespace
if [[ $(kubectl -n red auth can-i get secrets --as jane) == yes ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl -n red auth can-i list secrets --as jane) == no ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl -n red auth can-i delete secrets --as jane) == no ]]; then echo "success";else echo "failed"; fi

# for blue namespace
if [[ $(kubectl -n blue auth can-i get secrets --as jane) == yes ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl -n blue auth can-i list secrets --as jane) == yes ]]; then echo "success";else echo "failed"; fi
if [[ $(kubectl -n blue auth can-i delete secrets --as jane) == no ]]; then echo "success";else echo "failed"; fi