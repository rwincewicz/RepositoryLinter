require "net/http"
require "uri"
require "multi_json"
require "rack/utils"

class Crossref
  def funder(doi)
    uri = URI("http://api.crossref.org/works")
    uri.query = Rack::Utils.build_query(filter: "has-funder:true,doi:#{doi}")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/json"

    response = http.request(request)

    metadata = MultiJson.load(response.body)
    funders = metadata.fetch("message", {}).fetch("items", []).flat_map { |item|
      item["funder"]
    }

    {
      funders: funders
    }
  end

  def doi(doi)
    uri = URI("http://data.crossref.org/#{CGI.escape(doi)}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/json"

    response = http.request(request)

    metadata = MultiJson.load(response.body)

    {
      title: metadata["title"],
      issn: metadata["ISSN"],
      publishers: [{ name: metadata["publisher"] }],
      publications: [{ title: metadata["container-title" ], issn: metadata.fetch("ISSN", []).first }],
      volume: metadata["volume"],
      page: metadata["page"],
      authors: metadata["author"],
      subjects: metadata["subject"]
    }
  end

  def title(title)
    uri = URI("http://search.crossref.org/dois?q=#{CGI.escape(%{"#{title}"})}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/json"

    response = http.request(request)

    metadata = MultiJson.load(response.body)

    {
      dois: metadata.map { |record| { title: record['title'], doi: record['doi'] } }
    }
  end
end

