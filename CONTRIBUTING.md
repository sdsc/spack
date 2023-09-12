# SDSC HPC Software Contribution Guide

This document outlines how to contribute to the sdsc/spack project.

## Table of Contents

- [Getting Started](#getting-started)
- [Style Guides](#style-guides)
- [Miscellaneous Notes](#miscellaneous-notes)

## Getting Started

To contribute your change(s), please begin by creating a fork of the project in your personal GitHub account. If you have an existing GitHub account that is already associated with the [SDSC GitHub organization](https://github.com/sdsc), please use this account to create your fork. We recommend forking a complete copy the repository. e.g., uncheck the box
- [ ] **Copy the `sdsc-0.17.3` branch only**

before you click on the *Create fork* button. 

### Discussions

[GitHub Discussions](https://github.com/sdsc/spack/discussions) are enabled on the sdsc/spack project. At this time, we are using them to track meeting agendas and notes of the Spack Working Group at SDSC. However, we may consider using them in the future to document other annoucements, questions and answers, and discusions that are not well-catagorized as either an [Issue](#issues) or a ***Pull Request*** as described in more detail below. 
`
### Issues 

All GitHub Issues should be created within the sdsc/spack repository. 

In general, any change to an existing production instance should begin with the creation of a GitHub Issue that documents how the change request arised, how it was implemented, the pull requests used to resolve it, and any other commits that document the change. e.g., The issue might arise from an NSF ACCESS (ATS) ticket, an SDSC Zendesk (ZEN) ticket, or an internal team discussiion (SDSC). For example, the following example GitHub Issue is to modify the `modules.yaml` files for both the newely deployed `expanse/0.17.3/cpu/b` and `expanse/0.17.3.gpu/b` instances to provide users with a set of environment varibles they may use to reference the `ROOT` or `HOME` installiation path of a software package. 

- https://github.com/sdsc/spack/issues/74
- https://github.com/sdsc/spack/issues/75

### Pull Requests

Once an Issue is created. You can begin working on a pull request to resolve it. Before you make any changes to your fork of the sdsc/spack project, you should resync the target deployment branch that the pull request will be submitted to and is intended to eventually merged. This resyncing process can be done in two ways. The simplest is to use the *Sync fork* feature in GitHub. The other way on the command-line, where you will fetch changes and re-sync the deployment branch branch from sdsc/spack upstream.

## Style Guides

### Spack Configuration Files

Link to Spack documentation on this topic (and/or some other well-known
style guide for yaml files)

- https://spack.readthedocs.io/en/latest/configuration.html#configuration-files

### Spack Packages

Link to Spack documentation on this topic (and/or the standard PEP-8 
formatting principles).

- https://peps.python.org/pep-0008
- https://google.github.io/styleguide/pyguide.html

### Spack Specs

- https://google.github.io/styleguide/shellguide.html

## Miscellaneous Notes

https://github.com/atom/atom/blob/master/CONTRIBUTING.md#reporting-bugs

- name of the deployment branch: `"sdsc-${SPACK_VERSION}"`
- type of change: DOC, CONFIG, PACKAGE, or SPEC
- 

SDSC - sdsc-0.17.3 - DOC - README - 

SDSC: CONFIG - tscc/0.17.3/cpu - Set read-only group permissions on
 VASP6 in packages.yaml 

ACI-1XXXXX: PACKAGE - sdsc-0.17.3 - Update GROMACS 

ZEN-2XXXX: SPEC - expanse/0.17.3/gpu - Deploy 
