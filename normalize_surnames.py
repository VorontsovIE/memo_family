import csv
import pymorphy2

morph = pymorphy2.MorphAnalyzer()

def norm_surname(surname):
  parse_cases = morph.parse(surname)
  for parse_case in parse_cases:
    if 'Surn' in parse_case.tag.grammemes:
      return parse_case.normal_form
  return parse_cases[0].normal_form

def norm_patronimic(surname):
  parse_cases = morph.parse(surname)
  for parse_case in parse_cases:
    if 'Patr' in parse_case.tag.grammemes:
      return parse_case.normal_form
  return parse_cases[0].normal_form

with open('csv_unicode/fnames_normalized.csv', 'w') as fw:
  for row in open('csv_unicode/fnames.csv'):
    id, surname = row.strip().split(';')
    print(id, norm_surname(surname), sep=';', file = fw)

with open('csv_unicode/fathers_names_from_lnames.csv', 'w') as fw:
  for row in open('csv_unicode/lnames.csv'):
    id, patronimic = row.strip().split(';')
    print(id, norm_patronimic(patronimic), sep=';', file = fw) # Convert patronimic to normalized father's name


with open('algir_normalized.csv', 'w') as outfile:
  writer = csv.writer(outfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
  with open('algir.csv', 'r') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='"')
    for row in reader:
      writer.writerow([norm_surname(row[0].split(' ')[0])] + row)
