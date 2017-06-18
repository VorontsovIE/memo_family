import pymorphy2
morph = pymorphy2.MorphAnalyzer()
for l in open('csv_unicode/fnames.csv'):
  id, surname = l.strip().split(';')
  parse_cases = morph.parse(surname)
  norm = parse_cases[0].normal_form
  for parse_case in parse_cases:
    if 'Surn' in parse_case.tag.grammemes:
      norm = parse_case.normal_form
      break
  print(id,norm, sep=';')
