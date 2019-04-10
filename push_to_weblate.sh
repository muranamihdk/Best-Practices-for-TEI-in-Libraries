cd `dirname $0`

if [ $(git diff origin/localize_ja --name-only | wc -l) -eq 0 ]
then
  git status
  exit 0
fi

if [ $(git status | grep Changes | wc -l) -ne 0 ]
then
  git status
  exit 0
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
