_has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

_extract_argument() {
  echo "${2:-${1#*=}}"
}

_verbose() {
    set -x
}