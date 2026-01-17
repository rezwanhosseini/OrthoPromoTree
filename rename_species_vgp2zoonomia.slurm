#!/bin/bash

#SBATCH --job renameVGP2Zoonomia
#SBATCH -p dept_cpu
#SBATCH -c 64
#SBATCH --mem=64G
#SBATCH --output=logs/rename_%j.out


Rscript rename_species_vgp2zoonomia.R \
  promoterSeqs_byGene_combined \
  VGP_Species_withZoonomiaNames.txt \
  promoterSeqs_byGene_renamed \
  "*_combined_names.fa"
