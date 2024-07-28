#!/bin/sh

if [ $(curl -k -s -o /dev/null -w "%{http_code}" https://dmdhrumilmistry.local/service1 -H "Host: dmdhrumilmistry.local") -eq 200 ]; then echo "service1 is up"; else echo "service1 is down"; fi

if [ $(curl -k -s -o /dev/null -w "%{http_code}" https://dmdhrumilmistry.local/service2 -H "Host: dmdhrumilmistry.local") -eq 200 ]; then echo "service2 is up"; else echo "service2 is down"; fi

if [ $(curl -k -s -o /dev/null -w "%{http_code}" https://dmdhrumilmistry.local/ -H "Host: dmdhrumilmistry.local") -eq 404 ]; then echo "success"; else echo "fail"; fi