mkdir -p csv
find csv_cp1251/*.csv | xargs -n1 basename | xargs -n1 -I{} echo 'iconv -f cp1251 -t utf-8 csv_cp1251/{} > csv/{}' | bash
find csv/*.csv | xargs grep --files-with-matches -Pe $'\t' | xargs -n1 -I{} echo "sed --in-place --regexp-extended -e 's/\s*\t\s*/ /g' {}" | bash
#python3 normalize_surnames.py

