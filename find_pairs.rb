require_relative 'person_match'

load_data!
load_persons!


LINK_TYPES = {isFatherOf: 0, isSiblingOf: 1, isDuplicateOf: 2}

def relation_infos(person_1, person_2, link_type)
  infos = [
    person_1.id,
    person_2.id,
    LINK_TYPES[link_type],

    person_1.fullname_with_year,
    person_1.gender,
    person_1.birth_year,
    person_1.year_of_arrest,
    person_1.year_of_death,

    person_2.fullname_with_year,
    person_2.gender,
    person_2.birth_year,
    person_2.year_of_arrest,
    person_2.year_of_death,
  ]
end

####################################################################

headers = [
  'FirstPersonId', 'SecondPersonId', 'LinkType',
  'FirstName',  'FirstSex',  'FirstBirthYear',  'FirstYearOfArrest',  'FirstYearOfDeath',
  'SecondName', 'SecondSex', 'SecondBirthYear', 'SecondYearOfArrest', 'SecondYearOfDeath',
]
puts headers.join("\t")


# Отцы и дети

# Двухпроходка: сначала ищем по людям (отцам) потенциальных детей (при этом отбрасываем "детей" "родителей", у которых слишком много детей)
# Потом по детям ищем отцов. Если находим единственного, то это получается "компактное" семейство

# Дети не слишком "многодетных" отцов (слишком "многодетные отцы" - это скорее всего ошибки картирования)
potential_children = $persons.lazy.select{|person|
  (!person.birthplace.empty? || !person.liveplace.empty?)
}.map{|person|
  hypothetical_children(person)
}.select{|children|
  children.size <= 4
}.to_a.flatten

# По детям восстановим отцов
potential_children.uniq.map{|person|
  [person, hypothetical_fathers(person)]
}.reject{|person, hypots|
  hypots.empty? #|| hypots.size > 10
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot| !hypot.birthplace.empty? || !hypot.liveplace.empty? }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    !person.reabdate.empty? && person.reabdate == hypot.reabdate
  }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    loc_match_any?([person.birthplace, person.liveplace], [hypot.birthplace, hypot.liveplace], threshold: 0.0)
  }
 [person, hypots_refined]
}.select{|person, hypots|
  hypots.size == 1
}.map{|person, hypots|
  [person, hypots.first]
}.each{|child, father|
  infos = relation_infos(father, child, :isFatherOf)
  puts infos.join("\t")
}

# Сиблинги
$persons.lazy.select{|person|
  (!person.birthplace.empty? || !person.liveplace.empty?) && !person.reabdate.empty?
}.map{|person|
  [person, hypothetical_siblings(person)]
}.reject{|person, hypots|
  hypots.empty?
}
.map{|person, hypots|
  hypots_refined = hypots.select{|hypot| !hypot.birthplace.empty? || !hypot.liveplace.empty? }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    !person.reabdate.empty? && person.reabdate == hypot.reabdate
  }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    loc_match_any?([person.birthplace, person.liveplace], [hypot.birthplace, hypot.liveplace], threshold: 0.0)
  }
 [person, hypots_refined]
}.reject{|person, hypots|
  hypots.empty? || hypots.size > 4 # слишком много братьев-сестер. Вероятно, ошибка
}.flat_map{|person, hypots|
  hypots.map{|hypot|
    [person, hypot]
  }
}.select{|person, sibling|
  # isSiblingOf is a symmetrical relation so we need to check each pair just once
  # We can't do it before filtering too large groups because the last siblings will have small enough hypotheses to pass 
  person.id < sibling.id
}.each{|person, sibling|
  if person.fullname_with_year != sibling.fullname_with_year
    infos = relation_infos(person, sibling, :isSiblingOf)
  else
    infos = relation_infos(person, sibling, :isDuplicateOf)
  end
  puts infos.join("\t")
}
