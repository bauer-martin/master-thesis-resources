# Solver REPL for Java
FROM openjdk:11-stretch AS java-build
RUN git clone --depth=1 https://github.com/bauer-martin/solver-repl-java.git /home/solver-repl-java
WORKDIR /home/solver-repl-java
RUN ./gradlew installDist

# Solver REPL for C++
FROM openjdk:11-stretch AS cxx-build
RUN apt-get update && apt-get install -y \
    build-essential \
    libboost-all-dev \
    libgmp-dev
RUN git clone --depth=1 https://github.com/bauer-martin/solver-repl-cxx.git /home/solver-repl-cxx
RUN wget https://github.com/Kitware/CMake/releases/download/v3.14.5/cmake-3.14.5-Linux-x86_64.tar.gz -P /tmp \
    && mkdir /opt/cmake \
    && tar -xf /tmp/cmake-3.14.5-Linux-x86_64.tar.gz -C /opt/cmake \
    && rm /tmp/cmake-3.14.5-Linux-x86_64.tar.gz
RUN wget http://optimathsat.disi.unitn.it/releases/optimathsat-1.6.3/optimathsat-1.6.3-linux-64-bit.tar.gz -P /tmp \
    && tar -xf /tmp/optimathsat-1.6.3-linux-64-bit.tar.gz -C /opt \
    && mv /opt/optimathsat-1.6.3-linux-64-bit /opt/optimathsat \
    && rm /tmp/optimathsat-1.6.3-linux-64-bit.tar.gz \
    && wget https://github.com/google/or-tools/releases/download/v7.0/or-tools_debian-9_v7.0.6546.tar.gz -P /tmp \
    && tar -xf /tmp/or-tools_debian-9_v7.0.6546.tar.gz -C /opt \
    && mv /opt/or-tools_Debian-9.8-64bit_v7.0.6546 /opt/or-tools \
    && rm /tmp/or-tools_debian-9_v7.0.6546.tar.gz
ENV CMAKE_HOME="/opt/cmake/cmake-3.14.5-Linux-x86_64"
ENV PATH="${CMAKE_HOME}/bin:${PATH}"
WORKDIR /home/solver-repl-cxx/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DOPTIMATHSAT_ROOT=/opt/optimathsat -DOR_TOOLS_ROOT=/opt/or-tools \
    && make

# SPL Conqueror
FROM debian:stretch AS splconqueror-build
RUN apt-get update && apt-get install -y \
    git \
    wget \
    unzip \
    mono-complete
RUN wget https://github.com/Z3Prover/z3/releases/download/z3-4.7.1/z3-4.7.1-x64-debian-8.10.zip -P /tmp \
    && unzip -d /opt/z3 /tmp/z3-4.7.1-x64-debian-8.10.zip \
    && cp /opt/z3/z3-4.7.1-x64-debian-8.10/bin/libz3.so /usr/lib/libz3.so \
    && rm /tmp/z3-4.7.1-x64-debian-8.10.zip
WORKDIR /home
RUN git clone https://github.com/bauer-martin/SPLConqueror
WORKDIR /home/SPLConqueror/SPLConqueror
RUN git submodule update --init \
    && wget https://dist.nuget.org/win-x86-commandline/latest/nuget.exe \
    && git checkout solver \
    && mono nuget.exe restore ./ -MSBuildPath /usr/lib/mono/xbuild/14.0/bin \
    && xbuild /p:Configuration=Release /p:TargetFrameworkVersion="v4.5" /p:TargetFrameworkProfile="" ./SPLConqueror.sln
# TODO python3

FROM openjdk:11-stretch
RUN apt-get update && apt-get install -y libgomp1 mono-complete
COPY --from=java-build /home/solver-repl-java/build/install/solver-repl-java /home/external-solver/solver-repl-java
COPY --from=cxx-build /opt/or-tools/lib /opt/or-tools/lib
COPY --from=cxx-build /home/solver-repl-cxx/build/src/solver-repl-cxx /home/external-solver/solver-repl-cxx
COPY --from=splconqueror-build /home/SPLConqueror/SPLConqueror/CommandLine/bin/Release /home/SPLConqueror
COPY --from=splconqueror-build /usr/lib/libz3.so /usr/lib/libz3.so
RUN ln -s /home/external-solver/solver-repl-java/bin/solver-repl-java /bin/solver-repl-java
RUN ln -s /home/external-solver/solver-repl-cxx /bin/solver-repl-cxx
WORKDIR /home
ENTRYPOINT ["mono", "SPLConqueror/CommandLine.exe"]
# CMD ["/bin/bash"]
