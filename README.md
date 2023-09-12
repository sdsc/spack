# SDSC HPC Software Deployment Guide

This guide documents the Spack-based software deployment process in use 
by the CyberInfrastructure Services and Solutions (CISS) Group and the 
High-Performance Computing (HPC) User Services Group at the San Diego 
Supercomputer Center (SDSC). All of the definitions, conventions, 
policies and procedures outlined within the guide are intended to help
build, maintain, and deploy custom Spack instances on the HPC systems
they run and manage on behalf of end users in collaboration with the 
HPC Systems Group at SDSC. 

## Table of Contents

- [Definitions and Terminology](#definitions-and-terminology)
- [General Guidelines](#general-guidelines)
- [About the GitHub Repository](#about-the-github-repository)
- [How to Contribute](CONTRIBUTING.md)
- [Miscellaneous Notes](#miscellaneous-notes)

## Definitions and Terminology

- A Spack ***instance*** is a unique, stand-alone installation of a 
  specific version of `spack` that includes custom Spack configuration 
  files, Spack packages, and a collection of software applications, 
  libraries, and utilities built and installed by Spack.
- A Spack ***package*** is a set of instructions that defines how a 
  specific piece of software is compiled and/or installed by Spack. It
  specifies where to find and how to retrieve its software's source code, 
  its required (and/or optional) software dependencies, its compile-time 
  options, any patches to apply, etc. A Spack package is primarily defined 
  by it *package.py* file.
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
  In general, the core packages of a Spack instance are a set of compilers
  and other general software utilities. e.g., version control systems, 
  data transfer tools, etc.
- A Spack package ***dependency chain*** is an explicitly-defined ordered 
  set of Spack specs that share a common (core) compiler and/or MPI library,
  may depend on one another (or share other software dependencies), and 
  should be installed serially one after another, one at a time, as 
  prescribed by their dependencies.
- A Spack ***deployment branch*** is a *trunk*-like branch for a specific 
  version of `spack` that tracks all of the Spack configuration files, 
  Spack packages, and Spack specs used to deploy a Spack instance (or a
  set of instances).

## General Guidelines

The guidelines listed below are intended to provide a foundation for the
conventions, policies, and procedures established by SDSC to manage its 
Spack instances and the software deployment process on its HPC system. 
While none of the guidelines are definitive and many may change over time,
they should, however, be adhered to whenever possible, unless special 
circumstances apply.

- Any Spack instance deployed into production should originate from a 
  deployment branch within the sdsc/spack repository.
- Any change that must be made to a Spack instance already in production
  should originate as a pull request submitted to one of the deployment 
  brances within the sdsc/spack repository.
- 

- https://spack.readthedocs.io/en/latest/contribution_guide.html
- https://spack.readthedocs.io/en/latest/packaging_guide.html
- https://spack.readthedocs.io/en/latest/developer_guide.html

## About the GitHub Repository

The [sdsc/spack](https://github.com/sdsc/spack) GitHub repository is a 
custom fork of the Spack project's main [spack/spack](https://github.com/spack/spack)
GitHub repository.

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

## Miscellaneous Notes
