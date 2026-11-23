#show: doc => handout(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(running)$
  running: [$running$],
$endif$
  doc,
)
