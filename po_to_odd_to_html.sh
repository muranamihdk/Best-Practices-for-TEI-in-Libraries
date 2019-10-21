cd `dirname $0`
git checkout localize_ja
echo

# ------------------------------------------------------------------

if [ $(git diff origin/localize_ja --name-only | wc -l) -ne 0 ]
then
  echo
  git add .
  git commit -m "update Japanese translation po files"
  echo
  echo "git push origin localize_ja"
  git push origin localize_ja
fi

# ------------------------------------------------------------------

GETTEXT="gettext"
MSGFMT="msgfmt"
MSGMERGE="msgmerge"
ITSTOOL="itstool"

PREFIX_PATH="BestPractices"
POT_DIR="_pot"
PO_DIR="_po"
MO_DIR="_mo"
SOURCE_LANG="en"
TARGET_LANG="ja"

for COMMAND in $GETTEXT $MSGFMT $MSGMERGE $ITSTOOL
do
  which "$COMMAND" >/dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    echo "$COMMAND command was not found."
    exit
  fi
done

# poファイルからmoファイルを生成（_mo 以下に）
TARGET_DIR="${PREFIX_PATH}/${MO_DIR}"
if [ ! -d "$TARGET_DIR" ]
then
  mkdir -p "$TARGET_DIR"
  echo Created: "$TARGET_DIR"
fi

for SOURCE in `find "./${PREFIX_PATH}/${PO_DIR}/${TARGET_LANG}/" -type f -name "*.po" -print`
do
  MO_FILE="$TARGET_DIR"/$(basename "$SOURCE" .po).mo
  if [ ! -f "$MO_FILE" ]
  then
    msgfmt "$SOURCE" -o "$MO_FILE"
    echo Created: "$MO_FILE"
  elif [ "$SOURCE" -nt "$MO_FILE" ]
  then
    msgfmt "$SOURCE" -o "$MO_FILE"
    echo Updated: "$MO_FILE"
  else
    echo No Updated: "$MO_FILE"
  fi
done

# moファイルからoddファイルを生成（ja 以下に）
TARGET_DIR="${PREFIX_PATH}/${TARGET_LANG}"
if [ ! -d "$TARGET_DIR" ]
then
  mkdir -p "$TARGET_DIR"
  echo Created: "$TARGET_DIR"
fi

for SOURCE in `find "./${PREFIX_PATH}/${MO_DIR}/" -type f -name "*.mo" -print`
do
  ORIGINAL_FILE="${PREFIX_PATH}"/$(basename "$SOURCE" .mo).odd
  TARGET_FILE="$TARGET_DIR"/$(basename "$SOURCE" .mo).odd
  if [ ! -f "$TARGET_FILE" ]
  then
    itstool -m "$SOURCE" "$ORIGINAL_FILE" -o "$TARGET_FILE"
    echo Created: "$TARGET_FILE"
  elif [ "$SOURCE" -nt "$TARGET_FILE" ]
  then
    itstool -m "$SOURCE" "$ORIGINAL_FILE" -o "$TARGET_FILE"
    echo Updated: "$TARGET_FILE"
  else
    echo No Updated: "$TARGET_FILE"
  fi
done

if [ $(git diff origin/localize_ja --name-only | wc -l) -ne 0 ]
then
  echo
  git add .
  git commit -m "update Japanese translation odd files"
  echo
  echo "git push origin localize_ja"
  git push origin localize_ja
fi

# ------------------------------------------------------------------

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
#mv ${TMPTMP}.html ${TARGETDIR}/bptl-driver.html
#rm ${TMPTMP}

#mv: `/tmp/32099.xml.html' を stat できません: そのようなファイルやディレクトリはありません
#/tmp/32099.xml.html -> /tmp/32099.xml.tmpodd
#curl -s -F upload=@/tmp/32099.xml.tmpodd -o index.html https://oxgarage.tei-c.org/ege-webservice/Conversions/ODD%3Atext%3Axml/ODDC%3Atext%3Axml/oddhtml%3Aapplication%3Axhtml%2Bxml/

# OxGarage の Web API を利用して ODD ファイルから HTML ファイルを生成
curl -s -F upload=@${TMPTMP}.tmpodd -o index.html https://oxgarage.tei-c.org/ege-webservice/Conversions/ODD%3Atext%3Axml/ODDC%3Atext%3Axml/oddhtml%3Aapplication%3Axhtml%2Bxml/

# HTML ファイルを日本語訳公開用リポジトリに移動した後、公開用 GitHub リポジトリにアップロード
mv index.html /home/venus/tei/Best-Practices-for-TEI-in-Libraries-ja/
cd /home/venus/tei/Best-Practices-for-TEI-in-Libraries-ja/
git add index.html
git commit -m "update Japanese translations"
git push origin master
cd -
