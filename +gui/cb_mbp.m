function cb_mbp(hTree, eventData, handles) %,additionalVar)
import javax.swing.*
import javax.swing.tree.*;  

% if eventData.isMetaDown % right-click is like a Meta-button
  % if eventData.getClickCount==2 % how to detect double clicks
      global jtree;

      clickX = eventData.getX;
      clickY = eventData.getY;
%       fprintf('shift: %i;\n', eventData.isControlDown);
%       fprintf('alt:   %i;\n', eventData.isAltDown);
      treePath = jtree.getPathForLocation(clickX, clickY);
      if isempty(treePath); return; end;
      if eventData.getClickCount() ~= 1; return; end;
      if eventData.isControlDown ~= 1; return; end;
          nr=eventData.getClickCount();
          %disp([num2str(x) ': click count:' num2str(nr)]);
          % check if the checkbox was clicked
          node = treePath.getLastPathComponent;
          nodeValue = node.getValue;
          ans = evalin('base', nodeValue)
          assignin('base', 'ans', ans);
end % function mousePressedCallback
