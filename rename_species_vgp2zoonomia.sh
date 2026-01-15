#!/usr/bin/env bash
# Usage: bash promoterseqs_rename_with_zoonomia.sh <input_dir> <output_dir> <VGP_species_table.tsv>

set -euo pipefail

INDIR="${1:?Usage: $0 <input_dir> <output_dir> <VGP_species_table.tsv>}"
OUTDIR="${2:?Usage: $0 <input_dir> <output_dir> <VGP_species_table.tsv>}"
MAPTSV="${3:?Usage: $0 <input_dir> <output_dir> <VGP_species_table.tsv>}"

mkdir -p "$OUTDIR"

shopt -s nullglob
files=( "$INDIR"/*_combined_named.fa )
if [[ ${#files[@]} -eq 0 ]]; then
  echo "No files matching *_combined_named.fa in: $INDIR" >&2
  exit 1
fi

for infa in "${files[@]}"; do
  base="$(basename "$infa")"
  gene="${base%_combined_named.fa}"
  outfa="$OUTDIR/${gene}_combined_renamed.fa"
  echo "Renaming headers (VGP -> Zoonomia): $base -> $(basename "$outfa")"

  awk -v MAP="$MAPTSV" '
    BEGIN{
      FS="\t"
      # Read header row of mapping table to find column indices
      if ((getline line < MAP) <= 0) {
        print "ERROR: Could not read mapping file: " MAP > "/dev/stderr"
        exit 1
      }
      n = split(line, head, FS)
      for (i=1; i<=n; i++) idx[head[i]] = i

      if (!("Directory.Name" in idx) || !("Zoonomia_name" in idx)) {
        print "ERROR: mapping file must contain columns: Directory.Name and Zoonomia_name" > "/dev/stderr"
        exit 1
      }

      # Build map: VGP_name -> Zoonomia_name
      while ((getline line < MAP) > 0) {
        split(line, f, FS)
        split(f[idx["Directory.Name"]], a, "__")
        vgp = a[3]
        zoon = f[idx["Zoonomia_name"]]
        gsub(/\r/, "", vgp);  gsub(/\r/, "", zoon)
        if (vgp != "" && zoon != "") map[vgp] = zoon
      }
      close(MAP)
      FS = "\n"  # treat FASTA lines as whole lines
    }

    /^>/{
      # Example: >dipOrd2_[ENSG...]
      hdr = substr($0, 2)          # drop leading >
      vgp = hdr
      sub(/_\[.*$/, "", vgp)       # vgp = part before _[

      newname = (vgp in map) ? map[vgp] : vgp

      # Option 1 (most common): keep ONLY the species name in header
      print ">" newname
      next
    }

    { print }
  ' "$infa" > "$outfa"
done

echo "Done. Wrote ${#files[@]} files to: $OUTDIR"
