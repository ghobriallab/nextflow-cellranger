# Contitution

This document establishes the core principles, standards, and practices for this project. This project serves to develop nextflow pipelines for genomic data.

## Core Principles

### Documentation

When generating code and finding the best strategy for a solution follow the documentations in these folders:

- nextflow-master
- website-main

Only user the markdown files. 

## Type of development

We want litghweigth code, simple but robust enough that if it breaks we know what happened.

## Architecture

We use main.nf for the main workflow and then modules for each process. modules can be local or nf-core (whatever is easier to use.)

For local modules, follow the logic of nf-core modules, but we don't need tests there, keep if simple. We will need only docker containers.

## Parametrization

We want to allow users to change parameters, user module config to have default parameters for each module.

Make sure parameters can be set up in single config files that will be used to set up input, outdir and any other specific parameters. Make sure it can overwrite the defaults.

## Infrastructure

This code will be run in google cloude, but have this as a profile for nextflow since test runs will be run locally.

We will use always docker containers. 

We need some test data always to develop and make sure the code works.

## Type of data

This is a nextflow pipeline for single cell rnaseq. Data was produced with 10X technology. Search in their webpage for best practices on how to user their tools, like cellranger.