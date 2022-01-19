FROM ubuntu:focal

################################################################################
##########                           Mandel                           ##########
################################################################################
##             https://github.com/eosnetworkfoundation/mandel                 ##

# Install dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -yq      \
        binaryen                \
        build-essential         \
        ccache                  \
        clang-format            \
        cmake                   \
        curl                    \
        git                     \
        jq                      \
        libboost-all-dev        \
        libcurl4-openssl-dev    \
        libgmp-dev              \
        libssl-dev              \
        libtinfo5               \
        libusb-1.0-0-dev        \
        libzstd-dev             \
        llvm-11-dev             \
        ninja-build             \
        npm                     \
        pkg-config              \
        time                    \
        wget                    \
    && apt-get clean -yq \
    && rm -rf /var/lib/apt/lists/*

# Install CDT v1.7.0
#
RUN curl -LO https://github.com/EOSIO/eosio.cdt/releases/download/v1.7.0/eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb
RUN dpkg -i eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb

# Build Mandel from source
WORKDIR /root
RUN git clone https://github.com/eosnetworkfoundation/mandel.git
WORKDIR /root/mandel
RUN git submodule update --init --recursive
RUN mkdir /root/mandel/build
WORKDIR /root/mandel/build
RUN cmake                                   \
    -DCMAKE_BUILD_TYPE=Release              \
    -DDISABLE_WASM_SPEC_TESTS=yes           \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache    \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache      \
    ..
RUN make -j $(nproc)
RUN make install

# Run Mandel tests
## RUN npm install
## RUN ctest -j $(nproc) -LE "nonparallelizable_tests|long_running_tests" -E "full-version-label-test|release-build-test|print-build-info-test"
## RUN ctest -L "nonparallelizable_tests"
## RUN ctest -L "long_running_tests"


################################################################################
##########                    System Contracts                        ##########
################################################################################
##        https://github.com/eosnetworkfoundation/mandel-contracts.git        ##


# Add Mandel build path
ENV PATH="/root/mandel/build/bin:${PATH}"

# Build Mandel system contracts
WORKDIR /root
RUN git clone https://github.com/eosnetworkfoundation/mandel-contracts.git
WORKDIR /root/mandel-contracts
RUN mkdir /root/mandel-contracts/build
WORKDIR /root/mandel-contracts/build
RUN cmake                                   \
    -DCMAKE_BUILD_TYPE=Release              \
    -DBUILD_TESTS=yes                       \
    ..
RUN make -j $(nproc)

# Run system contract tests
## WORKDIR /root/mandel-contracts/build/tests
## RUN ctest -j $(nproc)


################################################################################
##########                 Developer nice-to-haves                    ##########
################################################################################

# Set up git and bash terminal completion
## Bash shell is needed to use ansi-c quotes
SHELL ["/bin/bash", "-c"] 

RUN echo $'\n\
parse_git_branch() {\n\
  git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \\(.*\\)/ (\\1)/"\n\
} \n\
export PS1="\u@\h \W\[\\033[32m\\]\\$(parse_git_branch)\\[\\033[00m\\] $ "\n\
if [ -f ~/.git-completion.bash ]; then\n\
  . ~/.git-completion.bash\n\
fi\n\
' >> /root/.bashrc

