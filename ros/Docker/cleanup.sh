#!/bin/sh

# Remove all intermediate images
docker rmi -f ad-tensorrt:latest || true
docker rmi -f ad-ros:latest || true
docker rmi -f ad-opencv:latest || true
docker rmi -f ad-vcpkg:latest || true
docker rmi -f ad-ncnn:latest || true

docker buildx prune -f
