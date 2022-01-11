# MDFconnect
mdf read/write

## Gui

The gui shows the structure of MDF_OBJECT objects (variables) inside the matlab workspace. 
Each element of the structure can be exported into the workspace (ctrl+mouse_left), this allows to check for details or tweak the content.
Note the gui shows the structure of the matlab workspace object and not the structure of the mdf file.
To inspect the actual file use the MDFValidator from Vector Informatik GmbH.
  
To start the gui type: `gui.runGui`.Use the drop down menu to change the displayed object. The drop down menu contains all MDF_OBJECT objects that, 
at the time when `gui.runGui` was executed, where present in the matlab workspace.
  
![gui main](/doc/guiMain.JPG "main")
  
Press the update button to refresh the objects in the drop down menu.
![gui update](/doc/guiUpdate.JPG "update")
  
By clicking(ctrl+mouse_left) on an element in the gui-tree the element get exported to the matlab workspace as the ans-variable. The ans-variable can 
the be tweaked (e.g. delete a link), that tweaking will be also affect the respective element in the MDF_OBJECT. This is due to the way matlab handles the 
copying of handle-classes.      
![gui ans](/doc/guiAns.JPG "ans")
  
The gui might fail if the object has to many element, this happens for measuremtents with thousands of signals.
![gui ans](/doc/guiError.JPG "error")
