#!/bin/sh

if [ $(curl -s -o /dev/null -w "%{http_code}" http://localhost/service1) -eq 200 ]; then echo "service1 is up"; else echo "service1 is down"; fi

if [ $(curl -s -o /dev/null -w "%{http_code}" http://localhost/service2) -eq 200 ]; then echo "service2 is up"; else echo "service2 is down"; fi

if [ $(curl -s -o /dev/null -w "%{http_code}" http://localhost/) -eq 404 ]; then echo "success"; else echo "fail"; fi