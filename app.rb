$: << File.expand_path("../lib", __FILE__)

require "sinatra"
require "sinatra/jsonp"
require "multi_json"
require "crossref"
require "romeo"
require "gtr"

configure do
  set :server, :puma
end

post "/validate" do
  params = MultiJson.load(request.body)
  request.logger.info(params)

  record = {
    errors: []
  }

  unless params.has_key?("publisher")
    record[:errors] << "Publisher field is missing"
  end

  unless params.has_key?("issn")
    record[:errors] << "ISSN field is missing"
  end

  unless params.has_key?("title")
    record[:errors] << "Title field is missing"
  end

  unless params.has_key?("publication")
    record[:errors] << "Publication field is missing"
  end

  unless params.has_key?("id_number")
    record[:errors] << "DOI field is missing"
  end

  unless params.has_key?("funders")
    record[:errors] << "Funders field is missing"
  end

  unless params.has_key?("creators")
    record[:errors] << "Creators field is missing"
  end

  romeo = Romeo.new
  crossref = Crossref.new
  gtr = GTR.new

  futures = []

  if params.has_key?("issn")
    futures << Thread.new { romeo.issn(params.fetch("issn")) }
  end

  if params.has_key?("publisher")
    futures << Thread.new { romeo.publisher(params.fetch("publisher")) }
  end

  if params.has_key?("publication")
    futures << Thread.new { romeo.title(params.fetch("publication")) }
  end

  if params.has_key?("title")
    futures << Thread.new { crossref.title(params.fetch("title")) }
  end

  if params.has_key?("id_number") && params.fetch("id_number") =~ /10\.\d{4,5}/
    doi = params.fetch("id_number")[/(10\.\d{4,5}.+)/, 1]
    futures << Thread.new { crossref.doi(doi) }
    futures << Thread.new { crossref.funder(doi) }
  end

  if params.has_key?("creators")
    futures << Thread.new { gtr.projects(params.fetch("creators")) }
  end

  futures.each_with_object(record) do |thread, memo|
    thread.value.each do |key, value|
      (memo[key] ||= []).concat(Array(value))
    end
  end

  record.each do |key, value|
    value.uniq!
  end

  response.headers["Access-Control-Allow-Origin"] = "*"

  jsonp(record)
end

