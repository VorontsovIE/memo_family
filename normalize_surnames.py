import csv
import pymorphy2

morph = pymorphy2.MorphAnalyzer()

def normalize_word(word, tag, fallback_to_original=False):
  parse_cases = morph.parse(word)
  for parse_case in parse_cases:
    if tag in parse_case.tag.grammemes:
      return parse_case.normal_form
  if fallback_to_original:
    return word.lower()
  else:
    return parse_cases[0].normal_form

def normalize_all_in_file(from_file, to_file, tag, fallback_to_original=False):
  with open(to_file, 'w', encoding='utf-8') as fw:
    for row in open(from_file, encoding='utf-8'):
      id, name = row.strip().split(';')
      print(id, name, normalize_word(name, tag, fallback_to_original=fallback_to_original), sep='\t', file = fw)

normalize_all_in_file('csv/names.csv', 'csv/names_w_normal_form.csv', 'Name', fallback_to_original=True)
normalize_all_in_file('csv/fnames.csv', 'csv/surnames_w_normal_form.csv', 'Surn')
normalize_all_in_file('csv/lnames.csv', 'csv/patronimics_w_normal_form.csv', 'Patr')

with open('algir_normalized.csv', 'w') as outfile:
  writer = csv.writer(outfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
  with open('algir.csv', 'r') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='"')
    for row in reader:
      normalized_surname = normalize_word(row[0].split(' ')[0], 'Surn')
      writer.writerow([normalized_surname] + row)
