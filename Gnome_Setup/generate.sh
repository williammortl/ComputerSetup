#!/usr/bin/bash

dnf repoquery --userinstalled \
    --queryformat '%{name} %{reason}\n' \
    > package-reasons.txt

awk '$2 == "User" {print $1}' package-reasons.txt \
    | sort -u > packages.txt

