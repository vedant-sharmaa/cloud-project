# Benchmarking HDFS vs GlusterFS

## COL733: CLOUD COMPUTING TECHNOLOGY FUNDAMENTALS

## Submitted To
**Dr. Abhilash Jindal**

## Submitted By
- Vedant Sharma (2024CSY7553)
- Amaiya Singhal (2021CS50598)
- Tejas Anand (2021CS50595)

## Overview
This repository contains the benchmarking setup and tests for comparing **HDFS (Hadoop Distributed File System)** and **GlusterFS** using **FIO (Flexible I/O Tester)**. The benchmarking aims to analyze the performance of these two distributed file systems under different workloads.

## Setup Instructions
To get started with benchmarking, follow the setup instructions below.

### Prerequisites
Ensure the following dependencies are installed:
- SSH (for distributed system communication)
- git (to clone this repository)

### Repository Structure
- `HDFS/`: Contains scripts, tests and readme for HDFS.
- `GlusterFS/`: Contains scripts, tests and readme for GlusterFS.

### HDFS Setup
1. Navigate to the HDFS directory:
   ```bash
   cd HDFS
   ```
2. Follow the instructions in the `README.md` located in the `HDFS` directory to configure and start HDFS.
3. Ensure all nodes in the HDFS cluster are properly started and reachable.

### GlusterFS Setup
1. Navigate to the GlusterFS directory:
   ```bash
   cd GlusterFS
   ```
2. Follow the instructions in the `README.md` located in the `GlusterFS` directory to configure and start GlusterFS.
3. Ensure all nodes in the GlusterFS cluster are properly started and reachable.

## Testing
For testing, we are using **FIO (Flexible I/O Tester)**.

## Result Analysis
The result analysis are given in the ppt and discussed in the 10-minute video.


**Thank you**
