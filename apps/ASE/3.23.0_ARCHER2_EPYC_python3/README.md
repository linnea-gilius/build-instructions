Instructions for installing ASE 3.23.0 for ARCHER2
------------------


These instructions are for installing ASE 3.23.0 on ARCHER2. ARCHER2 is an HPE Cray EX supercomputer with two  AMD EPYC 7742 processors per node.


### Environment setup
The environment setup follows the guidance outlined in the Using Python section of the ARCHER2 User Documentation, found [here](https://docs.archer2.ac.uk/user-guide/python/). When installing additional Python packages such as ASE via the `pip` command, it is recommended to create a lightweight virtual environment, which is created on top of an existing Python installation. Here, the existing Python installation is the HPE Cray Python distribution.

First, load the `PrgEnv-gnu` environment and the HPE Cray Python distribution:
```bash
module load PrgEnv-gnu
module load cray-python
```

Then, create the virtual environment within a specified folder:
```bash
python -m venv --system-site-packages /work/t01/t01/auser/myvenv
```

Next, activate the virtual environment:
```bash
source /work/t01/t01/auser/myvenv/bin/activate
```


### Installing ASE

The following command can be used to install ASE:
```bash
pip install ase
```

However, if you intend to run the tests provided by ASE, as briefly mentioned in the [ASE documentation](https://wiki.fysik.dtu.dk/ase/install.html#run-the-tests), use the following command instead: 
```bash
pip install ase[test]
```

If you intend to use pandas with ASE, the version of NumPy should be downgraded. Version 1.24.4 has been shown to work, though in theory, any version between 1.23.0 and 1.26.4 should be okay. The full explanation for this is provided in the notes below.
```bash
pip install ase --upgrade numpy==1.24.4
```


### Running ASE
In order to use the installed ASE in a Slurm script, follow the example shown [here](https://docs.archer2.ac.uk/user-guide/python/#running-python) in the ARCHER2 User Documentation.


### Notes on pandas and NumPy
The reason for manually downgrading NumPy is because the version of NumPy that would be installed by pip is not compatible with the version of pandas that is part of the `cray-python` module (pandas v1.4.2). This issue arises because one of ASE's dependencies is Matplotlib, which is not part of the `cray-python` module or installed on ARCHER2. Therefore, when pip installs ASE, it also installs the latest version of Matplotlib (v3.9.2), which requires a newer version of NumPy than that supplied by the `cray-python` module (v1.23.0 or newer). The version of NumPy pip installs to statisfy this requirement is v2.0.2, and this version is not compatible with pandas v1.4.2. If preferred, pandas could be upgraded instead of downgrading NumPy.


### Help improve these instructions

If you make changes that would update these instructions, please fork
this repository on GitHub, update the instructions and send a pull
request to incorporate them into this repository.
