$: << File.expand_path("../lib", __FILE__)

require "sinatra"
require "sinatra/jsonp"
require "rack/parser"
require "multi_json"
require "crossref"
require "romeo"

configure do
  set :server, :puma
end

use Rack::Parser, parsers: {
  "application/json" => -> (body) { MultiJson.load(body) }
}

post "/validate" do
  response = {
    errors: []
  }

  unless params.has_key?("publisher")
    response[:errors] << "Publisher field is missing"
  end

  unless params.has_key?("issn")
    response[:errors] << "ISSN field is missing"
  end

  unless params.has_key?("title")
    response[:errors] << "Title field is missing"
  end

  unless params.has_key?("publication")
    response[:errors] << "Publication field is missing"
  end

  romeo = Romeo.new
  crossref = Crossref.new
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

  if params.has_key?("id_number") && params.fetch("id_number") =~ /\A10\.\d{4,5}/
    futures << [
      :merge,
      Thread.new { crossref.doi(params.fetch("id_number")) }
    ]
  end

  futures.each_with_object(response) do |(key, thread), memo|
    if :merge == key
      thread.value.each do |key, value|
        (memo[key] ||= []).concat(Array(value))
      end
    else
      (memo[key] ||= []).concat(Array(thread.value))
    end
  end

  response.each do |key, value|
    value.uniq!
  end

  jsonp(response)
end

