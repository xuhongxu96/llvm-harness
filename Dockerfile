# syntax=docker/dockerfile:1.7

#-=============================================================================
# Common base: OS packages and tools needed to COMPILE the dependencies.
# Editing this stage (e.g. the build-time apt list) invalidates every
# dependency stage, so only add what is truly required to compile here.
#-=============================================================================
FROM ppc64le/ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

# Specify the directory that we'd like to install our dependencies to.
# Note, avoid using home directory as it will make the updating of UID/GID quite slow.
ENV LLVM_HARNESS_DEPS_DIR=/llvm-harness-deps

# Install the dependency installation scripts.
ENV LLVM_HARNESS_INSTALL_SCRIPT_DIR=/llvm-harness-install-scripts

# Set Rust and Cargo environment paths
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

# The dependency stages only build; the installation happens in the final image.
ENV LLVM_HARNESS_SKIP_INSTALL=1

RUN apt update \
    && apt install -y --no-install-recommends \
        sudo \
        build-essential \
        ca-certificates \
        pkg-config \
        make \
        cmake \
        ninja-build \
        gdb \
        git \
        curl \
        wget \
        zip \
        unzip \
        zstd \
        uuid-dev \
        # We use Python 3.12 as the gdb in Ubuntu 24.04 is using the version.
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3-pip \
    && apt autoremove -y && apt clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Rust.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
RUN rustc --version && cargo --version


#-=============================================================================
# Each dependency is built in its own stage (compilation only, no install).
# Editing one installation script only rebuilds that dependency (and, for
# alive2/llubi, the LLVM stage they depend on) -- never the other,
# independent dependencies such as re2c or z3.
#-=============================================================================

#- LLVM + ccache (alive2 and llubi build on top of this stage) ----------------
FROM base AS llvm
COPY buildscripts/deps.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/deps.sh
COPY buildscripts/install_llvm.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_llvm.sh
RUN bash $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_llvm.sh

#- z3 -------------------------------------------------------------------------
FROM base AS z3
COPY buildscripts/deps.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/deps.sh
COPY buildscripts/install_z3.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_z3.sh
RUN bash $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_z3.sh

#- re2c -----------------------------------------------------------------------
FROM base AS re2c
COPY buildscripts/deps.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/deps.sh
COPY buildscripts/install_re2c.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_re2c.sh
RUN bash $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_re2c.sh

#- alive2 (depends on LLVM + z3 + re2c) ---------------------------------------
FROM llvm AS alive2
COPY --from=z3 $LLVM_HARNESS_DEPS_DIR/z3 $LLVM_HARNESS_DEPS_DIR/z3
RUN ninja -C $LLVM_HARNESS_DEPS_DIR/z3/build install
COPY --from=re2c $LLVM_HARNESS_DEPS_DIR/re2c $LLVM_HARNESS_DEPS_DIR/re2c
RUN ninja -C $LLVM_HARNESS_DEPS_DIR/re2c/build install
COPY buildscripts/deps.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/deps.sh
COPY buildscripts/install_alive2.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_alive2.sh
RUN bash $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_alive2.sh

#- llubi, legacy (depends on LLVM) --------------------------------------------
FROM llvm AS llubi
COPY buildscripts/deps.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/deps.sh
COPY buildscripts/install_llubi.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_llubi.sh
RUN bash $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_llubi.sh

#- Python venv ----------------------------------------------------------------
FROM base AS py_deps
COPY buildscripts/deps.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/deps.sh
COPY buildscripts/install_py_deps.sh $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_py_deps.sh
COPY requirements.txt $LLVM_HARNESS_INSTALL_SCRIPT_DIR/requirements.txt
RUN bash $LLVM_HARNESS_INSTALL_SCRIPT_DIR/install_py_deps.sh


#-=============================================================================
# Final: runtime image. The source and built files are copied from the
# dependency stages and INSTALLED HERE, so the expensive compilation only
# re-runs when a dependency stage's inputs change -- never when this stage's
# apt list or user setup changes.
#-=============================================================================
FROM ppc64le/ubuntu:24.04

ARG USERNAME=harness
ARG USER_UID
ARG USER_GID

ENV DEBIAN_FRONTEND=noninteractive

# Specify the directory that we'd like to install our dependencies to.
ENV LLVM_HARNESS_DEPS_DIR=/llvm-harness-deps

# Set Rust and Cargo environment paths
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

# Runtime apt: packages used at runtime (including re-building LLVM for repairs).
# ADD NEW PACKAGES HERE -- editing this list only rebuilds this cheap stage and
# never re-runs the compilation in the dependency stages above.
RUN apt update \
    && yes | unminimize 2>&1 \
    && apt install -y --no-install-recommends \
        sudo \
        build-essential \
        ca-certificates \
        pkg-config \
        make \
        cmake \
        ninja-build \
        gdb \
        gdbserver \
        git \
        curl \
        wget \
        zip \
        unzip \
        ripgrep \
        # We use Python 3.12 as the gdb in Ubuntu 24.04 is using the version.
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        python3-pip \
        vim \
        tmux \
        zstd \
        uuid-dev \
        openjdk-25-jre \
        zsh \
    && apt autoremove -y && apt clean -y \
    && rm -rf /var/lib/apt/lists/*

# Copy the sources and built files out of the dependency stages (fast COPY, no compile).
COPY --from=base /usr/local/rustup /usr/local/rustup
COPY --from=base /usr/local/cargo /usr/local/cargo
COPY --from=llvm $LLVM_HARNESS_DEPS_DIR/llvm $LLVM_HARNESS_DEPS_DIR/llvm
COPY --from=llvm $LLVM_HARNESS_DEPS_DIR/ccache $LLVM_HARNESS_DEPS_DIR/ccache
COPY --from=z3 $LLVM_HARNESS_DEPS_DIR/z3 $LLVM_HARNESS_DEPS_DIR/z3
COPY --from=re2c $LLVM_HARNESS_DEPS_DIR/re2c $LLVM_HARNESS_DEPS_DIR/re2c
COPY --from=alive2 $LLVM_HARNESS_DEPS_DIR/alive2 $LLVM_HARNESS_DEPS_DIR/alive2
COPY --from=llubi $LLVM_HARNESS_DEPS_DIR/llubi-legacy $LLVM_HARNESS_DEPS_DIR/llubi-legacy
COPY --from=py_deps $LLVM_HARNESS_DEPS_DIR/py3_venv $LLVM_HARNESS_DEPS_DIR/py3_venv

# Install the built dependencies in the final image.
RUN ninja -C $LLVM_HARNESS_DEPS_DIR/llvm/build install \
    && ninja -C $LLVM_HARNESS_DEPS_DIR/ccache/build install
RUN ninja -C $LLVM_HARNESS_DEPS_DIR/z3/build install
RUN ninja -C $LLVM_HARNESS_DEPS_DIR/re2c/build install
RUN ninja -C $LLVM_HARNESS_DEPS_DIR/alive2/build install
RUN mv $LLVM_HARNESS_DEPS_DIR/llubi-legacy/build/llubi /usr/local/bin/llubi_legacy
RUN ldconfig

# Pull the latest commits to make sure the repo is up-to-date.
# Note, this must run after the installs above, as the installs reuse the
# LLVM source tree the builds were configured against.
RUN git -C $LLVM_HARNESS_DEPS_DIR/llvm/llvm checkout main \
    && git -C $LLVM_HARNESS_DEPS_DIR/llvm/llvm pull origin main

# Clean up the build/source directories (the LLVM source tree and the Python
# venv are kept).
RUN rm -rf $LLVM_HARNESS_DEPS_DIR/llvm/build \
       $LLVM_HARNESS_DEPS_DIR/ccache \
       $LLVM_HARNESS_DEPS_DIR/z3 \
       $LLVM_HARNESS_DEPS_DIR/re2c \
       $LLVM_HARNESS_DEPS_DIR/alive2 \
       $LLVM_HARNESS_DEPS_DIR/llubi-legacy \
       $LLVM_HARNESS_DEPS_DIR/antlr4

# Create the harness user.
RUN groupadd -g $USER_GID $USERNAME \
    && useradd -u $USER_UID -g $USER_GID -m $USERNAME \
    # Add the user to the sudo group without asking him to input password for his sudo operation
    # Note: Avoid using usermod as it always requires the user to input password
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# The admin user owns the dependencies. It has a fixed UID/GID so that the
# automatic UID/GID realignment done by tools such as VS Code never breaks
# dependency access; the real user is simply a member of this group.
ENV LLVM_HARNESS_ADMIN_USERNAME=harness-admin \
    LLVM_HARNESS_ADMIN_USER_UID=11011 \
    LLVM_HARNESS_ADMIN_USER_GID=11011
RUN groupadd -g $LLVM_HARNESS_ADMIN_USER_GID $LLVM_HARNESS_ADMIN_USERNAME \
    && useradd -u $LLVM_HARNESS_ADMIN_USER_UID -g $LLVM_HARNESS_ADMIN_USER_GID -m $LLVM_HARNESS_ADMIN_USERNAME \
    # Add the user to the sudo group without asking him to input password for his sudo operation
    # Note: Avoid using usermod as it always requires the user to input password
    && echo $LLVM_HARNESS_ADMIN_USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$LLVM_HARNESS_ADMIN_USERNAME \
    && chmod 0440 /etc/sudoers.d/$LLVM_HARNESS_ADMIN_USERNAME \
    # Grant the real user the same permission as the admin user
    && usermod -aG $LLVM_HARNESS_ADMIN_USERNAME $USERNAME \
    && chown -R -h $LLVM_HARNESS_ADMIN_USERNAME:$LLVM_HARNESS_ADMIN_USERNAME $LLVM_HARNESS_DEPS_DIR \
    && chmod -R g+w $LLVM_HARNESS_DEPS_DIR \
    && chmod 775 $LLVM_HARNESS_DEPS_DIR

USER $USERNAME
ENV SHELL=/bin/zsh

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

VOLUME ["/llvm-harness"]
WORKDIR /llvm-harness

ENTRYPOINT [ "/bin/zsh" ]