require "net/http"
require "uri"
require "multi_json"

class Crossref
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
      publication: metadata["container-title"],
      volume: metadata["volume"],
      page: metadata["page"],
      authors: metadata["author"],
      subjects: metadata["subject"]
    }
  end
end


