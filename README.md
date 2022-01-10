# MDFconnect
mdf read/write

## Gui

The gui shows the structure of a mdf object in the matlab workspace. 
Each element of the structure can be exported into the workspace (ctrl+mouse_left), this allows to check for details or tweak the content.
Note the gui shows the structur of the object in the matlab workspace and not the actual structur of the mdf file.
To inspect the actual file use the MDFValidator from Vector Informatik GmbH.
  
Start the gui via: `gui.runGui`. The displayed object can be selected through the drop down menu. The drop down menu contains all MDF_Object objects that, 
at the time when `gui.runGui` was executed, where present in the matlab workspace.
  
![gui main](/doc/guiMain.JPG "main")
  
Press the update button to refresh the objects in the drop down menu.
![gui update](/doc/guiUpdate.JPG "update")
  
![gui ans](/doc/guiAns.JPG "ans")
  
The gui might fail if the object has to many element, this happens for measuremtents with thousends of signals.
![gui ans](/doc/guiError.JPG "error")
