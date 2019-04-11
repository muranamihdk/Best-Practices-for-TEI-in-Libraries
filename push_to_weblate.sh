cd `dirname $0`

echo "git checkout localize_ja"
git checkout localize_ja
echo

if [ $(curl \
 -s \
 -H "Authorization: Token 4uQDi24YSNEYgpxkkTvwdk7z9gZYupXiUvcxyccT" \
 http://www3420ue.sakura.ne.jp:8080/api/projects/tei-in-libraries/repository/ \
| jq -r '.needs_commit') = true ]
then
  echo "Changes to commit exists at Weblate. Commit before local update."
  exit 1
fi

if [ $(git diff origin/localize_ja --name-only | wc -l) -ne 0 ]
then
  git status
  exit 0
fi

if [ $(git status | grep Changes | wc -l) -ne 0 ]
then
  git status
  exit 0
fi

if [ $(git status | grep "Your branch is ahead of" | wc -l) -ne 0 ]
then
  echo
  echo "git push origin localize_ja"
  git push origin localize_ja
  echo
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
