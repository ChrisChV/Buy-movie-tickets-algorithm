# Buy movie tickets algorithm

This dart project contains an algorithm to choose the better seats on the cinema.
Also contains a bot to buy movie tickets on [this page](https://www.cinemark-peru.com) using this algorithm.

## Algorithm

The algorithm is on `lib/algorithm.dart`. The algorithm is based on close clusters, since in
some cinemas the seats are already separated by a seat (as a health precaution),
so getting close clusters as results is also a valid answer. This proposal also works in
cinemas where all seats are available.

The user's preferred row is an input; the algorithm will start in this row. In the row it will find 
the cluster closest to the center of the room and it will be taken as valid if it does not exceed
the distance given by the user as input. If is not valid it goes to the next row, if is valid
gets the distance to the other clusters in the row and classifies them as valid if they do not exceed one
distance given by user as input. All valid ones join with the central cluster and the process is repeated
until there are enough seats to cover those required by the user.

**TODO**

- In the case that no valid cluster is found, the distances to the center should be obtained
  of all clusters and choose all those that are close to 0. In this case there are no longer seats together,
  then the best clusters in the room are bought regardless of whether they are together.
  
## Bot

The bot has two main parts: Finding the movie and buying the tickets.

In the part of finding the movie, you give to the bot some keys of the title of the movie you want to find.
The bot looks for the movie, if it can't find it, it refreshes the screen. When he finds it, he goes to the
purchase tickets part. This part was used to buy pre-sale tickets (where the movie appeared at midnight).

The part of buying tickets, navigates through the interface choosing the time and the type of seat.
When choosing the seats, it crawls the map of the room and passes it to the algorithm that returns
the right seats. The bot chooses the seats and continues browsing until the moment of purchase.

**TODO**

- Divide each navigation (page) so that when there is an error it only have to refresh the page and
  start from that part, don't restart the whole bot completely (current).
- Along with the previous point, have a better error handling and improve the bot so that it supports
  page outage or slow page loads.  
  
## Use

The bot uses [puppeteer](https://pub.dev/packages/puppeteer) to navigate in the page, so in
the first run it will download a version of chromium in the repository root (`.local-chromium /`),
so in the first execution it may take time.

To run it you need to have [dart installed](https://dart.dev/get-dart) and run this command:

```bash
dart bin/cine_ticket_bot.dar
```