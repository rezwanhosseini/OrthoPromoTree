#!/bin/bash

#SBATCH --job mchikina
#SBATCH -p dept_cpu
#SBATCH -c 64
#SBATCH --mem=64G
#sbatch -x n153,n154

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: sbatch $0 <input_base_dir> <output_base_dir>"
  exit 1
fi

# Input directory: contains multiple folders like A1BG, AAABBB, etc.
input_base_dir="$1"
# Output directory: where the combined files will go (same subfolder names)
output_base_dir="$2"

mkdir -p "$output_base_dir"

echo "Starting conditional FASTA concatenation with modified headers..."
echo "Input: $input_base_dir"
echo "Output: $output_base_dir"

for folder in "$input_base_dir"/*/; do
    folder_name=$(basename "$folder")
    input_folder="$folder"
    combined_fasta="${output_base_dir}/${folder_name}_combined_names.fa"

    echo "Processing $folder_name"

    # Empty output file if it exists
    > "$combined_fasta"

    if compgen -G "$input_folder"/*.fa > /dev/null; then
        for fa_file in "$input_folder"/*.fa; do
            fasta_name=$(basename "$fa_file" .fa)

            while IFS= read -r line; do
                if [[ $line == ">"* ]]; then
                    echo ">${fasta_name}_[${line#>}]" >> "$combined_fasta"
                else
                    echo "$line" >> "$combined_fasta"
                fi
            done < "$fa_file"
        done

        echo "Combined FASTA written to $combined_fasta"
    else
        echo "No .fa files found in $input_folder. Skipping."
        rm -f "$combined_fasta"
    fi
done

echo "All done."
