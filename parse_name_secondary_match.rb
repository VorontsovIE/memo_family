require 'open-uri'
require 'nokogiri'

man_names = []
(1..8).each do |ind|
  page = Nokogiri.parse(open("http://petroleks.ru/names/man#{ind}.php"))
  tbl = page.css('table').detect{|tbl|
    tbl.css('tr').first.css('td:last').text == 'Производное от имени отчество'
  }
  man_names += tbl.css('tr').drop(1).map{|row|
    name, secondaries = row.css('td').map(&:text).map{|txt| txt.encode(Encoding::UTF_8)}
    [name, secondaries.split(',').map(&:strip).reject(&:empty?).join(',')]
  }
end
puts man_names.map{|row| row.join("\t") }
