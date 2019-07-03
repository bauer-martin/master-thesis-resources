# SPLConqueror

## Build Automatically

Run the following command to build a docker image for SPL Conqueror.

```shell
$ ./configure.sh
```
This will set up a default environment:

- builds a docker image named `splconqueror`
- creates a folder named `data` in the current directory for file exchange with the container
- creates a shell script to run SPL Conqueror

Put all files you want SPL Conqueror to see into the `data` directory.
You can then run SPL Conqueror as follows.

```shell
$ ./run-splconqueror.sh data/script.a
```

## Build Manually

### Build the Docker Image

Run the following command to build a docker image for SPL Conqueror.
The name of the locally built image can be anything, but we use `splconqueror` in this example.

```shell
$ docker image build -t splconqueror .
```

Once the image is build, it can be run as follows:

```shell
$ docker container run splconqueror
```

### Run a SPL Conqueror Script

Let's assume that the host machine has a /path/to/data folder which contains the script file `script.a` and all other files required by the script.
Here is a sample script.

```text
log output.txt
vm feature-model.xml
solver z3
binary satoutput numConfigs:-1
printconfigs configs.csv
```

**Note:** This script assumes that there is a `feature-model.xml` file in the data folder.

Since SPL Conqueror is running inside its own container, it has no access to those files.
You have to mount your data folder inside the container using -v (or --volume) flag such that SPL Conqueror can work with them.
It doesn't matter where you mount it, because you have to specify the appropriate path in your script file anyway.
In this example, we mount it under the home directory.

```shell
$ docker container run -v /path/to/data:/home/data splconqueror data/script.a
```
1. The path to the script (here: `data/script.a`) lives in the context of the container.
1. A relative path is interpreted relative to `/home`.

## Using Other Solvers

SPL Conqueror comes with many different solvers.
Some of them need the path to the executable specified as a parameter in the script file.
Below is a list of all solvers and their paths inside the container.

| Solver                      | Executable Path         | Example                                                   |
| --------------------------- | ----------------------- | --------------------------------------------------------- |
| z3                          | not applicable          | `solver z3`                                               |
| Microsoft Solver Foundation | not applicable          | `solver msf`                                              |
| JaCoP                       | `/bin/solver-repl-java` | `solver jacop executable-path:/bin/solver-repl-java`      |
| Choco                       | `/bin/solver-repl-java` | `solver choco executable-path:/bin/solver-repl-java`      |
| Google OR-Tools             | `/bin/solver-repl-cxx`  | `solver ortools executable-path:/bin/solver-repl-cxx`     |
| OptiMathSAT                 | `/bin/solver-repl-cxx`  | `solver optimathsat executable-path:/bin/solver-repl-cxx` |
