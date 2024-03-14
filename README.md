# Webring

The Beam Bloggers webring is a collection of people and small companies blogging about Elixir, Erlang and other topics around the BEAM ecosystem. You find the site at [beambloggers.com](https://beambloggers.com).

## What is a Webring

Webrings are an old school web thing that is having a small resurgence these days. The idea is that a bunch of sites with related subject matter join a (circular) list and they all include a small element to send traffic to the other parts of the Webring. Recently famed is the [Weird Wide Webring](https://weirdwidewebring.net/) that gathers interesting, odd and quirky sites. We'll be the next semi-medium-sized thing.

We're currently not particularly circular and we need a new design for our UI to navigate to the next page in the ring. You can already create your own links though by pointing towards `/random`, `/prev` and `/next` on the beamblogger domain. Besides that we gather the sites and provide them to visitors :)

## How to join (or leave)

Check out `priv/sites` and add your site following the way `underjord.txt` is laid out in a new file. Stick to a single paragraph of text. Submit it as a PR and we will take a look.

Criteria:
- Run your own site (not Medium, dev.to), if this seems bad, let us know in the issues
- Your blog covers BEAM languages (Elixir, Erlang, Gleam, LFE and any others) or something closely related
- There is no requirement for how often you post

Recommendations:
- Get an RSS feed if you don't have one already and add an RSS autodiscovery link if you don't have one
- Add links on your site and point them to `/` (webring home), `/next`, `/prev` and `/random`

If you want to leave or get rid of us, send a PR and we'll let you go :)

### RSS autodiscovery example

We use these to pull your latest content and show it. It is an open standard. You control what we get and can show.

```
<link rel="alternate" type="application/rss+xml" href="https://underjord.io/feed.xml" />
```

## Ordering of sites

To allow as many people as possible to get a fair bit of exposure on this site we pull RSS feeds from the sites and expose the latest posts by each site. We also sort the main site list by latest posting. This means that posting often is an advantage for staying high in the site listing. However the "Latest from the feeds" section will only show a given site once regardless of their number of recent posts. We also only show the latest three under the site listing. The hope is that this gives a decent bit of fairness for active bloggers. It is documented here so if you wonder why you are not up in the rotation up top, you probably don't have an RSS feed and we want to encourage you to have one.

We'll keep tweaking and tuning this functionality. There are some ideas about how to check freshness on non-RSS sites but RSS makes it easy so we start there. Suggestions and PRs are welcome.

## Running the thing

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:8989`](http://localhost:8989) from your browser.
