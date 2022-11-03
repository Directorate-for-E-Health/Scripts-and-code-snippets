#!/bin/bash

# @author Henning Jensen

# Perform FAT lookup of ICD-10 mappings for Helseplattformen
# Expects an argument with a path to a csv file with ';' as field separator, where the first field is the snomed concept id.
# First row of file is skipped (usually header row)

# Requirements:
# * BASH
# * awk
# * jq - https://stedolan.github.io/jq/



FILE="$1"

for concept in $(cat $FILE | awk -F ';' '{if (NR!=1) {print $1}}'); do
	curl -s "https://fat.terminologi.ehelse.no/api/diagnosis/hp/icd10/$concept" |
		jq -r '[.conceptId, .termNorwegianSCT.value, ([.mapping[].icd10Code] | join(",")), ([.mapping[].icd10Term] | join(",")) ]|@csv'	
done
