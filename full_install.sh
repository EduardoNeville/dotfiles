#!/usr/bin/env bash
# Deprecated entrypoint — replaced by ./install.sh (profile-driven engine).
# Legacy flags still work by translation.
case "${1:-}" in
--full | -f | --unattended | -u) shift ;;
esac
echo "full_install.sh is retired → using ./install.sh $*"
exec ./install.sh "$@"