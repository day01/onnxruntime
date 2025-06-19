# Building ONNX Runtime musllinux wheels

This document describes how to prepare a musl-based build environment for creating Python wheels compatible with the `musllinux_1_2` policy.

## Prerequisites

You can either build inside a Docker container or cross-compile directly using the musl toolchain.

### Using Docker

Install Docker if you want to build the musllinux image locally. On Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y docker.io
```

Alternatively run `tools/install_docker.sh` from this repository.

### Using a native musl toolchain

Install the musl compiler wrappers when building without Docker:

```bash
sudo apt-get update
sudo apt-get install musl-tools musl-dev
```

## 1. Prepare the musllinux Docker image

ONNX Runtime uses the manylinux project to build portable Linux wheels, which now natively support the musllinux policy.

1. Clone the manylinux repository and change into its directory:

   ```bash
   git clone --depth 1 https://github.com/pypa/manylinux
   cd manylinux
   ```

2. Build the Docker image with the musllinux policy:

   ```bash
   POLICY=musllinux_1_2 PLATFORM=x86_64 COMMIT_SHA=latest ./build.sh
   docker tag quay.io/pypa/musllinux_1_2_x86_64:latest ort-musllinux
   ```

The resulting `ort-musllinux:latest` image contains the musl development packages required to build ONNX Runtime wheels.

## 2. Build ONNX Runtime inside the container

1. Start a container from the musllinux image and mount the source tree:

   ```bash
   docker run --rm -it -v <ORT_ROOT>:/workspace ort-musllinux bash
   ```

2. In the container build the wheel:

   ```bash
   cd /workspace
   ./build.sh --update --config Release --build --build_wheel --parallel
   ```

   The wheel is created under `build/Linux/Release/dist/` and is compatible with `musllinux_1_2`.

## 3. Build with the included Dockerfile

The `dockerfiles` directory provides a `Dockerfile.musllinux` that replicates the GitHub Actions workflow. Build the wheel locally with:

```bash
docker build -f dockerfiles/Dockerfile.musllinux -t ort-musllinux .
```

The wheel is saved under `/dist` in the resulting image.


## 4. Cross-compiling with CMake

You can also build outside of Docker using a toolchain file if you have a musl
toolchain installed. On Ubuntu the basic tools can be installed with

```bash
sudo apt-get install musl-tools musl-dev
```

For full C++ support you will need a cross `g++` compiler (for example from the
`musl-cross-make` project) so that `x86_64-linux-musl-g++` is available.

The repository
includes `cmake/linux_x86_64_musl_toolchain.cmake` which configures CMake for a
musl-based target:

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=cmake/linux_x86_64_musl_toolchain.cmake \
      -DCMAKE_BUILD_TYPE=Release -B build
cmake --build build -j$(nproc)
```

This produces libraries linked against musl in the `build` directory.

## 5. Automated builds

The repository provides a GitHub Actions workflow
[`musllinux.yml`](../.github/workflows/musllinux.yml) that automatically
builds ONNX Runtime wheels for the `musllinux_1_2` policy whenever a pull
request is opened. The workflow installs the musl toolchain on the runner,
invokes `build.sh` directly using the
`cmake/linux_x86_64_musl_toolchain.cmake` file,
and uploads the resulting wheel as an artifact.
