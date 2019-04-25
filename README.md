# IEC Build - Linux, x86_64, RichOS

This repository contains the Identity Edge Controller build environment for Linux x86_64 on RichOS platform. It builds
the [IEC Core](https://stash.forgerock.org/projects/IOT/repos/identity-edge-controller-core) source code and creates
distributables for the IEC Service, IEC C SDK and IEC Utility.

### Prepare the build Docker image

Install [Docker](https://docs.docker.com/install/) if you don't have it installed already.

Build the docker image:
```
docker build . -t iec-build-linux-x86_64:latest
```

### Build from IEC Core repo

This build will fetch the latest IEC Core source code and use it to build the distributables.

Run the build:
```
docker run --rm -it -v $(pwd):/root/iec iec-build-linux-x86_64:latest bash -c "./build.sh"
```

The distributables will be place in the `build/dist` directory.

### Build from local code

You can build the IEC from local source code by setting the `IEC_CORE_SRC` and mounting the source directory.

Clone the IEC Core repo:
```
git clone ssh://git@stash.forgerock.org:7999/iot/identity-edge-controller-core.git build/identity-edge-controller-core
```

Run the build:
```
docker run --rm -it \
                -v $(pwd):/root/iec \
                -v $(pwd)/build/identity-edge-controller-core:/root/iec-core-src \
                iec-build-linux-x86_64:latest \
                bash -c "export IEC_CORE_SRC=/root/iec-core-src && ./build.sh"
```

The distributables will be place in the `build/dist` directory.
