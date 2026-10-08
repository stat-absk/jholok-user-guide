# Settings the whole guide shares.

# The day the app's screenshots were taken. The app's demo moves its story by
# whole weeks so it ends near the day it runs, so the guide's shop must end on
# the same day as the screenshots or their dates won't match. Change this
# whenever the screenshots are taken again (scripts/capture_screens.R checks).
screens_taken_on <- as.Date("2026-10-08")

# About when in the day they were taken, as minutes after midnight. The app
# times the stock it sends out back from the moment it starts, so this only
# moves those send-outs by an hour or two; the guide shows their dates.
screens_minute <- 17 * 60
