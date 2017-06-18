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

VarFIO = Struct.new(:varname, :varifname, :variname, :varilname, :variall) do
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

def load_data!
  $FNAMES = File.readlines('csv_unicode/fnames.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $FNAMES_NORMALIZED = File.readlines('csv_unicode/fnames_normalized.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $NAMES = File.readlines('csv_unicode/names.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $LNAMES = File.readlines('csv_unicode/lnames.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PLACES = File.readlines('csv_unicode/geoplace.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $NATIONS = File.readlines('csv_unicode/nations.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $STATS = File.readlines('csv_unicode/stat.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $WORKS = File.readlines('csv_unicode/works.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $SUDORG = File.readlines('csv_unicode/sudorg.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h

  $REABORGAN = File.readlines('csv_unicode/reaborg.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PERSON_TO_REABORGAN = File.readlines('csv_unicode/linkreaborg.csv').drop(1).map{|l| person_id, reaborg_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(reaborg_id)] }.to_h

  $EDUCATION = File.readlines('csv_unicode/educat.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PERSON_TO_EDUCATION = File.readlines('csv_unicode/linkeducat.csv').drop(1).map{|l| person_id, educat_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(educat_id)] }.to_h

  $REPR_PREV = File.readlines('csv_unicode/reprprev.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PERSON_TO_REPR_PREV = File.readlines('csv_unicode/linkreprprev.csv').drop(1).map{|l| person_id, repr_prev_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(repr_prev_id)] }.to_h
  $REPR_NEXT = File.readlines('csv_unicode/reprnext.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PERSON_TO_REPR_NEXT = File.readlines('csv_unicode/linkreprnext.csv').drop(1).map{|l| person_id, repr_next_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(repr_next_id)] }.to_h

  $EDUCATION = File.readlines('csv_unicode/educat.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PERSON_TO_EDUCATION = File.readlines('csv_unicode/linkeducat.csv').drop(1).map{|l| person_id, educat_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(educat_id)] }.to_h

  $ARESTTYPE = File.readlines('csv_unicode/aresttyp.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PERSON_TO_ARESTTYPE = File.readlines('csv_unicode/linkaresttyp.csv').drop(1).map{|l| person_id, aresttype_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(aresttype_id)] }.to_h

  $PODDAN = File.readlines('csv_unicode/poddan.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h
  $PERSON_TO_PODDAN = File.readlines('csv_unicode/linkpoddan.csv').drop(1).map{|l| person_id, poddanstvo_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(poddanstvo_id)] }.to_h

  $PERSON_TO_FAMILY = File.readlines('csv_unicode/linkfams.csv').drop(1).map{|l| person_id, fam_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(fam_id)] }.to_h
  $FAMILIES = File.readlines('csv_unicode/fams.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h

  $VARFIO = File.readlines('csv_unicode/varnames.csv').drop(1).map{|l| id, *vals = l.split(';', 6).map(&:strip); [Integer(id), VarFIO.from_raw_strings(*vals)] }.to_h
  $PERSON_TO_VARFIO = File.readlines('csv_unicode/linkvarfio.csv').drop(1).map{|l| person_id, varfio_id = l.split(';', 2).map(&:strip); [Integer(person_id), Integer(varfio_id)] }.to_h


  $PRIGOVORS = File.readlines('csv_unicode/prigovor.csv').drop(1).map{|l| id, val = l.split(';', 2).map(&:strip); [Integer(id), val] }.to_h

  # Немного неоднозначно отчеству сопоставляется имя:  Эмильевич и Эмильевна --> Эмиль/Эмилий. Игнорируем
  $lname_to_name = File.readlines('man_names.tsv').map{|l| l.chomp.split("\t") }.flat_map{|name, lnames|
    lnames.split(',').map{|lname| [lname, name] }
  }.to_h
end

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
  def fname_normalized; $FNAMES_NORMALIZED[fname_id]; end
  def name; $NAMES[name_id]; end
  def lname; $LNAMES[lname_id]; end

  def birthplace; $PLACES[birthplace_id]; end
  def liveplace; $PLACES[liveplace_id]; end
  
  def stat; $STATS[stat_id]; end
  def work; $WORKS[stat_id]; end
  def sudorgan; $SUDORG[stat_id]; end
  
  def birthdate; dateHumanFormatted(birthdate_memofmt); end
  def arestdate; dateHumanFormatted(arestdate_memofmt); end
  def suddate; dateHumanFormatted(suddate_memofmt); end
  def mortdate; dateHumanFormatted(mortdate_memofmt); end
  def reabdate; dateHumanFormatted(reabdate_memofmt); end
  
  def father_name; $lname_to_name[lname]; end
  def full_name; "#{fname} #{name} #{lname}"; end
  def nation; $NATIONS[nation_id]; end
  def family; fam_id = $PERSON_TO_FAMILY[id]; fam_id && $FAMILIES[fam_id] end
  def reaborgan; reaborg_id = $PERSON_TO_REABORGAN[id]; reaborg_id && $REABORGAN[reaborg_id] end
  def education; educat_id = $PERSON_TO_EDUCATION[id]; educat_id && $EDUCATION[educat_id] end
  def poddanstvo; poddanstvo_id = $PERSON_TO_PODDAN[id]; poddanstvo_id && $PODDAN[poddanstvo_id] end
  def varfio; varfio_id = $PERSON_TO_VARFIO[id]; varfio_id && $VARFIO[varfio_id] end

  def aresttype; aresttype_id = $PERSON_TO_ARESTTYPE[id]; aresttype_id && $ARESTTYPE[aresttype_id] end

  def repr_prev; repr_prev_id = $PERSON_TO_REPR_PREV[id]; repr_prev_id && $REPR_PREV[repr_prev_id] end
  def repr_next; repr_next_id = $PERSON_TO_REPR_NEXT[id]; repr_next_id && $REPR_NEXT[repr_next_id] end

  def prigovor; $PRIGOVORS[prigovor_id]; end
  def vmn?; prigovor.match?(/ВМН|расстрел/i); end
  def to_s
    additional_infos = [birthdate, nation, birthplace].reject(&:empty?).join(';')
    "#{full_name} (#{additional_infos})"
  end

  def infocard
    result = ["#{full_name} (#{birthdate}) - #{nation}; #{poddanstvo}"]
    result << "Варианты имени: #{varfio}" if varfio
    result << "Родился: #{birthplace}" if !birthplace.empty?
    result << "ПМЖ: #{liveplace}" if !liveplace.empty?
    result << "Семья: #{family}"  if family && !family.empty?
    result << "Образование: #{education}"  if education && !education.empty?
    result << "Арест: #{arestdate} #{aresttype}" if (aresttype && !aresttype.empty?) || !arestdate.empty?
    result << "Постановление: (#{suddate}) #{stat} -- #{sudorg}"  if !suddate.empty? || !stat.empty? || !sudorg.empty?
    result << "Приговор: #{prigovor}; Расстрел: #{rasstrel ? 'да' : 'нет'}; Умер: #{mortdate}" if !prigovor.empty? || !mortdate.empty?
    result << "Реабилитирован: (#{reabdate}) #{reaborgan}"  if !reabdate.empty? || !reaborgan.empty?
    result.join("\n")
  end
  
  def full_info_row
    [id, fname, name, lname, birthdate, birthplace, nation, work, liveplace, 
      arestdate, sudorgan, suddate, stat, prigovor, rasstrel, mortdate, reabdate, book, age, gender].join("\t")
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
  places_1.any?{|place_1|
    places_2.any?{|place_2|
      loc_match?(place_1, place_2, threshold: threshold)
    }
  }
end

def load_persons!
  $persons_by_normfname_name = Hash.new{|h, fname|
    h[fname] = Hash.new{|h2, name|
      h2[name] = []
    }
  }

  $persons_by_fname_name = Hash.new{|h, fname|
    h[fname] = Hash.new{|h2, name|
      h2[name] = []
    }
  }

  $persons = []

  Person.each_in_file('csv_unicode/persons.csv'){|person|
    $persons_by_fname_name[person.fname][person.name] << person
    $persons_by_normfname_name[person.fname_normalized][person.name] << person
    $persons << person
  }
end
