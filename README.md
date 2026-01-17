# OrthoPromoTree
This repository is to build phylogentic trees from orthologous promoters previously constructed by OrthoPromo


**Installs**: MAFFT, PRANK, trimAl, RAxML (raxmlHPC-PTHREADS).
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
you might need to rename the species name in your fasta files (in our case from VGP) to match the tree (in our case from Zoonomia) used for the alignment by PRANK in the later steps.
```
sbatch rename_species_vgp2zoonomia.slurm
```
  
---

***1. Multiple alignment***

run **PRANK**: 

checking if not a lot of species are missing in the tree
```
# NOT NECESSARY - get a list of species that are missing in the Tree (so we can remove them from the sequences)
# for all on the cluster:
sbatch get_missing_species_inTree_all.slurm # output is in MotifTSSvalidation/missing_counts.tsv -- maximum number of speacies missing in the tree is 6 NoBigDeal

# NOT NECESSARY - remove the headers with the missing species (on a test subset) -- no need to do this since we will use -pruntree -prundata in prank
awk 'NR==FNR {drop[$1]=1; next}
     /^>/ {name=substr($0,2); keep=!(name in drop)}
     {if(keep) print}' AACS_missing.txt AACS_combined_renamed.fa > AACS_combined_nomissing.fa
```

Now the actual run:
```
#(takes ~5-10 minutes per region)

conda activate prank

# 1. put all the file names/directory into one txt file
find promoterSeqs_byGene_renamed/      -maxdepth 1 -type f -name '*_combined_renamed.fa'      | sort > promoter_files_all.txt

# 2. run them in batches of 100 files in 188 array jobs (should take ~16 hours)
sbatch run_prank_array_test.slurm promoter_files_all.txt 447-mammalian-2022v1.nh PRANK_results_all "-F -once -prunetree -prunedata"
```
