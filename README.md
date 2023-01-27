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

etc/spack/repos.yaml
var/spack/repos/sdsc/repo.yaml
var/spack/repos/sdsc/packages

etc/spack/sdsc/expanse/0.17.3/cpu/specs
etc/spack/sdsc/expanse/0.17.3/cpu/yamls




## Deploying HPC Software via Spack

### Deploying a Spack Instance

- start from existing deployment branch

### Managing Changes to a Spack Instance

- deploy change to configuration file
- add new package to sdsc package repository
- spack install a new spec

### Setting up a Shared Instance Configuration

### Using a Spack Mirror and Build Caches for Instance Backup(s)





## Additional Notes

### Protecting the sdsc/spack `develop` branch 

### Fetching changes and re-syncing the `develop` branch 

### Creating a new deployment branch
