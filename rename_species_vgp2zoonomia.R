#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4) {
  cat("Usage: Rscript rename_fasta_headers.R <fasta_dir> <mapping_tsv> <output_dir> <pattern>\n",
      "Example: Rscript rename_fasta_headers.R fastas VGP_Species_withZoonomiaNames.txt renamed \"*_combined_named.fa\"\n",
      sep = "")
  quit(status = 1)
}

fasta_dir   <- args[1]
mapping_tsv <- args[2]
output_dir  <- args[3]
pattern     <- args[4]

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ---- read mapping table (expects columns: VGP_name, Zoonomia_name) ----
map_df <- read.table(mapping_tsv, sep = "\t", header = T) #read.table(mapping_tsv, sep = "\t", header = TRUE, stringsAsFactors = FALSE, quote = "", comment.char = "")
map_df$VGP_name <- sapply(strsplit(map_df$Directory.Name, "__"), `[`, 3)

map_df$Zoonomia_name <- paste0(toupper(substr(map_df$Zoonomia_name, 1, 1)),
                               substr(map_df$Zoonomia_name, 2, nchar(map_df$Zoonomia_name)))

vgp2zoo <- setNames(map_df$Zoonomia_name, map_df$VGP_name)

# ---- find FASTA files ----
fa_files <- Sys.glob(file.path(fasta_dir, pattern))
if (length(fa_files) == 0) stop("No FASTA files matched: ", file.path(fasta_dir, pattern))

# If you truly want ONLY ONE file, uncomment the next line:
# fa_files <- fa_files[1]

for (infa in fa_files) {
  base <- basename(infa)
  out_base <- sub("_combined_names\\.fa$", "_combined_renamed.fa", base)
  outfa <- file.path(output_dir, out_base)

  lines <- readLines(infa)

  is_hdr <- startsWith(lines, ">")
  hdrs <- lines[is_hdr]

  # Extract VGP name: everything between ">" and "_["
  vgp <- sub("^>([^_]+)_\\[.*$", "\\1", hdrs)

  # Map to Zoonomia (fallback to original if missing)
  zoo <- vgp2zoo[vgp]
  zoo[is.na(zoo)] <- vgp[is.na(zoo)]

  # Replace entire header with >zoonomia_name
  lines[is_hdr] <- paste0(">", zoo)

  writeLines(lines, outfa)
  message("Wrote: ", outfa)
}

