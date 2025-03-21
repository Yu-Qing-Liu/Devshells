#!/bin/sh

# Build the Docker images one by one
docker buildx build -f Dockerfile.tensorrt -t ad-tensorrt:latest .
docker buildx build -f Dockerfile.ros -t ad-ros:latest .
docker buildx build -f Dockerfile.opencv -t ad-opencv:latest .
docker buildx build -f Dockerfile.vcpkg -t ad-vcpkg:latest .
docker buildx build -f Dockerfile.ncnn -t ad-ncnn:latest .
docker buildx build -f Dockerfile.acados -t ad-acados:latest .
docker buildx build -f Dockerfile.dev -t ad-dev:latest .
