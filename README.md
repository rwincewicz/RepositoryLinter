RepositoryLinter
================

An entry to the [Repositories Fringe 14](http://www.repositoryfringe.org/) Developer Challenge by [Rory McNicholl](https://github.com/cziaarm), [Paul Mucur](https://github.com/mudge) and [Richard Wincewicz](https://github.com/rwincewicz).

This is a small API that, given article metadata in the form of ePrints JSON,
will consult various different services (see below) to pull as much missing
data as possible.

## Usage

Post your article metadata as JSON to `/validate` to receive metadata in return:

```console
$ curl localhost:4567/validate -d '{ "title": "Revisiting the River Skerne: the long-term social benefits of river rehabilitation" }'
```

Will return:

```javascript
{
  "errors": [
    "Publisher field is missing",
    "ISSN field is missing",
    "Publication field is missing",
    "DOI field is missing",
    "Funders field is missing",
    "Creators field is missing"
  ],
  "dois": [
    {
      "title": "Revisiting the River Skerne: The long-term social benefits of river rehabilitation",
      "doi": "http://dx.doi.org/10.1016/j.landurbplan.2013.01.009"
    }
  ]
}
```

## APIs used

* [CrossRef](http://search.crossref.org/help/api);
* [SHERPA/RoMEO](http://www.sherpa.ac.uk/romeo/api.html);
* [Gateway to Research](http://gtr.rcuk.ac.uk/resources/api.html).
