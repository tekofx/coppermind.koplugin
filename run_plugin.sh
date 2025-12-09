#!/bin/bash

rsync -av --exclude="koreader/" ../coppermind.koplugin ../coppermind.koplugin/koreader/plugins/
koreader/kodev run
