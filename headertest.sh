#!/bin/bash

# Public header
# =============================================================================================================================
# resolve links - $0 may be a softlink
PRG="$0"

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done

# Get standard environment variables
PRGDIR=`dirname "$PRG"`


# echo color function
function cecho {
    # Usage:
    # cecho -red sometext     #Error, Failed
    # cecho -green sometext   # Success
    # cecho -yellow sometext  # Warnning
    # cecho -blue sometext    # Debug
    # cecho -white sometext   # info
    # cecho -n                # new line
    # end

    while [ "$1" ]; do
        case "$1" in 
            -normal)        color="\033[00m" ;;
# -black)         color="\033[30;01m" ;;
-red)           color="\033[31;01m" ;;
-green)         color="\033[32;01m" ;;
-yellow)        color="\033[33;01m" ;;
-blue)          color="\033[34;01m" ;;
# -magenta)       color="\033[35;01m" ;;
# -cyan)          color="\033[36;01m" ;;
-white)         color="\033[37;01m" ;;
-n)             one_line=1;   shift ; continue ;;
*)              echo -n "$1"; shift ; continue ;;
esac

shift
echo -en "$color"
echo -en "$1"
echo -en "\033[00m"
shift

done 
if [ ! $one_line ]; then
        echo
fi
}
# end echo color function

# echo color function, smarter
function echo_r () {
    [ $# -ne 1 ] && return 0
    echo -e "\033[31m$1\033[0m"
}
function echo_g () {
    [ $# -ne 1 ] && return 0
    echo -e "\033[32m$1\033[0m"
}
function echo_y () {
    [ $# -ne 1 ] && return 0
    echo -e "\033[33m$1\033[0m"
}
function echo_b () {
    [ $# -ne 1 ] && return 0
    echo -e "\033[34m$1\033[0m"
}
# end echo color function, smarter

WORKDIR=$PRGDIR
# end public header
# =============================================================================================================================

# Where to get source code
SOURCEURL=


function setDirectoryStructure() {
    # from capistrano
    # Refer: http://capistranorb.com/documentation/getting-started/structure/
    # Refer: http://capistranorb.com/documentation/getting-started/structure/#

    # ├── current -> /var/www/my_app_name/releases/20150120114500/
    # ├── releases
    # │   ├── 20150080072500
    # │   ├── 20150090083000
    # │   ├── 20150100093500
    # │   ├── 20150110104000
    # │   └── 20150120114500
    # ├── repo
    # │   └── <VCS related data>
    # ├── revisions.log
    # └── shared
    #     └── <linked_files and linked_dirs>

    # current is a symlink pointing to the latest release. This symlink is updated at the end of a successful deployment. If the deployment fails in any step the current symlink still points to the old release.
    # releases holds all deployments in a timestamped folder. These folders are the target of the current symlink.
    # repo holds the version control system configured. In case of a git repository the content will be a raw git repository (e.g. objects, refs, etc.).
    # revisions.log is used to log every deploy or rollback. Each entry is timestamped and the executing user (username from local machine) is listed. Depending on your VCS data like branchnames or revision numbers are listed as well.
    # shared contains the linked_files and linked_dirs which are symlinked into each release. This data persists across deployments and releases. It should be used for things like database configuration files and static and persistent user storage handed over from one release to the next.
    # The application is completely contained within the path of :deploy_to. If you plan on deploying multiple applications to the same server, simply choose a different :deploy_to path.

    # Check directories for deploy
    [ !-d current ] && mkdir $WORKDIR/current
    [ !-d release ] && mkdir $WORKDIR/release
    [ !-d repository ] && mkdir $WORKDIR/repository
    [ !-d share ] && mkdir $WORKDIR/share
    # end directories structure
    touch $WORKDIR/.lock
}

# set a direclock
if [[ ! -f $WORKDIR/.lock ]]; then
    setDirectoryStructure
fi


function checkDependencies() {
    # Refer: 
    # if [ -z ${var+x} ]; then
    #     echo "var is unset"; else echo "var is set to '$var'"
    # fi
    # if [ "$var x" = " x" ]; then
    #     echo "var is empty"; else echo "var is set to '$var'"
    # fi
    # if [ -z $var ]; then
    #     echo "var is empty"; else echo "var is set to '$var'"
    # fi
    if [[ -z $SOURCEURL ]]; then
        echo "Error: SOURCEURL is undefined! "
        exit 1
    fi
    DISKSPACE=`df $WORKDIR | tail -n1 | awk '{print $(NF -2)}'`
    if [[ $DISKSPACE -lt 2097152 ]]; then
        echo "Warnning: Disk space of $WORKDIR is smaller than 2GB"
        #exit 1
    fi

}

function deploy() {

	# Make directory to release directory
	SOURCEDIR="$WORKDIR/release/$(date +%Y%m%d%H%M%S)"
	[ !-d $SOURCEDIR ] && mkdir $SOURCEDIR

    # Get files from source code repository
    git clone $SOURCEURL $SOURCEDIR
    # svn co http://$SOURCEURL $WORKDIR/repository

    # get branchnames or revision numbers from VCS data


	# Remove .git or .svn
	[ -d $SOURCEDIR/.git ] && rm -rf $SOURCEDIR/.git
	[ -d $SOURCEDIR/.svn ] && rm -rf $SOURCEDIR/.svn

	# ifdef Complie
    # endif

	# Make source code symbolic link to current
	ln -s $SOURCEDIR/* $WORKDIR/current

	# Make conf and logs to share

	# Make conf and logs symbolic link to current
	ln -s $WORKDIR/share/conf $WORKDIR/current
	ln -s $WORKDIR/share/logs $WORKDIR/current
	# Start service or validate status
	$WORKDIR/current/bin/startup.sh start
	RETVAL=$?

	# if started ok, then create a workable program to a file
	if [[ $RETVAL -eq 0 ]]; then
	# Note cat with eof must start at row 0
	cat >$WORKDIR/share/workable_program.log <<eof
$SOURCEDIR
eof
	fi
}

# Rollback to last right configuraton
function rollback() {
	# The key is find last files which can work
	WORKABLE_PROGRAM=`cat $WORKDIR/share/workable_program.log`

	# # Stop service
	# $WORKDIR/current/bin/startup.sh stop

	# Remove failed deploy
	rm -f $WORKDIR/current/*

	# Remake source code symbolic link to current
	ln -s $WORKABLE_PROGRAM/* $WORKDIR/current

	# Remake conf and logs symbolic link to current
	ln -s $WORKDIR/share/conf $WORKDIR/current
	ln -s $WORKDIR/share/logs $WORKDIR/current 

	## Start service
	$WORKDIR/current/bin/startup.sh start
}




function destroy() {
    # echo a awrnning message
    echo "Warnning: This action will destroy this project, and this is unrecoverable! "
    answer="n"
    echo "Do you want to destroy this project? "
    read -p "(Default no,if you want please input: y ,if not please press the enter button):" answer
    case "$answer" in
        y|Y|Yes|YES|yes|yES|yEs|YeS|yeS )
        # dell all file expect for this script self
        find $WORKDIR -type f ! -name "$0" -exec rm -rf {} \; 
        ;;
        n|N|No|NO|no|nO)
        echo "destroy action is cancel"
        exit 0
        ;;
        *)
        echo "Are you kidding me? You are a bad kid! "
        exit 1
        ;;
    esac
    
}

# Just a test for call itself, comment it
# if [[ $# -lt 1 ]]; then
# 	$0 help
# 	exit
# fi
case $1 in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;

    help|*)
        echo "Usage: $0 {deploy|rollback} with $0 itself"
        exit 1
        ;;
esac

# This is not essential with 'case .. esac' handled no args excutions
# replace "exit 0" with ":"
#exit 0
: