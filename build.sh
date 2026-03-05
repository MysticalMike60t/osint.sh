#!/usr/bin/env bash

set -e

declare -lurx OSINTSH_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

declare -lur OSINTSH_LIB_DIR="$OSINTSH_SCRIPT_DIR/lib"
declare -lur OSINTSH_DIST_FOLDER="$OSINTSH_SCRIPT_DIR/dist"
declare -lur OSINTSH_TMP_FOLDER="$OSINTSH_SCRIPT_DIR/tmp"
declare -lur OSINTSH_TMP_FILENAME="osint.sh.tmp"
declare -lur OSINTSH_TMP_FILEPATH="$OSINTSH_TMP_FOLDER/$OSINTSH_TMP_FILENAME"

if [[ -d $OSINTSH_TMP_FOLDER ]]; then
  rm -rf $OSINTSH_TMP_FOLDER
fi

mkdir -p $OSINTSH_TMP_FOLDER

if [[ -d $OSINTSH_DIST_FOLDER ]]; then
  rm -rf $OSINTSH_DIST_FOLDER
fi

mkdir -p $OSINTSH_DIST_FOLDER

if [[ ! -d $OSINTSH_TMP_FOLDER ]] && [[ ! -d $OSINTSH_DIST_FOLDER ]]; then
  exit 1
fi

cp "$OSINTSH_SCRIPT_DIR/osint.sh" "$OSINTSH_TMP_FOLDER/$OSINTSH_TMP_FILENAME"

shopt -s globstar
for file in "$OSINTSH_LIB_DIR"/**/*.lib.sh; do
  [[ -f "$file" ]] || continue
  var+=$(<"$file")
  var+=$'\n\n'
done

export REPL="$var"

perl -0777 -i -pe '
  BEGIN { $r = $ENV{REPL} // "" }

  my $start = "# --> GENERATED CODE <-- #\n";
  my $endln = "# --> END GENERATED CODE <-- #";

  my $p = index($_, $start);
  die "Start marker not found\n" if $p < 0;

  my $q = index($_, $endln, $p + length($start));
  die "End marker not found\n" if $q < 0;

  # replace only the content between markers
  substr($_, $p + length($start), $q - ($p + length($start))) = $r;
' -- "$OSINTSH_TMP_FILEPATH"

if [[ -f $OSINTSH_TMP_FILEPATH ]]; then
  cp $OSINTSH_TMP_FILEPATH "$OSINTSH_DIST_FOLDER/osint.sh"
else
  exit 1
fi

if [[ -d $OSINTSH_TMP_FOLDER ]]; then
  rm -rf $OSINTSH_TMP_FOLDER
else
  exit 1
fi

exit 0