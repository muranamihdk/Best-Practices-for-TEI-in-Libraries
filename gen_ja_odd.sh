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

cd `dirname $0`
git checkout localize_ja
echo

for COMMAND in $GETTEXT $MSGFMT $MSGMERGE $ITSTOOL
do
  which "$COMMAND" >/dev/null 2>&1
  if [ "$?" -eq 1 ]
  then
    echo "$COMMAND command was not found."
    exit
  fi
done

if [ $(curl \
 -s \
 -H "Authorization: Token 4uQDi24YSNEYgpxkkTvwdk7z9gZYupXiUvcxyccT" \
 http://www3420ue.sakura.ne.jp:8080/api/projects/tei-in-libraries/repository/ \
| jq -r '.needs_commit') = true ]
then
  echo "Changes to commit exists at Weblate. Commit before local update."
  exit 1
fi

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

# pull at Weblate
if [ $(curl \
 -s \
 -d operation=pull \
 -H "Authorization: Token 4uQDi24YSNEYgpxkkTvwdk7z9gZYupXiUvcxyccT" \
 http://www3420ue.sakura.ne.jp:8080/api/components/tei-in-libraries/bptl-driver/repository/ \
| jq -r '.result') = false ]
then
  echo "Pull at Weblate Failure."
  exit 1
else
  echo "Pull at Weblate Success."
  echo
fi
