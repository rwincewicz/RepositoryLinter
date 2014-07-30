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
  response = {}

  unless params.has_key?("publisher")
    response[:errors] ||= []
    response[:errors] << "Publisher field is missing"
  end

  romeo = Romeo.new
  crossref = Crossref.new
  futures = []

  if params.has_key?("issn")
    futures << [
      :publisher_by_issn,
      Thread.new { romeo.issn(params.fetch("issn")) }
    ]
  end

  if params.has_key?("publisher")
    futures << [
      :publisher_by_publisher,
      Thread.new { romeo.publisher(params.fetch("publisher")) }
    ]
  end

  if params.has_key?("publication")
    futures << [
      :publisher_by_publication,
      Thread.new { romeo.title(params.fetch("publication")) }
    ]
  end

  if params.has_key?("id_number") && params.fetch("id_number") =~ /\A10\.\d{4,5}/
    futures << [
      :metadata_by_doi,
      Thread.new { crossref.doi(params.fetch("id_number")) }
    ]
  end

  futures.each_with_object(response) do |(key, thread), memo|
    memo[key] = thread.value
  end

  jsonp(response)
end

