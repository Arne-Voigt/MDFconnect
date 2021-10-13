function cb_dd( ObjectH, EventData )
%CB_DD Summary of this function goes here
%   Detailed explanation goes here

ObjectH.Value;

if isempty(ObjectH.Value); return; end;

evalin('base', 'treeContainer.delete');

objName = ObjectH.String{ObjectH.Value};
%objToDraw = evalin('base', objName);
hc_main = evalin('base', 'hc_main');

%objToDraw = evalin('base', mdfObjects{1});
strTreeInfo = sprintf('%s.getTreeNode()', objName);
uiTreeNode = evalin('base', strTreeInfo);

%[mtree, treeContainer] = uitree('v0', 'root', objToDraw.getTreeNode(),      'Parent', hc_main); % Parent is ignored
[mtree, treeContainer] = uitree('v0', 'root', uiTreeNode,  'Parent', hc_main); % Parent is ignored



clear objToDraw     
jtree = mtree.getTree;
% MousePressedCallback is not supported by the uitree, but by jtree
set(jtree, 'MousePressedCallback',  @gui.cb_mbp);
  

%[mtree, container] = uitree('v0', 'root',root, 'Parent',hc); % Parent is ignored
%[mtree,container] = uitree('v0', 'Root', root,'Position',[50,50,150,150],SelectionChangeFcn, @callback);

set(treeContainer, 'Parent', hc_main)

mtree.expand(mtree.Root.getChildAt(1))

assignin('base', 'treeContainer',  treeContainer);
assignin('base', 'jtree',  jtree);
drawnow

end

