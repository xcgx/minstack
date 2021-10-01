#!/usr/bin/env bash

## GPL,Written By MoeClub.org and linux-live.org,moded by minlearn (https://gitee.com/minlearn/minstack/) for minstackos remastering and installing (both local install and cloud dd) purposes and for onedrive mirror/image hosting.
## meant to work/tested under linux and osx with bash > 4
## usage: ci.sh [[-b 0 ] -h 0] -t minstackos|debianbase
## usage: diweb.sh -t minstackos|deepin20|win10ltsc|winsrv2019|dsm61715284|osx10146

# =================================================================
# globals
# =================================================================

# mirror settings(deb and img)
#export custDEBMIRROR0='https://github.com/minlearn/minstack/raw/master'
export custDEBMIRROR1='https://minlearn.coding.net/p/mytechrepos/d/minstack/git/raw/master'
#export custDEBMIRROR2='https://gitee.com/minlearn/minstack/raw/master'

#export custIMGMIRROR0='https://github.com/minlearn/minstack/raw/master'
export custIMGMIRROR1='https://minlearn.coding.net/p/mytechrepos/d/minstack/git/raw/master'

# BUILD/HOST/TARGET tripe,most usually are auto informed
export tmpBUILD='0' #0:linux,1:unix,osx,2,lxc
export tmpBUILDREUSEPBIFS='0' #use pre built initrfs.img in tmpbuild,0 dont use,1,use initrfs1.img,2,use initrfs2.img,auto informed
export tmpBUILDPUTPVEINIFS='0' # put pve building prodcure inside initramfs?
export tmpBUILDCI='0' #full ci/cd mode,with git and split post addon actions,auto informed

export tmpHOST='0'  #0:cloud host;1:bearmetal
export tmpHOSTMODEL=''  #0，kvm guest,1,pd guest,2,hv guest，4,mpb，auto informed,not customable

export tmpTARGET='' #debianbase(none),minstackos,winsrvcore2019,deepin20,dsm61715284,osx10146
export tmpTARGETMODE='0'  #0:CLOUDDDINSTALL ONLY MODE? 1:CLOUDDDINSTALL+BUILD FULL MODE? defaultly it sholudbe 0
export tmpTARGETDDURL=''
export tmpTARGETINSTANTWITHOUTVNC='0' #simple ci/cd mode,no interactive

# customables,autoanswers for ci/cd
export custWORD=''
export custIPADDR=''
export custIPMASK=''
export custIPGATE=''
export custIMGSIZE='10'
export custUSRANDPASS='tdl'
export tmpTGTNICNAME='eth0'
# pve only,input target nic public ip(127.0.0.1 and 127.0.1.1 forbidden,enter to use defaults 111.111.111.111)
export tmpTGTNICIP='111.111.111.111'
#input target wifi connecting settings(in valid hotspotname,hotspotpasswd,wifinicname form,passwd 8-63 long,enter to leave blank)
export tmpWIFICONNECT='CMCC-Lsl,11111111,wlan0'
# input target ip or domain that will be embeded into client
export tmpEBDCLIENTURL='t.shalol.com'

export GENCLIENTS='y'
export GENCLIENTSWINOSX='n'
export PACKCLIENTS='n'
export GENAPPS='0' #0:lxc0+mpd,1:lxc0+dsm,2：lxc0+dsm+linux,3:linux1h/2g/64g+win2h4g/128g only,4:linux1h/2g/64g+osx2h4g/128g only,5,all 0,1,2,3,4
export PACKAPPPS='n'

# dir settings
downdir='../minstacktmpdown'
remasteringdir='_tmpremastering'
targetdir='_tmptarget'

export PATH=.:./tools:../tools:/usr/sbin:/usr/bin:/sbin:/bin:/
topdir=$(dirname $(readlink -f $0))
cd $topdir
CWD="$(pwd)"
echo "Changing current directory to $CWD"

[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1
[[ ! "$(bash --version | head -n 1 | grep -o '[1-9]'| head -n 1)" -ge '4' ]] && echo "Error:bash must be at least 4!" && exit 1
[[ "$(uname)" == "Darwin" ]] && tmpBUILD='1' && read -s -n1 -p "osx detected"

while [[ $# -ge 1 ]]; do
  case $1 in
    -b|--build)
      shift
      tmpBUILD="$1"
      [[ "$tmpBUILD" == '2' ]] && echo "lxc given,will auto inform tmpBUILDCI and tmpBUILDREUSEPBIFS as 1,this is not by customs" && tmpBUILDCI='1' && tmpBUILDREUSEPBIFS='1' && tmpTARGETMODE='1' && echo -en "\n" && [[ -z "$tmpBUILDCI" ]] && echo "buildci were empty" && exit 1
      [[ "$tmpBUILD" != '2' ]] && tmpBUILDCI='0' && tmpBUILDREUSEPBIFS='0' && tmpTARGETMODE='1'
      shift
      ;;
    -h|--host)
      shift
      tmpHOST="$1"
      [[ "$tmpHOST" == '1' ]] && echo "baremetal host args given,will use mbp hostmodel and set TARGETMODE as 1,this is auto informed not by customs" && tmpHOSTMODEL='mbp' && tmpTARGETMODE='1' && echo -en "\n" && [[ -z "$tmpHOSTMODEL" ]] && echo "hostmodel were empty" && exit 1
      [[ "$tmpHOST" == '0' ]] && tmpTARGETMODE='1'
      [[ "$tmpHOST" == '2' ]] && tmpHOSTMODEL='hv'
      shift
      ;;
    -t|--target)
      shift
      tmpTARGET="$1"
      case $tmpTARGET in
        debianbase) tmpTARGETMODE='1' ;;
        minstackos) 
          [[ "$tmpHOST" != '2' && "$tmpTARGET" == 'minstackos' ]] && tmpTARGETMODEL=1 || tmpTARGETMODEL='0'
          [[ "$tmpTARGETMODE" != '1' ]] && echo "instonly mode detected" && tmpTARGETDDURL=$custIMGMIRROR1/_build/minstackos/minstack_
          [[ "$tmpTARGETMODE" == '1' ]] && echo "fullgen mode detected" && tmpTARGETDDURL=$custIMGMIRROR1/_build/minstackos/minstack_ ;;
        deepin20|win10ltsc|winsrv2019|dsm61715284|osx10146) tmpTARGETMODE='0';tmpTARGETDDURL=$custIMGMIRROR1/$tmpTARGET".gz" ;;
        *) echo "$tmpTARGET" |grep -q '^http://\|^ftp://\|^https://';[[ $? -ne '0' ]] && echo "targetname not known" && exit 1 || echo "raw urls detected" && tmpTARGETDDURL=$tmpTARGET ;;
      esac
      shift
      ;;
    *)
      if [[ "$1" != 'error' ]]; then echo -ne "\nInvaild option: '$1'\n\n"; fi
      echo -ne " Usage(args are self explained):\n\tbash $(basename $0)\t-b/--build\n\t\t\t\t-h/--host\n\t\t\t\t-t/--target\n\t\t\t\t\n"
      exit 1;
      ;;
    esac
  done

#clear

# =================================================================
# Below are function libs
# =================================================================

function CheckDependence(){
  FullDependence='0';
  lostdeplist="";
  for BIN_DEP in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "$1" |sed 's/,/\n/g' || echo "$1" |sed 's/,/\'$'\n''/g'`
    do
      if [[ -n "$BIN_DEP" ]]; then
        Founded='1';
        for BIN_PATH in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "$PATH" |sed 's/:/\n/g' || echo "$PATH" |sed 's/:/\'$'\n''/g'`
          do
            ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
            if [ $? == '0' ]; then
              Founded='0';
              break;
            fi
          done
        echo -en "[ \033[32m $BIN_DEP";
        if [ "$Founded" == '0' ]; then
          echo -en ",ok \033[0m] ";
        else
          FullDependence='1';
          echo -en ",\033[31m not ok \033[0m] ";
          lostdeplist+="$BIN_DEP"
        fi
      fi
  done
  if [ "$FullDependence" == '1' ]; then
    echo -ne "\n \033[31m Error! \033[0m Please use '\033[33m apt-get \033[0m' or '\033[33m yum \033[0m' or '\033[33m brew \033[0m' install it.\n"
    [[ $lostdeplist =~ "ar" ]] && echo "ar: in debian:binutils"
    [[ $lostdeplist =~ "xzcat" ]] && echo "xzcat: debian:xz-utils brew:xz"
    [[ $lostdeplist =~ "md5sum" || $lostdeplist =~ "sha1sum" || $lostdeplist =~ "sha256sum" ]] && echo "brew:coreutils"
    [[ $lostdeplist =~ "losetup" ]] && echo "losetup: debian:util-linux"
    [[ $lostdeplist =~ "parted" ]] && echo "parted: debian:parted"
    [[ $lostdeplist =~ "mkfs.vfat" ]] && echo "mkfs.vfat: debian:dosfstools"
    [[ $lostdeplist =~ "squashfs" ]] && echo "mksquashfs: debian:squashfs-tools"
    [[ $lostdeplist =~ "sqlite3" ]] && echo "mksquashfs: debian:sqlite3"
    [[ $lostdeplist =~ "unzip" ]] && echo "mksquashfs: debian:unzip"
    [[ $lostdeplist =~ "grub-mkimage" ]] && echo "grub-mkimage: debian:grub2"
    [[ $lostdeplist =~ "git" ]] && echo "git: debian:git"
    [[ $lostdeplist =~ "libtoolize" ]] && echo "libtoolize: debian:libtool"
    [[ $lostdeplist =~ "m4" ]] && echo "m4: debian:m4"
    [[ $lostdeplist =~ "make" ]] && echo "make: debian:make"
    [[ $lostdeplist =~ "g++" ]] && echo "g++: debian:g++"
    [[ $lostdeplist =~ "autoconf" ]] && echo "autoconf: debian:autoconf"
    [[ $lostdeplist =~ "zip" ]] && echo "zip: debian:zip"

    exit 1;
  fi
}

function SelectDEBMirror(){

  [ $# -ge 1 ] || exit 1

  declare -A MirrorTocheck
  MirrorTocheck=(["Debian0"]="" ["Debian1"]="" ["Debian2"]="")
  
  echo "$1" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian0]=$(echo "$1" |sed 's/\ //g');
  echo "$2" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian1]=$(echo "$2" |sed 's/\ //g');
  echo "$3" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian2]=$(echo "$3" |sed 's/\ //g');

  SpeedLog0=''
  SpeedLog1=''
  SpeedLog2=''

  for mirror in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "${!MirrorTocheck[@]}" |sed 's/\ /\n/g' |sort -n |grep "^Debian" || echo "${!MirrorTocheck[@]}" |sed 's/\ /\'$'\n''/g' |sort -n |grep "^Debian"`
    do
      CurMirror="${MirrorTocheck[$mirror]}"

      [ -n "$CurMirror" ] || continue

      # CheckPass1='0';
      # DistsList="$(wget --no-check-certificate -qO- "$CurMirror/dists/" |grep -o 'href=.*/"' |cut -d'"' -f2 |sed '/-\|old\|Debian\|experimental\|stable\|test\|sid\|devel/d' |grep '^[^/]' |sed -n '1h;1!H;$g;s/\n//g;s/\//\;/g;$p')";
      # for DIST in `echo "$DistsList" |sed 's/;/\n/g'`
        # do
          # [[ "$DIST" == "buster" ]] && CheckPass1='1' && break;
        # done
      # [[ "$CheckPass1" == '0' ]] && {
        # echo -ne '\nbuster not find in $CurMirror/dists/, Please check it! \n\n'
        # bash $0 error;
        # exit 1;
      # }

      # CheckPass2=0
      # ImageFile="SUB_MIRROR/releases/linux"
      # [ -n "$ImageFile" ] || exit 1
      # URL=`echo "$ImageFile" |sed "s#SUB_MIRROR#${CurMirror}#g"`
      # wget --no-check-certificate --spider --timeout=3 -o /dev/null "$URL"
      # [ $? -eq 0 ] && CheckPass2=1 && echo "$CurMirror" && break
    # done

      CurrentMirrorSpeed=$(curl --connect-timeout 10 -m 10 -Lo /dev/null -skLw "%{speed_download}" $CurMirror/debian/dists/buster/1m) && CurrentMirrorSpeed=${CurrentMirrorSpeed/.*}
      [ "$mirror" == "Debian0" ] && SpeedLog0="$CurrentMirrorSpeed"
      [ "$mirror" == "Debian1" ] && SpeedLog1="$CurrentMirrorSpeed"
      [ "$mirror" == "Debian2" ] && SpeedLog2="$CurrentMirrorSpeed"
    done
    [[ "$SpeedLog0" != "0.000" && "$SpeedLog0" -gt "$SpeedLog1" && "$SpeedLog0" -gt "$SpeedLog2" ]] && echo "${MirrorTocheck[Debian0]}"
    [[ "$SpeedLog1" != "0.000" && "$SpeedLog1" -gt "$SpeedLog0" && "$SpeedLog1" -gt "$SpeedLog2" ]] && echo "${MirrorTocheck[Debian1]}"
    [[ "$SpeedLog2" != "0.000" && "$SpeedLog2" -gt "$SpeedLog0" && "$SpeedLog2" -gt "$SpeedLog1" ]] && echo "${MirrorTocheck[Debian2]}"

    # [[ $CheckPass2 == 0 ]] && {
      # echo -ne "\033[31m Error! \033[0m the file linux not find in $CurMirror/releases/! \n";
      # bash $0 error;
      # exit 1;
    # }

}

function CheckTarget(){

  if [[ -n "$1" ]]; then
    echo "$1" |grep -q '^http://\|^ftp://\|^https://';
    [[ $? -ne '0' ]] && echo 'No valid URL in the DD argument,Only support http://, ftp:// and https:// !' && exit 1;

    IMGHEADERCHECK="$(curl -k -IsL "$1")";
    IMGTYPECHECK="$(echo "$IMGHEADERCHECK"|grep -E -o '200|302'|head -n 1)" || IMGTYPECHECK='0';

    #directurl style,just 1
    [[ "$IMGTYPECHECK" == '200' ]] && \
    {
      # IMGSIZE
      UNZIP='1' && sleep 3s && echo -en "[ \033[32m x-gzip \033[0m ]";
    }

    # refurl style,(no more imgheadcheck and 1 more imgtypecheck pass needed)
    [[ "$IMGTYPECHECK" == '302' ]] && \
    IMGTYPECHECKPASS_REF="$(echo "$IMGHEADERCHECK"|grep -E -o 'raw|qcow2|gzip|x-gzip'|head -n 1)" && {
      # IMGSIZE
      [[ "$IMGTYPECHECKPASS_REF" == 'raw' ]] && UNZIP='0' && sleep 3s && echo -e "[ \033[32m raw \033[0m ]";
      [[ "$IMGTYPECHECKPASS_REF" == 'qcow2' ]] && UNZIP='0' && sleep 3s && echo -e "[ \033[32m raw \033[0m ]";
      [[ "$IMGTYPECHECKPASS_REF" == 'gzip' ]] && UNZIP='1' && sleep 3s && echo -e "[ \033[32m gzip \033[0m ]";
      [[ "$IMGTYPECHECKPASS_REF" == 'x-gzip' ]] && UNZIP='1' && sleep 3s && echo -e "[ \033[32m x-gzip \033[0m ]";
      [[ "$IMGTYPECHECKPASS_REF" == 'gunzip' ]] && UNZIP='2' && sleep 3s && echo -e "[ \033[32m gunzip \033[0m ]";
    }

    [[ "$UNZIP" == '' ]] && echo 'didnt got a unzip mode, you may input a incorrect url,or the bad network traffic caused it,exit ... !' && exit 1;
    #[[ "$IMGSIZE" -le '10' ]] && echo 'img too small,is there sth wrong? exit ... !' && exit 1;
    [[ "$IMGTYPECHECK" == '0' ]] && echo 'not a raw,tar,gunzip or 301/302 ref file, exit ... !' && exit 1;

  else
    echo 'Please input vaild image URL! ';
    exit 1;
  fi

}

function getbasics(){

  compositemode="$1"
  kernelimage=$downdir/debian/dists/buster/main/binary-amd64/deb/linux-image-4.19.0-14-amd64_4.19.171-2_amd64.deb

  [[ "$1" == 'down' ]] && {

    [[ ! -f $kernelimage ]] && (for i in `seq -w 000 048`;do wget -qO- --no-check-certificate $MIRROR/_build/debian/dists/buster/main/binary-amd64/deb/linux-image-4.19.0-14-amd64_4.19.171-2_amd64.deb$i; done) > $kernelimage && [[ $? -ne '0' ]] && echo "download failed" && exit 1
    [[ ! -f $topdir/p/diweb/tdl/tdl.tar.gz ]] && (for i in `seq -w 000 057`;do wget -qO- --no-check-certificate $MIRROR/p/diweb/tdl/tdl.tar.gz$i; done) > $topdir/p/diweb/tdl/tdl.tar.gz && [[ $? -ne '0' ]] && echo "download failed" && exit 1

  }

  [[ "$1" == 'cat' ]] && {

    [[ ! -f $kernelimage ]] && cat $kernelimage*  > $kernelimage && [[ $? -ne '0' ]] && echo "cat failed" && exit 1
    [[ ! -f $topdir/p/diweb/tdl/tdl.tar.gz ]] && cat $topdir/p/diweb/tdl/tdl.tar.gz* > $topdir/p/diweb/tdl/tdl.tar.gz && [[ $? -ne '0' ]] && echo "cat failed" && exit 1

  }

}

function getoptpkgs(){

  compositemode="$1"

  declare -A OPTPKGS
  OPTPKGS=(
    ["libc1"]="dists/buster/main/debian-installer/binary-amd64/deb/libc6_2.28-10_amd64.deb"

    ["common1"]="dists/buster/main/debian-installer/binary-amd64/deb/libgnutls30_3.6.7-4-deb10u6_amd64.deb"
    ["common2"]="dists/buster/main/debian-installer/binary-amd64/deb/libp11-kit0_0.23.15-2-deb10u1_amd64.deb"
    ["common3"]="dists/buster/main/debian-installer/binary-amd64/deb/libtasn1-6_4.13-3_amd64.deb"
    ["common4"]="dists/buster/main/debian-installer/binary-amd64/deb/libnettle6_3.4.1-1_amd64.deb"
    ["common5"]="dists/buster/main/debian-installer/binary-amd64/deb/libhogweed4_3.4.1-1_amd64.deb"
    ["common6"]="dists/buster/main/debian-installer/binary-amd64/deb/libgmp10_6.1.2-dfsg-4_amd64.deb"

    ["busybox1"]="dists/buster/main/debian-installer/binary-amd64/deb/busybox_1.30.1-4_amd64.deb"

    ["wgetssl1"]="dists/buster/main/debian-installer/binary-amd64/deb/libidn2-0_2.0.5-1-deb10u1_amd64.deb"
    ["wgetssl2"]="dists/buster/main/debian-installer/binary-amd64/deb/libpsl5_0.20.2-2_amd64.deb"
    ["wgetssl3"]="dists/buster/main/debian-installer/binary-amd64/deb/libpcre2-8-0_10.32-5_amd64.deb"
    ["wgetssl4"]="dists/buster/main/debian-installer/binary-amd64/deb/libuuid1_2.33.1-0.1_amd64.deb"
    ["wgetssl5"]="dists/buster/main/debian-installer/binary-amd64/deb/zlib1g_1.2.11.dfsg-1_amd64.deb"
    ["wgetssl6"]="dists/buster/main/debian-installer/binary-amd64/deb/libssl1.1_1.1.1d-0-deb10u5_amd64.deb"
    ["wgetssl7"]="dists/buster/main/debian-installer/binary-amd64/deb/openssl_1.1.1d-0-deb10u5_amd64.deb"
    ["wgetssl8"]="dists/buster/main/debian-installer/binary-amd64/deb/wget_1.20.1-1.1_amd64.deb"
    ["wgetssl9"]="dists/buster/main/debian-installer/binary-amd64/deb/libunistring2_0.9.10-1_amd64.deb"
    ["wgetssl10"]="dists/buster/main/debian-installer/binary-amd64/deb/libffi6_3.2.1-9_amd64.deb"

    ["ddprogress1"]="dists/buster/main/debian-installer/binary-amd64/deb/libncursesw5_5.9-20140913-1-deb8u3_amd64.deb"
    ["ddprogress2"]="dists/buster/main/debian-installer/binary-amd64/deb/libtinfo5_5.9-20140913-1-deb8u3_amd64.deb"
    ["ddprogress3"]="dists/buster/main/debian-installer/binary-amd64/deb/debianutils_4.4-b1_amd64.deb"
    ["ddprogress4"]="dists/buster/main/debian-installer/binary-amd64/deb/sensible-utils_0.0.9-deb8u1_all.deb"
    ["ddprogress5"]="dists/buster/main/debian-installer/binary-amd64/deb/pv_1.5.7-2_amd64.deb"
    ["ddprogress6"]="dists/buster/main/debian-installer/binary-amd64/deb/dialog_1.2-20140911-1_amd64.deb"

    ["webfs1"]="dists/buster/main/debian-installer/binary-amd64/deb/mime-support_3.62_all.deb"
    ["webfs2"]="dists/buster/main/debian-installer/binary-amd64/deb/webfs_1.21-ds1-12_amd64.deb"

    ["xorg1"]="pool/ldeb/xorg.ldeb"
    #["xorg2"]="pool/ldeb/chromium.ldeb"

    ["faasd1"]="pool/ldeb/containerd.ldeb"
    ["faasd2"]="pool/ldeb/buildkit.ldeb"
    ["faasd3"]="pool/ldeb/faasd.ldeb"

    ["vscodeonline1"]="pool/ldeb/vscodeonline.ldeb"

  )

  for pkg in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "$2" |sed 's/,/\n/g' || echo "$2" |sed 's/,/\'$'\n''/g'`
    do
    
      [[ -n "${OPTPKGS[$pkg"1"]}" ]] && {

        for subpkg in `[[ "$tmpBUILDFORM" -ne '0' ]] && echo "${!OPTPKGS[@]}" |sed 's/\ /\n/g' |sort -n |grep "^$pkg" || echo "${!OPTPKGS[@]}" |sed 's/\ /\'$'\n''/g' |sort -n |grep "^$pkg"`
          do
            cursubpkgfile="${OPTPKGS[$subpkg]}"
            [ -n "$cursubpkgfile" ] || continue

            cursubpkgfilepath=${cursubpkgfile%/*}
            mkdir -p $downdir/debian/$cursubpkgfilepath
            cursubpkgfilename=${cursubpkgfile##*/}
            cursubpkgfilename2=$(echo $cursubpkgfilename|sed "s/\(+\|~\)/-/g")

            echo -en "\033[s \033[K [ \033[32m ${cursubpkgfilename2:0:10} \033[0m ] \033[u"

            [[ "$1" == 'down' ]] && {
              [[ $cursubpkgfilename2 == 'libc6_2.28-10_amd64.deb' ]] && [[ ! -f $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 ]] && (for i in 000 001 002;do wget -qO- --no-check-certificate $MIRROR/_build/debian/$cursubpkgfile$i; done) > $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 && [[ $? -ne '0' ]] && echo "download failed" && exit 1;
              [[ $cursubpkgfilename2 == 'libgnutls30_3.6.7-4-deb10u6_amd64.deb' ]] && [[ ! -f $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 ]] && (for i in 000 001;do wget -qO- --no-check-certificate $MIRROR/_build/debian/$cursubpkgfile$i; done) > $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 && [[ $? -ne '0' ]] && echo "download failed" && exit 1;
              [[ $cursubpkgfilename2 == 'libssl1.1_1.1.1d-0-deb10u5_amd64.deb' ]] && [[ ! -f $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 ]] && (for i in 000 001;do wget -qO- --no-check-certificate $MIRROR/_build/debian/$cursubpkgfile$i; done) > $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 && [[ $? -ne '0' ]] && echo "download failed" && exit 1;
              [[ $cursubpkgfilename2 != 'libc6_2.28-10_amd64.deb' && $cursubpkgfilename2 != 'libgnutls30_3.6.7-4-deb10u6_amd64.deb' && $cursubpkgfilename2 != 'libssl1.1_1.1.1d-0-deb10u5_amd64.deb' ]] && [[ ! -f $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 ]] && wget -qO- --no-check-certificate $MIRROR/_build/debian/$cursubpkgfile > $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 && [[ $? -ne '0' ]] && echo "download failed" && exit 1;
            }

            [[ "$1" == 'cat' ]] && {
              [[ $cursubpkgfilename2 == 'libc6_2.28-10_amd64.deb' || $cursubpkgfilename2 == 'libgnutls30_3.6.7-4-deb10u6_amd64.deb' || $cursubpkgfilename2 == 'libssl1.1_1.1.1d-0-deb10u5_amd64.deb' || $cursubpkgfilename2 != 'libc6_2.28-10_amd64.deb' ]] && [[ ! -f $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 ]] && cat $topdir/_build/debian/$cursubpkgfilepath/$cursubpkgfilename2* > $downdir/debian/$cursubpkgfilepath/$cursubpkgfilename2 && [[ $? -ne '0' ]] && echo "cat failed" && exit 1;
            }

          done
            # [[ ! -f  /tmp/boot/${OPTPKGS["bin"$pkg]}2 ]] && echo 'Error! $2 SUPPORT ERROR.' && exit 1;
      }

    done

  ## there is more to be download to downdir, under scripts patchinitrd.sh

}

ipNum()
{
  local IFS='.';
  read ip1 ip2 ip3 ip4 <<<"$1";
  echo $((ip1*(1<<24)+ip2*(1<<16)+ip3*(1<<8)+ip4));
}

SelectMax(){
  ii=0;
  for IPITEM in `route -n |awk -v OUT=$1 '{print $OUT}' |grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'`
    do
      NumTMP="$(ipNum $IPITEM)";
      eval "arrayNum[$ii]='$NumTMP,$IPITEM'";
      ii=$[$ii+1];
    done
  echo ${arrayNum[@]} |sed 's/\s/\n/g' |sort -n -k 1 -t ',' |tail -n1 |cut -d',' -f2;
}

parsenetcfg(){

  [ -n "$custIPADDR" ] && [ -n "$custIPMASK" ] && [ -n "$custIPGATE" ] && setNet='1';
  [[ -n "$custWORD" ]] && myPASSWORD="$(openssl passwd -1 "$custWORD")";
  [[ -z "$myPASSWORD" ]] && myPASSWORD='$1$4BJZaD0A$y1QykUnJ6mXprENfwpseH0';

  if [[ -n "$interface" ]]; then
    IFETH="$interface"
  else
    IFETH="auto"
  fi

  [[ "$setNet" == '1' ]] && {
    IPv4="$custIPADDR";
    MASK="$custIPMASK";
    GATE="$custIPGATE";
  } || {
    DEFAULTNET="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}')";
    [[ -n "$DEFAULTNET" ]] && IPSUB="$(ip addr |grep ''${DEFAULTNET}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')";
    IPv4="$(echo -n "$IPSUB" |cut -d'/' -f1)";
    NETSUB="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')";
    GATE="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')";
    [[ -n "$NETSUB" ]] && MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${NETSUB}'' |cut -d'/' -f1)";
  }

  [[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
    echo "Not found \`ip command\`, It will use \`route command\`."


    [[ -z $IPv4 ]] && IPv4="$(ifconfig |grep 'Bcast' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1)";
    [[ -z $GATE ]] && GATE="$(SelectMax 2)";
    [[ -z $MASK ]] && MASK="$(SelectMax 3)";

    [[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
      echo "Error! Not configure network. ";
      exit 1;
    }
  }

  [[ "$setNet" != '1' ]] && [[ -f '/etc/network/interfaces' ]] && {
    [[ -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='1' || AutoNet='0';
    [[ -d /etc/network/interfaces.d ]] && {
      ICFGN="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || ICFGN='0';
      [[ "$ICFGN" -ne '0' ]] && {
        for NetCFG in `ls -1 /etc/network/interfaces.d/*.cfg`
          do 
            [[ -z "$(cat $NetCFG | sed -n '/iface.*inet static/p')" ]] && AutoNet='1' || AutoNet='0';
            [[ "$AutoNet" -eq '0' ]] && break;
          done
      }
    }
  }

  [[ "$setNet" != '1' ]] && [[ -d '/etc/sysconfig/network-scripts' ]] && {
    ICFGN="$(find /etc/sysconfig/network-scripts -name 'ifcfg-*' |grep -v 'lo'|wc -l)" || ICFGN='0';
    [[ "$ICFGN" -ne '0' ]] && {
      for NetCFG in `ls -1 /etc/sysconfig/network-scripts/ifcfg-* |grep -v 'lo$' |grep -v ':[0-9]\{1,\}'`
        do 
          [[ -n "$(cat $NetCFG | sed -n '/BOOTPROTO.*[dD][hH][cC][pP]/p')" ]] && AutoNet='1' || {
            AutoNet='0' && . $NetCFG;
            [[ -n $NETMASK ]] && MASK="$NETMASK";
            [[ -n $GATEWAY ]] && GATE="$GATEWAY";
          }
          [[ "$AutoNet" -eq '0' ]] && break;
        done
    }
  }

}

parsegrub(){

  if [[ "$LoaderMode" == "0" ]]; then
    [[ -f '/boot/grub/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg';
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBVER='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg';
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBVER='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf';
    [ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub.\n" && exit 1;
  else
    tmpTARGETINSTANTWITHOUTVNC='0'
  fi

  if [[ "$LoaderMode" == "0" ]]; then
    [[ ! -f $GRUBDIR/$GRUBFILE ]] && echo "Error! Not Found $GRUBFILE. " && exit 1;

    [[ ! -f $GRUBDIR/$GRUBFILE.old ]] && [[ -f $GRUBDIR/$GRUBFILE.bak ]] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old;
    mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak;
    [[ -f $GRUBDIR/$GRUBFILE.old ]] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE;
  else
    GRUBVER='2'
  fi


  [[ "$GRUBVER" == '0' ]] && {

    mkdir -p $remasteringdir/grub

    READGRUB=''$remasteringdir'/grub/grub.read'
    cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' |grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' |sed 's/%%%%%%%/\n/g' >$READGRUB
    LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
    if [[ "$LoadNum" -eq '1' ]]; then
      cat $READGRUB |sed '/^$/d' >$remasteringdir/grub/grub.new;
    elif [[ "$LoadNum" -gt '1' ]]; then
      CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
      CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
      CFG1="";
      for tmpCFG in `awk '/}/{print NR}' $READGRUB`
        do
          [ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
        done
      [[ -z "$CFG1" ]] && {
        echo "Error! read $GRUBFILE. ";
        exit 1;
      }

      sed -n "$CFG0,$CFG1"p $READGRUB >$remasteringdir/grub/grub.new;
      [[ -f $remasteringdir/grub/grub.new ]] && [[ "$(grep -c '{' $remasteringdir/grub/grub.new)" -eq "$(grep -c '}' $remasteringdir/grub/grub.new)" ]] || {
        echo -ne "\033[31m Error! \033[0m Not configure $GRUBFILE. \n";
        exit 1;
      }
    fi
    [ ! -f $remasteringdir/grub/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
    sed -i "/menuentry.*/c\menuentry\ \'DI PE \[debian\ buster\ amd64\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" $remasteringdir/grub/grub.new
    sed -i "/echo.*Loading/d" $remasteringdir/grub/grub.new;
    INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
  }

  [[ "$GRUBVER" == '1' ]] && {
    CFG0="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
    CFG1="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >$remasteringdir/grub/grub.new;
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$[$CFG1-1]"p $GRUBDIR/$GRUBFILE >$remasteringdir/grub/grub.new;
    [[ ! -f $remasteringdir/grub/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
    sed -i "/title.*/c\title\ \'DebianNetboot \[buster\ amd64\]\'" $remasteringdir/grub/grub.new;
    sed -i '/^#/d' $remasteringdir/grub/grub.new;
    INSERTGRUB="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
  }

  if [[ "$LoaderMode" == "0" ]]; then
    [[ -n "$(grep 'linux.*/\|kernel.*/' $remasteringdir/grub/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

    LinuxKernel="$(grep 'linux.*/\|kernel.*/' $remasteringdir/grub/grub.new |awk '{print $1}' |head -n 1)";
    [[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
    LinuxIMG="$(grep 'initrd.*/' $remasteringdir/grub/grub.new |awk '{print $1}' |tail -n 1)";
    [ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" $remasteringdir/grub/grub.new && LinuxIMG='initrd';

    if [[ "$setInterfaceName" == "1" ]]; then
      Add_OPTION="net.ifnames=0 biosdevname=0";
    else
      Add_OPTION="";
    fi

    if [[ "$setIPv6" == "1" ]]; then
      Add_OPTION="$Add_OPTION ipv6.disable=1";
    fi

    if [[ "$tmpHOSTMODEL" != "hv" ]]; then
      BOOT_OPTION="auto=true $Add_OPTION hostname=debian domain= -- quiet";
    else
      BOOT_OPTION="console=ttyS0,115200n8 DEBIAN_FRONTEND=text $Add_OPTION hostname=debian domain= -- quiet";
    fi

    [[ "$Type" == 'InBoot' ]] && {
      sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz $BOOT_OPTION" $remasteringdir/grub/grub.new;
      sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrfs.img" $remasteringdir/grub/grub.new;
    }

    [[ "$Type" == 'NoBoot' ]] && {
      sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz $BOOT_OPTION" $remasteringdir/grub/grub.new;
      sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrfs.img" $remasteringdir/grub/grub.new;
    }

    sed -i '$a\\n' $remasteringdir/grub/grub.new;
  fi


}

patchgrub(){

  GRUBPATCH='0';

  if [[ "$LoaderMode" == "0" && "$tmpBUILD" != "1" && "$tmpTARGETMODE" == '0' ]]; then
    [ -f '/etc/network/interfaces' -o -d '/etc/sysconfig/network-scripts' ] || {
      echo "Error, Not found interfaces config.";
      exit 1;
    }

    sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
    sed -i ''${INSERTGRUB}'r '$remasteringdir'/grub/grub.new' $GRUBDIR/$GRUBFILE;

    sed -i 's/timeout_style=hidden/timeout_style=menu/g' $GRUBDIR/$GRUBFILE;
    sed -i 's/timeout=[0-9]*/timeout=30/g' $GRUBDIR/$GRUBFILE;

    [[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;
  fi

}

function unzipbasics(){

  mkdir -p $remasteringdir/initramfs/usr/bin $remasteringdir/initramfs/hehe0 $remasteringdir/01-core;

  #echo -en "busy unpacking the 4.19.0.14 kernel-image ..."
  kernelimage=$topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/linux-image-4.19.0-14-amd64_4.19.171-2_amd64.deb
  [[ $(ar -t ${kernelimage} | grep  -E -o data.tar.xz) == 'data.tar.xz' ]] && ar -p ${kernelimage} data.tar.xz |xzcat|tar -xf - -C $topdir/$remasteringdir/initramfs/hehe0
  
  #if [[ "$tmpTARGETMODE" == '1'  ]]; then
    depmod -b $topdir/$remasteringdir/initramfs/hehe0 4.19.0-14-amd64
  #fi
  
  cd $remasteringdir/initramfs;
  CWD="$(pwd)"
  echo "Changing current directory to $CWD,will use abs dir ..."
  #echo -en " - busy unpacking tdl.tar.gz ..."
  tar zxf $topdir/p/diweb/tdl/tdl.tar.gz -C . >>/dev/null 2>&1

  #cp -aR $topdir/p/diweb/tdl/debian-live ./lib >>/dev/null 2>&1
  #chmod +x ./lib/debian-live/*
  #cp -aR $topdir/p/diweb/tdl/updates ./lib/modules/4.19.0-14-amd64 >>/dev/null 2>&1


}

function unzipoptpkgs(){

  if [[ "$tmpTARGETMODE" == '0' || "$tmpTARGETMODE" == '1' ]]; then
    find $topdir/$downdir/debian/dists/buster/main/debian-installer -type f \( -name *.deb -o -name *.ldeb \) | \
    while read line; do 
      line2=${line##*/};
      echo -en "\033[s \033[K [ \033[32m ${line2:0:40} \033[0m ] \033[u";
      [[ $(ar -t ${line} | grep  -E -o data.tar.gz) == 'data.tar.gz' ]] && ar -p ${line} data.tar.gz |zcat|tar -xf - -C $topdir/$remasteringdir/initramfs || ar -p ${line} data.tar.xz |xzcat|tar -xf - -C $topdir/$remasteringdir/initramfs;
    done
  fi

}

preparepreseed(){


  # wget -qO- '$DDURL' |gzip -dc |dd of=$(list-devices disk |head -n1)|(pv -s \$IMGSIZE -n) 2&>1|dialog --gauge "progress" 10 70 0

  # azure hd need bs=10M or it will fail
  if [[ "$tmpHOSTMODEL" != "hv" ]]; then
    [[ "$UNZIP" == '0' ]] && PIPECMDSTR='wget -qO- '$tmpTARGETDDURL' |dd of=$(list-devices disk |head -n1)';
    [[ "$UNZIP" == '1' && "$tmpTARGET" != 'minstackos' ]] && PIPECMDSTR='wget -qO- '$tmpTARGETDDURL' |tar zOx |dd of=$(list-devices disk |head -n1)';
    [[ "$UNZIP" == '2' ]] && PIPECMDSTR='wget -qO- '$tmpTARGETDDURL' |gunzip -dc |dd of=$(list-devices disk |head -n1)';
    [[ "$tmpTARGET" == 'minstackos' ]] && PIPECMDSTR='(for i in `seq -w 0 100`;do wget -qO- --no-check-certificate '$tmpTARGETDDURL'$i; done)|tar zOx |dd of=$(list-devices disk |head -n1)';
  else
    [[ "$UNZIP" == '0' ]] && PIPECMDSTR='wget -qO- '$tmpTARGETDDURL' |dd of=$(list-devices disk |head -n1) bs=10M status=progress';
    [[ "$UNZIP" == '1' && "$tmpTARGET" != 'minstackos' ]] && PIPECMDSTR='wget -qO- '$tmpTARGETDDURL' |tar zOx |dd of=$(list-devices disk |head -n1) bs=10M status=progress';
    [[ "$UNZIP" == '2' ]] && PIPECMDSTR='wget -qO- '$tmpTARGETDDURL' |gunzip -dc |dd of=$(list-devices disk |head -n1) bs=10M status=progress';
    [[ "$tmpTARGET" == 'minstackos' ]] && PIPECMDSTR='(for i in `seq -w 0 100`;do wget -qO- --no-check-certificate '$tmpTARGETDDURL'$i; done)|tar zOx |dd of=$(list-devices disk |head -n1) bs=10M status=progress';
  fi

  cat >$topdir/$remasteringdir/initramfs/preseed.cfg<<EOF
d-i preseed/early_command string anna-install
d-i debian-installer/locale string en_US
d-i debian-installer/framebuffer boolean false
d-i console-setup/layoutcode string us
d-i keyboard-configuration/xkb-keymap string us
d-i hw-detect/load_firmware boolean true
d-i netcfg/choose_interface select $IFETH
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/dhcp_failed note
d-i netcfg/dhcp_options select Configure network manually
# d-i netcfg/get_ipaddress string $custIPADDR
d-i netcfg/get_ipaddress string $IPv4
d-i netcfg/get_netmask string $MASK
d-i netcfg/get_gateway string $GATE
d-i netcfg/get_nameservers string 8.8.8.8
d-i netcfg/no_default_route boolean true
d-i netcfg/confirm_static boolean true
d-i mirror/country string manual
#d-i mirror/http/hostname string $IPv4
d-i mirror/http/hostname string $MIRROR
d-i mirror/http/directory string /_build/debian
d-i mirror/http/proxy string
d-i apt-setup/services-select multiselect
d-i debian-installer/allow_unauthenticated boolean true
d-i passwd/root-login boolean ture
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password $myPASSWORD
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false
d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true
# kill -9 (ps |grep debian-util-shell | awk '{print 1}')
# debconf-set partman-auto/disk "\$(list-devices disk |head -n1)"
d-i partman/early_command string $PIPECMDSTR; \
sbin/reboot
EOF

}

patchpreseed(){

  # buildmode, set auto net
  [[ "$setNet" == '0' || "$LoaderMode" != "0" || "$tmpTARGETMODE" == '1' ]] && echo -en "\n - set net to auto dhcp mode in preseed.cfg ...... " && AutoNet='1'

  [[ "$AutoNet" == '1' ]] && {
    sed -i '/netcfg\/disable_autoconfig/d' $topdir/$remasteringdir/initramfs/preseed.cfg
    sed -i '/netcfg\/dhcp_options/d' $topdir/$remasteringdir/initramfs/preseed.cfg
    sed -i '/netcfg\/get_.*/d' $topdir/$remasteringdir/initramfs/preseed.cfg
    sed -i '/netcfg\/confirm_static/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  }

  #[[ "$GRUBPATCH" == '1' ]] && {
  #  sed -i 's/^d-i\ grub-installer\/bootdev\ string\ default//g' $topdir/$remasteringdir/initramfs/preseed.cfg
  #}
  #[[ "$GRUBPATCH" == '0' ]] && {
  #  sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' $topdir/$remasteringdir/initramfs/preseed.cfg
  #}

  sed -i '/user-setup\/allow-password-weak/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  sed -i '/user-setup\/encrypt-home/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  #sed -i '/pkgsel\/update-policy/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  #sed -i 's/umount\ \/media.*true\;\ //g' $topdir/$remasteringdir/initramfs/preseed.cfg

}

patchdi(){

  mv $topdir/$remasteringdir/initramfs/usr/bin/wget $topdir/$remasteringdir/initramfs/usr/bin/wget2
  cat >$topdir/$remasteringdir/initramfs/usr/bin/wget<<EOF
#!/bin/sh
#rdlkf() { [ -L "\$1" ] && (local lk="\$(readlink "\$1")"; local d="\$(dirname "$1")"; cd "\$d"; local l="\$(rdlkf "\$lk")"; ([[ "\$l" = /* ]] && echo "\$l" || echo "\$d/\$l")) || echo "\$1"; }
#DIR="\$(dirname "\$(rdlkf "\$0")")"
wget2 --no-check-certificate "\$@"
EOF
  chmod +x $topdir/$remasteringdir/initramfs/usr/bin/wget
    
  oldfix='wget404[[:space:]]$options[[:space:]]-O[[:space:]]"$file"[[:space:]]"$url"[[:space:]]||[[:space:]]RETVAL=$?'
  newfix='[[ ${url##*\/} == "scsi-modules-4.19.0-14-amd64-di_4.19.171-2_amd64.udeb" ]] \&\& { (for ii in 000 001 002;do wget -qO- --no-check-certificate "$url"$ii; done) > "$file" || RETVAL=$?; } || { wget404 $options -O "$file" "$url" || RETVAL=$?; }'
  oldfix2='wget404[[:space:]]-c[[:space:]]$options[[:space:]]"$url"[[:space:]]-O[[:space:]]"$file"[[:space:]]||[[:space:]]RETVAL=$?'
  newfix2='[[ ${url##*\/} == "scsi-modules-4.19.0-14-amd64-di_4.19.171-2_amd64.udeb" ]] \&\& { (for ii in 000 001 002;do wget -qO- --no-check-certificate "$url"$ii; done) > "$file" || RETVAL=$?; } || { wget404 -c $options "$url" -O "$file" || RETVAL=$?; }'
  sed -i "s/$oldfix/$newfix/g" $topdir/$remasteringdir/initramfs/usr/lib/fetch-url/http
  sed -i "s/$oldfix2/$newfix2/g" $topdir/$remasteringdir/initramfs/usr/lib/fetch-url/http

}

copy_including_deps()
{

  # we use below tgt checking,leaving src checking be done manually
  # otherwise we need level cd $srcinitramfs upper here before [ ! -e "$SRCINITRAMFS"/"$1" -o -e "$INITRAMFS"/"$1" ] affects and allow xx.* srcs
  if [ -e "$INITRAMFS"/"$1" ]; then
    return
  fi

  cd "$SRCINITRAMFS"; cp -R --parents "$1" "$INITRAMFS"; 
  # cd back
  cd "$INITRAMFS";

  if [ -L "$SRCINITRAMFS"/"$1" ]; then
    DIR="$(dirname "$SRCINITRAMFS"/"$1")"
    LNK="$(readlink "$SRCINITRAMFS"/"$1")"
    copy_including_deps "$(cd "$DIR"; realpath -s "$LNK")"
  fi

  #ldd "$SRCINITRAMFS"/"$1" 2>/dev/null | sed -r "s/.*=>|[(].*//g" | sed -r "s/^\\s+|\\s+\$//" \
  #| while read LIB; do
  #  copy_including_deps "$LIB"
  #  done

  for MOD in $(find "$SRCINITRAMFS"/"$1" -type f | grep .ko); do
    for DEP in $(cat $SRCINITRAMFS/$LMK/modules.dep | fgrep /$(basename $MOD): | tr ' ' '\n'|sed -e '1d'); do
      copy_including_deps "$LMK/$DEP"
    done
  done

  shift
  if [ "$SRCINITRAMFS"/"$1" != "" ]; then
    copy_including_deps "$@"
  fi
}

update_kernelmodule()
{

  SRCINITRAMFS=$topdir/$remasteringdir/initramfs/hehe0
  INITRAMFS=$topdir/$remasteringdir/initramfs

  #copy_including_deps /usr/bin/strace
  #copy_including_deps /usr/bin/lsof

  # kvm
  copy_including_deps $LMK/kernel/virt/lib/irqbypass.ko
  copy_including_deps $LMK/kernel/arch/x86/kvm/kvm*.*
  sed -i '/modprobe[[:space:]]fuse[[:space:]]2>\/dev\/null/a    modprobe kvm 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  # fs 
  #copy_including_deps $LMK/kernel/fs/ext2
  #copy_including_deps $LMK/kernel/fs/ext3
  copy_including_deps $LMK/kernel/fs/ext4
  copy_including_deps $LMK/kernel/fs/fat
  copy_including_deps $LMK/kernel/fs/nls

  sed -i '/modprobe[[:space:]]kvm[[:space:]]2>\/dev\/null/a    modprobe nls_ascii 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  copy_including_deps $LMK/kernel/fs/fuse
  copy_including_deps $LMK/kernel/fs/isofs
  #copy_including_deps $LMK/kernel/fs/ntfs
  copy_including_deps $LMK/kernel/fs/reiserfs

  # why still need this 2?
  copy_including_deps $LMK/kernel/lib/zstd/zstd_decompress.ko
  copy_including_deps $LMK/kernel/lib/xxhash.ko
  copy_including_deps $LMK/kernel/fs/squashfs

  # crc32c is needed for ext4, but I don't know which one, add them all, they are small
  find $LMK/kernel/ | grep crc32c | while read LINE; do
    copy_including_deps $LINE
  done

  #copy_including_deps $LMK/kernel/drivers/staging/zsmalloc # needed by zram
  copy_including_deps $LMK/kernel/drivers/block/zram
  copy_including_deps $LMK/kernel/drivers/block/loop.*

  copy_including_deps $LMK/kernel/drivers/virtio
  copy_including_deps $LMK/kernel/drivers/block/virtio*
      
  mkdir -p $INITRAMFS/etc/modules-load.d/
  echo virtio_input >> $INITRAMFS/etc/modules-load.d/virtioinput.conf

  # video
  copy_including_deps $LMK/kernel/drivers/gpu/drm/cirrus
  copy_including_deps $LMK/kernel/drivers/gpu/drm/virtio
  copy_including_deps $LMK/kernel/drivers/acpi/video.ko

  [[ "$tmpHOST" == '1' && "$tmpHOSTMODEL" == 'mbp' ]] && {
    copy_including_deps $LMK/kernel/drivers/video/backlight/apple_bl.ko
    copy_including_deps $LMK/kernel/drivers/gpu/drm/i915
  }


  # usb drivers
  copy_including_deps $LMK/kernel/drivers/usb/storage/usb-storage.*
  copy_including_deps $LMK/kernel/drivers/usb/host
  copy_including_deps $LMK/kernel/drivers/usb/common
  copy_including_deps $LMK/kernel/drivers/usb/core
  copy_including_deps $LMK/kernel/drivers/hid/usbhid
  copy_including_deps $LMK/kernel/drivers/hid/hid.*
  copy_including_deps $LMK/kernel/drivers/hid/uhid.*
  copy_including_deps $LMK/kernel/drivers/hid/hid-generic.*

  [[ "$tmpHOST" == '1' && "$tmpHOSTMODEL" == 'mbp' ]] && {
    copy_including_deps $LMK/kernel/drivers/hid/hid-apple.ko
  }

  # disk and cdrom drivers
  copy_including_deps $LMK/kernel/drivers/cdrom
  copy_including_deps $LMK/kernel/drivers/scsi/sr_mod.*
  copy_including_deps $LMK/kernel/drivers/scsi/sd_mod.*
  copy_including_deps $LMK/kernel/drivers/scsi/scsi_mod.*
  copy_including_deps $LMK/kernel/drivers/scsi/virtio_scsi.ko
  copy_including_deps $LMK/kernel/drivers/scsi/sg.*
  copy_including_deps $LMK/kernel/drivers/ata
  copy_including_deps $LMK/kernel/drivers/nvme
  copy_including_deps $LMK/kernel/drivers/mmc


  # inputs
  copy_including_deps $LMK/kernel/drivers/input/evdev.ko
  copy_including_deps $LMK/kernel/drivers/input/mouse/psmouse.ko
  copy_including_deps $LMK/kernel/drivers/input/mouse/sermouse.ko

  [[ "$tmpHOST" == '1' && "$tmpHOSTMODEL" == 'mbp' ]] && {
    copy_including_deps $LMK/kernel/drivers/input/mouse/bcm5974.ko
    copy_including_deps $LMK/kernel/drivers/input/mouse/appletouch.ko
    copy_including_deps $LMK/kernel/drivers/spi/spi-pxa2xx-platform.ko
    copy_including_deps $LMK/kernel/drivers/spi/spi-pxa2xx-pci.ko
    #copy_including_deps $LMK/updates/dkms/applespi.ko
  }


  # network support drivers

  copy_including_deps $LMK/kernel/drivers/net/tun.*

  sed -i '/modprobe[[:space:]]nls_ascii[[:space:]]2>\/dev\/null/a    modprobe tun 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  copy_including_deps $LMK/kernel/drivers/net/tap.*
  copy_including_deps $LMK/kernel/drivers/vhost/vhost.ko
  copy_including_deps $LMK/kernel/drivers/vhost/vhost_net.ko
  copy_including_deps $LMK/kernel/net/llc/llc.ko
  copy_including_deps $LMK/kernel/net/802/stp.ko
  copy_including_deps $LMK/kernel/net/netfilter/x_tables.ko
  copy_including_deps $LMK/kernel/net/ipv4/netfilter/ip_tables.ko
  copy_including_deps $LMK/kernel/net/bridge/bridge.ko
  copy_including_deps $LMK/kernel/drivers/net/veth.ko

  sed -i '/modprobe[[:space:]]tun[[:space:]]2>\/dev\/null/a    modprobe bridge 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib
  sed -i '/modprobe[[:space:]]bridge[[:space:]]2>\/dev\/null/a    modprobe veth 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  copy_including_deps $LMK/kernel/net/ipv4/netfilter/iptable_nat.ko
  copy_including_deps $LMK/kernel/net/ipv4/netfilter/ipt_MASQUERADE.ko
  sed -i '/modprobe[[:space:]]veth[[:space:]]2>\/dev\/null/a    modprobe iptable_nat 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib
  sed -i '/modprobe[[:space:]]iptable_nat[[:space:]]2>\/dev\/null/a    modprobe ipt_MASQUERADE 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  copy_including_deps $LMK/kernel/net/ipv4/netfilter/iptable_raw.ko
  copy_including_deps $LMK/kernel/net/netfilter/xt_CT.ko
  sed -i '/modprobe[[:space:]]ipt_MASQUERADE[[:space:]]2>\/dev\/null/a    modprobe iptable_raw 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib
  sed -i '/modprobe[[:space:]]iptable_raw[[:space:]]2>\/dev\/null/a    modprobe xt_CT 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  copy_including_deps $LMK/kernel/net/netfilter/xt_nat.ko
  copy_including_deps $LMK/kernel/net/netfilter/xt_tcpudp.ko
  sed -i '/modprobe[[:space:]]xt_CT[[:space:]]2>\/dev\/null/a    modprobe xt_nat 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib
  sed -i '/modprobe[[:space:]]xt_nat[[:space:]]2>\/dev\/null/a    modprobe xt_tcpudp 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  copy_including_deps $LMK/kernel/net/ipv4/netfilter/iptable_filter.ko
  sed -i '/modprobe[[:space:]]xt_tcpudp[[:space:]]2>\/dev\/null/a    modprobe iptable_filter 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib

  #pve needs this for pipefs.mount.service
  copy_including_deps $LMK/kernel/net/sunrpc/sunrpc.ko
  #pve watchdog-mux service
  copy_including_deps $LMK/kernel/drivers/watchdog/softdog.ko
  sed -i '/modprobe[[:space:]]iptable_filter[[:space:]]2>\/dev\/null/a    modprobe sunrpc 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib
  sed -i '/modprobe[[:space:]]sunrpc[[:space:]]2>\/dev\/null/a    modprobe softdog 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib


  #for later adding a swap
  sed -i 's/init_zram/# init_zram/g' $INITRAMFS/lib/debian-live/init
      

  [[ "$tmpHOST" == '1' && "$tmpHOSTMODEL" == 'mbp' ]] && {
    copy_including_deps $LMK/kernel/net/rfkill/rfkill.ko
    copy_including_deps $LMK/kernel/net/wireless/cfg80211.ko
    copy_including_deps $LMK/kernel/drivers/net/wireless/broadcom/brcm80211/brcmutil/brcmutil.ko
    copy_including_deps $LMK/kernel/drivers/net/wireless/broadcom/brcm80211/brcmfmac/brcmfmac.ko
  }

  copy_including_deps $LMK/kernel/drivers/net/virtio_net.ko

  # miscs

  [[ "$tmpHOST" == '1' && "$tmpHOSTMODEL" == 'mbp' ]] && {
    copy_including_deps $LMK/kernel/drivers/input/input-polldev.ko
    copy_including_deps $LMK/kernel/drivers/hwmon/applesmc.ko
    copy_including_deps $LMK/kernel/drivers/acpi/button.ko
    copy_including_deps $LMK/kernel/drivers/acpi/ac.ko
    copy_including_deps $LMK/kernel/drivers/acpi/sbshc.ko
    copy_including_deps $LMK/kernel/drivers/acpi/sbs.ko
  }

  # hv guest support

  #copy_including_deps $LMK/kernel/drivers/pci/host/pci-hyperv.ko
  copy_including_deps $LMK/kernel/drivers/video/fbdev/hyperv_fb.ko
  copy_including_deps $LMK/kernel/drivers/net/hyperv/hv_netvsc.ko
  copy_including_deps $LMK/kernel/drivers/input/serio/hyperv-keyboard.ko
  copy_including_deps $LMK/kernel/drivers/scsi/hv_storvsc.ko
  copy_including_deps $LMK/kernel/drivers/hid/hid-hyperv.ko
  copy_including_deps $LMK/kernel/drivers/hv/hv_utils.ko
  copy_including_deps $LMK/kernel/drivers/hv/hv_balloon.ko


  # copy all custom-built modules
  copy_including_deps $LMK/updates
  sed -i '/modprobe[[:space:]]softdog[[:space:]]2>\/dev\/null/a    modprobe exfat 2>/dev/null' $INITRAMFS/lib/debian-live/livekitlib


  copy_including_deps $LMK/modules.*
  find $INITRAMFS -name "*.ko.gz" -exec gunzip {} \;
  # trim modules.order file. Perhaps we could remove it entirely
  MODULEORDER="$(cd "$INITRAMFS/$LMK/"; find -name "*.ko" | sed -r "s:^./::g" | tr "\n" "|" | sed -r "s:[.]:.:g")"
  cat $INITRAMFS/$LMK/modules.order | sed -r "s/.ko.gz\$/.ko/" | grep -E "$MODULEORDER"/foo/bar > $INITRAMFS/$LMK/_
  mv $INITRAMFS/$LMK/_ $INITRAMFS/$LMK/modules.order


  depmod -b $INITRAMFS $KERNEL


  #cleanup
  #rm -rf $INITRAMFS/tmp/*
}

patchinitrd(){

  chrootdir=$topdir/$remasteringdir/initramfs/initrd

  #chroot $chrootdir useradd -m -p "$(openssl passwd -1 "$custUSRANDPASS")" $custUSRANDPASS

  for i in dbus_1.12.20-0-deb10u1_amd64.deb libdbus-1-3_1.12.20-0-deb10u1_amd64.deb libexpat1_2.2.6-2-deb10u1_amd64.deb coreutils_8.30-3_amd64.deb cloud-guest-utils_0.29-1_all.deb; do 

    [[ "$tmpTARGETMODE" == '0' ]] && [[ "$i" != 'coreutils_8.30-3_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && wget -qO- --no-check-certificate $MIRROR/_build/debian/dists/buster/main/binary-amd64/deb/$i > $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "download failed" && exit 1
    [[ "$tmpTARGETMODE" == '0' ]] && [[ "$i" == 'coreutils_8.30-3_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && (for ii in 000 001 002;do wget -qO- --no-check-certificate $MIRROR/_build/debian/dists/buster/main/binary-amd64/deb/$i$ii; done) > $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "download failed" && exit 1

    [[ "$tmpTARGETMODE" == '1' ]] && [[ "$i" != 'coreutils_8.30-3_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && cp $topdir/_build/debian/dists/buster/main/binary-amd64/deb/$i $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "copy failed" && exit 1
    [[ "$tmpTARGETMODE" == '1' ]] && [[ "$i" == 'coreutils_8.30-3_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && cat $topdir/_build/debian/dists/buster/main/binary-amd64/deb/$i* > $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "cat failed" && exit 1

  done


  mkdir -p $chrootdir/tools
  cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/cloud-guest-utils_0.29-1_all.deb $chrootdir/tools/cloud-guest-utils_0.29-1_all.deb
  [[ $(ar -t $chrootdir/tools/cloud-guest-utils_0.29-1_all.deb | grep  -E -o data.tar.gz) == 'data.tar.gz' ]] && ar -p $chrootdir/tools/cloud-guest-utils_0.29-1_all.deb data.tar.gz |zcat|tar -xf - -C $chrootdir/usr/bin ./usr/bin/growpart --strip-components=3 || ar -p $chrootdir/tools/cloud-guest-utils_0.29-1_all.deb data.tar.xz |xzcat|tar -xf - -C $chrootdir/usr/bin ./usr/bin/growpart --strip-components=3
  chmod +x $chrootdir/usr/bin/growpart
  rm -rf $chrootdir/../bin/dd
  cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/coreutils_8.30-3_amd64.deb $chrootdir/tools/coreutils_8.30-3_amd64.deb
  [[ $(ar -t $chrootdir/tools/coreutils_8.30-3_amd64.deb | grep  -E -o data.tar.gz) == 'data.tar.gz' ]] && ar -p $chrootdir/tools/coreutils_8.30-3_amd64.deb data.tar.gz |zcat|tar -xf - -C $chrootdir/../bin ./bin/dd --strip-components=2 || ar -p $chrootdir/tools/coreutils_8.30-3_amd64.deb data.tar.xz |xzcat|tar -xf - -C $chrootdir/../bin ./bin/dd --strip-components=2
  chmod +x $chrootdir/../bin/dd
  chroot $chrootdir sh -c "rm -rf /tools/coreutils_8.30-3_amd64.deb /tools/cloud-guest-utils_0.29-1_all.deb; dpkg -iR /tools >/dev/null 2>&1; rm -rf /tools"


  chroot $chrootdir sh -c "echo '[Unit]\nDescription=grow-part\n\n[Service]\nType=oneshot\nUser=root\nExecStart=/bin/bash -c \"[[ -b /dev/vda ]] && growpart /dev/vda 2 && resize2fs /dev/vda2;[[ -b /dev/sda ]] && growpart /dev/sda 2 && resize2fs /dev/sda2\"\n\n[Install]\nWantedBy=multi-user.target' > /usr/lib/systemd/system/growpart.service; \
  systemctl enable growpart.service >/dev/null 2>&1"

  chroot $chrootdir sh -c "echo 'root:tdl' | chpasswd root; echo 'tdl ALL=(ALL) ALL' >> /etc/sudoers"

  # for azure
  [[ "$tmpHOSTMODEL" == 'hv' ]] && chroot $chrootdir sh -c "systemctl enable serial-getty@ttyS0.service >/dev/null 2>&1"

  #chroot $chrootdir sh -c "groupadd -g 18 messagebus; \
  #yes|apt-get install --no-install-recommends dbus sudo -y -qq >/dev/null 2>&1"
  #sudo sh -c "echo 'tdl ALL=(ALL) ALL' >> $chrootdir/etc/sudoers"


  [[ -z "$tmpTGTNICNAME" ]] && echo "nicname not given,will exit" && exit
  mkdir -p $chrootdir/../etc/systemd/network
  ln -s /dev/null $chrootdir/../etc/systemd/network/99-default.link
  ln -s /dev/null $chrootdir/etc/systemd/network/99-default.link
  [[ "$tmpHOST" == '1' && "$tmpHOSTMODEL" == 'mbp' ]] && sed -i "s/eth0/${tmpWIFICONNECT##*,}/g" $chrootdir/etc/network/interfaces || sed -i "s/eth0/$tmpTGTNICNAME/g" $chrootdir/etc/network/interfaces

  [[ -z "$tmpTGTNICIP" ]] && echo "nicip not given,will exit" && exit
  sed -i "s/127.0.1.1/$tmpTGTNICIP/g" $chrootdir/etc/hosts

  # fix,case initspawn dont perserve blow,this fix also make xorg.service work well
  [[ "$tmpBUILDPUTPVEINIFS" == '0' ]] && \
  sudo sh -c "echo 'postfix:x:105:110::/var/spool/postfix:/usr/sbin/nologin\n \
  _rpc:x:105:65534::/run/rpcbind:/usr/sbin/nologin\n \
  statd:x:107:65534::/var/lib/nfs:/usr/sbin/nologin\n \
  sshd:x:108:65534::/run/sshd:/usr/sbin/nologin\n \
  gluster:x:109:114::/var/lib/glusterd:/usr/sbin/nologin\n \
  ceph:x:64045:64045:Ceph storage service:/var/lib/ceph:/usr/sbin/nologin' >> $chrootdir/etc/passwd;
      
  echo 'messagebus:x:18:\nsystemd-coredump:x:999:ssl-cert:x:109:\n \
  postfix:x:110:\n \
  postdrop:x:111:\n \
  rdma:x:112:\n \
  ssh:x:113:\n \
  gluster:x:114:\n \
  ceph:x:64045:' >> $chrootdir/etc/group"


  [[ "$tmpHOST" == '1' && "$tmpHOSTMODEL" == 'mbp' ]] && {


    for i in firmware-brcm80211_20190114-2_all.deb libnl-3-200_3.4.0-1_amd64.deb libnl-genl-3-200_3.4.0-1_amd64.deb iw_5.0.1-1_amd64.deb libpcsclite1_1.8.24-1_amd64.deb libnl-route-3-200_3.4.0-1_amd64.deb readline-common_7.0-5_all.deb libreadline7_7.0-5_amd64.deb wpasupplicant_2.7-git20190128-0c1e29f-6-deb10u2_amd64.deb lsb-base_10.2019051400_all.deb dhcpcd5_7.1.0-2_amd64.deb psmisc_23.2-1_amd64.deb laptop-mode-tools_1.72-3_all.deb; do 

      [[ "$tmpTARGETMODE" == '0' ]] && [[ "$i" != 'firmware-brcm80211_20190114-2_all.deb' || "$i" != 'wpasupplicant_2.7-git20190128-0c1e29f-6-deb10u2_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && wget -qO- --no-check-certificate $MIRROR/_build/debian/dists/buster/main/binary-amd64/deb/$i > $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "download failed" && exit 1
      [[ "$tmpTARGETMODE" == '0' ]] && [[ "$i" == 'firmware-brcm80211_20190114-2_all.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && (for ii in 000 001 002 003 004;do wget -qO- --no-check-certificate $MIRROR/_build/debian/dists/buster/main/binary-amd64/deb/$i$ii; done) > $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "download failed" && exit 1
      [[ "$tmpTARGETMODE" == '0' ]] && [[ "$i" == 'wpasupplicant_2.7-git20190128-0c1e29f-6-deb10u2_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && (for ii in 000 001;do wget -qO- --no-check-certificate $MIRROR/_build/debian/dists/buster/main/binary-amd64/deb/$i$ii; done) > $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "download failed" && exit 1

      [[ "$tmpTARGETMODE" == '1' ]] && [[ "$i" != 'firmware-brcm80211_20190114-2_all.deb' || "$i" != 'wpasupplicant_2.7-git20190128-0c1e29f-6-deb10u2_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && cp $topdir/_build/debian/dists/buster/main/binary-amd64/deb/$i $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "copy failed" && exit 1
      [[ "$tmpTARGETMODE" == '1' ]] && [[ "$i" == 'firmware-brcm80211_20190114-2_all.deb' || "$i" == 'wpasupplicant_2.7-git20190128-0c1e29f-6-deb10u2_amd64.deb' ]] && [[ ! -f $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i ]] && cat $topdir/_build/debian/dists/buster/main/binary-amd64/deb/$i* > $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/$i && [[ $? -ne '0' ]] && echo "cat failed" && exit 1

    done

    mkdir -p $chrootdir/firmware
    cp $topdir/$downdir/debian/dists/buster/main-non-free/binary-amd64/deb/firmware-brcm80211_20190114-2_all.deb $chrootdir/firmware/firmware-brcm80211_20190114-2_all.deb
    chroot $chrootdir sh -c "dpkg -iR /firmware >/dev/null 2>&1; rm -rf /firmware"
    # mv it to the right place,this is important or brcm80211 wont load
    mv $chrootdir/lib/firmware $chrootdir/../lib

    mkdir -p $chrootdir/tools
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/libnl-3-200_3.4.0-1_amd64.deb $chrootdir/tools/libnl-3-200_3.4.0-1_amd64.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/libnl-genl-3-200_3.4.0-1_amd64.deb $chrootdir/tools/libnl-genl-3-200_3.4.0-1_amd64.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/iw_5.0.1-1_amd64.deb $chrootdir/tools/iw_5.0.1-1_amd64.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/libpcsclite1_1.8.24-1_amd64.deb $chrootdir/tools/libpcsclite1_1.8.24-1_amd64.deb

    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/libdbus-1-3_1.12.20-0-deb10u1_amd64.deb $chrootdir/tools/libdbus-1-3_1.12.20-0-deb10u1_amd64.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/libnl-route-3-200_3.4.0-1_amd64.deb $chrootdir/tools/libnl-route-3-200_3.4.0-1_amd64.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/readline-common_7.0-5_all.deb $chrootdir/tools/readline-common_7.0-5_all.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/libreadline7_7.0-5_amd64.deb $chrootdir/tools/libreadline7_7.0-5_amd64.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/wpasupplicant_2.7-git20190128-0c1e29f-6-deb10u2_amd64.deb $chrootdir/tools/wpasupplicant_2.7-git20190128-0c1e29f-6-deb10u2_amd64.deb

    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/lsb-base_10.2019051400_all.deb $chrootdir/tools/lsb-base_10.2019051400_all.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/dhcpcd5_7.1.0-2_amd64.deb $chrootdir/tools/dhcpcd5_7.1.0-2_amd64.deb

    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/psmisc_23.2-1_amd64.deb $chrootdir/tools/psmisc_23.2-1_amd64.deb
    cp $topdir/$downdir/debian/dists/buster/main/binary-amd64/deb/laptop-mode-tools_1.72-3_all.deb $chrootdir/tools/laptop-mode-tools_1.72-3_all.deb
    chroot $chrootdir sh -c "dpkg -iR /tools >/dev/null 2>&1; rm -rf /tools || echo sry,errors happen,errors like umet deps will prevent apt-get install working from now on,please fix asap && exit 1"

    chroot $chrootdir sh -c "tmpWIFICONNECTPARTI=\${tmpWIFICONNECT%,*} && \
    \[ -z \$tmpWIFICONNECT \] && echo \"wifi connect settings not given,wpa_supplicant wont work\" && :; \
    systemctl disable wpa_supplicant.service >/dev/null 2>&1; \
    echo \"ctrl_interface=/var/run/wpa_supplicant\nupdate_config=1\n\" > /etc/wpa_supplicant/wpa_supplicant-nl80211-\${tmpWIFICONNECT##*,}.conf; \
    wpa_passphrase \${tmpWIFICONNECTPARTI%,*} \${tmpWIFICONNECTPARTI#*,} >> /etc/wpa_supplicant/wpa_supplicant-nl80211-\${tmpWIFICONNECT##*,}.conf; \
    systemctl enable wpa_supplicant-nl80211@\${tmpWIFICONNECT##*,}.service >/dev/null 2>&1"

    chroot $chrootdir sh -c "mkdir -p /var/lib/systemd/backlight;echo 100 > /var/lib/systemd/backlight/pci-0000:00:02.0:backlight:intel_backlight"

    chroot $chrootdir sh -c "sed -i 's/ENABLE_LAPTOP_MODE_ON_AC=0/ENABLE_LAPTOP_MODE_ON_AC=1/g' /etc/laptop-mode/laptop-mode.conf; ## \
    sed -i 's/\[value\]/100/g' /etc/laptop-mode/conf.d/lcd-brightness.conf; \
    sed -i 's#/proc/acpi/video/VID/LCD/brightness#/sys/class/backlight/intel_backlight/brightness#g' /etc/laptop-mode/conf.d/lcd-brightness.conf"
  }


}

# =================================================================
# Below are main routes
# =================================================================

echo -e "\n \033[36m # Checking Prerequisites: \033[0m"

echo -en "\n - Checking deps ......:"
if [[ "$tmpTARGET" == 'debianbase' ]] && [[ "$tmpTARGETMODE" == '1' ]]; then
  CheckDependence wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat,md5sum,sha1sum,sha256sum;
elif [[ "$tmpTARGET" == 'minstackos' ]] && [[ "$tmpTARGETMODE" == '1' ]] && [[ "$tmpBUILD" == '1' ]] ; then
  CheckDependence wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat,diskutil;
else
  CheckDependence wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat;
fi

echo -en "\n - Selecting The Fastest DEB Mirror ......:" 

MIRROR=$(SelectDEBMirror $custDEBMIRROR0 $custDEBMIRROR1 $custDEBMIRROR2)
[ -n "$MIRROR" ] && echo -en "[ \033[32m ${MIRROR} \033[0m ]" || exit 1

UNZIP=''
IMGSIZE=''

echo -en "\n - Checking TARGET ......."
[[ "$tmpTARGETMODE" == '0' && "$tmpTARGET" != 'minstackos' ]] && CheckTarget $tmpTARGETDDURL || echo -en "[ \033[32m genmode,skipping!! \033[0m ]"

sleep 2s

echo -e "\n\n \033[36m # Parepare Res: \033[0m"

#[[ -d $downdir ]] && rm -rf $downdir;
mkdir -p $downdir $topdir/p/diweb/tdl $downdir/debian/dists/buster/main/binary-amd64/deb

sleep 2s && echo -en "\n - Get linux-image and initrfs-tarball ......"
[[ "$tmpTARGETMODE" == '0' ]] && getbasics down && echo -en "[ \033[32m inst mode,down!! \033[0m ]" || getbasics cat && echo -en "[ \033[32m gen mode,cat!! \033[0m ]"
echo -en "\n - Get full udebs pkg files ..... "
[[ "$tmpBUILD" != '1' && "$tmpTARGET" == 'debianbase' ]] && getfullpkgs || echo -en "[ \033[32m not debianbase,skipping!! \033[0m ]"
echo -en "\n - Get optional/necessary deb pkg files ...... "
[[ "$tmpBUILD" != '1' && "$tmpTARGET" != 'debianbase' && "$tmpTARGETMODE" == '0' ]] && getoptpkgs down libc,common,wgetssl && echo -en "[ \033[32m inst mode,down!! \033[0m ]" || getoptpkgs cat libc,common,wgetssl && echo -en "[ \033[32m gen mode,cat!! \033[0m ]"
sleep 2s && echo -en "\n - save and set the netcfg ......"

setNet='0'
interface=''

[[ "$tmpBUILD" != '1' && "$tmpTARGET" != 'debianbase' ]] && parsenetcfg || echo -en "[ \033[32m done!! \033[0m ]"

echo -e "\n\n \033[36m # Remastering all up... \033[0m"

[[ -d $remasteringdir ]] && rm -rf $remasteringdir;

mkdir -p $targetdir

sleep 2s && echo -en "\n - processing grub ......"

LoaderMode='0'
setInterfaceName='0'
setIPv6='0'

[[ "$tmpBUILD" != '1' && "$tmpTARGETMODE" == '0' && "$tmpTARGET" != 'debianbase' ]] && parsegrub && sleep 2s && echo -en "[ \033[32m $remasteringdir/grub/grub.new \033[0m ]"

[[ "$tmpTARGETINSTANTWITHOUTVNC" == '0' ]] && {

  patchgrub

  [[ "$tmpTARGETMODE" == '0' || "$tmpTARGETMODE" == '1' && "$tmpBUILDRESUEPBIFS" == '0' ]] && {
    sleep 2s && echo -en "\n - unpacking linux-image and initrfs tar-ball ......"
    unzipbasics
    sleep 2s && echo -en "\n - unzipping option pkgs ...."
    unzipoptpkgs

    if [[ "$tmpTARGETMODE" == '0' || "$tmpTARGETMODE" == '1' ]]; then
      sleep 2s && echo -en "\n - inst or build mod,make a separated preseed file for cdi images and patchs it......."
      preparepreseed
      patchpreseed
      sleep 2s && echo -en "\n - make a safe wget wrapper to inc --no-check-certificate and patch usr/lib/fetch-url for segments downloading ..."
      patchdi
    fi

    if [[ "$tmpTARGETMODE" == '0' || "$tmpTARGETMODE" == '1' ]]; then
      sleep 2s &&   echo -en "\n - make a initramfs/lib/modules* updates ......"

      cd $topdir/$remasteringdir/initramfs
      CWD="$(pwd)"
      echo "Changing current directory to $CWD"

    
      KERNEL=4.19.0-14-amd64
      LMK="lib/modules/$KERNEL"

      #add basic live here?no,should only modules
      #always add the cloudhost ones and kvm ones
      #do actual remastering
      update_kernelmodule

      sleep 2s &&   echo -en "\n - patching initramfs/initrd (as an option,you can also do chrootinstallpve aside here) \n"
      patchinitrd
      ## do chrootinstallpve remastering here?
      #chrootinstallpve
    fi

  }

  echo -e "\n\n \033[36m # finishing... \033[0m"

  echo -en "\n - copying vmlinuz to the target/mnt ......"
  [[ -d /boot ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" == "0" ]] && cp -f $topdir/$remasteringdir/initramfs/hehe0/boot/vmlinuz-4.19.0-14-amd64 /boot/vmlinuz

  # now we can safetly del the hehe0,no use anymore (both in genmod+instmod or instonlymode)
  [[ "$tmpBUILDREUSEPBIFS" == '0' ]] && rm -rf $topdir/$remasteringdir/initramfs/hehe0


  [[ "$tmpTARGETMODE" == '0' ]] && sleep 2s && echo -en "\n - packaging initrfs to the target/mnt....." && [[ "$tmpBUILD" != '1' ]] && find . | cpio -H newc --create --quiet | gzip -9 > /boot/initrfs.img #|| find . | cpio -H rpax --create --quiet | gzip -9 > /Volumes/TMPVOL/initrfs.img

  [[ "$tmpBUILDCI" == '1' ]] && echo -en "\n - full ci args given,will do ci addons ....." && dociaddons

  #rm -rf $remasteringdir/initramfs;

}

[[ "$tmpTARGETINSTANTWITHOUTVNC" == '1' ]] && {
  sed -i '$i\\n' $GRUBDIR/$GRUBFILE
  sed -i '$r $remasteringdir/grub/grub.new' $GRUBDIR/$GRUBFILE
  echo -e "\n \033[33m \033[04m It will reboot! \nPlease connect VNC! \nSelect \033[0m \033[32m DI PE [debian buster amd64] \033[33m \033[4m to install system. \033[04m\n\n \033[31m \033[04m There is some information for you.\nDO NOT CLOSE THE WINDOW! \033[0m\n"
  echo -e "\033[35m IPv4\t\tNETMASK\t\tGATEWAY \033[0m"
  echo -e "\033[36m \033[04m $IPv4 \033[0m \t \033[36m \033[04m $MASK \033[0m \t \033[36m \033[04m $GATE \033[0m \n\n"

  read -n 1 -p "Press Enter to reboot..." INP
  [[ "$INP" != '' ]] && echo -ne '\b \n\n';
}

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE


if [[ "$LoaderMode" == "0" ]]; then
  echo -en "\n - packaging finished,and all done! see if we need do ci addons, or just auto rebooting after 10s" && sleep 10s && clear && reboot >/dev/null 2>&1
else
  rm -rf "$HOME/loader"
  mkdir -p "$HOME/loader"
  cp -rf "/boot/initrfs.img" "$HOME/loader/initrfs.img"
  cp -rf "/boot/vmlinuz" "$HOME/loader/vmlinuz"
  [[ -f "/boot/initrfs.img" ]] && rm -rf "/boot/initrfs.img"
  [[ -f "/boot/vmlinuz" ]] && rm -rf "/boot/vmlinuz"
  echo && ls -AR1 "$HOME/loader"
fi

