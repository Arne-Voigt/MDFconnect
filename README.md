# MDFconnect
## Scope/Usage
The repo allows the export of Matlab/Simulink simulation data into the mdf file format and the import from a mdf file for the use in Matlab/Simulink. The implementation should work for the 3.x versions of the file format, version 4.x (*.m4f) is not supported. 
  
 To get started use the repo MDFconnect_example, it includes a two simple example scripts for writing Simulink data into a mdf-file and for importing mdf-data into the Matlab workspace. 
  
This repo was generated to familiar myself with object orientated programming in Matlab, so don’t expect this to be error free. 
However, I found it to more convenient, reliable and faster than the widely used “mdfimport” script. 
But you may also want to consider the “Vehicle Network Toolbox”, which is the Matlab internal toolbox for interactions with the mdf/m4f files. 
Alternatively, you could use one of the mdf importer/exporter libraries from python, those are often well maintained, and access it through Matlabs python-interface.  

## Gui

The gui shows the structure of MDF_OBJECT objects (variables) inside the Matlab workspace. 
Each element of the structure can be exported into the workspace (ctrl+mouse_left), this allows to check for details or tweak the content.
Note the gui shows the structure of the Matlab workspace object and not the structure of the mdf file.
To inspect the actual file, use the MDFValidator from Vector Informatik GmbH.
  
To start the gui type: `gui.runGui` .Use the drop down menu to change the displayed object. The drop down menu contains all MDF_OBJECT objects that, 
at the time when `gui.runGui` was executed, where present in the Matlab workspace.
  
![gui main](/doc/guiMain.JPG "main")
  
Press the update button to refresh the objects in the drop down menu.
![gui update](/doc/guiUpdate.JPG "update")
  
By clicking(ctrl+mouse_left) on an element in the gui-tree the element get exported to the matlab workspace as the ans-variable. The ans-variable can 
the be tweaked (e.g. delete a link), that tweaking will be also affect the respective element in the MDF_OBJECT. This is due to the way Matlab handles the 
copying of handle-classes.      
![gui ans](/doc/guiAns.JPG "ans")
  
The gui might fail if the object has to many element, this happens for measurements with thousands of signals.
![gui ans](/doc/guiError.JPG "error")
