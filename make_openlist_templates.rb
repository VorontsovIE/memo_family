require 'set'

father_of_person = Hash.new{|h,k| h[k] = Set.new }
children_of_person = Hash.new{|h,k| h[k] = Set.new }
siblings_of_person = Hash.new{|h,k| h[k] = Set.new }

duplicates = File.readlines('duplicates.tsv').map(&:chomp).to_set
genders_of_person = Hash.new{|h,k| h[k] = Set.new }

File.readlines('pairs_maxfreq_50.tsv').each do |l|
  linktype, person_1, person_1_gender, person_2, person_2_gender = l.chomp.split("\t")
  genders_of_person[person_1] << person_1_gender || ''
  genders_of_person[person_2] << person_2_gender || ''
  case linktype
  when '0'
    children_of_person[person_1] << person_2
    father_of_person[person_2] << person_1
  when '1'
    siblings_of_person[person_1] << person_2
    siblings_of_person[person_2] << person_1
  end      
end

children_of_person.reject!{|person, relatives| duplicates.include?(person) || relatives.any?{|relative| duplicates.include?(relative) } }
father_of_person.reject!{|person, relatives| duplicates.include?(person) || relatives.any?{|relative| duplicates.include?(relative) } }
siblings_of_person.reject!{|person, relatives| duplicates.include?(person) || relatives.any?{|relative| duplicates.include?(relative) } }


children_of_person.each{|father, children|
  children.each{|child|
    if genders_of_person[child].size == 1
      child_gender = genders_of_person[child].to_a.first
      child_gender = 'undefined'  unless child_gender == 'м' || child_gender == 'ж'
    else
      child_gender = 'undefined'
    end
   
    if child_gender == 'undefined'
      relation = 'has_son/daughter'
    else
      relation = (child_gender == 'м') ? 'has_son' : 'has_daughter'
    end
    puts [father, relation, child].join("\t")
  }
}

father_of_person.each{|child, fathers|
  next  unless fathers.size == 1
  father = fathers.to_a.first
  puts [child, 'has_father', father].join("\t")
}

siblings_of_person.each{|person, siblings|
  siblings.each{|sibling|
    if genders_of_person[sibling].size == 1
      sibling_gender = genders_of_person[sibling].to_a.first
      sibling_gender = 'undefined'  unless sibling_gender == 'м' || sibling_gender == 'ж'
    else
      sibling_gender = 'undefined'
    end
    
    if sibling_gender == 'undefined'
      relation = 'has_brother/sister'
    else
      relation = (sibling_gender == 'м') ? 'has_brother' : 'has_sister'
    end
    puts [person, relation, sibling].join("\t")
  }
}
