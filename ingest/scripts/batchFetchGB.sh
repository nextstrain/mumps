#! /usr/bin/env bash
# Auth: Jennifer Chang
# Date: 2018/05/14

set -e
set -u

# ======================= USAGE
if [[ $# -lt 1 ]]; then
  echo "USAGE: bash batchFetchGB.sh [genbank.ids] > [genbank.gb]"          >&2
  echo "  Given a file with a list of GenBank IDS, separated by newlines"  >&2
  echo "  Return a the concatinated genbanks from NCBI, fetched in batches">&2
  echo "     of 100 at a time" >&2
  echo " " >&2
  exit 0
fi

# ======================= Variables
NUM=0
QUERY=""
BATCH=100      # Fetch in batches of 50, 100, etc
FILE=${BATCH}  # Starting batch

# ======================= Main
GBLIST=$1

[[ -d gb ]] || mkdir gb

TOT=`grep -cv "^$" ${GBLIST}`
while read IDS; do
    if [[ $NUM -ge $BATCH ]]; then
    	echo "===== Fetching $((FILE-BATCH+1)) to $FILE of ${TOT} total Genbank IDs " >&2
    	[[ -f gb/${FILE}.gb ]] || sleep 1
    	[[ -f gb/${FILE}.gb ]] || curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&amp;id=${QUERY};rettype=gb&amp;retmode=text" > gb/${FILE}.gb

    	NUM=1;
    	QUERY="${IDS}";
    	FILE=$((FILE+BATCH));
    else
    	NUM=$((NUM+1))
    	QUERY="${QUERY},${IDS}"
    fi
done < ${GBLIST}

if [[ $NUM -gt 0 ]]; then
    echo "===== Fetching $((FILE-BATCH+1)) to ${TOT} of ${TOT} total Genbank IDs " >&2
    [[ -f gb/${FILE}.gb ]] || sleep 1
    [[ -f gb/${FILE}.gb ]] || curl "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&amp;id=${QUERY};rettype=gb&amp;retmode=text" > gb/${FILE}.gb
fi

cat gb/*.gb
rm -rf gb
