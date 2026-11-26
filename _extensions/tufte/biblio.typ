$if(citations)$
$if(csl)$

#set bibliography(style: "$csl$")
$elseif(bibliographystyle)$

#set bibliography(style: "$bibliographystyle$")
$endif$
$if(bibliography)$
$if(reference-list)$

#bibliography($for(bibliography)$"$bibliography$"$sep$,$endfor$)
$else$

#hidden-bibliography($for(bibliography)$"$bibliography$"$sep$,$endfor$)
$endif$
$endif$
$endif$
