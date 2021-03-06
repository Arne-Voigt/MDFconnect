# MDFconnect
## Scope/Usage
The repo allows the export of Matlab/Simulink simulation data into the mdf file format and the import from a mdf file for the use in Matlab/Simulink. The implementation should work for the 3.x versions of the file format, version 4.x (*.m4f) is not supported. 
  
 To get started use the repo [MDFconnect_example](https://github.com/Arne-Voigt/MDFconnect_example), it includes two simple example scripts for writing and reading. 
  
This repo was generated to familiar myself with object orientated programming in Matlab, so don?t expect this to be error free. 
However, I found it to be more reliable and faster than the widely used ?mdfimport? script. 
But you may also want to consider the ?Vehicle Network Toolbox?, which is Matlabs internal toolbox for interactions with mdf/m4f files. 
Alternatively, you could use one of the mdf importer/exporter libraries from python, those are often well maintained, and access it through Matlabs python-interface.

## SW structure
The mdf-format contains different elements that are linked together. For each of those element the repo defines a class. Those class objects will be linked together in the Matlab workspace, so that this structure is reflecting the structure of the mdf. 

Each of the classes is handling its writing into or its reading from a mdf-file. This means that for writing/reading a mdf-file the software just needs to step through the linked list of objects and call the write/read method.

The main class of the framework is MDF_OBJECT. It?s used to add simulation data for mdf file writing or it can be used to read in a mdf-file and extract the data.
  
### Example for writing:
start by collecting some data to write
```  
simDataBucket = tsBucket();
simDataBucket.add(logsout);
```

Copy data into the object and write the file
```
MdfObjWrite = MDF_OBJECT();
MdfObjWrite.importTsBucket(simDataBucket);
MdfObjWrite.print('testWrite.mdf');
```

### Example for reading:

start by reading the file
```
MdfObjRead = MDF_OBJECT();
MdfObjRead.read('testWrite.mdf');
```

next: extract signals into a Map container (Matlabs version of a hash-list), the signal names must adhere to the regex string

```
cntnr = MdfObjRead.hHD.getContainerOfAllCNsRegEx('.*');
```

finally: copy everything from the container into the Matlab workspace:
```
for key = cntnr.keys()
    sigData = cntnr(key{1}).getDataAsTimeseries();
    if ~isempty(sigData)
        assignin('base', sigData.Name, sigData);
    end
end
```



## Gui

The gui shows the structure of MDF_OBJECT objects (variables) inside the Matlab workspace. 
Each element of the structure can be exported into the workspace (ctrl+mouse_left), this allows to check for details or tweak the content.
Note the gui shows the structure of the Matlab workspace object and not the structure of the mdf file.
To inspect the actual file, use the MDFValidator from Vector Informatik GmbH.
  
To start the gui type: `gui.runGui`. Use the drop down menu to change the displayed object. The drop down menu contains all MDF_OBJECT objects that, 
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
