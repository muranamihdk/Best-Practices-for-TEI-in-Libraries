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

# xmlファイルからpotファイルを生成（_pot 以下に）
for SOURCE in `find . -maxdepth 2 -type f -name "*.odd" -print`
do
  SOURCE_DIR=`dirname $SOURCE`
  TARGET_DIR="${PREFIX_PATH}/${POT_DIR}"
  if [ ! -d "$TARGET_DIR" ]
  then
    mkdir -p "$TARGET_DIR"
    echo Created: "$TARGET_DIR"
  fi
  TARGET_FILE="$TARGET_DIR"/$(basename "$SOURCE" .odd).pot
  if [ ! -f "$TARGET_FILE" ]
  then
    itstool -o "$TARGET_FILE" "$SOURCE"
    echo Created: "$TARGET_FILE"
  elif [ "$SOURCE" -nt "$TARGET_FILE" ]
  then
    itstool -o "$TARGET_FILE" "$SOURCE"
    echo Updated: "$TARGET_FILE"
  fi 
done

# potファイルからpoファイルを生成（_po/ja 以下に）／poファイルがあるときは変更をマージ
TARGET_DIR="${PREFIX_PATH}/${PO_DIR}/${TARGET_LANG}"
if [ ! -d "$TARGET_DIR" ]
then
  mkdir -p "$TARGET_DIR"
  echo Created: "$TARGET_DIR"
fi

for SOURCE in `find "./${PREFIX_PATH}/${POT_DIR}/" -type f -name "*.pot" -print`
do
  PO_FILE="$TARGET_DIR"/$(basename "$SOURCE" .pot).po
  if [ ! -f "$PO_FILE" ]
  then
    cp "$SOURCE" "$PO_FILE"
    echo Created: "$PO_FILE"
  elif [ "$SOURCE" -nt "$PO_FILE" ]
  then
    msgmerge -U "$PO_FILE" "$SOURCE"
    echo Updated: "$PO_FILE"
  fi
done

if [ $(git diff origin/localize_ja --name-only | wc -l) -ne 0 ]
then
  echo
  git add .
  git commit -m "updated po files"
  echo
  echo "git push origin localize_ja"
  git push origin localize_ja
elif [ $(git status | grep "Untracked files" | wc -l) -ne 0 ]
then
  echo
  git add .
  git commit -m "created po files"
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
