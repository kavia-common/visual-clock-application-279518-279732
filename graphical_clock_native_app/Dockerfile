# syntax=docker/dockerfile:1.6
# Base image with Ubuntu for building native C++/GTK4 apps
FROM ubuntu:22.04

# Prevent tzdata from prompting during install
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools first
RUN apt-get update -q && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl sudo git bash coreutils build-essential \
      pkg-config cmake clang g++ \
      libx11-dev libgtk-4-dev libglib2.0-dev libpulse-dev \
      x11-utils lsof xdpyinfo pstree binutils \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for better security
ARG USERNAME=builder
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Set workspace
ENV APP_HOME=/workspace/graphical_clock_native_app
WORKDIR ${APP_HOME}

# Copy project files
COPY . ${APP_HOME}

# Ensure scripts are executable
RUN chmod +x .init/*.sh || true && \
    chmod +x start.sh || true

# Persist minimal env expected by scripts
RUN bash -lc 'echo "export GRAPHICAL_CLOCK_WORKSPACE=${APP_HOME}" > /etc/profile.d/GRAPHICAL_CLOCK_WORKSPACE.sh && chmod 644 /etc/profile.d/GRAPHICAL_CLOCK_WORKSPACE.sh' && \
    bash -lc 'echo -e "export DISPLAY=:99\nexport GRAPHICAL_CLOCK_WORKSPACE=${APP_HOME}" > /etc/profile.d/graphical_clock_env.sh && chmod 644 /etc/profile.d/graphical_clock_env.sh'

# Switch to non-root user
USER ${USERNAME}

# Scaffold, install deps idempotently, and build
# Using bash -lc ensures login semantics where profile.d is loaded where referenced
RUN bash -lc ".init/scaffold.sh" && \
    bash -lc ".init/install.sh" && \
    bash -lc ".init/build.sh"

# Default command runs validation which builds and starts then stops the app
CMD ["bash", "-lc", ".init/validation.sh"]
