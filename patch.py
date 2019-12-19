import re

# ========================================================
#「3.6. テキスト区分」の表に日本語訳独自の文字を追加する
#（poファイルでは同じ文章を訳し分けられないのでここで対応）
# ========================================================

replacements = (
    ("http://www.tei-c.org/release/xml/tei/stylesheet/tei.css", "https://www.tei-c.org/release/xml/tei/stylesheet/tei.css"),
    ("http://www.tei-c.org/release/xml/tei/stylesheet/tei-print.css", "https://www.tei-c.org/release/xml/tei/stylesheet/tei-print.css"),
    ("<td>acknowledgement</td><td>（要旨）", "<td>acknowledgement</td><td>（謝辞）"),
    ("<td>foreword</td><td>（要旨）", "<td>foreword</td><td>（序文）"),
    ("<td>bibliography</td><td>（付録）", "<td>bibliography</td><td>（参考文献）"),
    ("<td>glossary</td><td>（付録）", "<td>glossary</td><td>（用語集）"),
    ("<td>notes</td><td>（付録）", "<td>notes</td><td>（注）"),
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


# ========================================================
#「4.1.8. TEIヘッダーで推奨される要素と属性」の表に折り畳みを実装する
# ========================================================

with open("index.html") as f:
    source = f.read()

table = re.search(r"<h4><span class=\"headingNumber\">4.1.8. </span>.+?<table.+?</table>", source).group(0)

td_num = 1  # tdの数は階層の深さを意味する. 1〜7まであり、数字が大きくなるほど階層が深い
previous_td_num = 1
previous_tag = ""
classes = []  # タグ名をクラス名として使用する. ここに追加していく
all_classes = []  # テスト用
for matched, colspan, tag in re.findall("(<tr>.*?<td colspan=\"(\d)\">.*?&lt;(.+?)&gt;)", table):
    branch_count = len(re.findall("├", matched))
    td_num = len(re.findall("<td", matched))
    tag = tag.split()[0]  # タグ名のみを取り出す. ex. teiHeader xml:lang="___" ---> teiHeader
    # 階層が深くなったら
    if td_num > previous_td_num:
        classes.append(previous_tag)
        all_classes.append(previous_tag)  # テスト用
    # 階層が浅くなったら
    elif td_num < previous_td_num:
        del classes[td_num - previous_td_num:]
    table = re.sub("<tr>", "<tr class=\"{}\">".format(" ".join(classes)), table, count=1)

    previous_td_num = td_num
    previous_tag = tag

# 値が同じならクラス名にダブりなし
assert len(all_classes) == len(set(all_classes))

for class_tag in all_classes:
    if class_tag in ["teiHeader", "keywords"]:  # teiHeaderは├がないので、keywordsは階層が浅いので折りたたまない
        continue
    found = re.search("<td>?(├|└)</td>(<td colspan=\"\d\">)?<span class=\"?(gi|tag)\">&lt;{}.*?&gt;</span>".format(class_tag), table).group(0)
    found = re.sub("<td>?(├|└)</td>", "<td id=\"{}\">┬</td>".format(class_tag), found)
    table = re.sub("<td>?(├|└)</td>(<td colspan=\"\d\">)?<span class=\"?(gi|tag)\">&lt;{}.*?&gt;</span>".format(class_tag), found, table)

toggle_scripts = ""
for class_tag in all_classes:
    if class_tag in ["teiHeader", "keywords"]:
        continue
    script = """document.getElementById("{}").textContent = "▼";
    $("#{}").click(function() {{
        var elem = $(".{}")[0];
        if (elem.style.display == 'none') {{
            $(".{}").show();
            document.getElementById("{}").textContent = "▼";
        }}
        else {{
            $(".{}").hide();
            document.getElementById("{}").textContent = "▶︎";
        }}
    }});""".replace("{}", class_tag)
    toggle_scripts += script

table_tr_toggle_script = """
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
<script>
$(document).ready(function() {{
    {}
}});
</script>
""".format(toggle_scripts)

table = re.sub(r"\\", "〆", table)
source = re.sub(r"<h4><span class=\"headingNumber\">4.1.8. </span>.+?<table.+?</table>", table, source, count=1)
source = re.sub("〆", r"\\", source)
source = source.replace("</body>", table_tr_toggle_script + "</body>")

with open("index.html", "w") as f:
    f.write(source)
