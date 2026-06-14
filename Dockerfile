# Stage 1: Build nocc-server from VKCOM repository
FROM archlinux:latest AS builder
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm gcc make git go
RUN git clone https://github.com/VKCOM/nocc.git /tmp/nocc && \
    cd /tmp/nocc && \
    make server

# Stage 2: Create the final execution image with all compilation dependencies
FROM archlinux:latest
# Install all compilation libraries required by DDNet (based on README.md)
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    cmake \
    curl \
    ffmpeg \
    freetype2 \
    git \
    glew \
    glslang \
    gmock \
    libnotify \
    libpng \
    ninja \
    opusfile \
    python \
    rust \
    sdl2 \
    spirv-tools \
    sqlite \
    vulkan-headers \
    vulkan-icd-loader \
    wavpack \
    x264 \
    openssl

# Fix the freetype2 include path mismatch for nocc parser
RUN ln -sf /usr/include/freetype2/freetype /usr/include/freetype

# Copy nocc-server binary from the builder stage
COPY --from=builder /tmp/nocc/bin/nocc-server /usr/bin/nocc-server

# Expose the compilation port
EXPOSE 43210

# Create cache directory
RUN mkdir -p /tmp/nocc/cpp

# Set the entrypoint to run the compilation server
ENTRYPOINT ["/usr/bin/nocc-server", "-host", "0.0.0.0", "-port", "43210", "-cpp-dir", "/tmp/nocc/cpp"]
