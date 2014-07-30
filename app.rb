$: << File.expand_path("../lib", __FILE__)

require "sinatra"
require "yajl"
require "crossref"
require "romeo"

configure do
  set :server, :puma
end

post "/validate" do
  parser = Yajl::Parser.new
  encoder = Yajl::Encoder.new
  metadata = parser.parse(request.body)

  response = {}

  unless metadata.has_key?("publisher")
    response[:errors] ||= []
    response[:errors] << "Publisher field is missing"
  end

  romeo = Romeo.new
  crossref = Crossref.new
  futures = []

  if metadata.has_key?("issn")
    futures << [
      :publisher_by_issn,
      Thread.new { romeo.issn(metadata.fetch("issn")) }
    ]
  end

  if metadata.has_key?("publisher")
    futures << [
      :publisher_by_publisher,
      Thread.new { romeo.publisher(metadata.fetch("publisher")) }
    ]
  end

  if metadata.has_key?("publication")
    futures << [
      :publisher_by_publication,
      Thread.new { romeo.title(metadata.fetch("publication")) }
    ]
  end

  if metadata.has_key?("id_number") && metadata.fetch("id_number") =~ /\A10\.\d{4,5}/
    futures << [
      :metadata_by_doi,
      Thread.new { crossref.doi(metadata.fetch("id_number")) }
    ]
  end

  futures.each_with_object(response) do |(key, thread), memo|
    memo[key] = thread.value
  end

  encoder.encode(response)
end

