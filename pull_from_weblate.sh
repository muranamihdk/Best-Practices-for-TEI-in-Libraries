cd ~/tei/teiinlibraries/
echo "git checkout localize_ja"
git checkout localize_ja
echo

if [ $(curl \
 -s \
 -H "Authorization: Token 4uQDi24YSNEYgpxkkTvwdk7z9gZYupXiUvcxyccT" \
 http://www3420ue.sakura.ne.jp:8080/api/projects/tei-in-libraries/repository/ \
| jq -r '.needs_commit') = false ]
then
  echo "No changes to commit"
  exit 0
fi

if [ $(curl \
 -s \
 -d operation=commit \
 -H "Authorization: Token 4uQDi24YSNEYgpxkkTvwdk7z9gZYupXiUvcxyccT" \
 http://www3420ue.sakura.ne.jp:8080/api/components/tei-in-libraries/bptl-driver/repository/ \
| jq -r '.result') = false ]
then
  echo "Commit Failure."
  exit 1
else
  echo "Commit Success."
fi

echo

while :
do
 if [ $(curl \
  -s \
  -H "Authorization: Token 4uQDi24YSNEYgpxkkTvwdk7z9gZYupXiUvcxyccT" \
  http://www3420ue.sakura.ne.jp:8080/api/projects/tei-in-libraries/repository/ \
 | jq -r '.needs_push') = true ]
 then
   echo "Waiting for Weblate to push changes..."
   sleep 3
 else
  break
 fi
done

echo "git pull origin localize_ja"
git pull origin localize_ja
