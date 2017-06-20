require 'zlib'
require 'sinatra'
require_relative 'person_match'

def pairs_for_person(person_id)
  [$pairs_by_first_id[person_id], $pairs_by_second_id[person_id]].compact.inject([], &:+).uniq
end

def entire_family_pairs(person_id)
  pairs = []
  new_pairs = pairs_for_person(person_id)
  while new_pairs.size > pairs.size
    pairs = new_pairs
    new_pairs = new_pairs.flat_map{|person_1, person_2, link_id|
      pairs_for_person(person_1) + pairs_for_person(person_2)
    }.uniq
  end
  pairs
end

LINK_TYPES = ['Является отцом', 'Сиблинги', 'Дубликат']

Zlib::GzipReader.open('parent_sibling_duplicate_pairs.tsv.gz') {|gz|
  $pairs = gz.readlines.map{|row| row.split("\t").first(3).map(&:to_i) }
}

$pairs_by_first_id = $pairs.group_by{|pair| pair[0] }
$pairs_by_second_id = $pairs.group_by{|pair| pair[1] }

load_data!
load_persons!

$person_by_id = $persons.map{|person| [person.id, person] }.to_h

get '/pair/:id' do
  id = Integer(params['id'])
  person_1_id, person_2_id, link_type_id = *$pairs[id]
  person_1 = $person_by_id[person_1_id]
  person_2 = $person_by_id[person_2_id]
  haml :show_pair, locals: {person_1: person_1, person_2: person_2, link_type: LINK_TYPES[link_type_id]}
end

get '/' do
  id = (rand * $pairs.size).to_i
  redirect to("/pair/#{id}")
end

# family_id is an id of any person in family
get '/family/:family_id' do
  family_id = Integer(params['family_id'])
  pairs = entire_family_pairs(family_id)
  p pairs
  relations = pairs.map{|first_id, second_id, link_id|
    {person_1: $person_by_id[first_id], person_2: $person_by_id[second_id], link_type: LINK_TYPES[link_id]}
  }
  haml :show_family, locals: {relations: relations}
end
