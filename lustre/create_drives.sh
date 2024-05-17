#!/usr/bin/env bash
# Allocate files be used as hard drives by containers for creating file systems

fallocate -l $1 mgs_data.img
fallocate -l $1 mdt_data.img
fallocate -l $1 ost_data.img
