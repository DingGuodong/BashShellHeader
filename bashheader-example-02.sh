#!/bin/bash
# Copyright (c) 1999-2013 Philip Hands <phil@hands.com>
#               2013 Martin Kletzander <mkletzan@redhat.com>
#               2010 Adeodato =?iso-8859-1?Q?Sim=F3?= <asp16@alu.ua.es>
#               2010 Eric Moret <eric.moret@gmail.com>
#               2009 Xr <xr@i-jeuxvideo.com>
#               2007 Justin Pryzby <justinpryzby@users.sourceforge.net>
#               2004 Reini Urban <rurban@x-ray.at>
#               2003 Colin Watson <cjwatson@debian.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Shell script to manage docker container(s), List containers | Stop and Remove one or more containers
# See the docker(1), docker-stop(1), docker-inspect(1), docker-ps(1), docker-rm(1) man page for details

[ ${UID} -ne 0 ] && echo >&2 "Permission denied" && exit

usage () {
    printf 'Usage: %s [-a|-i|-l|-r|-?|-h|--help]  CONTAINER [CONTAINER...]\n' "$0" >&2
    # if you want use eof or EOF not at first column, you must use tab with "	" rather than spaces "    "
    cat <<-eof
        a shell script to use for "docker stop" and "docker rm" easily.
        
        Example: 

            $0 -l                                           List containers(default shows just running)
            $0 -i  CONTAINER|IMAGE [CONTAINER|IMAGE...]     Return low-level information on a container or image
            $0 -a  CONTAINER|IMAGE [CONTAINER|IMAGE...]     Show all containers
            $0 -r  CONTAINER|IMAGE [CONTAINER|IMAGE...]     Stop and remove one or more containers
            $0 -h                                           Print usage

eof
    exit 1
}


[ "x$1" == "x" ] && echo >&2 "ERROR: invalid option" && usage

case "$1" in

    --help|-h|-\?)
        usage
        ;;
    -i)
        OPT=$2
        [ "x$OPT" == "x" ] && echo >&2 "ERROR: invalid option" && usage
        /usr/bin/docker inspect $OPT
        ;;
    -l)
        [ $# -gt 2 ] && printf '%s: ERROR: Too many arguments.  Expecting 0 arguments, got: %s\n\n' "$0" "$@" >&2 && usage
        /usr/bin/docker ps
        ;;
    -a|-la|-al)
        [ $# -gt 2 ] && printf '%s: ERROR: Too many arguments.  Expecting 0 arguments, got: %s\n\n' "$0" "$@" >&2 && usage
        /usr/bin/docker ps -a
        ;;
    -r|-s|-sr)
        shift
        OPT=$@
        [ "x$OPT" == "x" ] && echo >&2 "ERROR: invalid option" && usage
        /usr/bin/docker stop $OPT && /usr/bin/docker rm $OPT
        ;;
    *)
        usage
        ;;
esac
