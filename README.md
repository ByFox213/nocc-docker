# Kubernetes Distributed C++ Compilation with nocc

This folder contains configurations to deploy **nocc-server** (distributed C++ compiler developed by VKCOM) inside a Kubernetes cluster to accelerate compiling native C++ projects (such as DDNet).

It supports scaling compilation across multiple cluster nodes while maintaining high caching efficiency.

---

## Files Included

* **[Dockerfile](file:///home/foxy/k8s/nocc/Dockerfile)**: Multi-stage Dockerfile that compiles `nocc-server` from source and packages it on top of `archlinux:latest` with all DDNet build dependencies pre-installed (GCC 16.1.1, CMake, OpenSSL, SDL2, FFmpeg, etc.).
* **[nocc-k8s.yaml](file:///home/foxy/k8s/nocc/nocc-k8s.yaml)**: Kubernetes Deployment and Service manifest configured to run 3 replicas of `nocc-server` (spread across nodes).
* **[start-port-forward.sh](file:///home/foxy/k8s/nocc/start-port-forward.sh)**: A helper script that automatically discovers all running pod names and starts background port-forwards to different local ports (`43211`, `43212`, `43213`) to preserve each pod's compilation cache.

---

## Setup & Deployment Guide

### Step 1: Build the Docker Image
You can build the Docker image locally on your host:
```bash
docker build -t nocc-server:latest .
```
*(Alternatively, you can use the image built automatically by the GitHub Actions workflow from GitHub Container Registry).*

### Step 2: Deploy to Kubernetes
Apply the manifest to spawn 3 replicas of the server:
```bash
kubectl apply -f nocc-k8s.yaml
```

### Step 3: Establish Port-Forwarding
Run the helper script to create port-forwards to each pod:
```bash
./start-port-forward.sh
```
The script will output the exact environment variables you need to export. Example:
```text
Port-forwards started in background.
To stop them, run: killall kubectl
----------------------------------------
Export the following env variables to use them:
export NOCC_SERVERS="127.0.0.1:43211;127.0.0.1:43212;127.0.0.1:43213"
export NOCC_GO_EXECUTABLE="/usr/bin/nocc-daemon"
```

---

## How to Build

### Option 1: CLI Compilation
1. Export the environment variables returned by the script:
   ```bash
   export NOCC_SERVERS="127.0.0.1:43211;127.0.0.1:43212;127.0.0.1:43213"
   export NOCC_GO_EXECUTABLE="/usr/bin/nocc-daemon"
   ```
2. Configure CMake to use the `nocc` launcher:
   ```bash
   cmake -Bbuild-nocc -GNinja \
     -DCMAKE_BUILD_TYPE=Debug \
     -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/nocc \
     -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/nocc
   ```
3. Run the parallel compilation (e.g. 20-60 threads):
   ```bash
   cmake --build build-nocc -j60
   ```

### Option 2: CLion IDE Integration
1. Open **Settings -> Build, Execution, Deployment -> Toolchains**. Ensure C/C++ Compilers are set to `/usr/bin/gcc` and `/usr/bin/g++` (do not set them to `nocc`).
2. Open **Settings -> Build, Execution, Deployment -> CMake**, choose your profile, and configure:
   * **CMake Options**:
     ```text
     -DCMAKE_C_COMPILER_LAUNCHER=/usr/bin/nocc -DCMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/nocc
     ```
   * **Environment Variables**:
     * `NOCC_SERVERS` = `127.0.0.1:43211;127.0.0.1:43212;127.0.0.1:43213`
     * `NOCC_GO_EXECUTABLE` = `/usr/bin/nocc-daemon`
   * **Build Options**:
     ```text
     --parallel 60
     ```
3. Reload CMake cache (**Tools -> CMake -> Reset Cache and Reload Project**) and build.
