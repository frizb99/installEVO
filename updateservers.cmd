set roboOptions=/R:2 /W:10 /NDL /NP /mir



FOR %%i IN (willisserver rnssserver nv01server az08server fl01server az07server az12server) DO (
robocopy \\rnssitstorage\software\evo "\\%%i\support files\evo" * %roboOptions% 


)


pause

exit /b

