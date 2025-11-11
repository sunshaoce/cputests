## Quick Start

```shell
git clone --recursive https://github.com/sunshaoce/cputests.git
cd cputests

# CC1 and CC2 can be empty to use default compiler
# CC1: gcc by default
# CC2: clang by default
./run-tests.sh

# Or specify compilers explicitly
CC1=<PATH_TO_COMPILER1> CC2=<PATH_TO_COMPILER2> ./run-tests.sh
```

Then results will be in the `results` directory.

### Missing `libomp.so`

Find the path to `libomp.so` in your compiler installation, and set the `CC1FLAGS` or `CC2FLAGS` for example:

```shell
CC1FLAGS="-L <PATH_TO_LIBOMP>" ./run-tests.sh
```

### Clean

```shell
./clean-all.sh
```
