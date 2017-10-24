FROM nvidia/cuda:9.0-devel-ubuntu16.04
MAINTAINER Alex Yang <aleozlx@gmail.com>

# System dependencies
RUN apt-get -y update && apt-get -y install build-essential gfortran libblas-dev liblapack-dev libatlas-base-dev python3-dev vim wget

# Python3 + numpy + scipy
RUN apt-get -y install python3-pip && pip3 install --upgrade pip
RUN BLAS=/usr/lib/libblas/libblas.so LAPACK=/usr/lib/lapack/liblapack.so pip3 --no-cache-dir install numpy scipy

# OpenCV3
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

RUN cd /opt/opencv-3.3.0/build && make -j8
# Other Python packages
# COPY requirements.txt /requirements.txt
# RUN pip3 --no-cache-dir install -r /requirements.txt

# Create workespace
# RUN mkdir -p /workspace "`python3 -m site --user-site`"
WORKDIR /workspace
CMD /bin/bash
