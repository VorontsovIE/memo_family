require 'levenshtein'
require 'csv'

def getDay(dateInMemorialFmt)
  result = dateInMemorialFmt & 0b11111
  result != 0 ? result : nil
end

def getMonth(dateInMemorialFmt)
  result = (dateInMemorialFmt >> 5) & 0b1111
  result != 0 ? result : nil
end

def getYear(dateInMemorialFmt)
  result = (dateInMemorialFmt >> 9)
  result != 0 ? (result + 1800) : nil
end

def dateHumanFormatted(dateInMemorialFmt)
  [getDay(dateInMemorialFmt), getMonth(dateInMemorialFmt), getYear(dateInMemorialFmt)].drop_while(&:nil?).join('.')
end

$FNAMES = File.readlines('csv_unicode/fnames.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$NAMES = File.readlines('csv_unicode/names.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$LNAMES = File.readlines('csv_unicode/lnames.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$PLACES = File.readlines('csv_unicode/geoplace.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$NATIONS = File.readlines('csv_unicode/nations.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$STATS = File.readlines('csv_unicode/stat.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$WORKS = File.readlines('csv_unicode/works.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$SUDORG = File.readlines('csv_unicode/sudorg.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h

$PERSON_TO_FAMILY = File.readlines('csv_unicode/linkfams.csv').drop(1).map{|l| person_id, fam_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(fam_id)] }.to_h
$FAMILIES = File.readlines('csv_unicode/fams.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
$PRIGOVORS = File.readlines('csv_unicode/prigovor.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h

# Немного неоднозначно отчеству сопоставляется имя:  Эмильевич и Эмильевна --> Эмиль/Эмилий. Игнорируем
$lname_to_name = File.readlines('man_names.tsv').map{|l| l.chomp.split("\t") }.flat_map{|name, lnames|
  lnames.split(',').map{|lname| [lname, name] }
}.to_h

Person = Struct.new(:id, :fname_id, :name_id, :lname_id, :birthdate_memofmt, :birthplace_id, :nation_id, :work_id, :liveplace_id, 
                    :arestdate_memofmt, :sudorgan_id, :suddate_memofmt, :stat_id, :prigovor_id, :rasstrel, :mortdate_memofmt, :reabdate_memofmt,
                    :book, :age, :gender) do
  def self.from_string(str)
    id, fname_id, name_id, lname_id, birthdate_memofmt, birthplace_id, nation_id, work_id, liveplace_id, 
                    arestdate_memofmt, sudorgan_id, suddate_memofmt, stat_id, prigovor_id, rasstrel, mortdate_memofmt, reabdate_memofmt, book, age, gender = str.chomp.split(";")
    self.new(Integer(id), Integer(fname_id), Integer(name_id), Integer(lname_id), Integer(birthdate_memofmt), Integer(birthplace_id), 
            Integer(nation_id), Integer(work_id), Integer(liveplace_id), Integer(arestdate_memofmt), Integer(sudorgan_id), Integer(suddate_memofmt), Integer(stat_id), 
            Integer(prigovor_id), rasstrel == 'T', Integer(mortdate_memofmt), Integer(reabdate_memofmt), Integer(book), Integer(age), gender&.to_sym)
  end

  def self.each_in_file(fn, &block)
    return enum_for(:each_in_file, fn) unless block_given?
    File.open(fn) do |f|
      f.readline
      f.each_line{|l| yield from_string(l) }
    end
  end

  def fname; $FNAMES[fname_id]; end
  def name; $NAMES[name_id]; end
  def lname; $LNAMES[lname_id]; end

  def birthplace; $PLACES[birthplace_id]; end
  def liveplace; $PLACES[liveplace_id]; end
  
  def stat; $STATS[stat_id]; end
  def work; $WORKS[stat_id]; end
  def sudorg; $SUDORG[stat_id]; end
  
  def birthdate; dateHumanFormatted(birthdate_memofmt); end
  def arestdate; dateHumanFormatted(arestdate_memofmt); end
  def suddate; dateHumanFormatted(suddate_memofmt); end
  def mortdate; dateHumanFormatted(mortdate_memofmt); end
  def reabdate; dateHumanFormatted(reabdate_memofmt); end
  
  def father_name; $lname_to_name[lname]; end
  def full_name; "#{fname} #{name} #{lname}"; end
  def nation; $NATIONS[nation_id]; end
  def family; fam_id = $PERSON_TO_FAMILY[id]; fam_id && $FAMILIES[fam_id] end
  def prigovor; $PRIGOVORS[prigovor_id]; end
  def vmn?; prigovor.match?(/ВМН|расстрел/i); end
  def to_s
    additional_infos = [birthdate, nation, birthplace].reject(&:empty?).join(';')
    "#{full_name} (#{additional_infos})"
  end

  def infocard
    result = ["#{full_name} (#{birthdate}) - #{nation}"]
    result << "Родился: #{birthplace}" if birthplace
    result << "ПМЖ: #{liveplace}" if liveplace
    result << "Арест: #{arestdate}" if arestdate
    result << "Постановление: (#{suddate}) #{stat} -- #{sudorg}"  if suddate || stat || sudorg
    result << "Приговор: #{prigovor}; Расстрел: #{rasstrel ? 'да' : 'нет'}; Умер: #{mortdate}" if prigovor || mortdate
    result.join("\n")
  end
  
  alias_method :inspect, :to_s
end

def older?(first, second, min_difference: 0, default: nil)
  return default  if !getYear(first) || !getYear(second)  
  getYear(first) + min_difference < getYear(second)
end


$persons_by_fname_name = Hash.new{|h, fname|
  h[fname] = Hash.new{|h2, name|
    h2[name] = []
  }
}

$persons = []

Person.each_in_file('csv_unicode/persons.csv'){|person|
  $persons_by_fname_name[person.fname][person.name] << person
  $persons << person
}

####################################################################

$persons.map{|person|
  father_hypots = $persons_by_fname_name[person.fname][person.father_name]
    .reject{|hypot_father|
      hypot_father == person # Иосиф Иосифович
    }.select{|hypot_father|
      older?(hypot_father.birthdate_memofmt, person.birthdate_memofmt, min_difference: 14, default: false)
    }

  [person, father_hypots]
}.reject{|person, hypots|
  hypots.empty? || hypots.size > 3
}.select{|person, hypots|
  !person.birthplace.empty? && hypots.any?{|hypot| !hypot.birthplace.empty? }
}
#.each_with_index{|(person, hypots), idx| print '.'  if idx % 100 == 99 }
.first(30).each{|person, hypots|
  puts [person, hypots.join(' / ')].join(' --> ')
}

###########################################################

def loc_match?(place_1, place_2, threshold: 0.5)
  return false  unless place_1 && place_2
  Levenshtein.normalized_distance(place_1.downcase, place_2.downcase) <= threshold 
end

def loc_match_any?(places_1, places_2, threshold: 0.5)
  places_1.any?{|place_1|
    places_2.any?{|place_2|
      loc_match?(place_1, place_2, threshold: threshold)
    }
  }
end

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
