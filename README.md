# OrthoPromoTree
This repository is to build phylogentic trees from orthologous promoters previously constructed by OrthoPromo


**Installs**: MAFFT, PRANK, trimAl, RAxML (raxmlHPC-PTHREADS).
```
MAFFT: sudo apt
```
```
PRANK:
conda create -n prank -c conda-forge -c bioconda prank mafft -y
conda activate prank
```
```
trimAL:
  git clone https://github.com/inab/trimal.git
  cd source
  make
  cd ..
  export PATH=/home/seh197/rezwan/research/Maria/MotifTSSvalidation/RERconverge/trimal/source:$PATH
  trimal -h ## check installation
```
```
RAxML:
  git clone https://github.com/stamatak/standard-RAxML.git
  cd standard-RAxML/
  make -f Makefile.PTHREADS.gcc
  ./raxmlHPC-PTHREADS -h ## check installation
  export PATH=/home/seh197/rezwan/research/Maria/MotifTSSvalidation/RERconverge/standard-RAxML:$PATH
  raxmlHPC-PTHREADS -h
  ```


**prepare the orthologous promoters**

if your orthologous promoters are in a directory following this pattern:
```
dir/{Gene}/{one_fasta_per_species}
```
you'll need to combine them into one single fasta per gene including all species with their names in the header.

```
sbatch combine_species_per_Gene.slurm path/to/input/ path/to/output/
```
