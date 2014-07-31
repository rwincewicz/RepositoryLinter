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

  unless params.has_key?("creators")
    record[:errors] << "Creators field is missing"
  end

  romeo = Romeo.new
  crossref = Crossref.new
  gtr = GTR.new
  futures = []

  if params.has_key?("issn")
    futures << [
      :publishers,
      Thread.new { romeo.issn(params.fetch("issn")) }
    ]
  end

  if params.has_key?("publisher")
    futures << [
      :publishers,
      Thread.new { romeo.publisher(params.fetch("publisher")) }
    ]
  end

  if params.has_key?("publication")
    futures << [
      :publishers,
      Thread.new { romeo.title(params.fetch("publication")) }
    ]
  end

  if params.has_key?("title")
    futures << [
      :merge,
      Thread.new { crossref.title(params.fetch("title")) }
    ]
  end

  if params.has_key?("id_number") && params.fetch("id_number") =~ /10\.\d{4,5}/
    doi = params.fetch("id_number")[/(10\.\d{4,5}.+)/, 1]
    futures << [
      :merge,
      Thread.new { crossref.doi(doi) }
    ]
  end

  if params.has_key?("creators")
    futures << [
      :merge,
      Thread.new { gtr.projects(params.fetch("creators")) }
    ]
  end

  futures.each_with_object(record) do |(key, thread), memo|
    if :merge == key
      thread.value.each do |key, value|
        (memo[key] ||= []).concat(Array(value))
      end
    else
      (memo[key] ||= []).concat(Array(thread.value))
    end
  end

  record.each do |key, value|
    value.uniq!
  end

  response.headers["Access-Control-Allow-Origin"] = "*"

  jsonp(record)
end
