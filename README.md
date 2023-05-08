# SDSC HPC Software Deployment Guide

This guide documents the Spack-based software deployment process in use by the CyberInfrastructure Services and Solutions (CISS) Group and the High-Performance Computing (HPC) User Services Group at the San Diego Supercomputer Center (SDSC). All of the definitions, procedures, conventions, and policies defined within the guide are intended to help to build, maintain, and deploy custom Spack instances on the HPC systems they run and manage in collaboration with the HPC Systems Group at SDSC. 

## Table of Contents

- [Definitions and Terminology](https://github.com/sdsc/spack#definitions-and-terminolog)
- [DEPLOYMENT.md](DEPLOYMENT.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)

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
