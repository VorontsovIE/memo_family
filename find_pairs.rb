require_relative 'person_match'

load_data!
$stderr.puts 'Loaded supplementary data'
load_persons!
$stderr.puts 'Loaded persons'

$num_persons_at_birthplace = $persons.each_with_object(Hash.new(0)){|person, hsh| hsh[person.birth_place] += 1 }
$num_persons_at_liveplace = $persons.each_with_object(Hash.new(0)){|person, hsh| hsh[person.live_place] += 1 }
$num_persons_at_reabdate = $persons.each_with_object(Hash.new(0)){|person, hsh| hsh[person.reab_date] += 1 }

$stderr.puts 'Frequencies calculated'

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
    person_1.birth_place,
    person_1.live_place,
    person_1.reab_date,
    (!person_1.birth_place.empty? ? $num_persons_at_birthplace[person_1.birth_place] : 0) + (!person_1.live_place.empty? ? $num_persons_at_liveplace[person_1.live_place] : 0),
    $num_persons_at_reabdate[person_1.reab_date],


    person_2.fullname_with_year,
    person_2.gender,
    person_2.birth_year,
    person_2.year_of_arrest,
    person_2.year_of_death,
    person_2.birth_place,
    person_2.live_place,
    person_2.reab_date,
    (!person_2.birth_place.empty? ? $num_persons_at_birthplace[person_2.birth_place] : 0) + (!person_2.live_place.empty? ? $num_persons_at_liveplace[person_2.live_place] : 0),
    $num_persons_at_reabdate[person_2.reab_date],
  ]
end

####################################################################

headers = [
  'FirstPersonId', 'SecondPersonId', 'LinkType',
  'FirstName',  'FirstSex',  'FirstBirthYear',  'FirstYearOfArrest',  'FirstYearOfDeath', 'FirstBirthPlace', 'FirstLivePlace', 'FirstReabdate',
  'FirstSamePlaceOccurences', 'FirstSameReabdateOccurences',
  'SecondName', 'SecondSex', 'SecondBirthYear', 'SecondYearOfArrest', 'SecondYearOfDeath', 'SecondBirthPlace', 'SecondLivePlace', 'SecondReabdate',
  'SecondSamePlaceOccurences', 'SecondSameReabdateOccurences',
]
puts headers.join("\t")


# Отцы и дети

# Двухпроходка: сначала ищем по людям (отцам) потенциальных детей (при этом отбрасываем "детей" "родителей", у которых слишком много детей)
# Потом по детям ищем отцов. Если находим единственного, то это получается "компактное" семейство

# Дети не слишком "многодетных" отцов (слишком "многодетные отцы" - это скорее всего ошибки картирования)
potential_children = $persons.lazy.select{|person|
  (!person.birth_place.empty? || !person.live_place.empty?)
}.map{|person|
  hypothetical_children(person)
}.select{|children|
  children.size <= 4
}.to_a.flatten

$stderr.puts 'Potential children extracted'

# По детям восстановим отцов
potential_children.uniq.map{|person|
  [person, hypothetical_fathers(person)]
}.reject{|person, hypots|
  hypots.empty? #|| hypots.size > 10
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot| !hypot.birth_place.empty? || !hypot.live_place.empty? }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    !person.reab_date.empty? && person.reab_date == hypot.reab_date
  }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    # loc_match_any?([person.birth_place, person.live_place], [hypot.birth_place, hypot.live_place], threshold: 0.0)
    ([person.birth_place_id, person.live_place_id] & [hypot.birth_place_id, hypot.live_place_id]).any?{|id| id && id != 0 }
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
$stderr.puts 'Parents extracted'

# Сиблинги
$persons.lazy.select{|person|
  (!person.birth_place.empty? || !person.live_place.empty?) && !person.reab_date.empty?
}.map{|person|
  [person, hypothetical_siblings(person)]
}.reject{|person, hypots|
  hypots.empty?
}
.map{|person, hypots|
  hypots_refined = hypots.select{|hypot| !hypot.birth_place.empty? || !hypot.live_place.empty? }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    !person.reab_date.empty? && person.reab_date == hypot.reab_date
  }
  [person, hypots_refined]
}.map{|person, hypots|
  hypots_refined = hypots.select{|hypot|
    loc_match_any?([person.birth_place, person.live_place], [hypot.birth_place, hypot.live_place], threshold: 0.0)
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

$stderr.puts 'Siblings extracted'
