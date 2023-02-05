# SDSC HPC Software Deployment Guide

This document outlines the Spack-based software deployment process in 
use by the San Diego Supercomputer Center's (SDSC) High-Performance 
Computing (HPC) User Services Group. All definitions, procedures, 
conventions, and policies defined within this guide are used by the 
group to build and maintain the custom Spack instances they deploy on 
SDSC's HPC systems for end users. 

## Disclaimer

This is a new and evolving software deployment process in development 
and use by the SDSC HPC User Services Group to centrally manage HPC 
software on HPC systems with Spack. Please consider the status of the
project as a pre-alpha release at this time. Use at your own risk. 

## Definitions and Terminology

- A Spack ***instance*** is a unique, stand-alone installation of a 
  specific version of `spack` that includes custom Spack configuration 
  files, Spack packages, and a collection of Spack-installed software 
  applications, libraries, and utilities.
- A Spack ***package*** is a set of instructions that defines how a 
  specific piece of software is compiled and/or installed by Spack. For 
  example, a Spack package specifies where to find and how to retrieve 
  the software's source code, its required (and/or optional) software 
  dependencies, its compile-time options, any patches to apply, etc. A 
  Spack package is primarily defined by it *package.py* file.
- A Spack ***spec*** is a string descriptor that specifies a particular 
  build configuration of a Spack package. The full syntax of a spec 
  may include the package name, its version, the compiler it should be 
  built with, the compiler version, the system architecture it should be
  compiled for, any compile-time options for the package, and any 
  requirements that should be enforced on its dependencies at build time.
- The ***core*** packages of a Spack instance are those software 
  applications, libraries, and/or utilities compiled with Spack using 
  the default system compiler. These packages form the foundation of the 
  software environment upon which additional Spack packages are built.
  In general, the core packages of a Spack instance are a set of (core)
  compilers and other general software utilities. e.g., version control
  systems, data transfer tools, etc.
- A Spack package ***dependency chain*** is an explicitly-defined  
  ordered set of Spack specs that share a common (core) compiler and/or
  MPI library, may depend on one another (or share other software 
  dependencies), and should be installed one after another, one at a 
  time, as prescribed by their dependencies.
- A Spack ***deployment branch*** is a *trunk*-like branch for a specific 
  version of `spack` that tracks all of the Spack configuration files, 
  Spack packages, and Spack specs used to deploy a Spack instance (or a
  set of instances). 

## GitHub Repository

The [sdsc/spack](https://github.com/sdsc/spack) project is a custom fork 
of the Spack project's main GitHub repository, which is referred to in 
this guide as the [spack/spack](https://github.com/spack/spack) repo. 
The primary aim of the sdsc/spack repo is to manage and track all 
changes made to the custom Spack instances deployed by SDSC on its HPC 
systems.

### Deployment Branches

The sdsc/spack repo and its use in practice are fundamentally structured
around the concept of *deployment branches*. A deployment branch is a
*trunk*-like branch created from an unmodifed, official release version
of `spack` and is named accordingly, unless special circumstances 
require that an intermediate commit be used. For example, the 
`sdsc-0.17.3` deployment branch was created by checking out the 
[v0.17.3](https://github.com/spack/spack/releases/tag/v0.17.3) release

Once a version of Spack is selected and checked out, only a few minor 
changes and/or additions are made to the Spack release in order to 
initialize a deployment branch within the sdsc/spack repo. These 
modifications are as follows:

- The official version of the Spack `README.md` file is removed and 
  replaced with the latest version of this document --- the *SDSC HPC 
  Software Deployment Guide*.
- The latest version of the sdsc/spack `CONTRIBUTING.md` file is also
  included to provide information on how one may contribute to the 
  sdsc/spack project and its deployment branches.
- A Spack package repository --- `var/spack/repos/sdsc` --- created to 
  store all custom Spack packages created and/or maintained by SDSC, 
  including all of SDSC's custom modifications to Spack's existing 
  `builtin` packages.
- A Spack instance repository --- `etc/spack/sdsc` --- is created
  to  ...


All other types of branches (see
  [CONTRIBUTING.md](CONTRIBUTING.md)) should start from a deployment
  branch.

### Package Repository

### Instance Repositories

### Access Control and Permissions

Write access to the sdsc/spack repository is restricted to SDSC team 
members who are responsible for managing and tracking issues, reviewing
and merging pull requests, and maintaining the custom deployment 
branches in the repository. All other SDSC team members who wish to 
contribute to the sdsc/spack repository should submit their changes via
pull requests from their own public fork of the sdsc/spack repository.



etc/spack/repos.yaml
var/spack/repos/sdsc/repo.yaml
var/spack/repos/sdsc/packages

etc/spack/sdsc/expanse/0.17.3/cpu/specs
etc/spack/sdsc/expanse/0.17.3/cpu/yamls




## Deploying HPC Software via Spack

### Deploying a New Spack Instance

1. Login to the Spack user account designated for the ownership, 
   deployment, and managment of the new instance. e.g., All production 
   instances on Expanse targeted at and optimized for ...
   ```
   sudo -u spack_cpu ssh spack_cpu@login.expanse.sdsc.edu
   ```

2. Start an interactive session on the reserved build node with write 
   access to the /cm/shared filesystem.
   ```
   srun --partition=ind-shared --reservation=root_73  --account=use300 --nodes=1 --ntasks-per-node=1 --cpus-per-task=16 --mem=32G --time=48:00:00 --pty --wait=0 /bin/bash
   ```

3. Navigate to the Spack version directory.
   ```
   cd /cm/shared/apps/spack/0.17.3
   ```

4. Create a instance name directory and change to it.
   ```
   mkdir cpu
   ```
   and then change to it.
   ```
   cd cpu/
   ```

5. Clone the sdsc/spack GitHub repository and rename its top-level 
   directory to the deployment version.
   ```
   git clone https://github.com/sdsc/spack.git a/
   ```
   And then change to the directory.
   ```
   cd a/
   ```

6. Check out the latest version of the deployment branch for the instance.
   ```
   git checkout sdsc-0.17.3
   ```

7. Navigate to the etc/spack directory.
   ```
   cd etc/spack
   ```

8. Copy the instance's initial configuration files to etc/spack.
   ```
   cp sdsc/expanse/0.17.3/cpu/yamls/\*.yaml ./
   ```

9. Navigate to the specs directory for the instance.
   ```
   cd sdsc/expanse/0.17.3/cpu/specs
   ``` 

10. Modify the core spec build scripts as necessary 
    ```
    sed -i 's/#SBATCH --reservation=root_63/#SBATCH --reservation=root_73/g' *.sh
    ```
    and then submit the spec build script at the start of the instance's core 
    (non-compiler) package dependency chain to the scheduler.
    ```
    sbatch parallel@20210922.sh
    ```
11. After the core (non-compiler) packages are built and installed 
    successfully, run the spec build script for the primary GCC
    compiler for the instance.
    ```
    sbatch gcc@10.2.0.sh
    ```
12. Once the primary GCC compiler is installed, edit the `compilers.yaml` 
    configuration file in etc/spack 
    ```
    vi "${SPACK_ROOT}/etc/spack/compilers.yaml"
    ```
    to include the default compiler build flags.
    ```
    flags:
      cflags: -O2 -march=native
      cxxflags: -O2 -march=native
      fflags: -O2 -march=native
    ```

13. Once the GCC compiler 's Spack configuration is complete, run its 
    package dependency chain.
    ```
    sbatch cmake@3.21.4.sh 
    ```

14. Follow map from here. adjust spec build scripts as necessary.

Create a dependency chain map on how to deploy any instance tracked in 
the repository. Place map in instance directory. e.g.
```
expanse/0.17.3/cpu
```
   
### Managing Changes to an Existing Spack Instance

- deploy change to configuration file
- add new package to sdsc package repository
- spack install a new spec

### Setting up a Shared Instance Configuration

### Using a Spack Mirror and Build Caches for Instance Backup(s)





## Additional Notes

### Protecting the sdsc/spack `develop` branch 

As discussed in its Contribution Guide, the Spack project currently uses 
the `develop` branch as its main development branch. This branch contains
all of the latest contributions to the project from the Spack community
and it is the branch on which tagged version releases of Spack are 
currently made. Moreover, all pull requests submitted back upstream to 
the Spack project are generally expected to start from and target the 
develop branch. As such, NO COMMITS or MERGES should ever be made 
directly to the develop branch of the sdsc/spack repository (or your own 
public fork of the sdsc/spack repository). It is maintained as an exact
mirror copy of the Spack project's upstream develop branch and nothing 
else.

### Fetching changes and re-syncing the `develop` branch 

When the develop branch of the sdsc/spack repository (or your own public
fork of the sdsc/spack repository) needs to be re-synchronized with the 
spack/spack upstream develop branch, you can fetch and merge all of the
recent changes as follows:

```
git clone https://github.com/sdsc/spack.git
cd spack
git fetch origin
git checkout develop
git remote add upstream https://github.com/spack/spack.git
git fetch --tags upstream
git merge upstream/develop
git push
git push --tags
```

### Creating a new deployment branch

A new deployment branch should be created prior to upgrading to a new
version of Spack. To create a new deployment branch, first fetch changes
and resync the develop branch from the spack/spack upstream repository 
as described above. Then create the new deployment branch from one of 
the most recent tagged releases available.

### Pulling files frome remote without overwriting local files

```
git stash
```

```
git pull
```

```
git stash pop
```

https://stackoverflow.com/questions/19216411/how-do-i-pull-files-from-remote-without-overwriting-local-files
