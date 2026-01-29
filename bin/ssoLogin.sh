#!/bin/bash

USERNAME="shuk.liu"
kinit $USERNAME@BYTEDANCE.COM

ssh -p 29418 git.byted.org
