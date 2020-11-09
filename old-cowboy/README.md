# The BEAM Blogger Webring

## What is a Webring

Webrings are an old school web thing that is having a small resurgence these days. The idea is that a bunch of sites with related subject matter join a (circular) list and they all include a small element to send traffic to the other parts of the Webring. Recently famed is the [Weird Wide Webring](https://weirdwidewebring.net/) that gathers interesting, odd and quirky sites. We'll be the next semi-medium-sized thing.

## How to join (or leave)

Check out `priv/sites` and add your site following the way `underjord.txt` is laid out in a new file. Stick to a single paragraph of text. Submit it as a PR and we will take a look.

Criteria:
- Run your own site (not Medium, dev.to), if this seems bad, let us know in the issues
- Your blog covers BEAM languages (Elixir, Erlang, Gleam, LFE and any others) or something closely related
- There is no requirement for how often you post

When you've been added we strongly recommend you integrate the shuffler to give back some idle traffic to the Webring. It doesn't do anything harmful. It is just a static piece of code with a couple of outbound links.

Somewhere below your content is recommended. Feel free to adjust the styling to fit your site but preferrably keep all the elements.

## How to integrate the shuffler

In `integration` you'll find the `webring.min.html` and `webring.html` which is the markup you need to integrate in your site. Just pick one, the .min is less readable but denser.

Once published you will be able to pull the current integration by just sending a GET request to /integration.

## How to get rid of us

Just send a PR to have your site removed and remove the shuffler from your site :)