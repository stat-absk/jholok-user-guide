# The app's Velvet & Gold colours, for charts and tables in the guide.
#
# Taken from the colour sets in Jholok/Assets.xcassets/Theme (light
# appearance). Keep them in step with the app: a reader should recognise a
# chart in the guide as the same chart on the phone.

guide_colours <- list(
  surface_base = "#F6F2EA",
  surface_raised = "#FFFDF8",
  surface_inset = "#EFE9DD",
  text_primary = "#1C1A16",
  text_secondary = "#6A6456",
  hairline = "#E2DACB",
  gold_mid = "#F5B81C",
  gold_deep = "#8A5200",
  jade = "#0E6F5A",
  ruby = "#A61E48",
  sapphire = "#1B5FB5",
  neutral = "#6B6258"
)

# Short is ruby and over is jade, as on Review and Result.
discrepancy_colours <- c(
  short = guide_colours$ruby,
  over = guide_colours$jade,
  matched = guide_colours$neutral
)
