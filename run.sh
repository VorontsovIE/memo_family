find csv/*.csv | xargs -n1 basename | xargs -n1 -I{} echo 'iconv -f cp1251 -t utf-8 csv/{} > csv_unicode/{}' | bash
find csv_unicode/*.csv | xargs grep --files-with-matches -Pe $'\t' | xargs -n1 -I{} echo "sed --in-place --regexp-extended -e 's/\s*\t\s*/ /' {}" | bash
python3 normalize_surnames.py

