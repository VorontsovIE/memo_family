require 'person_match'

load_data!
load_persons!

####################################################################

$persons.lazy.map{|person|
  father_hypots = $persons_by_normfname_name[person.fname_normalized][person.father_name]
    .reject{|hypot_father|
      hypot_father == person # Иосиф Иосифович
    }.select{|hypot_father|
      older?(hypot_father.birthdate_memofmt, person.birthdate_memofmt, min_difference: 14, default: false)
    }

  [person, father_hypots]
}.reject{|person, hypots|
  hypots.empty? || hypots.size > 1 # 3
}.select{|person, hypots|
  !person.birthplace.empty? && hypots.any?{|hypot| !hypot.birthplace.empty? }
}.select{|person, hypots|
  hypot = hypots.first
  loc_match_any?([person.birthplace, person.liveplace], [hypot.birthplace, hypot.liveplace], threshold: 0.0)
}.first(30).each{|person, hypots|
  hypot = hypots.first
  puts '-------------------'
  puts person.infocard
  puts ' ==>'
  puts hypot.infocard
}
# .select{|person, hypots| person.family || hypots.first.family}
#.each_with_index{|(person, hypots), idx| print '.'  if idx % 100 == 99 }

###########################################################


algir = CSV.readlines('algir.csv').drop(1)
algir.select{|person|
  person[6]&.match?(/ЧСИР/i)
}.map{|algir|
  surname = algir[0].split(' ').first
  same_surname_persons = $persons_by_fname_name[surname].values.flatten.select{|person| person.gender == :м && person.vmn? }
  [algir, same_surname_persons]
}.select{|algir, same_surname_persons|
  same_surname_persons.size == 1
}.map{|algir, same_surname_persons|
  [algir, same_surname_persons.first]
}.select{|algir, person_2|
  loc_match_any?([algir[2], algir[5]], [person_2.birthplace, person_2.liveplace], threshold: 0.6)
}.each{|algir, person_2|
  puts '----------------'
  puts person_2.infocard
  puts '  ==>'
  puts algir.join("\t")
}.tap{|dataset|
  puts "Количество: #{dataset.size}"
}
