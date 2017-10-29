# aleozlx/cvstack

OpenCV + TensorFlow container image [rolling release]

## What's included:

* Ubuntu 16.04
* CUDA 9 + cuDNN 7
* OpenCV `3.3.0` + extra modules on CUDA 9
* TensorFlow `1.4.0-rc1` on CUDA 9 & cuDNN 7
* Numpy + Scipy on libblas + liblapack
* Isolated X11 GUI support
* And more python packages:
    * pandas matplotlib h5py scikit-learn scikit-image ...
    * Check out `requirements.txt` for complete list.

## Example Usage

~~~
nvidia-docker run -it -e DISPLAY --net=host -v "/tmp/.X11-unix:/tmp/.X11-unix" -v "$HOME/.Xauthority:/home/developer/.Xauthority" aleozlx/cvstack
~~~
