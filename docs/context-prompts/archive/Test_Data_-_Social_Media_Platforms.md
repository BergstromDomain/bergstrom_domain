# TASK
* Generate test data for Social Media Platforms to support manual testing. These platforms are likely to be added as a post deployment step to PROD once we get there
* This is for manual/exploratory testing in a local dev database — not FactoryBot factories for
  the automated suite (those live under `spec/factories/` and should already exist or be added
  there separately if the feature needs new ones).

---

# SCOPE
* Create the following 'Social Media Platforms' with the 'System Admin' as the author
| Name                    	| URL 					| Logo			| Description
| Facebook			| https://www.facebook.com/		| Facebook_Logo.png	| 
| LinkedIn			| https://au.linkedin.com/		| LinkedIn_Logo.png	| 
| Instagram			| https://www.instagram.com/		| Instagram_Logo.png	|
| WhatApp			| https://www.whatsapp.com/		| WhatsApp_Logo.jpg	|
| Board Game Arena		| https://boardgamearena.com/		| BGA_Logo.png		|
| Komoot			| https://www.komoot.com/		| Komoot_Logo.png	|
| Strava			| https://www.strava.com/		| Strava_Logo.jpeg	|
| The Crag			| https://www.thecrag.com/en/home	| theCrag_Logo.png	|
| Spotify			| https://open.spotify.com/		| Spotify_Logo.png	| 
| YouTube			| https://www.youtube.com/		| YouTube_Logo.png	|
| Meetup			| https://www.meetup.com/en-AU/		| Meetup_Logo.png	|



---

# REALISM CONSTRAINTS
N/A
---

# GENERATION METHOD
* [x] `bin/rails console` script (one-off, not committed)
* [ ] `db/seeds.rb` addition (if this should be repeatable/shared)
* [ ] Import via existing `ImportService`/CSV, if the app supports it

---

# CLEANUP
* N/A

---

# OPEN QUESTIONS
*(Running log of unresolved questions raised while generating data.)*

