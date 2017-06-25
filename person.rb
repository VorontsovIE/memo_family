require 'sqlite3'
require 'sequel'

DB = Sequel.postgres('memorial', host: 'localhost', user: 'ilya', password: 'ilya')

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

def has_date?(date_memofmt); getYear(date_memofmt) || getMonth(date_memofmt) || getDay(date_memofmt); end

def dateHumanFormatted(dateInMemorialFmt)
  # [getDay(dateInMemorialFmt), getMonth(dateInMemorialFmt), getYear(dateInMemorialFmt)].drop_while(&:nil?).join('.')
  [getDay(dateInMemorialFmt), getMonth(dateInMemorialFmt), getYear(dateInMemorialFmt)].map{|x| x || '_' }.join('.')
end

class Person < Sequel::Model(:persons)
  def name; DB[:names].where(id: name_id).get(:value); end
  def surname; DB[:surnames].where(id: surname_id).get(:value); end
  def patronimic; DB[:patronimics].where(id: patronimic_id).get(:value); end
  
  def name_normalized; DB[:names].where(id: name_id).get(:normal_form); end
  def surname_normalized; DB[:surnames].where(id: surname_id).get(:normal_form); end
  def patronimic_normalized; DB[:patronimics].where(id: patronimic_id).get(:normal_form); end
  
  
  def has_age?; age_id && age_id != 0; end
  def has_occupation?; occupation_id && occupation_id != 0; end
  def has_criminal_article?; criminal_article_id && criminal_article_id != 0; end
  def has_judicial_organ?; judicial_organ_id && judicial_organ_id != 0; end
  def has_nation?; nation_id && nation_id != 0; end
  def has_sentence?; sentence_id && sentence_id != 0; end

  def age; DB[:ages].where(id: age_id).get(:value); end
  def occupation; DB[:occupations].where(id: occupation_id).get(:value); end
  def criminal_article; DB[:criminal_articles].where(id: criminal_article_id).get(:value); end
  def judicial_organ; DB[:judicial_organs].where(id: judicial_organ_id).get(:value); end
  def nation; DB[:nations].where(id: nation_id).get(:value); end
  def sentence; DB[:sentences].where(id: sentence_id).get(:value); end
  
  def memory_book; DB[:memory_books].where(id: memory_book_id).get(:title); end
  def memory_book_source; DB[:memory_books].where(id: memory_book_id).get(:source); end
  
  
  def has_birth_place?; birth_place_id && birth_place_id != 0; end
  def has_live_place?; live_place_id && live_place_id != 0; end
  
  def birth_place; DB[:places].where(id: birth_place_id).get(:value); end
  def live_place; DB[:places].where(id: live_place_id).get(:value); end
  

  def has_birth_date?; has_date?(birth_date_memofmt); end
  def has_arest_date?; has_date?(arest_date_memofmt); end
  def has_sud_date?; has_date?(sud_date_memofmt); end
  def has_mort_date?; has_date?(mort_date_memofmt); end
  def has_reab_date?; has_date?(reab_date_memofmt); end
  
  def birth_date; dateHumanFormatted(birth_date_memofmt); end
  def arest_date; dateHumanFormatted(arest_date_memofmt); end
  def sud_date; dateHumanFormatted(sud_date_memofmt); end
  def mort_date; dateHumanFormatted(mort_date_memofmt); end
  def reab_date; dateHumanFormatted(reab_date_memofmt); end

  def birth_year; getYear(birth_date_memofmt); end
  def year_of_arrest; getYear(arest_date_memofmt); end
  def year_of_death; getYear(mort_date_memofmt); end

  def family
    DB[:families].join(:person_to_family, :family_id => :id)
                 .join(:persons, :id => :person_id)
                 .where(Sequel[:persons][:id] => id)
                 .get(Sequel[:families][:value])
  end

  def education
    DB[:educations].join(:person_to_education, :education_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:educations][:value])
  end

  def criminal_case
    DB[:criminal_cases].join(:person_to_criminal_case, :criminal_case_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:criminal_cases][:value])
  end

  def arest_organ
    DB[:arest_organs].join(:person_to_arest_organ, :arest_organ_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:arest_organs][:value])
  end

  def arest_type
    DB[:arest_types].join(:person_to_arest_type, :arest_type_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:arest_types][:value])
  end

  def citizenship
    DB[:citizenships].join(:person_to_citizenship, :citizenship_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:citizenships][:value])
  end

  def party
    DB[:parties].join(:person_to_party, :party_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:parties][:value])
  end

  def rehabilitation_organ
    DB[:rehabilitation_organs].join(:person_to_rehabilitation_organ, :rehabilitation_organ_id => :id )
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:rehabilitation_organs][:value])
  end

  def rehabilitation_reason
    DB[:rehabilitation_reasons].join(:person_to_rehabilitation_reason, :rehabilitation_reason_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:rehabilitation_reasons][:value])
  end

  def mort_place
    DB[:mort_places].join(:person_to_mort_place, :mort_place_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:mort_places][:value])
  end

  def birth_year
    DB[:birth_years].join(:person_to_birth_year, :birth_year_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:birth_years][:value])
  end

  def previous_repression
    DB[:previous_repressions].join(:person_to_previous_repression, :previous_repression_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:previous_repressions][:value])
  end

  def next_repression
    DB[:next_repressions].join(:person_to_next_repression, :next_repression_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get(Sequel[:next_repressions][:value])
  end

  def name_variations
    DB[:name_variations].join(:person_to_name_variation, :name_variation_id => :id)
                    .join(:persons, :id => :person_id)
                    .where(Sequel[:persons][:id] => id)
                    .get([
                      Sequel[:name_variations][:var_name],
                      Sequel[:name_variations][:vari_fname],
                      Sequel[:name_variations][:vari_name],
                      Sequel[:name_variations][:vari_lname],
                      Sequel[:name_variations][:vari_all],
                    ]) || Array.new(5)
  end

  def capital_punishment?; sentence.match?(/ВМН|расстрел/i); end

  def full_name; "#{surname} #{name} #{patronimic}"; end

  def full_info
    [
      id, surname, name, patronimic, birth_date, birth_place, nation, occupation, live_place, 
      arest_date, judicial_organ, sud_date, criminal_article, sentence_id, rasstrel ? 'T' : 'F', mort_date, reab_date,
      memory_book, memory_book_source, age, sex,
      family, education, criminal_case, arest_organ, arest_type, citizenship, party, rehabilitation_organ, rehabilitation_reason,
      mort_place, birth_year, previous_repression, next_repression, *name_variations
    ]
  end
end


# Person.join(:names, :id => :name_id)
#   .select_all(:persons)
#   .select_append( Sequel.as(Sequel[:names][:value], :name) )
#   .select_append( Sequel.as(Sequel[:names][:normal_form], :name_normalized) )


# File.open('')
Person.order(:id).each{|person|
  # None helps join to work correct
  puts person.full_info.map{|x| x || 'None' }.join("\t")
}