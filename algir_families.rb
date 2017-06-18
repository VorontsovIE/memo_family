require_relative 'person_match'

load_data!
load_persons!

AlgirPerson = Struct.new(:surname_normalized, :full_name, :birthdate, :birthplace, :sex, :nationality, :liveplace,
                         :obvin, :osujd_date, :osujd_org, :prigovor, :source) do
  def self.each_in_file(filename)
    return enum_for(:each_in_file, filename)  unless block_given?
    CSV.readlines(filename).drop(1).map{|row|
      yield self.new(*row)
    }
  end

  def chsir?; obvin&.match?(/ЧСИР/i); end
  def surname; full_name.split(' ').first; end

  def to_s
    additional_infos = [birthdate, nationality, birthplace].compact.reject(&:empty?).join(';')
    "#{full_name} (#{additional_infos})"
  end
  alias_method :inspect, :to_s
end

AlgirPerson.each_in_file('algir_normalized.csv').lazy.select(&:chsir?).map{|algir_person|
  same_surname_persons = $persons_by_normfname_name[algir_person.surname_normalized].values.flatten
  
  repressed_due_to_hypots = same_surname_persons.select(&:vmn?).reject{|person|
    person.full_name == algir_person.full_name # я - не родственник себя же
  }
  [algir_person, repressed_due_to_hypots]
}.select{|algir_person, repressed_due_to_hypots|
  repressed_due_to_hypots.size == 1
}.map{|algir_person, repressed_due_to_hypots|
  [algir_person, repressed_due_to_hypots.first]
}.select{|p1,p2|
  loc_match_any?([p1.birthplace, p1.liveplace], [p2.birthplace, p2.liveplace], threshold: 0.2)
}.each{|p1, p2|
  puts "-------------------------"
  puts "#{p1}\n#{p1.liveplace}"
  puts " ==> "
  puts "#{p2}\n#{p2.liveplace}"
}