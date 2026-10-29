FROM ghcr.io/autowarefoundation/autoware:universe-devel-cuda-jazzy-20260929

ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get install -y \
    vim \
    python3-pip \
    python3-dev \
    ros-jazzy-rmw-cyclonedds-cpp \
    git \
    git-lfs \
    curl \
    sudo \
    python3-pip \
    ansible \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv && \
    chown -R ${UID}:${GID} /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN mkdir -p ${AUTOWARE_DATA_PATH} && \
    chown -R ${UID}:${GID} ${AUTOWARE_DATA_PATH}

USER ${UID}:${GID}
    
RUN python3 -m pip install --upgrade pip setuptools wheel \
 && python3 -m pip install --no-cache-dir \
    "carla==0.9.16" \
    PyYAML \
    "numpy<2" \
    transforms3d \
    six \
    opencv-python \
    pygame \
    shapely \
    networkx \
    Polygon

RUN echo "source /opt/venv/bin/activate" >> ~/.bashrc
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
RUN echo "source /opt/autoware/setup.bash" >> ~/.bashrc

ENTRYPOINT [ "/shared/autoware/EntryPoint_autoware.sh" ]
