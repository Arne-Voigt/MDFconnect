hFig = figure(); 
set(hFig,'WindowStyle','docked')

import javax.swing.*
import javax.swing.tree.*;
global jtree;

hc_main = uiflowcontainer('v0','Units','norm','Position',[0,0,1,1]);
set(hc_main,'FlowDirection','TopDown')

hc_minor = uiflowcontainer('v0','Units','norm','Position',[0,0,1,1]);
set(hc_minor,'Parent', hc_main)
set(hc_minor, 'HeightLimits',[20,26])
set(hc_minor,'FlowDirection','LeftToRight')

%% pushbutton
hpb =  uicontrol('string',' ','parent',hc_minor);
set(hpb, 'WidthLimits', [0 30]);
set(hpb, 'callback', @gui.cb_pb)
% icon in pushbutton
[a,map]=imread('+gui/myUpdate_6.png');
[r,c,d]=size(a); 
x=ceil(r/18); 
y=ceil(c/25); 
g=a(1:x:end,1:y:end,:);
g(g==255)=5.5*255;
set(hpb,'CData',g);

%% drop-down
s = whos; 
matches= strcmp({s.class}, 'MDF_OBJECT');
mdfObjects = {s(matches).name};

hdd = uicontrol('Style','popup', 'String',mdfObjects);
set(hdd, 'parent', hc_minor);
set(hdd, 'callback', @gui.cb_dd);
set(hdd, 'HeightLimits', [30,30]);


%% get all MDF_OBJECT in ws --> update dropDown
vars = evalin('base', 'whos');

matches = strcmp({vars.class}, 'MDF_OBJECT');
mdfObjects = {vars(matches).name};

hdd = evalin('base', 'hdd');
set(hdd, 'String', mdfObjects);

%% setup tree
if isempty(mdfObjects); return; end;

% [mtree, treeContainer] = uitree('v0', 'root', MdfObjWrite.getTreeNode(), 'Parent', hc_main); % Parent is ignored
objToDraw = evalin('base', mdfObjects{1});
strTreeInfo = sprintf('%s.getTreeNode()', mdfObjects{1});
[mtree, treeContainer] = uitree('v0', 'root', evalin('base', strTreeInfo),  'Parent', hc_main); % Parent is ignored
clear objToDraw     
jtree = mtree.getTree;
% MousePressedCallback is not supported by the uitree, but by jtree
set(jtree, 'MousePressedCallback',  @gui.cb_mbp);
  

%[mtree, container] = uitree('v0', 'root',root, 'Parent',hc); % Parent is ignored
%[mtree,container] = uitree('v0', 'Root', root,'Position',[50,50,150,150],SelectionChangeFcn, @callback);

set(treeContainer, 'Parent', hc_main)

% hb = uicontrol('string','press me','parent',hc_main);
% set(hb, 'HeightLimits',[20,20])

% expand HD-node
mtree.expand(mtree.Root.getChildAt(1))

drawnow