require 'zlib'
require 'sinatra'
require_relative 'person_match'

Zlib::GzipReader.open('pairs_reabdate_twopass.tsv.gz') {|gz|
  $pairs = gz.readlines.map{|row| row.split("\t").first(2).map(&:to_i) }
}

load_data!
load_persons!

$person_by_id = $persons.map{|person| [person.id, person] }.to_h

get '/' do
  if params['id']
    id = Integer(params['id'])
    father_id, child_id = *$pairs[id]
    father_id, child_id = *$pairs.sample
    father = $person_by_id[father_id]
    child = $person_by_id[child_id]
    haml :show_pair, locals: {person_1: father, person_2: child}
  else
    id = (rand * $pairs.size).to_i
    redirect to("/?id=#{id}")
  end
  redirect
end
