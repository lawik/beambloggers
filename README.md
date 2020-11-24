# Webring

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Ordering of sites

To allow as many people as possible to get a fair bit of exposure on this site we pull RSS feeds from the sites and expose the latest posts by each site. We also sort the main site list by latest posting. This means that posting often is an advantage for staying high in the site listing. However the "Latest from the feeds" section will only show a given site once regardless of their number of recent posts. We also only show the latest three under the site listing. The hope is that this gives a decent bit of fairness for active bloggers. It is documented here so if you wonder why you are not up in the rotation up top, you probably don't have an RSS feed and we want to encourage you to have one.

We'll keep tweaking and tuning this functionality. There are some ideas about how to check freshness on non-RSS sites but RSS makes it easy so we start there. Suggestions and PRs are welcome.

