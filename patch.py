import re

replacements = (
    ("http://www.tei-c.org/release/xml/tei/stylesheet/tei.css", "https://www.tei-c.org/release/xml/tei/stylesheet/tei.css"),
    ("http://www.tei-c.org/release/xml/tei/stylesheet/tei-print.css", "https://www.tei-c.org/release/xml/tei/stylesheet/tei-print.css"),
    ("<td>acknowledgement</td><td>（要旨）", "<td>acknowledgement</td><td>（謝辞）"),
    ("<td>foreword</td><td>（要旨）", "<td>foreword</td><td>（序文）"),
)

with open("index.html") as f:
    source = f.read()

for old, new in replacements:
    if re.search(old, source):
        source = source.replace(old, new)
        if re.search(new, source):
            print(f'Replaced: "{old}" with "{new}".')
        else:
            print(f'Skipped: failed to replace "{old}".')
    else:
        print(f'Skipped: not found "{old}".')

with open("index.html", "w") as f:
    f.write(source)
