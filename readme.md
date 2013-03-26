CScript Syntax Highlighter
====================

The purpose this project is create a Eclipse syntax highlighter to CScript language(Convey's DSL).

The project began with the idea of ​​making a CScrip syntax highlighting to Sublime Text([Show sublime Text installing](https://github.com/AugustoPedraza/CScript_Syntax_Highlighted#sublime-text-installing), but due to some limitations found during the development of sublime text version, I decided developing the sytax highlighting to Eclipse.


#### Sublime Text installing

1. Download the [cscript.tmLanguage](https://github.com/AugustoPedraza/CScript_Syntax_Highlighted/blob/master/sublime_text/cscript.JSON-tmLanguage) and [cscript.tmLanguage.cache](https://github.com/AugustoPedraza/CScript_Syntax_Highlighted/blob/master/sublime_text/cscript.tmLanguage.cache) files.

2. Open Sublime Text 2 and do click on *Preferences>Browse Packages.* Select the *User* folder and open it. Then move the files previously downloaded.

3. Restart Sublime Text and open a *.unit* file.



#### Editing the sublime tex syntax highlihgting.

1. Follow the steps from this [tutorial](http://docs.sublimetext.info/en/latest/extensibility/syntaxdefs.html)

2. Dowload the */sublime_text/cscript.JSON-tmLanguage* and use this to do the [tutorial](http://docs.sublimetext.info/en/latest/extensibility/syntaxdefs.html)


__NOTE:__ currently the sublime text version only highlight the header of file, the class definition and some methods.