---
title: Importing And Downloading
app_section: event_tracker
supports_guest: false
supports_user: false
supports_content_creator: true
---

Content Creators and above can bring people and events in from a spreadsheet, and download them again. Both are under **Actions › Import & Export** in the left nav.

## Import People And Events

Upload a CSV file with one row per person and event, in these columns:

| First name | Last name | Event type | Event title | Event date |
| --- | --- | --- | --- | --- |
| Anna | Svensson | Birthday | Anna's Birthday | 1985-05-12 |

Choose **Download CSV Template** for a file with the right headings and one example row for each Event Type. Replace or delete the example rows before importing. Left as they are, each one fails with an invalid date.

How each row is handled:

- **Event type** must match an existing Event Type. Capitals don't matter.
- **Person**: an existing person is reused when their full name is exactly the first and last name given, ignoring capitals. Someone with a middle name won't match. Otherwise a new person is created.
- **Event**: an event whose title matches an existing event gets this person added to it, and its date is left as it is. Otherwise a new event is created.
- **Event date** is written `YYYY-MM-DD`. Leave out the year, like `-05-12`, when you don't know it.
- Everything new is created as **Restricted** and owned by you. Change the Visibility afterwards if you want to share it.

Each row is imported on its own, so a bad row doesn't stop the rest. Afterwards the page shows how many rows were imported and lists each failed row with its row number and the reason.

## Download People And Events

Narrow the list with the same Basic or SQL filter as *Filtering People And Events*, then choose **Download CSV**. The file has the same columns as the import, one row for each person and event, ordered by last name, and only includes what you're allowed to see. It's named `BergstromDomain_Occasions_` followed by the date.

In the download, an event without a year has an empty **Event date**, and a person with no events has empty event columns.
