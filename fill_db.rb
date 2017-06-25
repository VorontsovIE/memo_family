require 'sequel'
# require_relative 'person_match'

def unquote(str)
  result = str
  result = result.gsub(/""/, '"')
  result = result[1..-2]  if result.match?(/^".*"$/)
  result
end

def value_id_rows(filename, &block)
  rows = File.readlines(filename).drop(1).map{|l| l.chomp.split(';', 2) }
  if block_given?
    rows.map{|id, val| [Integer(id), yield(unquote(val))] }
  else
    rows.map{|id, val| [Integer(id), unquote(val)] }
  end
end


def populate_table_with_id_value_pairs(database, table_name, csv_file)
  return  if database.table_exists?(table_name)
  database.create_table table_name do
    # primary_key :id
    Integer :id, primary_key: true, :index=>{ :unique=>true }  # non-autoincrementing
    String :value
  end
  database[table_name].import([:id, :value], value_id_rows(csv_file))
end

# source type is unique integer to store normal forms of different word types in a single table
def populate_table_with_id_value_normalized_value(database, table_name, source_type, csv_file)
  return  if database.table_exists?(table_name)
  database.create_table table_name do
    # primary_key :id
    Integer :id, primary_key: true, index: {unique: true}  # non-autoincrementing
    String :value
    foreign_key :normal_form_id, index: true
  end
  data = File.readlines(csv_file).drop(1).map{|line|
    id, value, normal_form = line.chomp.split("\t", 3)
    normal_form_id = DB[:normal_forms].where(value: normal_form, source_type: source_type).get(:id)
    normal_form_id ||= DB[:normal_forms].insert(value: normal_form, source_type: source_type)
    [Integer(id), value, normal_form_id]
  }
  database[table_name].import([:id, :value, :normal_form_id], data)
end

def populate_link_table(database, first_foreign_key, table_name, second_foreign_key, csv_file)
  return  if database.table_exists?(table_name)
  database.create_table table_name do
    foreign_key first_foreign_key, index: true
    foreign_key second_foreign_key, index: true
  end
  database[table_name].import([first_foreign_key, second_foreign_key], value_id_rows(csv_file){|other_id| Integer(other_id) } )
end


# DB = Sequel.connect('sqlite://memorial.db')

DB = Sequel.postgres('memorial', host: 'localhost', user: 'ilya', password: 'ilya')
populate_table_with_id_value_pairs(DB, :places, 'csv_unicode/geoplace.csv')
populate_table_with_id_value_pairs(DB, :judicial_organs, 'csv_unicode/sudorg.csv')
populate_table_with_id_value_pairs(DB, :criminal_articles, 'csv_unicode/stat.csv')
populate_table_with_id_value_pairs(DB, :occupations, 'csv_unicode/works.csv')
populate_table_with_id_value_pairs(DB, :sentences, 'csv_unicode/prigovor.csv')
populate_table_with_id_value_pairs(DB, :nations, 'csv_unicode/nations.csv')

populate_table_with_id_value_pairs(DB, :families, 'csv_unicode/fams.csv')
populate_table_with_id_value_pairs(DB, :educations, 'csv_unicode/educat.csv')
populate_table_with_id_value_pairs(DB, :criminal_cases, 'csv_unicode/delos.csv')
populate_table_with_id_value_pairs(DB, :arest_organs, 'csv_unicode/arestorg.csv')
populate_table_with_id_value_pairs(DB, :arest_types, 'csv_unicode/aresttyp.csv')
populate_table_with_id_value_pairs(DB, :citizenships, 'csv_unicode/poddan.csv')
populate_table_with_id_value_pairs(DB, :parties, 'csv_unicode/parties.csv')
populate_table_with_id_value_pairs(DB, :rehabilitation_organs, 'csv_unicode/reaborg.csv')
populate_table_with_id_value_pairs(DB, :rehabilitation_reasons, 'csv_unicode/reabreas.csv')
populate_table_with_id_value_pairs(DB, :mort_places, 'csv_unicode/mortplac.csv')
populate_table_with_id_value_pairs(DB, :ages, 'csv_unicode/ages.csv')
populate_table_with_id_value_pairs(DB, :birth_years, 'csv_unicode/birthyear.csv')
populate_table_with_id_value_pairs(DB, :previous_repressions, 'csv_unicode/reprprev.csv')
populate_table_with_id_value_pairs(DB, :next_repressions, 'csv_unicode/reprnext.csv')

populate_link_table(DB, :person_id, :person_to_family, :family_id, 'csv_unicode/linkfams.csv')
populate_link_table(DB, :person_id, :person_to_education, :education_id, 'csv_unicode/linkeducat.csv')
populate_link_table(DB, :person_id, :person_to_criminal_case, :criminal_case_id, 'csv_unicode/linkdelo.csv')
populate_link_table(DB, :person_id, :person_to_arest_organ, :arest_organ_id, 'csv_unicode/linkarestorg.csv')
populate_link_table(DB, :person_id, :person_to_arest_type, :arest_type_id, 'csv_unicode/linkaresttyp.csv')
populate_link_table(DB, :person_id, :person_to_citizenship, :citizenship_id, 'csv_unicode/linkpoddan.csv')
populate_link_table(DB, :person_id, :person_to_party, :party_id, 'csv_unicode/linkparty.csv')
populate_link_table(DB, :person_id, :person_to_rehabilitation_organ, :rehabilitation_organ_id, 'csv_unicode/linkreaborg.csv')
populate_link_table(DB, :person_id, :person_to_rehabilitation_reason, :rehabilitation_reason_id, 'csv_unicode/linkreabreas.csv')
populate_link_table(DB, :person_id, :person_to_mort_place, :mort_place_id, 'csv_unicode/linkmortplace.csv')
populate_link_table(DB, :person_id, :person_to_birth_year, :birth_year_id, 'csv_unicode/linkbirthye.csv')

populate_link_table(DB, :person_id, :person_to_previous_repression, :previous_repression_id, 'csv_unicode/linkreprprev.csv')
populate_link_table(DB, :person_id, :person_to_next_repression, :next_repression_id, 'csv_unicode/linkreprnext.csv')

populate_link_table(DB, :person_id, :person_to_name_variation, :name_variation_id, 'csv_unicode/linkvarfio.csv')


unless DB.table_exists?(:normal_forms)
  DB.create_table :normal_forms do
    primary_key :id, index: {unique: true}
    String :value
    Integer :source_type
    index [:value, :source_type], unique: true
  end
end

unless DB.table_exists?(:memory_books)
  DB.create_table :memory_books do
    primary_key :id
    String :title
    String :source
  end
  data = File.readlines('csv_unicode/books.csv').drop(1).map{|line|
    id, title, source = line.chomp.split(';', 3)
    [Integer(id), title, source]
  }
  DB[:memory_books].import([:id, :title, :source], data)
end

# normal form for surname is just name lowercased etc (for compatibility with father's name obtained from patronimic)
populate_table_with_id_value_normalized_value(DB, :names, 1, 'csv_unicode/names_w_normal_form.csv')
# normal form for surname is surname in masculine form
populate_table_with_id_value_normalized_value(DB, :surnames, 2, 'csv_unicode/surnames_w_normal_form.csv')
# normal form for patronimic is normalized father's name
populate_table_with_id_value_normalized_value(DB, :patronimics, 3, 'csv_unicode/patronimics_w_normal_form.csv')

unless DB.table_exists?(:name_variations)
  DB.create_table :name_variations do
    primary_key :id, index: {unique: true}
    String :var_name
    String :vari_fname
    String :vari_name
    String :vari_lname
    String :vari_all
    # just an example
    # String :var_template
    # String :var_surname
    # String :var_patronimic
    # String :var_all
    # String :surname_variants
    # String :etc_variants
  end
  data = File.readlines('csv_unicode/varnames.csv').drop(1).map{|line|
    id, *rest = line.chomp.split(';', 6)
    [Integer(id), *rest]
  }
  DB[:name_variations].import([:id, :var_name, :vari_fname, :vari_name, :vari_lname, :vari_all], data)
end

unless DB.table_exists?(:persons)
  DB.create_table :persons do
    Integer :id, primary_key: true, index: {unique: true} # not autoincrement (as it suffers from importing: starts autoincrement index from 1)

    foreign_key :surname_id, :surnames, index: true
    foreign_key :name_id, :names, index: true
    foreign_key :patronimic_id, :patronimics, index: true

    Integer :birth_date_memofmt
    foreign_key :birth_place_id, :places, index: true
    foreign_key :nation_id, :nations, index: true
    foreign_key :occupation_id, :occupations, index: true
    foreign_key :live_place_id, :places, index: true
    Integer :arest_date_memofmt
    foreign_key :judicial_organ_id, :judicial_organs, index: true
    Integer :sud_date_memofmt
    foreign_key :criminal_article_id, :criminal_articles, index: true
    foreign_key :sentence_id, :sentences, index: true
    TrueClass :rasstrel, index: true
    Integer :mort_date_memofmt
    Integer :reab_date_memofmt

    foreign_key :memory_book_id, :memory_books, index: true
    foreign_key :age_id, :ages, index: true
    String :sex, index: true
  end
  col_order = [
    :id, :surname_id, :name_id, :patronimic_id, :birth_date_memofmt, :birth_place_id, :nation_id, :occupation_id, :live_place_id,
    :arest_date_memofmt, :judicial_organ_id, :sud_date_memofmt, :criminal_article_id, :sentence_id, 
    :rasstrel, :mort_date_memofmt, :reab_date_memofmt, :memory_book_id, :age_id, :sex,
  ]
  data = File.open('csv_unicode/persons.csv'){|f|
    f.readline
    f.each_line.each_slice(10000).map{|chunk|
      data = chunk.map{|str|
        id, surname_id, name_id, patronimic_id, birth_date_memofmt, birth_place_id, nation_id, occupation_id, live_place_id,
          arest_date_memofmt, judicial_organ_id, sud_date_memofmt, criminal_article_id, sentence_id, 
          rasstrel, mort_date_memofmt, reab_date_memofmt, memory_book_id, age_id, sex = str.chomp.split(";")
        [ Integer(id), Integer(surname_id), Integer(name_id), Integer(patronimic_id), Integer(birth_date_memofmt), 
          Integer(birth_place_id), Integer(nation_id), Integer(occupation_id), Integer(live_place_id), Integer(arest_date_memofmt), 
          Integer(judicial_organ_id), Integer(sud_date_memofmt), Integer(criminal_article_id), Integer(sentence_id), rasstrel == 'T', 
          Integer(mort_date_memofmt), Integer(reab_date_memofmt), Integer(memory_book_id), Integer(age_id), sex ]
      }
      DB[:persons].import(col_order, data)
    }
  }
end
