require 'levenshtein'
require 'csv'

def unquote(str)
  result = str
  result = result.gsub(/""/, '"')
  result = result[1..-2]  if result.match?(/^".*"$/)
  result
end

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

VarFIO ||= Struct.new(:varname, :varifname, :variname, :varilname, :variall)
class VarFIO
  def self.from_raw_strings(varname, varifname, variname, varilname, variall)
    self.new( *[varname, varifname, variname, varilname, variall].map{|x| x.split('|').map(&:strip)} )
  end

  def to_s
    [varname, varifname, variname, varilname, variall].map{|vars| vars.join("/") }.reject(&:empty?).join("; ")
    # Требуется консультация
    # result = []
    # result << "Имя: {#{varname.join('/')}}"  if !varname.empty?
    # result << "Имя: {#{varname.join('/')}}"  if !varname.empty?
    # results.join('; ')
  end
  alias_method :inspect, :to_s
end

def table_value_by_id(filename, &block)
  rows = File.readlines(filename).drop(1).map{|l| l.chomp.split(';', 2) }
  if block_given?
    result = rows.map{|id, val| [Integer(id), yield(unquote(val))] }.to_h
  else
    result = rows.map{|id, val| [Integer(id), unquote(val)] }.to_h
  end
  raise 'Many-to-many table where one-to-many expected'  unless rows.size == result.size
  result
end

def table_id_pair(filename)
  rows = File.readlines(filename).drop(1).map{|l| l.chomp.split(';', 2) }
  result = rows.map{|id_1, id_2| [Integer(id_1), Integer(id_2)] }.to_h
  raise 'Many-to-many table where one-to-many expected'  unless rows.size == result.size
  result
end


def load_data!
  $FNAMES = table_value_by_id('csv_unicode/fnames.csv')
  $FNAMES_NORMALIZED = table_value_by_id('csv_unicode/fnames_normalized.csv')
  $NAMES = table_value_by_id('csv_unicode/names.csv')
  $LNAMES = table_value_by_id('csv_unicode/lnames.csv')
  $FATHER_NAME_FROM_LNAMES = table_value_by_id('csv_unicode/fathers_names_from_lnames.csv')
  $PLACES = table_value_by_id('csv_unicode/geoplace.csv')
  $NATIONS = table_value_by_id('csv_unicode/nations.csv')
  $STATYA = table_value_by_id('csv_unicode/stat.csv')
  $WORKS = table_value_by_id('csv_unicode/works.csv')
  $SUDORG = table_value_by_id('csv_unicode/sudorg.csv')

  $REABORGAN = table_value_by_id('csv_unicode/reaborg.csv')
  $PERSON_TO_REABORGAN = table_id_pair('csv_unicode/linkreaborg.csv')

  $EDUCATION = table_value_by_id('csv_unicode/educat.csv')
  $PERSON_TO_EDUCATION = table_id_pair('csv_unicode/linkeducat.csv')

  $REPR_PREV = table_value_by_id('csv_unicode/reprprev.csv')
  $PERSON_TO_REPR_PREV = table_id_pair('csv_unicode/linkreprprev.csv')
  $REPR_NEXT = table_value_by_id('csv_unicode/reprnext.csv')
  $PERSON_TO_REPR_NEXT = table_id_pair('csv_unicode/linkreprnext.csv')

  $EDUCATION = table_value_by_id('csv_unicode/educat.csv')
  $PERSON_TO_EDUCATION = table_id_pair('csv_unicode/linkeducat.csv')

  $AREST_TYPE = table_value_by_id('csv_unicode/aresttyp.csv')
  $PERSON_TO_ARESTTYPE = table_id_pair('csv_unicode/linkaresttyp.csv')

  $PODDAN = table_value_by_id('csv_unicode/poddan.csv')
  $PERSON_TO_PODDAN = table_id_pair('csv_unicode/linkpoddan.csv')

  $PERSON_TO_FAMILY = table_id_pair('csv_unicode/linkfams.csv')
  $FAMILIES = table_value_by_id('csv_unicode/fams.csv')

  $VARFIO = File.readlines('csv_unicode/varnames.csv').drop(1).map{|l|
    id, *vals = l.split(';', 6).map(&:strip)
    [Integer(id), VarFIO.from_raw_strings(*vals)]
  }.to_h

  $PERSON_TO_VARFIO = table_id_pair('csv_unicode/linkvarfio.csv')


  $PRIGOVORS = table_value_by_id('csv_unicode/prigovor.csv')

  # Немного неоднозначно отчеству сопоставляется имя:  Эмильевич и Эмильевна --> Эмиль/Эмилий. Игнорируем
  $lname_to_name = File.readlines('man_names.tsv').map{|l| l.chomp.split("\t") }.flat_map{|name, lnames|
    lnames.split(',').map{|lname| [lname, name] }
  }.to_h

  $name_to_lnames = File.readlines('man_names.tsv').map{|l| l.chomp.split("\t") }.map{|name, lnames| [name, lnames.split(',')] }.to_h
end

Person ||= Struct.new(:id, :fname_id, :name_id, :lname_id, :birth_date_memofmt, :birth_place_id, :nation_id, :work_id, :live_place_id,
                    :arest_date_memofmt, :sudorgan_id, :sud_date_memofmt, :stat_id, :prigovor_id, :rasstrel, :mort_date_memofmt, :reab_date_memofmt,
                    :book, :age, :gender)
class Person
  def self.from_string(str)
    id, fname_id, name_id, lname_id, birth_date_memofmt, birth_place_id, nation_id, work_id, live_place_id,
                    arest_date_memofmt, sudorgan_id, sud_date_memofmt, stat_id, prigovor_id, rasstrel, mort_date_memofmt, reab_date_memofmt, book, age, gender = str.chomp.split(";")
    self.new(Integer(id), Integer(fname_id), Integer(name_id), Integer(lname_id), Integer(birth_date_memofmt), Integer(birth_place_id),
            Integer(nation_id), Integer(work_id), Integer(live_place_id), Integer(arest_date_memofmt), Integer(sudorgan_id), Integer(sud_date_memofmt), Integer(stat_id),
            Integer(prigovor_id), rasstrel == 'T', Integer(mort_date_memofmt), Integer(reab_date_memofmt), Integer(book), Integer(age), gender&.to_sym)
  end

  def self.each_in_file(fn, &block)
    return enum_for(:each_in_file, fn) unless block_given?
    File.open(fn) do |f|
      f.readline
      f.each_line{|l| yield from_string(l) }
    end
  end

  def fname; $FNAMES[fname_id]; end
  def fname_normalized; $FNAMES_NORMALIZED[fname_id]; end
  def name; $NAMES[name_id]; end
  def lname; $LNAMES[lname_id]; end

  def birth_place; $PLACES[birth_place_id]; end
  def live_place; $PLACES[live_place_id]; end

  def statya; $STATYA[stat_id]; end
  def work; $WORKS[work_id]; end
  def sudorgan; $SUDORG[sudorgan_id]; end

  def birth_year; getYear(birth_date_memofmt); end
  def year_of_arrest; getYear(arest_date_memofmt); end
  def year_of_death; getYear(mort_date_memofmt); end

  def birth_date; dateHumanFormatted(birth_date_memofmt); end
  def arest_date; dateHumanFormatted(arest_date_memofmt); end
  def sud_date; dateHumanFormatted(sud_date_memofmt); end
  def mort_date; dateHumanFormatted(mort_date_memofmt); end
  def reab_date; dateHumanFormatted(reab_date_memofmt); end

  def father_name; $lname_to_name[lname]; end
  def father_name_normalized; $FATHER_NAME_FROM_LNAMES[lname_id]; end
  def full_name; "#{fname} #{name} #{lname}"; end
  def nation; $NATIONS[nation_id]; end
  def family; fam_id = $PERSON_TO_FAMILY[id]; fam_id && $FAMILIES[fam_id] end
  def reab_organ; reaborg_id = $PERSON_TO_REABORGAN[id]; reaborg_id && $REABORGAN[reaborg_id] end
  def education; educat_id = $PERSON_TO_EDUCATION[id]; educat_id && $EDUCATION[educat_id] end
  def poddanstvo; poddanstvo_id = $PERSON_TO_PODDAN[id]; poddanstvo_id && $PODDAN[poddanstvo_id] end
  def varfio; varfio_id = $PERSON_TO_VARFIO[id]; varfio_id && $VARFIO[varfio_id] end

  def arest_type; aresttype_id = $PERSON_TO_ARESTTYPE[id]; aresttype_id && $AREST_TYPE[aresttype_id] end

  def repr_prev; repr_prev_id = $PERSON_TO_REPR_PREV[id]; repr_prev_id && $REPR_PREV[repr_prev_id] end
  def repr_next; repr_next_id = $PERSON_TO_REPR_NEXT[id]; repr_next_id && $REPR_NEXT[repr_next_id] end

  def prigovor; $PRIGOVORS[prigovor_id]; end
  def vmn?; prigovor.match?(/ВМН|расстрел/i); end
  def to_s
    additional_infos = [birth_date, nation, birth_place].reject(&:empty?).join(';')
    "#{full_name} (#{additional_infos})"
  end

  def infocard
    result = ["#{full_name} (#{birth_date}) - #{nation}; #{poddanstvo}"]
    result << "Варианты имени: #{varfio}" if varfio
    result << "Родился: #{birth_place}" if !birth_place.empty?
    result << "ПМЖ: #{live_place}" if !live_place.empty?
    result << "Семья: #{family}"  if family && !family.empty?
    result << "Образование: #{education}"  if education && !education.empty?
    result << "Арест: #{arest_date} #{arest_type}" if (arest_type && !arest_type.empty?) || !arest_date.empty?
    result << "Постановление: (#{sud_date}) #{statya} -- #{sudorgan}"  if !sud_date.empty? || !statya.empty? || !sudorgan.empty?
    result << "Приговор: #{prigovor}; Расстрел: #{rasstrel ? 'да' : 'нет'}; Умер: #{mort_date}" if !prigovor.empty? || !mort_date.empty?
    result << "Реабилитирован: (#{reab_date}) #{reab_organ}"  if !reab_date.empty? || !reab_organ.empty?
    result.join("\n")
  end

  def fullname_with_year
    "#{full_name} (#{getYear(birth_date_memofmt)})"
  end

  def full_info_row
    [id, fname, name, lname, birth_date, birth_place, nation, work, live_place,
      arest_date, sudorgan, sud_date, statya, prigovor, rasstrel, mort_date, reab_date, book, age, gender].join("\t")
  end
  alias_method :inspect, :to_s
end

def older?(first, second, min_difference: 0, default: nil)
  return default  if !getYear(first) || !getYear(second)
  getYear(first) + min_difference < getYear(second)
end

def loc_match?(place_1, place_2, threshold: 0.5)
  return false  unless place_1 && !place_1.empty? && place_2 && !place_2.empty?
  Levenshtein.normalized_distance(place_1.downcase, place_2.downcase) <= threshold
end

def loc_match_any?(places_1, places_2, threshold: 0.5)
  places_1.compact.map(&:downcase).reject(&:empty?).any?{|place_1|
    places_2.compact.map(&:downcase).reject(&:empty?).any?{|place_2|
      threshold.zero?  ?  (place_1 == place_2)  :  loc_match?(place_1, place_2, threshold: threshold)
    }
  }
end

def hypothetical_fathers(person)
  $persons_by_normfname_name[person.fname_normalized][person.father_name]
    .reject{|hypot_father|
      hypot_father == person # Иосиф Иосифович
    }.select{|hypot_father|
      older?(hypot_father.birth_date_memofmt, person.birth_date_memofmt, min_difference: 14, default: false)
    }
end

def hypothetical_children(person)
  same_surnames = $persons_by_normfname_lname[person.fname_normalized]
  lnames = $name_to_lnames[person.name] || []
  lnames.flat_map{|children_name|
    same_surnames[children_name]
  }.reject{|hypot_children|
    hypot_children == person # Иосиф Иосифович
  }.select{|hypot_children|
    older?(person.birth_date_memofmt, hypot_children.birth_date_memofmt, min_difference: 14, default: false)
  }
end

def hypothetical_siblings(person)
  $persons_by_normfname_normfathersname[person.fname_normalized][person.father_name_normalized].reject{|hypot|
    hypot == person # One isn't himself sibling
  }
end

def load_persons!
  $persons_by_normfname_name = Hash.new{|h, fname|
    h[fname] = Hash.new{|h2, name|
      h2[name] = []
    }
  }

  $persons_by_normfname_lname = Hash.new{|h, fname|
    h[fname] = Hash.new{|h2, lname|
      h2[lname] = []
    }
  }

  $persons_by_normfname_normfathersname = Hash.new{|h, fname|
    h[fname] = Hash.new{|h2, father_name|
      h2[father_name] = []
    }
  }

  $persons = []

  Person.each_in_file('csv_unicode/persons.csv'){|person|
    $persons_by_normfname_name[person.fname_normalized][person.name] << person
    $persons_by_normfname_lname[person.fname_normalized][person.lname] << person
    $persons_by_normfname_normfathersname[person.fname_normalized][person.father_name_normalized] << person
    $persons << person
  }
end
