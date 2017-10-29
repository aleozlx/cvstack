FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04
MAINTAINER Alex Yang <aleozlx@gmail.com>

# System dependencies
RUN apt-get -y update && apt-get -y install build-essential gfortran libblas-dev liblapack-dev libatlas-base-dev python3-dev vim wget

# Python3 + numpy + scipy
RUN apt-get -y install python3-pip && pip3 install --upgrade pip
RUN BLAS=/usr/lib/libblas/libblas.so LAPACK=/usr/lib/lapack/liblapack.so pip3 --no-cache-dir install numpy scipy

# OpenCV 3.3.0
RUN apt-get -y install libjpeg8-dev libtiff5-dev libjasper-dev libpng12-dev
RUN apt-get -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev
RUN apt-get -y install cmake pkg-config libgtk-3-dev unzip
RUN wget --quiet -O /opt/opencv.zip https://github.com/opencv/opencv/archive/3.3.0.zip
RUN wget --quiet -O /opt/opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/3.3.0.zip
RUN cd /opt && unzip opencv.zip && unzip opencv_contrib.zip
COPY patches/FindCUDA-CUDA9.cmake /opt/opencv-3.3.0/cmake/FindCUDA.cmake
COPY patches/OpenCVDetectCUDA-CUDA9.cmake /opt/opencv-3.3.0/cmake/OpenCVDetectCUDA.cmake
COPY patches/cudev-common-cuda9.hpp /opt/opencv-3.3.0/modules/cudev/include/opencv2/cudev/common.hpp
RUN mkdir /opt/opencv-3.3.0/build && cd /opt/opencv-3.3.0/build && cmake \
    -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_CUDA=ON -D WITH_CUBLAS=ON -D WITH_TBB=OFF -D WITH_V4L=OFF -D WITH_QT=OFF -D WITH_OPENGL=ON \
    -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 \
    -D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib-3.3.0/modules \
    -D PYTHON3_EXECUTABLE=/usr/bin/python3 \
    -D PYTHON_INCLUDE_DIR=/usr/include/python3.5m \
    -D PYTHON_INCLUDE_DIR2=/usr/include/x86_64-linux-gnu/python3.5m \
    -D PYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so \
    -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.5/dist-packages/numpy/core/include/ \
    -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -DCUDA_NVCC_FLAGS="-D_FORCE_INLINES" ..
# ref: https://gist.github.com/filitchp/5645d5eebfefe374218fa2cbf89189aa
# cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_CUDA=ON -D WITH_CUBLAS=ON -D WITH_TBB=ON -D WITH_V4L=ON -D WITH_QT=ON -D WITH_OPENGL=ON -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -DCUDA_NVCC_FLAGS="-D_FORCE_INLINES" ..
RUN cd /opt/opencv-3.3.0/build && make -j8 && make install && ldconfig

# TensorFlow 1.4.0-rc1
RUN apt-get -y install openjdk-8-jdk libcupti-dev python3-wheel curl
RUN pip3 install six wheel
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
RUN curl https://bazel.build/bazel-release.pub.gpg | apt-key add -
RUN apt-get -y update && apt-get -y install git bazel
# RUN wget --quiet -O /opt/tensorflow.zip https://github.com/tensorflow/tensorflow/archive/v1.3.1.zip
# RUN cd /opt && unzip tensorflow.zip
RUN cd /opt && git clone https://github.com/tensorflow/tensorflow.git /opt/tensorflow-1.4.0-rc1
RUN cd /opt/tensorflow-1.4.0-rc1 && git checkout v1.4.0-rc1
ENV CI_BUILD_PYTHON=python3 \
    LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH \
    CUDNN_INSTALL_PATH=/usr/lib/x86_64-linux-gnu \
    PYTHON_BIN_PATH=/usr/bin/python3 \
    PYTHON_LIB_PATH=/usr/local/lib/python3.5/dist-packages \
    TF_NEED_HDFS=1 \
    TF_NEED_GCP=0 \
    TF_NEED_CUDA=1 \
    TF_CUDA_VERSION=9.0 \
    TF_CUDNN_VERSION=7 \
    TF_CUDA_COMPUTE_CAPABILITIES=3.0,3.5,5.2,6.0,6.1
# ref: https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.devel-gpu
# ref: https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/Dockerfile.devel-gpu-cuda9-cudnn7
RUN cd /opt/tensorflow-1.4.0-rc1 && ./configure
RUN cd /opt/tensorflow-1.4.0-rc1 && ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH} \
    bazel build --config=opt --config=cuda \
    --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
        tensorflow/tools/pip_package:build_pip_package && \
    rm /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/pip && \
    pip --no-cache-dir install --upgrade /tmp/pip/tensorflow-*.whl && \
    rm -rf /tmp/pip && \
    rm -rf /root/.cache

# Other Python packages
COPY requirements.txt /requirements.txt
RUN pip3 --no-cache-dir install -r /requirements.txt
RUN apt -y install python3-tk

# Enable non-root with sudo and GUI
# ref: http://wiki.ros.org/docker/Tutorials/GUI
# ref: http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/
RUN apt -y install sudo
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer /home/developer/workspace "`python3 -m site --user-site`" && \
    echo "developer:x:${uid}:${gid}:developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

USER developer
ENV HOME /home/developer
WORKDIR /home/developer/workspace
CMD /bin/bash

# nvidia-docker run -it -e DISPLAY --net=host -v "/tmp/.X11-unix:/tmp/.X11-unix" -v "$HOME/.Xauthority:/home/developer/.Xauthority" cvstack
