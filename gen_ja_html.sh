cd `dirname $0`
git checkout localize_ja

CMDNAME=`basename $0`
help=""
DEBUG=false
PRINTPATHS=false
while getopts "dphH" opt; do
    case $opt in
        d ) DEBUG=true
            ;;
        p ) PRINTPATHS=true
            ;;
        h ) printf "usage: $0 [-dphH]\nshould be issued from the working directory that contains the source BPTL ODD files; use the -H switch for more detailed help info\n"
            exit 1
            ;;
        H ) printf "$help"
            exit 1
            ;;
        * ) printf "usage: $0 [-dphH]\nshould be issued from the working directory that contains the source BPTL ODD files; use the -H switch for more detailed help info\n"
            exit 1
    esac
done
shift $((OPTIND - 1))

if [ $DEBUG = true ]; then set -o xtrace; fi

PSC=${PSC:-_}                     # prefix separator string (typically '.' or '_')
TMPDIR=${TMPDIR:-/tmp}            # temporary directory
TMP=${TiLBPtemp}$$.xml            # temporary sibling file
TMPTMP=${TMPDIR}/${TMP}           # temporary file in temp dir

SOURCEDIR=BestPractices/ja
TARGETDIR=BestPractices/ja

XSLDIR=${XSLDIR:-/home/venus/tei/Stylesheets}
P5SRC=${P5SRC:-/home/venus/tei/TEI/P5/p5subset.xml}

if [ ${PRINTPATHS} = true ]; then
    echo "XSLDIR=${XSLDIR} P5SRC=${P5SRC} ${0}"
    exit 13
fi

if which xml ; then
    STARLET=`which xml`
elif which xmlstarlet ; then
    STARLET=`which xmlstarlet`
fi

echo ""; echo "--------- generate HTML from main driver ---------"
xmllint --xinclude ${SOURCEDIR}/bptl-driver.odd | ${STARLET} ed -N t=http://www.tei-c.org/ns/1.0 --delete "//t:schemaSpec" > ${TMPTMP}
${XSLDIR}/bin/teitohtml --odd --localsource=${P5SRC} ${TMPTMP}
mv ${TMPTMP}.html ${TARGETDIR}/bptl-driver.html
rm ${TMPTMP}
