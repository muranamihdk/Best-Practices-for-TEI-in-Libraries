msgfmt BestPractices/_po/ja/bptl-driver.po -o BestPractices/bptl-driver.mo
itstool -m BestPractices/bptl-driver.mo BestPractices/bptl-driver.odd -o BestPractices/ja/bptl-driver.odd
git add .
git commit -m "updated ja/bptl-driver.odd"
git push origin localize_ja
