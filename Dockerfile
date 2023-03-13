FROM arm32v7/debian:buster-20220801 

RUN apt-get update && apt-get install -y \
  cmake \
  gcc \
  g++ \
  python3-dev \
  python3-numpy \
  #libavcodec-dev \
  #libavformat-dev \
  #libswscale-dev \
  #libgtk2.0-dev \
  #libgstreamer-plugins-base1.0-dev \
  #libgstreamer1.0-dev \
  libjpeg-dev \
  libpng-dev \
  git \
  wget \
  devscripts \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /home/opencv_build

RUN git clone https://github.com/Itseez/opencv.git && \
    git clone https://github.com/Itseez/opencv_contrib.git 

ARG VERSION="4.5.0"
ARG PACKAGE_NAME=libopencv_${VERSION}_armhf

RUN cd opencv; git checkout -b work ${VERSION} && \
    cd ../opencv_contrib; git checkout -b work ${VERSION}

WORKDIR /home/opencv_build/opencv/build

RUN cmake -DCMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \
    -D PYTHON3_EXECUTABLE=$(which python3) \
    -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -D PYTHON_INCLUDE_DIR2=$(python3 -c "from os.path import dirname; from distutils.sysconfig import get_config_h_filename; print(dirname(get_config_h_filename()))") \
    -D PYTHON_LIBRARY=$(python3 -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") \
    -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") \
    -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") ..
    #-D PYTHON3_EXECUTABLE=/usr/bin/python3 \
    #-D PYTHON3_INCLUDE_DIR=/usr/bin/python3 \
    #-D PYTHON3_PACKAGES_PATH=/usr/local/lib/python3.7/dist-packages 

RUN mkdir -p /home/${PACKAGE_NAME}/usr/local && \
    mkdir -p /home/${PACKAGE_NAME}/DEBIAN && \
    mv -v /usr/local /usr/local.org && \
    ln -sf /home/${PACKAGE_NAME}/usr/local /usr/local

RUN make -j4

RUN make install && \
    ldconfig

RUN rm /usr/local && \
    mv -v /usr/local.org /usr/local

RUN echo \
"Package: libopencv\n\
Priority: extra\n\
Section: universe/lib\n\
Maintainer: kmchord9 <kmchord9@gmail.com>\n\
Architecture: armhf\n\
Version: ${VERSION}\n\
Depends:   libjpeg-dev, libpng-dev\n\
Homepage: https://opencv.org/\n\
Description: development files for opencv\n" \
>> /home/${PACKAGE_NAME}/DEBIAN/control

RUN dpkg-deb --build /home/${PACKAGE_NAME}

CMD ["/bin/bash"] 