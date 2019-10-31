FROM ubuntu:18.10

ENV TF_NEED_CUDA=0
ENV TF_NEED_GCP=1
ENV TF_CUDA_COMPUTE_CAPABILITIES=5.2,3.5
ENV TF_NEED_HDFS=1
ENV TF_NEED_OPENCL=0
ENV TF_NEED_JEMALLOC=1
ENV TF_ENABLE_XLA=0
ENV TF_NEED_VERBS=0
ENV TF_CUDA_CLANG=0
ENV TF_DOWNLOAD_CLANG=0
ENV TF_NEED_MKL=0
ENV TF_DOWNLOAD_MKL=0
ENV TF_NEED_MPI=0
ENV TF_NEED_S3=1
ENV TF_NEED_KAFKA=1
ENV TF_NEED_GDR=0
ENV TF_NEED_OPENCL_SYCL=0
ENV TF_SET_ANDROID_WORKSPACE=0
ENV TF_NEED_AWS=0
ENV TF_NEED_IGNITE=0
ENV TF_NEED_ROCM=0

# ENV GCC_VERSION="7"

WORKDIR /

RUN apt update

RUN apt install -y \
    build-essential \
    curl \
    git \
    wget \
    libjpeg-dev \
    openjdk-8-jdk \
    gcc \
    g++ \
    python3 \
    python3-pip \
    python3-venv \
    pkg-config \
    zip \
    unzip \
    zlib1g-dev \
    wget \
    && rm -rf /var/lib/lists/*

# Install Python dependencies
RUN bash -c "ln -s /usr/bin/python3 /usr/bin/python; ln -s /usr/bin/pip3 /usr/bin/pip"
RUN pip install numpy wheel keras_preprocessing keras-applications

# Install Bazel
ENV BAZEL_VERSION="0.24.1"
RUN wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh \
    && chmod +x bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh \
    && ./bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh \
    && rm bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh

ENV TF_VERSION_GIT_TAG=1.14.0
ENV TF_ROOT=/tensorflow

RUN git clone --depth 1 -b v${TF_VERSION_GIT_TAG} "https://github.com/tensorflow/tensorflow.git"

ENV PYTHON_BIN_PATH="/usr/bin/python"
ENV PYTHON_VERSION="3.6"
ENV PYTHON_LIB_PATH="/usr/local/lib/python3.6/dist-packages"
ENV PYTHONPATH="/tensorflow/lib"
ENV PYTHON_ARG="/tensorflow/lib"
ENV GCC_HOST_COMPILER_PATH="/usr/bin/gcc"
ENV CC_OPT_FLAGS="-mavx -mavx2 -mfma -msse4.2 -mavx512f"

RUN cd $TF_ROOT && ./configure

RUN cd $TF_ROOT && bazel build --verbose_failures --config=opt --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" //tensorflow/tools/pip_package:build_pip_package

ENV PACKAGE_NAME="tensorflow"
ENV SUBFOLDER_NAME="${TF_VERSION_GIT_TAG}-py${PYTHON_VERSION}"

RUN mkdir -p "/wheels/${SUBFOLDER_NAME}"

RUN cd $TF_ROOT && bazel-bin/tensorflow/tools/pip_package/build_pip_package "/wheels/${SUBFOLDER_NAME}" --project_name "${PACKAGE_NAME}"

RUN chmod -R 777 /wheels/

# CMD bash
