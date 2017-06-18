find csv/*.csv | xargs -n1 basename | xargs -n1 -I{} echo 'iconv -f cp1251 -t utf-8 csv/{} > csv_unicode/{}'
python3 normalize_surnames.py

