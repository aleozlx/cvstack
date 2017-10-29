#!/usr/bin/python
from __future__ import print_function
from __future__ import unicode_literals
import sys, os
if os.system("grep -q docker /proc/1/cgroup")!=0:
    DOCKER="nvidia-docker"
    IMAGE="aleozlx/cvstack"
    PORTS = []
    VOLUMNS = [
        '-v', os.path.abspath('.') + ':/home/developer/workspace:ro',
        '-v', '/tmp/.X11-unix:/tmp/.X11-unix:rw',
        '-v', os.path.expanduser('~/.Xauthority') + ':/home/developer/.Xauthority:ro'
    ]
    argv = [DOCKER, 'run', '-it', '-e', 'DISPLAY', '--net=host'] + PORTS + VOLUMNS + [IMAGE] + ['python3', 'example.py']
    print(' '.join(map(lambda i: ("'%s'"%i) if ' ' in i else i, argv)))
    os.execvp(DOCKER, argv)

h1 = '===== \x1B[1m{}\x1B[0m ====='.format
import numpy as np
print(h1('Numpy'))
np.__config__.show()
import tensorflow as tf
print(h1('TensorFlow'))
print(tf.__version__)
import cv2
print(h1('OpenCV'))
print(cv2.__version__)

import matplotlib.pyplot as plt
t = np.arange(0.0, 2.0, 0.01)
s = 1 + np.sin(2*np.pi*t)
plt.plot(t, s)
plt.xlabel('time (s)')
plt.ylabel('voltage (mV)')
plt.title('About as simple as it gets, folks')
plt.grid(True)
plt.show()

print(h1('GPU(s)'))
os.execvp('nvidia-smi', 'nvidia-smi --query-gpu=index,name,driver_version,memory.free,display_mode --format=csv'.split())
