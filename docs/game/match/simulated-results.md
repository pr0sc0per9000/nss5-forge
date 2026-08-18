# Scorelines for matches the player does not play

> **Source:** `TFixture.GetRandomGoal` @ 0x004c4d29 (VERIFIED) · `TFixture.PlayFixture` @ 0x004c47e1 (READ)
> **Confidence:** HIGH
> **Last checked:** 2026-08-15

Most matches in a season are not played by the user - every other fixture in every other
league still needs a result. The game does not simulate those matches. It rolls each team's
goal count independently from a **fixed weighted table** that ignores who is playing.

## The table

`TFixture.GetRandomGoal()` returns a number of goals from 0 to 10, picked from these weights:

| Goals | Weight | Chance |
|---:|---:|---:|
| 0 | 1536 | **23.82%** |
| 1 | 1536 | **23.82%** |
| 2 | 1536 | **23.82%** |
| 3 | 1536 | **23.82%** |
| 4 | 256 | 3.97% |
| 5 | 32 | 0.50% |
| 6 | 8 | 0.124% |
| 7 | 4 | 0.062% |
| 8 | 2 | 0.031% |
| 9 | 1 | 0.0155% |
| 10 | 1 | 0.0155% |

Total weight 6,448. `TFixture.PlayFixture` calls this **twice** - once for the home team,
once for the away team - and the two rolls are independent.

## What this means in play

**Nothing about the teams affects the result.** Not their rating, not their form, not home
advantage, not the league they are in. A bottom-of-the-table side has exactly the same
scoring distribution as the champions. Every simulated fixture in the game world is a coin
toss from the same jar.

**0, 1, 2 and 3 goals are exactly equally likely**, at 23.82% each. Together they account
for 95.3% of all team scores. Real football is not shaped like this - actual team scores
peak at 1 goal and fall away - so simulated results carry noticeably more 0-0s and more 3-3s
than a real league table would produce.

Four or more goals is rare: 4.6% combined. Double figures happen about once in every 6,448
team-innings, so roughly once every few thousand fixtures somebody wins 10-0.

## Why it is worth knowing

This is a small function with a large reach. Every league table, every promotion and
relegation race, every rival's form in a career happens downstream of this table. If the
game world ever feels statistically flat - mid-table sides going unbeaten, giants getting
thrashed for no reason - this is the cause, and it is a single array of eleven integers.

It is also probably the cheapest meaningful rebalance in the whole game. Replacing the flat
0-3 plateau with a Poisson-shaped table weighted by team rating would make the simulated
world behave like football, and it touches one function.

## Implementation detail worth preserving

The pick loop has an edge case that is easy to get wrong when reimplementing. The code rolls
`r = Rand(1, tot)` - inclusive on both ends - then walks the table subtracting weights, and
returns `i` when `w[i] > r`. Because the roll starts at 1 rather than 0, the very top value
(`r = 6448`) falls through the entire loop and hits the trailing `Return 0`.

So 0 goals is reached by two separate paths: 1,535 values at the top of the loop and one
value falling off the end. It still totals exactly 1,536, so the distribution above is
correct - but a reimplementation that "cleans up" the loop into a conventional
`r = Rand(0, tot-1)` walk will silently shift every probability by one roll. The behaviour
is right by accident of the fallthrough, not by design, and it should be copied deliberately
rather than tidied.

*Jargon note: `Rand(a, b)` in BlitzMax returns a whole number between `a` and `b` including
both ends. "Weight" here just means how many tickets that outcome has in the raffle - the
chance is the outcome's tickets divided by 6,448 total tickets.*
