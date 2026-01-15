# OrthoPromoTree
This repository is to build phylogentic trees from orthologous promoters previously constructed by OrthoPromo


**prepare the orthologous promoters**

if your orthologous promoters are in a directory following this pattern:
```
dir/{Gene}/{one_fasta_per_species}
```
you'll need to combine them into one single fasta per gene including all species with their names in the header.

```
sbatch combine_species_per_Gene.slurm path/to/input/ path/to/output/
```
