Instructions for installing ASE 3.23.0 for ARCHER2
------------------


These instructions are for installing ASE 3.23.0 on ARCHER2. ARCHER2 is an HPE Cray EX supercomputer with two  AMD EPYC 7742 processors per node.


### Environment setup
The environment setup is very similar to the guidance outlined in the Using Python section of the ARCHER2 User Documentation, found [here](https://docs.archer2.ac.uk/user-guide/python/). When installing additional Python packages such as ASE via the `pip` command, it is recommended to create a lightweight virtual environment, which is created on top of an existing Python installation. Here, the existing Python installation is the HPE Cray Python distribution.

First, load the `PrgEnv-gnu` environment and the HPE Cray Python distribution:
```bash
module load PrgEnv-gnu
module load cray-python
```

Then, navigate to the folder where the virtual environment should be created and create the environment:
```bash
cd <folder>
python -m venv --system-site-packages .
```

Next, activate the virtual environment:
```bash
source bin/activate
```


### Installing ASE

The following command can be used to install ASE:
```bash
pip install ase
```

However, if you intend to run the tests provided by ASE, as briefly mentioned in the [ASE documentation](https://wiki.fysik.dtu.dk/ase/install.html#run-the-tests), use the following command instead. Additional information about testing ASE can be found below. 
```
pip install ase[test]
```


If you intend to use pandas with ASE, the version of NumPy should be downgraded. Version 1.24.4 has been shown to work, though in theory, any version between 1.23.0 and 1.26.4 should be okay. The explanation for this is provided in the notes below.
```bash
pip install ase --upgrade numpy==1.24.4
```


### Testing ASE
In order to test ASE, simply run the following command:
```
ase test
```

When the tests were run in the environment specified in the Additional Notes section below, 1 test is known to fail, seemingly related to the `tkinter` package.

It was noticed that two other conditions caused additional tests to fail:
1. when the version of NumPy was 2.0. The error messages suggested the failures were due to deprecations in NumPy 2.0.
2. when the virtual environment was set up exactly as specified by the ARCHER2 documentation, instead of set up according to the set up instructions above. These errors were due to issues with ASE's absolute and relative paths.


### Running ASE

The following Slurm script demonstrates how to serially run the installed ASE in a Slurm script. It is based off an [example](https://docs.archer2.ac.uk/user-guide/python/#running-python) provided in the ARCHER2 User Documentation. Since ASE has been installed in a virtual environment, this environment must be activated within the job submission script. In this example, test_ase.py is the name of Python program which uses ASE.

```
#!/bin/bash

# Slurm job options (job name, job time)
#SBATCH --job-name=ase_serial
#SBATCH --ntasks=1
#SBATCH --time=00:10:00
    
# Replace [budget code] below with project code (e.g. t01)
#SBATCH --account=[budget code]
#SBATCH --partition=serial
#SBATCH --qos=serial

# Activate the virtual environment
source <<path to virtual environment>>/bin/activate
    
# Run the Python program
python test_ase.py
```


If the Python program that utilises ASE also includes parallelism (e.g. uses the CASTEP or LAMMPS calculator), the following Slurm script should be used instead. 

Note: when using a calculator, it is very important that the command passed to ASE contains "srun". This could be done via the `export` Bash command or by passing it ASE within the Python program, depending on the calculator's documentation. 
One example of this is when using the CASTEP calculator, the command should be in the format `"srun <any options> <path to castep>"`. Furthermore, it is also important to ensure that all required modules are loaded with the `module load` command. 

```
#!/bin/bash
# Slurm job options (job name, compute nodes, job time)
#SBATCH --job-name=ase_parallel
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=0:10:0

# Replace [budget code] below with your budget code (e.g. t01)
#SBATCH --account=[budget code]
#SBATCH --partition=standard
#SBATCH --qos=standard

# Activate the virtual environment
source <<path to virtual environment>>/bin/activate

# Pass cpus-per-task setting to srun
export SRUN_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}

# Run the Python program
python test_ase.py
```


### Notes on pandas and NumPy
The reason for manually downgrading NumPy is because the version of NumPy that would be installed by pip is not compatible with the version of pandas that is part of the `cray-python` module (pandas v1.4.2). This issue arises because one of ASE's dependencies is Matplotlib, which is not part of the `cray-python` module or installed on ARCHER2. Therefore, when pip installs ASE, it also installs the latest version of Matplotlib (v3.9.2), which requires a newer version of NumPy than that supplied by the `cray-python` module (v1.23.0 or newer). The version of NumPy pip installs to statisfy this requirement is v2.0.2, and this version is not compatible with pandas v1.4.2. If preferred, pandas could be upgraded instead of downgrading NumPy.


### Additional Notes
The table shows which versions of the modules these build and testing instructions were tested with.

Module | Version
------ | -------
`cray-python` | 3.9.13.1
`PrgEnv-gnu` | 8.3.3
`ASE` | 3.23.0
`NumPy` | 1.24.4


### Help improve these instructions

If you make changes that would update these instructions, please fork
this repository on GitHub, update the instructions and send a pull
request to incorporate them into this repository.
