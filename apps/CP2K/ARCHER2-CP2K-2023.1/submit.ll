#!/bin/bash --login
  
#SBATCH -J build_cp2k
#SBATCH -o build_cp2k.o%j
#SBATCH -e build_cp2k.o%j
#SBATCH --time=02:00:00
#SBATCH --ntasks=8
#SBATCH --partition=serial
#SBATCH --qos=serial
#SBATCH --account=<project code>


echo -e "\n\nSpecify versions of CP2K and supporting libraries..."
################################################################################################################
# https://github.com/cp2k/cp2k/tags
CP2K_VERSION=2023.1

# https://github.com/cp2k/libint-cp2k/tags
LIBINT_VERSION=2.6.0
LIBINT_VERSION_SUFFIX=cp2k-lmax-4

# https://gitlab.com/libxc/libxc/-/tags
LIBXC_VERSION=6.1.0

# https://gitlab.mpcdf.mpg.de/elpa/elpa/-/tags
ELPA_VERSION=2022.11.001

# https://github.com/plumed/plumed2/tags
PLUMED_VERSION=2.8.2
################################################################################################################


echo -e "\n\nLoading modules..."
################################################################################################################
module -q restore
module -q load PrgEnv-gnu
module -q load cray-fftw
module -q load cray-python
module -q load cpe/21.09
module -q load mkl

module list
################################################################################################################


echo -e "\n\nPreparing CP2K build environment..."
################################################################################################################
export OMP_NUM_THREADS=1

CP2K_CRAY_LD_LIBRARY_PATH=`echo ${CRAY_LD_LIBRARY_PATH} | sed 's:\:/opt/cray/pe/libsci/.*/.*/.*/x86_64/lib::g'`
export LD_LIBRARY_PATH=${CP2K_CRAY_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}
export FCFLAGS="-fallow-argument-mismatch"

PRFX=${HOME/home/work}/apps
CP2K_LABEL=cp2k
CP2K_NAME=${CP2K_LABEL}-${CP2K_VERSION}
CP2K_BASE=${PRFX}/${CP2K_LABEL}
CP2K_ROOT=${CP2K_BASE}/${CP2K_NAME}

mkdir -p ${CP2K_BASE}
cd ${CP2K_BASE}

rm -rf ${CP2K_NAME}
wget -q https://github.com/${CP2K_LABEL}/${CP2K_LABEL}/releases/download/v${CP2K_VERSION}/${CP2K_NAME}.tar.bz2
bunzip2 ${CP2K_NAME}.tar.bz2
tar xf ${CP2K_NAME}.tar
rm ${CP2K_NAME}.tar

mkdir ${CP2K_ROOT}/libs
################################################################################################################


echo -e "\n\nPreparing CP2K arch file..."
################################################################################################################
cd ${CP2K_BASE}

if [ -d "${CP2K_BASE}/build-instructions" ]; then
  cp ${CP2K_BASE}/build-instructions/apps/CP2K/ARCHER2-CP2K-${CP2K_VERSION}/ARCHER2.psmp ${CP2K_ROOT}/arch/
else
  git clone https://github.com/hpc-uk/build-instructions.git
  cp ${CP2K_BASE}/build-instructions/apps/CP2K/ARCHER2-CP2K-${CP2K_VERSION}/ARCHER2.psmp ${CP2K_ROOT}/arch/
  rm -rf build-instructions
fi

sed -i "s:<CP2K_ROOT>:${CP2K_ROOT}:" ${CP2K_ROOT}/arch/ARCHER2.psmp
sed -i "s:<LIBINT_VERSION>:${LIBINT_VERSION}:" ${CP2K_ROOT}/arch/ARCHER2.psmp
sed -i "s:<LIBINT_VERSION_SUFFIX>:${LIBINT_VERSION_SUFFIX}:" ${CP2K_ROOT}/arch/ARCHER2.psmp
sed -i "s:<LIBXC_VERSION>:${LIBXC_VERSION}:" ${CP2K_ROOT}/arch/ARCHER2.psmp
sed -i "s:<ELPA_VERSION>:${ELPA_VERSION}:" ${CP2K_ROOT}/arch/ARCHER2.psmp
sed -i "s:<PLUMED_VERSION>:${PLUMED_VERSION}:" ${CP2K_ROOT}/arch/ARCHER2.psmp
################################################################################################################


echo -e "\n\nBuilding libint..."
################################################################################################################
cd ${CP2K_ROOT}/libs

LIBINT_LABEL=libint
LIBINT_NAME=${LIBINT_LABEL}-${LIBINT_VERSION}-${LIBINT_VERSION_SUFFIX}
LIBINT_ARCHIVE=${LIBINT_LABEL}-v${LIBINT_VERSION}-${LIBINT_VERSION_SUFFIX}
LIBINT_INSTALL=${CP2K_ROOT}/libs/${LIBINT_LABEL}/${LIBINT_VERSION}/${LIBINT_VERSION_SUFFIX}

mkdir -p ${LIBINT_LABEL}
cd ${LIBINT_LABEL}

rm -rf ${LIBINT_NAME}
wget -q https://github.com/${CP2K_LABEL}/${LIBINT_LABEL}-${CP2K_LABEL}/releases/download/v${LIBINT_VERSION}/${LIBINT_ARCHIVE}.tgz
tar zxf ${LIBINT_ARCHIVE}.tgz
rm ${LIBINT_ARCHIVE}.tgz
mv ${LIBINT_ARCHIVE} ${LIBINT_NAME}

cd ${LIBINT_NAME}

CC=cc CXX=CC FC=ftn LDFLAGS=-dynamic ./configure \
    --enable-fortran --with-cxx-optflags=-O \
    --prefix=${LIBINT_INSTALL}

make -j ${SLURM_NTASKS}
make -j ${SLURM_NTASKS} install
make -j ${SLURM_NTASKS} clean
################################################################################################################


echo -e "\n\nBuilding libxc..."
################################################################################################################
cd ${CP2K_ROOT}/libs

LIBXC_LABEL=libxc
LIBXC_NAME=${LIBXC_LABEL}-${LIBXC_VERSION}
LIBXC_INSTALL=${CP2K_ROOT}/libs/${LIBXC_LABEL}/${LIBXC_VERSION}

mkdir -p ${LIBXC_LABEL}
cd ${LIBXC_LABEL}

rm -rf ${LIBXC_NAME}
wget -q https://gitlab.com/${LIBXC_LABEL}/${LIBXC_LABEL}/-/archive/${LIBXC_VERSION}/${LIBXC_NAME}.tar.gz
tar zxf ${LIBXC_NAME}.tar.gz
rm ${LIBXC_NAME}.tar.gz
cd ${LIBXC_NAME}

autoreconf -i

CC=cc CXX=CC FC=ftn ./configure --prefix=${LIBXC_INSTALL}

make -j ${SLURM_NTASKS}
make -j ${SLURM_NTASKS} install
make -j ${SLURM_NTASKS} clean
################################################################################################################


echo -e "\n\nBuilding ELPA..."
################################################################################################################
cd ${CP2K_ROOT}/libs

ELPA_LABEL=elpa
ELPA_NAME=${ELPA_LABEL}-${ELPA_VERSION}
ELPA_INSTALL=${CP2K_ROOT}/libs/${ELPA_LABEL}/${ELPA_VERSION}

mkdir -p ${ELPA_LABEL}
cd ${ELPA_LABEL}

rm -rf ${ELPA_NAME}
wget -q https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/${ELPA_VERSION}/${ELPA_NAME}.tar.gz
tar zxf ${ELPA_NAME}.tar.gz
rm ${ELPA_NAME}.tar.gz

cd ${ELPA_NAME}
mkdir build-serial
cd build-serial

export LIBS="-L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -Wl,--no-as-needed -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core -lmkl_blacs_intelmpi_lp64 -lgomp -lpthread -lm -ldl"

CC=cc CXX=CC FC=ftn LDFLAGS=-dynamic ../configure       \
  --enable-openmp=no --enable-shared=no \
  --disable-avx512 --disable-detect-mpi-launcher \
  --without-threading-support-check-during-build \
  --prefix=${ELPA_INSTALL}/serial

make -j ${SLURM_NTASKS}
make -j ${SLURM_NTASKS} install
make -j ${SLURM_NTASKS} clean

cd ${CP2K_ROOT}/libs/${ELPA_LABEL}/${ELPA_NAME}
mkdir build-openmp
cd build-openmp

export LIBS="-L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -Wl,--no-as-needed -lmkl_gf_lp64 -lmkl_gnu_thread -lmkl_core -lmkl_blacs_intelmpi_lp64 -lgomp -lpthread -lm -ldl"

CC=cc CXX=CC FC=ftn LDFLAGS=-dynamic ../configure \
  --enable-openmp=yes --enable-shared=no --enable-allow-thread-limiting \
  --disable-avx512 --disable-detect-mpi-launcher \
  --without-threading-support-check-during-build \
  --prefix=${ELPA_INSTALL}/openmp

make -j ${SLURM_NTASKS}
make -j ${SLURM_NTASKS} install
make -j ${SLURM_NTASKS} clean
################################################################################################################


echo -e "\n\nBuilding Plumed..."
################################################################################################################
cd ${CP2K_ROOT}/libs

PLUMED_LABEL=plumed
PLUMED_NAME=${PLUMED_LABEL}-${PLUMED_VERSION}
PLUMED_INSTALL=${CP2K_ROOT}/libs/${PLUMED_LABEL}/${PLUMED_VERSION}

mkdir -p ${PLUMED_LABEL}
cd ${PLUMED_LABEL}

rm -rf ${PLUMED_NAME}
wget -q https://github.com/${PLUMED_LABEL}/${PLUMED_LABEL}2/archive/refs/tags/v${PLUMED_VERSION}.tar.gz
tar zxf v${PLUMED_VERSION}.tar.gz
rm v${PLUMED_VERSION}.tar.gz
mv ${PLUMED_LABEL}2-${PLUMED_VERSION} ${PLUMED_NAME}
cd ${PLUMED_NAME}

CC=cc CXX=CC FC=ftn MPIEXEC=srun ./configure \
  --disable-openmp --disable-shared --disable-dlopen \
  --prefix=${PLUMED_INSTALL}

make -j ${SLURM_NTASKS}
make -j ${SLURM_NTASKS} install
make -j ${SLURM_NTASKS} clean
################################################################################################################


echo -e "\n\nBuilding CP2K..."
################################################################################################################
cd ${CP2K_ROOT}

make -j ${SLURM_NTASKS} ARCH=ARCHER2 VERSION=psmp
make -j ${SLURM_NTASKS} clean ARCH=ARCHER2 VERSION=psmp
################################################################################################################
