require_relative 'person_match'

load_data!
load_persons!

LINK_TYPES = {hasfather: 0, }
####################################################################

headers = [
  'FirstPersonId', 'SecondPersonId', 'LinkType',
  'FirstName',  'FirstSex',  'FirstBirthYear',  'FirstYearOfArrest',  'FirstYearOfDeath',
  'SecondName', 'SecondSex', 'SecondBirthYear', 'SecondYearOfArrest', 'SecondYearOfDeath',
]
puts headers.join("\t")

$persons.lazy.select{|person|
  (!person.birthplace.empty? || !person.liveplace.empty?)
}.map{|person|
  [person, hypothetical_fathers(person)]
}.reject{|person, hypots|
  hypots.empty? #|| hypots.size > 10
}.map{|person, hypots|
  hypots_with_place = hypots.select{|hypot| !hypot.birthplace.empty? || !hypot.liveplace.empty? }
  hypots_with_same_reabdate = hypots_with_place.select{|hypot|
    person.reabdate == hypot.reabdate
  }
  hypots_same_location = hypots_with_same_reabdate.select{|hypot|
    loc_match_any?([person.birthplace, person.liveplace], [hypot.birthplace, hypot.liveplace], threshold: 0.0)
  }
 [person, hypots_with_same_reabdate]
}.select{|person, hypots|
  hypots.size == 1
}.map{|person, hypots|
  [person, hypots.first]
}.each{|child, father|
  infos = [
    father.id,
    child.id,
    LINK_TYPES[:hasfather],

    father.fullname_with_year,
    father.gender,
    father.birth_year,
    father.year_of_arrest,
    father.year_of_death,

    child.fullname_with_year,
    child.gender,
    child.birth_year,
    child.year_of_arrest,
    child.year_of_death,
  ]
  puts infos.join("\t")
}
# # .count
# # .each_with_index{|(person, hypot), idx| print '.'  if idx % 100 == 99 }
# .first(30).each{|person, hypot|
#   puts '-------------------'
#   puts person.infocard
#   puts ' ==>'
#   puts hypot.infocard
# }
