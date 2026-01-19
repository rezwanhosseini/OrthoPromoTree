# OrthoPromoTree
This repository is to build phylogentic trees from orthologous promoters previously constructed by OrthoPromo


**Installs**: MAFFT, PRANK, trimAl, RAxML (raxmlHPC-PTHREADS).
```
PRANK:
conda create -n prank -c conda-forge -c bioconda prank mafft -y
conda activate prank
conda install -c conda-forge parallel

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
sbatch run_prank_array_all.slurm promoter_files_all.txt 447-mammalian-2022v1.nh PRANK_results_all "-F -once -prunetree -prunedata"
```

***2. Trimming the gaps and unused sequences***

```
# for one .best.fa:
trimal -in AACS.best.fas -out AACS.best.trim.fas -gappyout

# for multiple - while keep tracking of the fractions selected and deleted
bash run_trimAl_test.sh <PRANK_results_test> <trimAl_results_test>

# for multiple on the cluster - (conda activate trimal)
# make a list of the files first:
find "$INDIR" -maxdepth 1 -type f -name <'*pattern'> | sort > <output.txt> # MAFFT_best_fa_files.txt

# then run the following to trim the files in batches of 200 by 94 array jobs
sbatch run_trimAl_all.slurm # this will save the trimmed alignments in trimAl_results_all/*.best.trim.fas

# counting the number of species in each region before and after trimming:
./count_headers.sh PRANK_results_test best.fas # before
./count_headers.sh trimAl_results_test best.trim.fas # after
# now get the difference between before and after

```

***3. build the tree***
```
conda activate treestuff-env
# for one region:

# 1. first prune the tree (to remove the species that we don't have sequences for)
awk '/^>/{sub(/^>/,""); print $1}' PRANK_results_test/AACS.best.fas | sort -u > fasta.taxa # get the fasta species
nw_labels -I 447-mammalian-2022v1.nh | sort -u > tree.taxa # get the tree species
comm -23 tree.taxa fasta.taxa > to_remove.taxa # get the species to remove
pxrmt -t 447-mammalian-2022v1.nh -f to_remove.taxa > 447-mammalian-2022v1.pruned.nh # prune the tree

# 2. build the tree based on the alignment for the region
raxmlHPC-PTHREADS -T 8 -s PRANK_results_test/AACS.best.fas   -m GTRGAMMA -t 447-mammalian-2022v1.pruned.nh -f e -p 1   -n AACS_untrim 


# for all regions:
find PRANK_results_all/ -maxdepth 1 -type f -name '*.best.fas' | sort > PRANK_best_fas_files.txt
nw_labels -I 447-mammalian-2022v1.nh | sort -u > taxa_files/tree.taxa
sbatch run_RAxML_all.slurm # note the INDIR=PRANK_results_all, OUTDIR=prank_untrimmed_RAxML, manifest=PRANK_best_fas_files.txt, and raxmlHPC-PTHREADS <other args> -n "{gene}_untrim, change RESULT and LOGFILE accordingly -- will make outputs in prank_untrimmed_RAxML/*raxml.tree

# this will create 11790 trees. some regions do not have enough species for the tree to build

find trimAl_results_all/ -maxdepth 1 -type f -name '*.best.trim.fas' | sort > trimAl_best_trim_fas_files.txt
### TODO: after trimming some sites from some species will be all NNNNN --> need to remove them or handle them somehow
code to handle it: ---
sbatch run_RAxML_all.slurm # note the INDIR=trimAl_results_all, OUTDIR=prank_trimmed_RAxML, and manifest=trimAl_best_trim_fas_files.txt, and raxmlHPC-PTHREADS <other args> -n "{gene}_trim, change RESULT and LOGFILE accordingly -- will make outputs in prank_trimmed_RAxML/*raxml.tree


```
